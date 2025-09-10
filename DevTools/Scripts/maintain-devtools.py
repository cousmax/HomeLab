#!/usr/bin/env python3
"""
DevTools Stack Maintenance - Gitea Edition
Comprehensive maintenance and management for Gitea development tools
"""

import os
import sys
import subprocess
import json
import sqlite3
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
import argparse

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'

class DevToolsMaintainer:
    def __init__(self):
        self.compose_file = "docker-compose.yml"
        self.backup_dir = Path("backups")
        self.services = self._get_services()
        
    def print_colored(self, text: str, color: str = Colors.NC):
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self, text: str):
        self.print_colored(f"\n=== {text} ===", Colors.CYAN)
        
    def _get_services(self) -> List[str]:
        """Get list of services from docker-compose.yml"""
        try:
            result = subprocess.run(
                ["docker-compose", "config", "--services"],
                capture_output=True, text=True, check=True
            )
            return result.stdout.strip().split('\n')
        except subprocess.CalledProcessError:
            return []

    def _run_command(self, command: List[str], capture_output: bool = False) -> Optional[subprocess.CompletedProcess]:
        """Run a command with error handling"""
        try:
            if capture_output:
                return subprocess.run(command, capture_output=True, text=True, check=True)
            else:
                subprocess.run(command, check=True)
                return None
        except subprocess.CalledProcessError as e:
            self.print_colored(f"Error running command: {' '.join(command)}", Colors.RED)
            if capture_output and e.stdout:
                self.print_colored(f"Output: {e.stdout}", Colors.YELLOW)
            if capture_output and e.stderr:
                self.print_colored(f"Error: {e.stderr}", Colors.RED)
            return None

    def status(self):
        """Show status of all services"""
        self.print_header("DevTools Stack Status")
        
        self._run_command(["docker-compose", "ps"])
        
        # Health check
        self.print_header("Health Check")
        
        for service in self.services:
            if self._is_service_healthy(service):
                self.print_colored(f"✅ {service}: Healthy", Colors.GREEN)
            else:
                self.print_colored(f"❌ {service}: Unhealthy", Colors.RED)

    def _is_service_healthy(self, service: str) -> bool:
        """Check if a service is healthy"""
        result = self._run_command(
            ["docker-compose", "ps", "-q", service],
            capture_output=True
        )
        
        if not result or not result.stdout.strip():
            return False
        
        container_id = result.stdout.strip()
        inspect_result = self._run_command(
            ["docker", "inspect", container_id, "--format", "{{.State.Running}}"],
            capture_output=True
        )
        
        return inspect_result and inspect_result.stdout.strip() == "true"

    def logs(self, service: str = None, follow: bool = False, lines: int = 50):
        """Show logs for services"""
        self.print_header(f"Logs - {service or 'All Services'}")
        
        command = ["docker-compose", "logs"]
        if follow:
            command.append("-f")
        command.extend(["--tail", str(lines)])
        if service:
            command.append(service)
        
        self._run_command(command)

    def update(self, service: str = None):
        """Update services"""
        self.print_header("Updating Services")
        
        services_to_update = [service] if service else self.services
        
        for svc in services_to_update:
            self.print_colored(f"Updating {svc}...", Colors.BLUE)
            
            # Pull latest image
            self._run_command(["docker-compose", "pull", svc])
            
            # Recreate container
            self._run_command(["docker-compose", "up", "-d", svc])
        
        self.print_colored("✅ Update complete", Colors.GREEN)

    def backup(self):
        """Create backup of all data"""
        self.print_header("Creating Backup")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = self.backup_dir / f"devtools_backup_{timestamp}"
        
        # Create backup directory
        backup_path.mkdir(parents=True, exist_ok=True)
        
        # Stop services for consistent backup
        self.print_colored("Stopping services for backup...", Colors.YELLOW)
        self._run_command(["docker-compose", "stop"])
        
        try:
            # Backup configurations
            config_files = ["docker-compose.yml", ".env", "README.md"]
            for config_file in config_files:
                if os.path.exists(config_file):
                    shutil.copy2(config_file, backup_path)
                    self.print_colored(f"✅ Backed up {config_file}", Colors.GREEN)
            
            # Backup data directories
            data_dirs = []
            
            if "gitea" in self.services:
                data_dirs.extend(["gitea/data", "gitea/postgres"])
            if "gitea-runner" in self.services:
                data_dirs.append("gitea/runner")
            if "drone" in self.services:
                data_dirs.append("drone/data")
            if "portainer" in self.services:
                data_dirs.append("portainer/data")
            if "code-server" in self.services:
                data_dirs.append("code-server/config")
            
            for data_dir in data_dirs:
                if os.path.exists(data_dir):
                    dest_path = backup_path / data_dir
                    dest_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copytree(data_dir, dest_path, dirs_exist_ok=True)
                    self.print_colored(f"✅ Backed up {data_dir}", Colors.GREEN)
            
            # Create backup info file
            backup_info = {
                "timestamp": timestamp,
                "services": self.services,
                "backup_type": "full"
            }
            
            with open(backup_path / "backup_info.json", "w") as f:
                json.dump(backup_info, f, indent=2)
            
            # Compress backup
            self.print_colored("Compressing backup...", Colors.BLUE)
            shutil.make_archive(str(backup_path), 'tar', str(backup_path.parent), backup_path.name)
            shutil.rmtree(backup_path)
            
            self.print_colored(f"✅ Backup created: {backup_path}.tar", Colors.GREEN)
            
        finally:
            # Restart services
            self.print_colored("Restarting services...", Colors.BLUE)
            self._run_command(["docker-compose", "up", "-d"])

    def restore(self, backup_file: str):
        """Restore from backup"""
        self.print_header("Restoring from Backup")
        
        backup_path = Path(backup_file)
        if not backup_path.exists():
            self.print_colored(f"Backup file not found: {backup_file}", Colors.RED)
            return
        
        # Extract backup
        temp_dir = Path("temp_restore")
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        
        self.print_colored("Extracting backup...", Colors.BLUE)
        shutil.unpack_archive(backup_file, temp_dir)
        
        # Find extracted directory
        extracted_dirs = [d for d in temp_dir.iterdir() if d.is_dir()]
        if not extracted_dirs:
            self.print_colored("No backup data found in archive", Colors.RED)
            return
        
        restore_dir = extracted_dirs[0]
        
        # Stop services
        self.print_colored("Stopping services...", Colors.YELLOW)
        self._run_command(["docker-compose", "down"])
        
        try:
            # Restore configurations
            config_files = ["docker-compose.yml", ".env", "README.md"]
            for config_file in config_files:
                source = restore_dir / config_file
                if source.exists():
                    shutil.copy2(source, config_file)
                    self.print_colored(f"✅ Restored {config_file}", Colors.GREEN)
            
            # Restore data directories
            for item in restore_dir.iterdir():
                if item.is_dir() and item.name not in [".", ".."]:
                    if os.path.exists(item.name):
                        shutil.rmtree(item.name)
                    shutil.copytree(item, item.name)
                    self.print_colored(f"✅ Restored {item.name}", Colors.GREEN)
            
            self.print_colored("✅ Restore complete", Colors.GREEN)
            
        finally:
            # Clean up
            shutil.rmtree(temp_dir)
            
            # Restart services
            self.print_colored("Starting services...", Colors.BLUE)
            self._run_command(["docker-compose", "up", "-d"])

    def cleanup(self):
        """Clean up old data and logs"""
        self.print_header("Cleanup")
        
        # Clean up old backups (keep last 10)
        if self.backup_dir.exists():
            backups = sorted(self.backup_dir.glob("*.tar"), key=os.path.getmtime, reverse=True)
            old_backups = backups[10:]  # Keep newest 10
            
            for old_backup in old_backups:
                old_backup.unlink()
                self.print_colored(f"🗑️  Removed old backup: {old_backup.name}", Colors.YELLOW)
        
        # Clean up Docker
        self.print_colored("Cleaning up Docker resources...", Colors.BLUE)
        self._run_command(["docker", "system", "prune", "-f"])
        
        # Clean up logs (if using default Docker logging)
        self.print_colored("Truncating container logs...", Colors.BLUE)
        for service in self.services:
            result = self._run_command(
                ["docker-compose", "ps", "-q", service],
                capture_output=True
            )
            if result and result.stdout.strip():
                container_id = result.stdout.strip()
                log_file = f"/var/lib/docker/containers/{container_id}/{container_id}-json.log"
                if os.path.exists(log_file):
                    try:
                        open(log_file, 'w').close()
                        self.print_colored(f"✅ Cleaned logs for {service}", Colors.GREEN)
                    except PermissionError:
                        self.print_colored(f"⚠️  Cannot clean logs for {service} (permission denied)", Colors.YELLOW)

    def gitea_admin(self):
        """Gitea-specific admin tasks"""
        if "gitea" not in self.services:
            self.print_colored("Gitea service not found", Colors.RED)
            return
        
        self.print_header("Gitea Administration")
        
        print("Available Gitea admin commands:")
        print("  1. Create user")
        print("  2. List users")
        print("  3. Generate runner token")
        print("  4. Repository statistics")
        print("  5. Database maintenance")
        
        choice = input(f"{Colors.BLUE}Select option (1-5): {Colors.NC}").strip()
        
        if choice == "1":
            self._gitea_create_user()
        elif choice == "2":
            self._gitea_list_users()
        elif choice == "3":
            self._gitea_generate_runner_token()
        elif choice == "4":
            self._gitea_repo_stats()
        elif choice == "5":
            self._gitea_db_maintenance()

    def _gitea_create_user(self):
        """Create Gitea user via CLI"""
        username = input(f"{Colors.BLUE}Username: {Colors.NC}").strip()
        email = input(f"{Colors.BLUE}Email: {Colors.NC}").strip()
        password = input(f"{Colors.BLUE}Password: {Colors.NC}").strip()
        
        if not all([username, email, password]):
            self.print_colored("All fields are required", Colors.RED)
            return
        
        admin_flag = "--admin" if input(f"{Colors.BLUE}Make admin? (y/n): {Colors.NC}").lower() == 'y' else ""
        
        command = [
            "docker-compose", "exec", "gitea",
            "gitea", "admin", "user", "create",
            "--username", username,
            "--email", email,
            "--password", password
        ]
        
        if admin_flag:
            command.append(admin_flag)
        
        self._run_command(command)

    def _gitea_list_users(self):
        """List Gitea users"""
        self._run_command([
            "docker-compose", "exec", "gitea",
            "gitea", "admin", "user", "list"
        ])

    def _gitea_generate_runner_token(self):
        """Generate runner registration token"""
        print(f"{Colors.YELLOW}To generate a runner token:{Colors.NC}")
        print("1. Access Gitea web interface")
        print("2. Go to Site Administration → Actions → Runners")
        print("3. Click 'Create new runner'")
        print("4. Copy the registration token")
        print("5. Update .env file with RUNNER_TOKEN value")
        print("6. Restart runner: docker-compose restart gitea-runner")

    def _gitea_repo_stats(self):
        """Show repository statistics"""
        result = self._run_command([
            "docker-compose", "exec", "gitea-db",
            "psql", "-U", "gitea", "-d", "gitea",
            "-c", "SELECT COUNT(*) as repositories FROM repository;"
        ], capture_output=True)
        
        if result:
            self.print_colored("Repository Statistics:", Colors.CYAN)
            print(result.stdout)

    def _gitea_db_maintenance(self):
        """Gitea database maintenance"""
        print(f"{Colors.CYAN}Database Maintenance Options:{Colors.NC}")
        print("  1. Vacuum database")
        print("  2. Check database integrity")
        print("  3. Database backup")
        
        choice = input(f"{Colors.BLUE}Select option: {Colors.NC}").strip()
        
        if choice == "1":
            self._run_command([
                "docker-compose", "exec", "gitea-db",
                "psql", "-U", "gitea", "-d", "gitea", "-c", "VACUUM;"
            ])
        elif choice == "2":
            self._run_command([
                "docker-compose", "exec", "gitea-db",
                "psql", "-U", "gitea", "-d", "gitea", "-c", "SELECT pg_database_size('gitea');"
            ])
        elif choice == "3":
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_file = f"gitea_db_backup_{timestamp}.sql"
            self._run_command([
                "docker-compose", "exec", "gitea-db",
                "pg_dump", "-U", "gitea", "gitea", ">", backup_file
            ])

    def monitoring(self):
        """Show monitoring information"""
        self.print_header("DevTools Monitoring")
        
        # Resource usage
        self.print_colored("Resource Usage:", Colors.CYAN)
        self._run_command(["docker", "stats", "--no-stream"])
        
        # Port usage
        self.print_header("Port Status")
        ports = {
            "3000": "Gitea Web",
            "2222": "Gitea SSH", 
            "3001": "Drone CI",
            "9000": "Portainer",
            "8443": "Code Server"
        }
        
        for port, service in ports.items():
            result = self._run_command([
                "netstat", "-an"
            ], capture_output=True)
            
            if result and f":{port}" in result.stdout:
                self.print_colored(f"✅ {service} ({port}): Active", Colors.GREEN)
            else:
                self.print_colored(f"❌ {service} ({port}): Inactive", Colors.RED)

    def interactive_menu(self):
        """Interactive maintenance menu"""
        while True:
            self.print_header("DevTools Maintenance Menu")
            
            print("Available options:")
            print("  1. Status")
            print("  2. Logs")
            print("  3. Update services")
            print("  4. Backup")
            print("  5. Restore")
            print("  6. Cleanup")
            print("  7. Gitea admin")
            print("  8. Monitoring")
            print("  9. Exit")
            
            choice = input(f"\n{Colors.BLUE}Select option (1-9): {Colors.NC}").strip()
            
            try:
                if choice == "1":
                    self.status()
                elif choice == "2":
                    service = input(f"{Colors.BLUE}Service (or Enter for all): {Colors.NC}").strip() or None
                    follow = input(f"{Colors.BLUE}Follow logs? (y/n): {Colors.NC}").strip().lower() == 'y'
                    self.logs(service, follow)
                elif choice == "3":
                    service = input(f"{Colors.BLUE}Service (or Enter for all): {Colors.NC}").strip() or None
                    self.update(service)
                elif choice == "4":
                    self.backup()
                elif choice == "5":
                    backup_file = input(f"{Colors.BLUE}Backup file path: {Colors.NC}").strip()
                    if backup_file:
                        self.restore(backup_file)
                elif choice == "6":
                    self.cleanup()
                elif choice == "7":
                    self.gitea_admin()
                elif choice == "8":
                    self.monitoring()
                elif choice == "9":
                    break
                else:
                    self.print_colored("Invalid option", Colors.RED)
            except KeyboardInterrupt:
                print(f"\n{Colors.YELLOW}Operation cancelled{Colors.NC}")
                continue
            
            input(f"\n{Colors.BLUE}Press Enter to continue...{Colors.NC}")

def main():
    parser = argparse.ArgumentParser(description="DevTools Stack Maintenance")
    parser.add_argument("command", nargs="?", choices=[
        "status", "logs", "update", "backup", "restore", "cleanup", 
        "gitea-admin", "monitoring", "menu"
    ], default="menu", help="Maintenance command")
    parser.add_argument("--service", help="Specific service to operate on")
    parser.add_argument("--follow", action="store_true", help="Follow logs")
    parser.add_argument("--backup-file", help="Backup file for restore")
    
    args = parser.parse_args()
    
    maintainer = DevToolsMaintainer()
    
    try:
        if args.command == "status":
            maintainer.status()
        elif args.command == "logs":
            maintainer.logs(args.service, args.follow)
        elif args.command == "update":
            maintainer.update(args.service)
        elif args.command == "backup":
            maintainer.backup()
        elif args.command == "restore":
            if not args.backup_file:
                print(f"{Colors.RED}--backup-file is required for restore{Colors.NC}")
                return
            maintainer.restore(args.backup_file)
        elif args.command == "cleanup":
            maintainer.cleanup()
        elif args.command == "gitea-admin":
            maintainer.gitea_admin()
        elif args.command == "monitoring":
            maintainer.monitoring()
        else:
            maintainer.interactive_menu()
            
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Maintenance cancelled{Colors.NC}")

if __name__ == "__main__":
    main()
