#!/usr/bin/env python3
"""
Media Server Maintenance Script
Health checks, updates, and maintenance for media server stack
"""

import os
import sys
import json
import subprocess
import time
from datetime import datetime
from typing import Dict, List

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'

class MediaServerMaintenance:
    def __init__(self):
        self.compose_command = self._detect_compose_command()
        self.log_file = "media-server-maintenance.log"
        
    def print_colored(self, text: str, color: str = Colors.NC):
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self, text: str):
        self.print_colored(f"=== {text} ===", Colors.CYAN)
        
    def ask_yes_no(self, prompt: str, default: str = "n") -> bool:
        response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip().lower()
        return (response or default.lower()) in ['y', 'yes', 'true', '1']

    def log_action(self, action: str, status: str = "SUCCESS", details: str = ""):
        """Log maintenance actions"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {action}: {status}"
        if details:
            log_entry += f" - {details}"
        
        try:
            with open(self.log_file, 'a') as f:
                f.write(log_entry + "\n")
        except Exception as e:
            self.print_colored(f"Warning: Could not write to log: {e}", Colors.YELLOW)

    def _detect_compose_command(self) -> str:
        """Detect available Docker Compose command"""
        commands = [
            ['docker', 'compose', 'version'],
            ['docker-compose', 'version']
        ]
        
        for cmd in commands:
            try:
                subprocess.run(cmd, capture_output=True, check=True, timeout=5)
                return ' '.join(cmd[:-1])
            except:
                continue
        
        return 'docker compose'

    def check_services(self) -> Dict[str, str]:
        """Check status of media server services"""
        self.print_colored("🔍 Checking service health...", Colors.CYAN)
        
        service_status = {}
        
        try:
            # Get running containers
            result = subprocess.run(
                [*self.compose_command.split(), 'ps', '--format', 'json'],
                capture_output=True, text=True, check=True
            )
            
            if result.stdout.strip():
                # Parse container status
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    try:
                        container = json.loads(line)
                        name = container.get('Service', container.get('Name', 'unknown'))
                        state = container.get('State', container.get('Status', 'unknown'))
                        
                        if 'running' in state.lower():
                            service_status[name] = 'running'
                        else:
                            service_status[name] = 'stopped'
                            
                    except json.JSONDecodeError:
                        continue
            
            # Display results
            if service_status:
                running_count = sum(1 for status in service_status.values() if status == 'running')
                total_count = len(service_status)
                
                self.print_colored(f"Status: {running_count}/{total_count} services running", 
                                 Colors.GREEN if running_count == total_count else Colors.YELLOW)
                
                for service, status in service_status.items():
                    color = Colors.GREEN if status == 'running' else Colors.RED
                    icon = "✅" if status == 'running' else "❌"
                    self.print_colored(f"  {icon} {service}: {status}", color)
            else:
                self.print_colored("No services found or stack not running", Colors.YELLOW)
            
            self.log_action("Health Check", "SUCCESS")
            return service_status
            
        except Exception as e:
            self.print_colored(f"❌ Health check failed: {e}", Colors.RED)
            self.log_action("Health Check", "FAILED", str(e))
            return {}

    def check_storage_usage(self):
        """Check storage usage for media paths"""
        self.print_header("Storage Usage")
        
        # Common media server paths to check
        paths_to_check = [
            ("Current directory", "."),
            ("Media library", "/mnt/media"),
            ("Photo storage", "/mnt/photos"),
            ("Transcode temp", "/tmp/transcode"),
        ]
        
        for name, path in paths_to_check:
            if os.path.exists(path):
                try:
                    result = subprocess.run(['df', '-h', path], capture_output=True, text=True)
                    if result.returncode == 0:
                        lines = result.stdout.strip().split('\n')
                        if len(lines) >= 2:
                            fields = lines[1].split()
                            if len(fields) >= 5:
                                used_pct = int(fields[4].rstrip('%'))
                                color = Colors.RED if used_pct > 90 else Colors.YELLOW if used_pct > 80 else Colors.GREEN
                                self.print_colored(f"  {name}: {fields[4]} used ({fields[3]} free)", color)
                except Exception as e:
                    self.print_colored(f"  {name}: Could not check - {e}", Colors.YELLOW)

    def update_containers(self):
        """Update container images"""
        self.print_colored("📥 Updating container images...", Colors.CYAN)
        
        try:
            # Pull latest images
            result = subprocess.run(
                [*self.compose_command.split(), 'pull'],
                capture_output=True, text=True, check=True
            )
            
            self.print_colored("✅ Images updated successfully", Colors.GREEN)
            
            if self.ask_yes_no("Restart services to use updated images?", "y"):
                self.restart_services()
                
            self.log_action("Container Update", "SUCCESS")
            
        except Exception as e:
            self.print_colored(f"❌ Update failed: {e}", Colors.RED)
            self.log_action("Container Update", "FAILED", str(e))

    def restart_services(self):
        """Restart all services"""
        self.print_colored("🔄 Restarting services...", Colors.CYAN)
        
        try:
            # Stop services
            subprocess.run([*self.compose_command.split(), 'down'], check=True)
            
            # Start services
            subprocess.run([*self.compose_command.split(), 'up', '-d'], check=True)
            
            self.print_colored("✅ Services restarted successfully", Colors.GREEN)
            
            # Wait and check status
            time.sleep(5)
            self.check_services()
            
            self.log_action("Service Restart", "SUCCESS")
            
        except Exception as e:
            self.print_colored(f"❌ Restart failed: {e}", Colors.RED)
            self.log_action("Service Restart", "FAILED", str(e))

    def backup_configs(self):
        """Backup configuration files"""
        self.print_colored("💾 Backing up configurations...", Colors.CYAN)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"media-server-backup_{timestamp}.tar.gz"
        
        try:
            # Items to backup
            backup_items = []
            for item in ["docker-compose.yml", ".env", "*/config", "*/pgdata"]:
                if os.path.exists(item.split('/')[0]):  # Check if base directory exists
                    backup_items.append(item)
            
            if backup_items:
                # Create backup
                subprocess.run(['tar', '-czf', backup_name] + backup_items, check=True)
                self.print_colored(f"✅ Backup created: {backup_name}", Colors.GREEN)
                self.log_action("Configuration Backup", "SUCCESS", backup_name)
            else:
                self.print_colored("⚠️  No configuration files found to backup", Colors.YELLOW)
                
        except Exception as e:
            self.print_colored(f"❌ Backup failed: {e}", Colors.RED)
            self.log_action("Configuration Backup", "FAILED", str(e))

    def show_service_logs(self):
        """Show logs for services"""
        self.print_colored("📋 Service Logs", Colors.CYAN)
        
        try:
            # Get list of services
            result = subprocess.run(
                [*self.compose_command.split(), 'ps', '--services'],
                capture_output=True, text=True, check=True
            )
            
            services = result.stdout.strip().split('\n')
            if not services or services == ['']:
                self.print_colored("No services found", Colors.YELLOW)
                return
            
            print("\nAvailable services:")
            for i, service in enumerate(services, 1):
                print(f"  {i}. {service}")
            
            choice = input(f"\nSelect service (1-{len(services)}) or 'all': ").strip()
            
            if choice.lower() == 'all':
                subprocess.run([*self.compose_command.split(), 'logs', '--tail', '50'])
            else:
                try:
                    service_idx = int(choice) - 1
                    if 0 <= service_idx < len(services):
                        subprocess.run([*self.compose_command.split(), 'logs', '--tail', '50', services[service_idx]])
                    else:
                        self.print_colored("Invalid selection", Colors.RED)
                except ValueError:
                    self.print_colored("Invalid selection", Colors.RED)
                    
        except Exception as e:
            self.print_colored(f"❌ Could not get logs: {e}", Colors.RED)

    def cleanup_system(self):
        """Clean up Docker system"""
        self.print_colored("🧹 Cleaning up system...", Colors.CYAN)
        
        cleanup_commands = [
            ("unused containers", ['docker', 'system', 'prune', '-f']),
            ("unused images", ['docker', 'image', 'prune', '-f']),
            ("unused volumes", ['docker', 'volume', 'prune', '-f']),
        ]
        
        for name, command in cleanup_commands:
            try:
                result = subprocess.run(command, capture_output=True, text=True, check=True)
                self.print_colored(f"✅ Cleaned {name}", Colors.GREEN)
            except Exception as e:
                self.print_colored(f"⚠️  Failed to clean {name}: {e}", Colors.YELLOW)
        
        self.log_action("System Cleanup", "SUCCESS")

    def show_service_urls(self):
        """Display service access URLs"""
        self.print_header("Service URLs")
        
        urls = {
            "immich": ("http://localhost:2283", "Photo & Video Management"),
            "jellyfin": ("http://localhost:8096", "Media Server"),
            "plex": ("http://localhost:32400/web", "Media Server"), 
            "petio": ("http://localhost:7777", "Request Management"),
            "tautulli": ("http://localhost:8181", "Plex Analytics"),
            "wizarr": ("http://localhost:5690", "User Management")
        }
        
        # Check which services are likely running
        try:
            result = subprocess.run([*self.compose_command.split(), 'ps', '--services'], 
                                  capture_output=True, text=True, check=True)
            running_services = result.stdout.strip().split('\n')
        except:
            running_services = []
        
        for service, (url, description) in urls.items():
            if any(service in running_service for running_service in running_services):
                self.print_colored(f"  🌐 {service.upper()}: {url} - {description}", Colors.CYAN)

    def show_maintenance_menu(self):
        """Interactive maintenance menu"""
        while True:
            self.print_header("Media Server Maintenance")
            
            menu_options = [
                ("1", "Check service health", self.check_services),
                ("2", "Update container images", self.update_containers),
                ("3", "Restart all services", self.restart_services),
                ("4", "Check storage usage", self.check_storage_usage),
                ("5", "Backup configurations", self.backup_configs),
                ("6", "Show service logs", self.show_service_logs),
                ("7", "Clean up system", self.cleanup_system),
                ("8", "Show service URLs", self.show_service_urls),
                ("9", "Full maintenance", self.full_maintenance),
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

    def full_maintenance(self):
        """Run all maintenance tasks"""
        self.print_colored("🔧 Running full maintenance...", Colors.CYAN)
        
        tasks = [
            ("Health Check", self.check_services),
            ("Storage Check", self.check_storage_usage),
            ("Update Check", self.update_containers),
            ("System Cleanup", self.cleanup_system),
            ("Configuration Backup", self.backup_configs),
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

    def run(self):
        """Main entry point"""
        if len(sys.argv) > 1:
            # Command line mode
            command = sys.argv[1].lower()
            commands = {
                'health': self.check_services,
                'update': self.update_containers,
                'restart': self.restart_services,
                'storage': self.check_storage_usage,
                'backup': self.backup_configs,
                'logs': self.show_service_logs,
                'cleanup': self.cleanup_system,
                'urls': self.show_service_urls,
                'full': self.full_maintenance
            }
            
            if command in commands:
                commands[command]()
            else:
                self.print_colored(f"Unknown command: {command}", Colors.RED)
                self.print_colored("Available: " + ", ".join(commands.keys()), Colors.YELLOW)
        else:
            # Interactive mode
            self.show_maintenance_menu()

if __name__ == "__main__":
    try:
        maintenance = MediaServerMaintenance()
        maintenance.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Maintenance cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
