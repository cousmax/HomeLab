#!/usr/bin/env python3
"""
Docker Compose Stack Simulator
Test and validate your compose setup without running containers
"""

import os
import sys
import json
import socket
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'

class ComposeSimulator:
    def __init__(self, compose_file: str = "docker-compose.yml"):
        self.compose_file = compose_file
        self.env_file = ".env"
        self.simulation_results = {}
        
    def print_colored(self, text: str, color: str = Colors.NC):
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self, text: str):
        self.print_colored(f"=== {text} ===", Colors.CYAN)
        
    def print_success(self, text: str):
        self.print_colored(f"✓ {text}", Colors.GREEN)
        
    def print_error(self, text: str):
        self.print_colored(f"✗ {text}", Colors.RED)
        
    def print_warning(self, text: str):
        self.print_colored(f"⚠ {text}", Colors.YELLOW)
        
    def print_info(self, text: str):
        self.print_colored(f"ℹ {text}", Colors.BLUE)

    def check_file_exists(self, filepath: str) -> bool:
        """Check if required files exist"""
        return os.path.exists(filepath)

    def validate_compose_syntax(self) -> bool:
        """Validate docker-compose.yml syntax using docker-compose config"""
        try:
            result = subprocess.run([
                "docker-compose", "config", "--quiet"
            ], capture_output=True, text=True, cwd=os.path.dirname(os.path.abspath(self.compose_file)))
            
            if result.returncode == 0:
                self.print_success("Docker Compose syntax is valid")
                return True
            else:
                self.print_error(f"Docker Compose syntax error: {result.stderr}")
                return False
        except FileNotFoundError:
            self.print_warning("docker-compose not found, skipping syntax validation")
            return True
        except Exception as e:
            self.print_error(f"Error validating compose syntax: {e}")
            return False

    def check_port_availability(self, ports: List[str]) -> Dict[str, bool]:
        """Check if ports are available on the system"""
        port_status = {}
        
        for port_mapping in ports:
            # Extract host port from mapping like "8080:8080" or "8080"
            if ":" in port_mapping:
                host_port = port_mapping.split(":")[0]
            else:
                host_port = port_mapping
                
            try:
                port_num = int(host_port)
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', port_num))
                sock.close()
                
                if result == 0:
                    port_status[port_mapping] = False  # Port is in use
                    self.print_warning(f"Port {host_port} is already in use")
                else:
                    port_status[port_mapping] = True   # Port is available
                    self.print_success(f"Port {host_port} is available")
                    
            except ValueError:
                self.print_warning(f"Invalid port format: {port_mapping}")
                port_status[port_mapping] = False
            except Exception as e:
                self.print_error(f"Error checking port {host_port}: {e}")
                port_status[port_mapping] = False
                
        return port_status

    def parse_compose_file(self) -> Optional[Dict]:
        """Parse the docker-compose.yml file"""
        try:
            # Use docker-compose to parse the file (handles .env substitution)
            result = subprocess.run([
                "docker-compose", "config"
            ], capture_output=True, text=True, cwd=os.path.dirname(os.path.abspath(self.compose_file)))
            
            if result.returncode == 0:
                # Parse the YAML output - simplified parsing for our needs
                lines = result.stdout.split('\n')
                services = {}
                current_service = None
                
                for line in lines:
                    if line.strip().startswith('services:'):
                        continue
                    elif line.strip() and not line.startswith(' ') and ':' in line:
                        current_service = line.strip().rstrip(':')
                        services[current_service] = {'ports': [], 'volumes': [], 'depends_on': []}
                    elif current_service and '- "' in line and ':' in line:
                        # Extract port mappings
                        port = line.strip().replace('- "', '').replace('"', '')
                        services[current_service]['ports'].append(port)
                
                return {'services': services}
            else:
                self.print_error(f"Failed to parse compose file: {result.stderr}")
                return None
                
        except Exception as e:
            self.print_error(f"Error parsing compose file: {e}")
            return None

    def simulate_service_startup_order(self, compose_data: Dict) -> List[str]:
        """Simulate the order services would start based on dependencies"""
        services = compose_data.get('services', {})
        startup_order = []
        
        # Simple dependency resolution (topological sort would be better)
        independent_services = []
        dependent_services = []
        
        for service_name, service_config in services.items():
            depends_on = service_config.get('depends_on', [])
            if not depends_on:
                independent_services.append(service_name)
            else:
                dependent_services.append((service_name, depends_on))
        
        startup_order.extend(independent_services)
        
        # Add dependent services (simplified)
        while dependent_services:
            for service, deps in dependent_services[:]:
                if all(dep in startup_order for dep in deps):
                    startup_order.append(service)
                    dependent_services.remove((service, deps))
        
        return startup_order

    def check_volume_paths(self, compose_data: Dict) -> Dict[str, bool]:
        """Check if volume mount paths exist"""
        volume_status = {}
        services = compose_data.get('services', {})
        
        for service_name, service_config in services.items():
            volumes = service_config.get('volumes', [])
            for volume in volumes:
                if ':' in volume:
                    host_path = volume.split(':')[0]
                    # Skip special Docker paths
                    if not host_path.startswith('/var/run/docker.sock') and not host_path.startswith('/etc/'):
                        if os.path.exists(host_path):
                            volume_status[volume] = True
                            self.print_success(f"Volume path exists: {host_path}")
                        else:
                            volume_status[volume] = False
                            self.print_warning(f"Volume path missing: {host_path}")
        
        return volume_status

    def simulate_network_connectivity(self, compose_data: Dict) -> Dict[str, bool]:
        """Simulate network connectivity between services"""
        network_status = {}
        services = compose_data.get('services', {})
        
        # Check if custom networks are defined
        networks = compose_data.get('networks', {})
        if networks:
            self.print_success("Custom networks defined")
            for network_name, network_config in networks.items():
                subnet = network_config.get('ipam', {}).get('config', [{}])[0].get('subnet', 'dynamic')
                self.print_info(f"Network '{network_name}': {subnet}")
        
        # Simulate service-to-service connectivity
        service_names = list(services.keys())
        for service in service_names:
            network_status[service] = True  # Assume connectivity works
            
        return network_status

    def generate_test_compose(self, services_to_test: List[str]) -> str:
        """Generate a minimal test compose file with hello-world containers"""
        test_compose = {
            'version': '3.8',
            'services': {},
            'networks': {
                'test-network': {
                    'driver': 'bridge'
                }
            }
        }
        
        for i, service in enumerate(services_to_test):
            test_compose['services'][f"test-{service}"] = {
                'image': 'hello-world',
                'container_name': f"test-{service}",
                'networks': ['test-network']
            }
        
        # Write to temporary file
        test_file = tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False)
        
        # Simple YAML generation
        content = f"version: '{test_compose['version']}'\n\n"
        content += "services:\n"
        for service_name, service_config in test_compose['services'].items():
            content += f"  {service_name}:\n"
            content += f"    image: {service_config['image']}\n"
            content += f"    container_name: {service_config['container_name']}\n"
        
        content += "\nnetworks:\n"
        for network_name, network_config in test_compose['networks'].items():
            content += f"  {network_name}:\n"
            content += f"    driver: {network_config['driver']}\n"
        
        test_file.write(content)
        test_file.close()
        
        return test_file.name

    def run_dry_run_test(self) -> bool:
        """Run a dry-run test with hello-world containers"""
        try:
            compose_data = self.parse_compose_file()
            if not compose_data:
                return False
                
            services = list(compose_data.get('services', {}).keys())[:3]  # Test first 3 services
            
            test_file = self.generate_test_compose(services)
            self.print_info(f"Generated test compose file: {test_file}")
            
            # Try to create and immediately remove test containers
            result = subprocess.run([
                "docker-compose", "-f", test_file, "up", "--no-start"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                self.print_success("Test containers created successfully")
                
                # Clean up
                subprocess.run([
                    "docker-compose", "-f", test_file, "down", "--remove-orphans"
                ], capture_output=True, text=True)
                
                os.unlink(test_file)
                return True
            else:
                self.print_error(f"Test failed: {result.stderr}")
                os.unlink(test_file)
                return False
                
        except Exception as e:
            self.print_error(f"Dry run test failed: {e}")
            return False

    def run_full_simulation(self):
        """Run complete simulation suite"""
        self.print_header("Docker Compose Stack Simulation")
        
        # Check prerequisites
        self.print_header("Prerequisites Check")
        
        if not self.check_file_exists(self.compose_file):
            self.print_error(f"Compose file not found: {self.compose_file}")
            return
        else:
            self.print_success(f"Found compose file: {self.compose_file}")
            
        if not self.check_file_exists(self.env_file):
            self.print_warning(f"Environment file not found: {self.env_file}")
        else:
            self.print_success(f"Found environment file: {self.env_file}")
        
        # Validate syntax
        self.print_header("Syntax Validation")
        syntax_valid = self.validate_compose_syntax()
        
        if not syntax_valid:
            self.print_error("Syntax validation failed. Please fix errors before continuing.")
            return
        
        # Parse compose file
        compose_data = self.parse_compose_file()
        if not compose_data:
            self.print_error("Failed to parse compose file")
            return
        
        services = compose_data.get('services', {})
        self.print_success(f"Found {len(services)} services: {', '.join(services.keys())}")
        
        # Check port availability
        self.print_header("Port Availability Check")
        all_ports = []
        for service_name, service_config in services.items():
            all_ports.extend(service_config.get('ports', []))
        
        if all_ports:
            port_status = self.check_port_availability(all_ports)
            available_ports = sum(1 for available in port_status.values() if available)
            self.print_info(f"Ports available: {available_ports}/{len(all_ports)}")
        else:
            self.print_info("No exposed ports found")
        
        # Check volume paths
        self.print_header("Volume Path Check")
        volume_status = self.check_volume_paths(compose_data)
        if volume_status:
            existing_paths = sum(1 for exists in volume_status.values() if exists)
            self.print_info(f"Volume paths exist: {existing_paths}/{len(volume_status)}")
        else:
            self.print_info("No volume mounts found")
        
        # Simulate network connectivity
        self.print_header("Network Configuration")
        network_status = self.simulate_network_connectivity(compose_data)
        
        # Simulate startup order
        self.print_header("Service Startup Order Simulation")
        startup_order = self.simulate_service_startup_order(compose_data)
        self.print_info("Simulated startup sequence:")
        for i, service in enumerate(startup_order, 1):
            self.print_colored(f"  {i}. {service}", Colors.WHITE)
        
        # Optional dry run test
        self.print_header("Dry Run Test (Optional)")
        if input(f"{Colors.BLUE}Run dry run test with hello-world containers? (y/n): {Colors.NC}").lower().startswith('y'):
            dry_run_success = self.run_dry_run_test()
            if dry_run_success:
                self.print_success("Dry run test completed successfully")
            else:
                self.print_warning("Dry run test encountered issues")
        
        # Summary
        self.print_header("Simulation Summary")
        self.print_success("✓ Compose file syntax valid")
        self.print_success(f"✓ {len(services)} services configured")
        
        if all_ports:
            conflicts = sum(1 for available in port_status.values() if not available)
            if conflicts > 0:
                self.print_warning(f"⚠ {conflicts} port conflicts detected")
            else:
                self.print_success("✓ No port conflicts")
        
        print()
        self.print_info("Next steps:")
        print(f"  1. Review any warnings above")
        print(f"  2. Create missing directories if needed")
        print(f"  3. Update .env file with your configuration")
        print(f"  4. Run: {Colors.YELLOW}docker-compose up -d{Colors.NC}")

def main():
    if len(sys.argv) > 1:
        compose_file = sys.argv[1]
    else:
        compose_file = "docker-compose.yml"
    
    simulator = ComposeSimulator(compose_file)
    simulator.run_full_simulation()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Simulation cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
        sys.exit(1)
