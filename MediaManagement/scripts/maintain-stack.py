#!/usr/bin/env python3
"""
HomeLab Media Stack Maintenance Script
Handles updates, cleanup, health checks, and routine maintenance
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime, timedelta

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'

class MediaStackMaintenance:
    def __init__(self):
        self.compose_command = self._detect_compose_command()
        self.maintenance_log = "maintenance.log"
        
    def print_colored(self, text: str, color: str = Colors.NC):
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self, text: str):
        self.print_colored(f"=== {text} ===", Colors.CYAN)
        
    def ask_yes_no(self, prompt: str, default: str = "n") -> bool:
        while True:
            response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip().lower()
            response = response or default.lower()
            return response in ['y', 'yes', 'true', '1']

    def log_action(self, action: str, status: str = "SUCCESS", details: str = ""):
        """Log maintenance actions"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {action}: {status}"
        if details:
            log_entry += f" - {details}"
        
        try:
            with open(self.maintenance_log, 'a') as f:
                f.write(log_entry + "\n")
        except Exception as e:
            self.print_colored(f"Warning: Could not write to log: {e}", Colors.YELLOW)

    def _detect_compose_command(self) -> str:
        """Detect the correct Docker Compose command"""
        commands_to_try = [
            ['docker', 'compose', 'version'],
            ['docker-compose', 'version'],
            ['podman-compose', 'version']
        ]
        
        for cmd in commands_to_try:
            try:
                result = subprocess.run(cmd, capture_output=True, check=True, timeout=10)
                if cmd[0] == 'docker' and cmd[1] == 'compose':
                    return 'docker compose'
                elif cmd[0] == 'docker-compose':
                    return 'docker-compose'
                elif cmd[0] == 'podman-compose':
                    return 'podman-compose'
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
                continue
        
        # If none work, try to detect Docker Desktop on Windows
        if os.name == 'nt':  # Windows
            try:
                # Check if Docker Desktop is running
                result = subprocess.run(['docker', 'version'], capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    return 'docker compose'
            except:
                pass
        
        self.print_colored("⚠ Warning: Docker Compose not detected. Using 'docker compose' as fallback.", Colors.YELLOW)
        return 'docker compose'

    def _run_compose_command(self, args: List[str], use_sudo: bool = False) -> subprocess.CompletedProcess:
        """Run docker compose command with optional sudo"""
        cmd = self.compose_command.split() + args
        
        # First try without sudo if not explicitly requested
        if not use_sudo:
            try:
                return subprocess.run(cmd, capture_output=True, text=True, check=True, timeout=30)
            except subprocess.CalledProcessError as e:
                # Check if it's a permission error
                if "permission denied" in e.stderr.lower() or "dial unix" in e.stderr.lower():
                    self.print_colored("Permission denied, trying with sudo...", Colors.YELLOW)
                    use_sudo = True
                else:
                    # For other errors, show the actual error message
                    error_details = e.stderr.strip() if e.stderr.strip() else e.stdout.strip()
                    if error_details:
                        self.print_colored(f"Docker compose error: {error_details}", Colors.RED)
                    raise
        
        # Try with sudo if requested or permission was denied
        if use_sudo:
            cmd = ['sudo'] + cmd
            try:
                return subprocess.run(cmd, capture_output=True, text=True, check=True, timeout=30)
            except subprocess.CalledProcessError as e:
                # Show detailed error for sudo failures
                error_details = e.stderr.strip() if e.stderr.strip() else e.stdout.strip()
                if "no such file or directory" in error_details.lower():
                    raise Exception("docker-compose.yml not found in current directory")
                elif "no configuration file provided" in error_details.lower():
                    raise Exception("No docker-compose.yml found. Make sure you're in the right directory.")
                else:
                    raise Exception(f"Docker compose failed: {error_details}")
            except subprocess.TimeoutExpired:
                raise Exception("Docker compose command timed out")

    def _check_docker_permissions(self) -> bool:
        """Check if user can run Docker without sudo"""
        try:
            result = subprocess.run(['docker', 'version'], capture_output=True, text=True, timeout=5)
            return result.returncode == 0
        except:
            return False

    def _check_user_in_docker_group(self) -> bool:
        """Check if current user is in docker group"""
        try:
            result = subprocess.run(['groups'], capture_output=True, text=True)
            return 'docker' in result.stdout
        except:
            return False

    def check_stack_health(self) -> Dict[str, str]:
        """Check health of all services"""
        self.print_colored("🔍 Checking service health...", Colors.CYAN)
        
        # First check if Docker is available
        try:
            subprocess.run(['docker', '--version'], capture_output=True, check=True, timeout=5)
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            self.print_colored("❌ Docker is not installed or not running", Colors.RED)
            
            # On Windows, check if Docker Desktop might be installed but not running
            if os.name == 'nt':
                docker_desktop_paths = [
                    r"C:\Program Files\Docker\Docker\Docker Desktop.exe",
                    r"C:\Users\Public\Desktop\Docker Desktop.lnk",
                    os.path.expanduser(r"~\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Docker Desktop.lnk")
                ]
                
                docker_installed = any(os.path.exists(path) for path in docker_desktop_paths)
                if docker_installed:
                    self.print_colored("Docker Desktop appears to be installed but not running", Colors.YELLOW)
                    self.print_colored("Please start Docker Desktop and try again", Colors.BLUE)
                else:
                    self.print_colored("Please install Docker Desktop from https://docker.com/products/docker-desktop", Colors.YELLOW)
            else:
                self.print_colored("Please install Docker and ensure the Docker service is running", Colors.YELLOW)
            
            self.log_action("Health Check", "FAILED", "Docker not available")
            return {}

        # Check Docker permissions
        if not self._check_docker_permissions():
            if not self._check_user_in_docker_group():
                self.print_colored("⚠ User not in docker group. This may require sudo for Docker commands.", Colors.YELLOW)
                self.print_colored("To fix this, run: sudo usermod -aG docker $USER && newgrp docker", Colors.BLUE)
        
        # Check if we're in a directory with docker-compose.yml
        compose_files = ['docker-compose.yml', 'docker-compose.yaml', '../docker-compose.yml', '../docker-compose.yaml']
        compose_file_found = any(os.path.exists(f) for f in compose_files)
        
        if not compose_file_found:
            self.print_colored("❌ No docker-compose.yml found in current or parent directory", Colors.RED)
            self.print_colored("Please run this from your media stack directory", Colors.YELLOW)
            self.print_colored("Looking for: docker-compose.yml or docker-compose.yaml", Colors.BLUE)
            self.log_action("Health Check", "FAILED", "No docker-compose.yml found")
            return {}
        
        try:
            # First try with JSON format
            try:
                result = self._run_compose_command(['ps', '--format', 'json'])
                # Clean the output - sometimes there's extra text
                json_output = result.stdout.strip()
                
                # Handle case where output might have multiple JSON objects
                if json_output.startswith('['):
                    services = json.loads(json_output)
                else:
                    # Try to parse as individual JSON objects (one per line)
                    lines = [line.strip() for line in json_output.split('\n') if line.strip()]
                    services = []
                    for line in lines:
                        try:
                            services.append(json.loads(line))
                        except json.JSONDecodeError:
                            # Skip non-JSON lines
                            continue
                
            except (json.JSONDecodeError, subprocess.CalledProcessError):
                # Fallback to table format and parse manually
                self.print_colored("JSON format failed, using table format...", Colors.YELLOW)
                result = self._run_compose_command(['ps'])
                services = self._parse_compose_table(result.stdout)
            
            service_status = {}
            if not services:
                self.print_colored("No services found or stack not running", Colors.YELLOW)
                self.print_colored("Try starting your stack with: docker-compose up -d", Colors.BLUE)
                return {}
                
            for service in services:
                if isinstance(service, dict):
                    name = service.get('Service', service.get('Name', service.get('service', 'unknown')))
                    state = service.get('State', service.get('status', 'unknown'))
                    health = service.get('Health', service.get('health', 'unknown'))
                else:
                    # Fallback for parsed table format
                    name = service.get('name', 'unknown')
                    state = service.get('state', 'unknown') 
                    health = service.get('health', 'unknown')
                
                if 'running' in state.lower() or 'up' in state.lower():
                    if 'healthy' in health.lower():
                        status = 'healthy'
                    elif 'unhealthy' in health.lower():
                        status = 'unhealthy'
                    else:
                        status = 'running'
                elif 'exit' in state.lower() or 'stop' in state.lower():
                    status = 'stopped'
                else:
                    status = state.lower()
                
                service_status[name] = status
            
            # Display results
            healthy_count = sum(1 for s in service_status.values() if s in ['healthy', 'running'])
            total_count = len(service_status)
            
            self.print_colored(f"Health Status: {healthy_count}/{total_count} services healthy", Colors.GREEN if healthy_count == total_count else Colors.YELLOW)
            
            for service, status in service_status.items():
                color = Colors.GREEN if status in ['healthy', 'running'] else Colors.RED
                self.print_colored(f"  {service}: {status}", color)
            
            self.log_action("Health Check", "SUCCESS", f"{healthy_count}/{total_count} healthy")
            return service_status
            
        except Exception as e:
            error_msg = str(e)
            if "The system cannot find the file specified" in error_msg:
                self.print_colored("❌ Docker command not found", Colors.RED)
                self.print_colored("Please ensure Docker Desktop is installed and running", Colors.YELLOW)
            else:
                self.print_colored(f"❌ Health check failed: {error_msg}", Colors.RED)
            self.log_action("Health Check", "FAILED", error_msg)
            return {}

    def _parse_compose_table(self, output: str) -> List[Dict[str, str]]:
        """Parse docker-compose ps table output as fallback"""
        services = []
        lines = output.strip().split('\n')
        
        # Skip header lines and empty lines
        data_lines = [line for line in lines if line.strip() and not line.startswith('NAME') and not line.startswith('Container')]
        
        for line in data_lines:
            # Parse table format: NAME    IMAGE    COMMAND    CREATED    STATUS    PORTS
            parts = line.split()
            if len(parts) >= 4:
                name = parts[0]
                # Status is usually in parts[4] or later, look for 'Up' or 'Exited'
                status = 'unknown'
                for part in parts[4:]:
                    if 'Up' in part or 'running' in part.lower():
                        status = 'running'
                        break
                    elif 'Exit' in part or 'stop' in part.lower():
                        status = 'stopped' 
                        break
                
                services.append({
                    'name': name,
                    'state': status,
                    'health': 'unknown'
                })
        
        return services

    def update_containers(self):
        """Update all container images"""
        self.print_colored("📥 Updating container images...", Colors.CYAN)
        
        try:
            # Pull latest images
            self.print_colored("Pulling latest images...", Colors.BLUE)
            result = self._run_compose_command(['pull'])
            
            if "Downloaded newer image" in result.stdout or "Status: Image is up to date" in result.stdout:
                self.print_colored("✅ Images updated successfully", Colors.GREEN)
                
                # Ask to restart services
                if self.ask_yes_no("Restart services to use updated images?", "y"):
                    self.restart_stack()
                    
                self.log_action("Container Update", "SUCCESS")
            else:
                self.print_colored("✅ All images already up to date", Colors.GREEN)
                self.log_action("Container Update", "SUCCESS", "No updates needed")
                
        except Exception as e:
            self.print_colored(f"❌ Update failed: {e}", Colors.RED)
            self.log_action("Container Update", "FAILED", str(e))

    def restart_stack(self):
        """Restart the entire stack"""
        self.print_colored("🔄 Restarting stack...", Colors.CYAN)
        
        try:
            # Stop services
            self.print_colored("Stopping services...", Colors.BLUE)
            self._run_compose_command(['down'])
            
            # Start services
            self.print_colored("Starting services...", Colors.BLUE)
            self._run_compose_command(['up', '-d'])
            
            # Wait and verify
            time.sleep(5)
            self.print_colored("✅ Stack restarted successfully", Colors.GREEN)
            self.log_action("Stack Restart", "SUCCESS")
            
            # Quick health check
            self.check_stack_health()
            
        except Exception as e:
            self.print_colored(f"❌ Restart failed: {e}", Colors.RED)
            self.log_action("Stack Restart", "FAILED", str(e))

    def cleanup_system(self):
        """Clean up Docker system and logs"""
        self.print_colored("🧹 Cleaning up system...", Colors.CYAN)
        
        cleanup_tasks = [
            ("Unused containers", ['system', 'prune', '-f']),
            ("Unused images", ['image', 'prune', '-f']),
            ("Unused volumes", ['volume', 'prune', '-f']),
            ("Unused networks", ['network', 'prune', '-f']),
        ]
        
        for task_name, docker_args in cleanup_tasks:
            try:
                self.print_colored(f"Cleaning {task_name.lower()}...", Colors.BLUE)
                cmd = ['docker'] + docker_args
                result = subprocess.run(cmd, capture_output=True, text=True, check=True)
                
                if result.stdout.strip():
                    self.print_colored(f"✅ {task_name} cleaned", Colors.GREEN)
                else:
                    self.print_colored(f"✅ No unused {task_name.lower()}", Colors.GREEN)
                    
            except Exception as e:
                self.print_colored(f"⚠ Failed to clean {task_name.lower()}: {e}", Colors.YELLOW)
        
        # Clean log files if they're too large
        self._cleanup_log_files()
        
        self.log_action("System Cleanup", "SUCCESS")

    def _cleanup_log_files(self):
        """Clean up large log files"""
        log_paths = [
            "/var/lib/docker/containers/*/",
            "./logs/",
            "./**/logs/"
        ]
        
        for log_path in log_paths:
            try:
                # Find large log files (>100MB)
                find_cmd = f"find {log_path} -name '*.log' -size +100M 2>/dev/null"
                result = subprocess.run(find_cmd, shell=True, capture_output=True, text=True)
                
                if result.stdout.strip():
                    large_logs = result.stdout.strip().split('\n')
                    self.print_colored(f"Found {len(large_logs)} large log files", Colors.YELLOW)
                    
                    if self.ask_yes_no("Truncate large log files?", "y"):
                        for log_file in large_logs:
                            try:
                                subprocess.run(['sudo', 'truncate', '-s', '0', log_file], check=True)
                                self.print_colored(f"Truncated: {log_file}", Colors.GREEN)
                            except:
                                pass
                                
            except:
                pass

    def backup_configs(self):
        """Backup configuration files"""
        self.print_colored("💾 Backing up configurations...", Colors.CYAN)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = f"backup_{timestamp}"
        
        try:
            os.makedirs(backup_dir, exist_ok=True)
            
            # Files to backup
            backup_items = [
                "docker-compose.yml",
                ".env",
                "config/",
                self.maintenance_log
            ]
            
            backed_up = []
            for item in backup_items:
                if os.path.exists(item):
                    if os.path.isfile(item):
                        subprocess.run(['cp', item, backup_dir], check=True)
                    else:
                        subprocess.run(['cp', '-r', item, backup_dir], check=True)
                    backed_up.append(item)
            
            if backed_up:
                # Create tarball
                tarball = f"{backup_dir}.tar.gz"
                subprocess.run(['tar', '-czf', tarball, backup_dir], check=True)
                subprocess.run(['rm', '-rf', backup_dir], check=True)
                
                self.print_colored(f"✅ Backup created: {tarball}", Colors.GREEN)
                self.log_action("Configuration Backup", "SUCCESS", tarball)
                
                # Clean old backups (keep last 5)
                self._cleanup_old_backups()
            else:
                self.print_colored("⚠ No configuration files found to backup", Colors.YELLOW)
                
        except Exception as e:
            self.print_colored(f"❌ Backup failed: {e}", Colors.RED)
            self.log_action("Configuration Backup", "FAILED", str(e))

    def _cleanup_old_backups(self):
        """Keep only the 5 most recent backups"""
        try:
            backups = sorted([f for f in os.listdir('.') if f.startswith('backup_') and f.endswith('.tar.gz')])
            if len(backups) > 5:
                for old_backup in backups[:-5]:
                    os.remove(old_backup)
                    self.print_colored(f"Removed old backup: {old_backup}", Colors.BLUE)
        except:
            pass

    def check_disk_usage(self):
        """Check disk usage for important paths"""
        self.print_colored("💽 Checking disk usage...", Colors.CYAN)
        
        paths_to_check = [
            ("Current directory", "."),
            ("Docker root", "/var/lib/docker"),
            ("Data path", os.environ.get('DATA_PATH', '/mnt/media')),
        ]
        
        for name, path in paths_to_check:
            if os.path.exists(path):
                try:
                    result = subprocess.run(['df', '-h', path], capture_output=True, text=True, check=True)
                    lines = result.stdout.strip().split('\n')
                    if len(lines) >= 2:
                        fields = lines[1].split()
                        if len(fields) >= 5:
                            used_pct = fields[4].rstrip('%')
                            color = Colors.RED if int(used_pct) > 90 else Colors.YELLOW if int(used_pct) > 80 else Colors.GREEN
                            self.print_colored(f"  {name}: {fields[4]} used ({fields[2]} free)", color)
                except:
                    self.print_colored(f"  {name}: Could not check", Colors.YELLOW)

    def show_service_logs(self):
        """Show recent logs for services"""
        self.print_colored("📋 Recent service logs...", Colors.CYAN)
        
        try:
            result = self._run_compose_command(['ps', '--services'])
            services = result.stdout.strip().split('\n')
            
            if not services or services == ['']:
                self.print_colored("No services found", Colors.YELLOW)
                return
            
            print("\nAvailable services:")
            for i, service in enumerate(services, 1):
                print(f"  {i}. {service}")
            
            choice = input(f"\nEnter service number (1-{len(services)}) or 'all': ").strip()
            
            if choice.lower() == 'all':
                for service in services:
                    self._show_service_log(service)
            else:
                try:
                    service_idx = int(choice) - 1
                    if 0 <= service_idx < len(services):
                        self._show_service_log(services[service_idx])
                    else:
                        self.print_colored("Invalid selection", Colors.RED)
                except ValueError:
                    self.print_colored("Invalid selection", Colors.RED)
                    
        except Exception as e:
            self.print_colored(f"❌ Could not get service logs: {e}", Colors.RED)

    def _show_service_log(self, service: str):
        """Show logs for a specific service"""
        self.print_colored(f"\n📋 Logs for {service}:", Colors.CYAN)
        try:
            result = self._run_compose_command(['logs', '--tail', '20', service])
            print(result.stdout)
        except Exception as e:
            self.print_colored(f"Could not get logs for {service}: {e}", Colors.RED)

    def show_maintenance_menu(self):
        """Show interactive maintenance menu"""
        while True:
            self.print_header("HomeLab Media Stack Maintenance")
            
            menu_options = [
                ("1", "Check stack health", self.check_stack_health),
                ("2", "Update container images", self.update_containers),
                ("3", "Restart entire stack", self.restart_stack),
                ("4", "Clean up system", self.cleanup_system),
                ("5", "Backup configurations", self.backup_configs),
                ("6", "Check disk usage", self.check_disk_usage),
                ("7", "Show service logs", self.show_service_logs),
                ("8", "Full maintenance (all tasks)", self.full_maintenance),
                ("9", "Show maintenance log", self.show_maintenance_log),
                ("d", "Docker diagnostics", self.docker_diagnostics),
                ("f", "Fix Docker permissions", self.fix_docker_permissions),
                ("q", "Quit", None)
            ]
            
            print()
            for option, description, _ in menu_options:
                self.print_colored(f"  {option}. {description}", Colors.WHITE)
            
            choice = input(f"\n{Colors.BLUE}Select option:{Colors.NC} ").strip().lower()
            
            if choice == 'q':
                break
            
            for option, _, function in menu_options:
                if choice == option and function:
                    print()
                    function()
                    input(f"\n{Colors.BLUE}Press Enter to continue...{Colors.NC}")
                    break
            else:
                if choice != 'q':
                    self.print_colored("Invalid option", Colors.RED)
                    time.sleep(1)

    def fix_docker_permissions(self):
        """Help fix Docker permissions for the current user"""
        self.print_colored("🔧 Docker Permissions Fix", Colors.CYAN)
        
        # Check current status
        can_run_docker = self._check_docker_permissions()
        in_docker_group = self._check_user_in_docker_group()
        
        self.print_colored(f"Current user can run Docker without sudo: {'✅' if can_run_docker else '❌'}", 
                          Colors.GREEN if can_run_docker else Colors.RED)
        self.print_colored(f"Current user is in docker group: {'✅' if in_docker_group else '❌'}", 
                          Colors.GREEN if in_docker_group else Colors.RED)
        
        if can_run_docker:
            self.print_colored("✅ Docker permissions are already correct!", Colors.GREEN)
            return
        
        if not in_docker_group:
            self.print_colored("\n🔨 To fix Docker permissions:", Colors.YELLOW)
            self.print_colored("1. Add your user to the docker group:", Colors.BLUE)
            self.print_colored("   sudo usermod -aG docker $USER", Colors.WHITE)
            self.print_colored("\n2. Apply the group changes:", Colors.BLUE)
            self.print_colored("   newgrp docker", Colors.WHITE)
            self.print_colored("\n3. Or logout and login again", Colors.BLUE)
            
            if self.ask_yes_no("\nWould you like me to run these commands for you?", "y"):
                try:
                    # Add user to docker group
                    self.print_colored("Adding user to docker group...", Colors.BLUE)
                    result = subprocess.run(['sudo', 'usermod', '-aG', 'docker', os.getenv('USER', 'ubuntu')], 
                                          capture_output=True, text=True)
                    if result.returncode == 0:
                        self.print_colored("✅ User added to docker group", Colors.GREEN)
                        self.print_colored("⚠ You need to logout/login or run 'newgrp docker' for changes to take effect", Colors.YELLOW)
                    else:
                        self.print_colored(f"❌ Failed to add user to docker group: {result.stderr}", Colors.RED)
                        
                except Exception as e:
                    self.print_colored(f"❌ Error: {e}", Colors.RED)
        else:
            self.print_colored("User is in docker group but Docker commands still fail.", Colors.YELLOW)
            self.print_colored("Try running: newgrp docker", Colors.BLUE)
            self.print_colored("Or logout and login again.", Colors.BLUE)

    def docker_diagnostics(self):
        """Run Docker diagnostics to help troubleshoot issues"""
        self.print_colored("🔍 Docker Diagnostics", Colors.CYAN)
        
        # Check permissions first
        self.print_colored("\n--- Docker Permissions ---", Colors.YELLOW)
        can_run_docker = self._check_docker_permissions()
        in_docker_group = self._check_user_in_docker_group()
        
        self.print_colored(f"Can run Docker without sudo: {'✅ Yes' if can_run_docker else '❌ No'}", 
                          Colors.GREEN if can_run_docker else Colors.RED)
        self.print_colored(f"User in docker group: {'✅ Yes' if in_docker_group else '❌ No'}", 
                          Colors.GREEN if in_docker_group else Colors.RED)
        
        # Check compose file
        self.print_colored("\n--- Compose File ---", Colors.YELLOW)
        compose_files = ['docker-compose.yml', 'docker-compose.yaml', '../docker-compose.yml', '../docker-compose.yaml']
        for compose_file in compose_files:
            if os.path.exists(compose_file):
                self.print_colored(f"✅ Found: {compose_file}", Colors.GREEN)
                break
        else:
            self.print_colored("❌ No docker-compose.yml found", Colors.RED)
        
        # Standard Docker diagnostics
        diagnostics = [
            ("Docker version", ['docker', '--version']),
            ("Docker info", ['docker', 'info', '--format', '{{.ServerVersion}}']),
            ("Compose version", self.compose_command.split() + ['version']),
            ("Running containers", ['docker', 'ps', '--format', 'table {{.Names}}\t{{.Status}}']),
            ("Docker system info", ['docker', 'system', 'df'])
        ]
        
        for test_name, command in diagnostics:
            self.print_colored(f"\n--- {test_name} ---", Colors.YELLOW)
            try:
                # Try without sudo first
                result = subprocess.run(command, capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    self.print_colored("✅ Success", Colors.GREEN)
                    output = result.stdout.strip()
                    if output:
                        print(output)
                    else:
                        print("(No output)")
                else:
                    # Try with sudo if it failed
                    if not can_run_docker:
                        sudo_command = ['sudo'] + command
                        result = subprocess.run(sudo_command, capture_output=True, text=True, timeout=10)
                        if result.returncode == 0:
                            self.print_colored("✅ Success (with sudo)", Colors.GREEN)
                            output = result.stdout.strip()
                            if output:
                                print(output)
                            else:
                                print("(No output)")
                        else:
                            self.print_colored("❌ Failed (even with sudo)", Colors.RED)
                            if result.stderr.strip():
                                print(result.stderr.strip())
                    else:
                        self.print_colored("❌ Failed", Colors.RED)
                        if result.stderr.strip():
                            print(result.stderr.strip())
                            
            except FileNotFoundError:
                self.print_colored("❌ Command not found", Colors.RED)
            except subprocess.TimeoutExpired:
                self.print_colored("❌ Timeout", Colors.RED)
            except Exception as e:
                self.print_colored(f"❌ Error: {e}", Colors.RED)

    def full_maintenance(self):
        """Run all maintenance tasks"""
        self.print_colored("🔧 Running full maintenance...", Colors.CYAN)
        
        tasks = [
            ("Health Check", self.check_stack_health),
            ("Update Containers", self.update_containers),
            ("System Cleanup", self.cleanup_system),
            ("Configuration Backup", self.backup_configs),
            ("Disk Usage Check", self.check_disk_usage),
        ]
        
        for task_name, task_func in tasks:
            self.print_colored(f"\n--- {task_name} ---", Colors.YELLOW)
            try:
                task_func()
            except Exception as e:
                self.print_colored(f"❌ {task_name} failed: {e}", Colors.RED)
            time.sleep(1)
        
        self.print_colored("\n✅ Full maintenance completed!", Colors.GREEN)
        self.log_action("Full Maintenance", "SUCCESS")

    def show_maintenance_log(self):
        """Show recent maintenance log entries"""
        self.print_colored("📜 Recent maintenance log:", Colors.CYAN)
        
        try:
            if os.path.exists(self.maintenance_log):
                with open(self.maintenance_log, 'r') as f:
                    lines = f.readlines()
                    
                # Show last 20 entries
                recent_lines = lines[-20:] if len(lines) > 20 else lines
                
                for line in recent_lines:
                    line = line.strip()
                    if "FAILED" in line:
                        self.print_colored(line, Colors.RED)
                    elif "SUCCESS" in line:
                        self.print_colored(line, Colors.GREEN)
                    else:
                        print(line)
            else:
                self.print_colored("No maintenance log found", Colors.YELLOW)
                
        except Exception as e:
            self.print_colored(f"Could not read log: {e}", Colors.RED)

    def run(self):
        """Main entry point"""
        if len(sys.argv) > 1:
            # Command line mode
            command = sys.argv[1].lower()
            
            commands = {
                'health': self.check_stack_health,
                'update': self.update_containers,
                'restart': self.restart_stack,
                'cleanup': self.cleanup_system,
                'backup': self.backup_configs,
                'disk': self.check_disk_usage,
                'logs': self.show_service_logs,
                'full': self.full_maintenance,
                'log': self.show_maintenance_log,
                'diagnostics': self.docker_diagnostics,
                'fix-permissions': self.fix_docker_permissions
            }
            
            if command in commands:
                commands[command]()
            else:
                self.print_colored(f"Unknown command: {command}", Colors.RED)
                self.print_colored("Available commands: " + ", ".join(commands.keys()), Colors.YELLOW)
        else:
            # Interactive mode
            self.show_maintenance_menu()

if __name__ == "__main__":
    try:
        maintenance = MediaStackMaintenance()
        maintenance.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Maintenance cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
