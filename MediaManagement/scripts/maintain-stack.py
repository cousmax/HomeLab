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
        try:
            subprocess.run(['docker', 'compose', 'version'], capture_output=True, check=True)
            return 'docker compose'
        except:
            try:
                subprocess.run(['docker-compose', 'version'], capture_output=True, check=True)
                return 'docker-compose'
            except:
                return 'docker compose'  # Default fallback

    def _run_compose_command(self, args: List[str], use_sudo: bool = False) -> subprocess.CompletedProcess:
        """Run docker compose command with optional sudo"""
        cmd = self.compose_command.split() + args
        if use_sudo:
            cmd = ['sudo'] + cmd
        
        try:
            return subprocess.run(cmd, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError:
            # Try with sudo if initial attempt fails
            if not use_sudo:
                return self._run_compose_command(args, use_sudo=True)
            raise

    def check_stack_health(self) -> Dict[str, str]:
        """Check health of all services"""
        self.print_colored("🔍 Checking service health...", Colors.CYAN)
        
        try:
            result = self._run_compose_command(['ps', '--format', 'json'])
            services = json.loads(result.stdout)
            
            service_status = {}
            for service in services:
                name = service.get('Service', service.get('Name', 'unknown'))
                state = service.get('State', 'unknown')
                health = service.get('Health', 'unknown')
                
                if state == 'running':
                    if health == 'healthy':
                        status = 'healthy'
                    elif health == 'unhealthy':
                        status = 'unhealthy'
                    else:
                        status = 'running'
                else:
                    status = 'stopped'
                
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
            self.print_colored(f"❌ Health check failed: {e}", Colors.RED)
            self.log_action("Health Check", "FAILED", str(e))
            return {}

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
                'log': self.show_maintenance_log
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
