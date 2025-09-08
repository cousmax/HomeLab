#!/usr/bin/env python3
"""
Dynamic Docker Compose Generator
Generates docker-compose.yml files with templates and configuration management
"""

import os
import sys
import json
import yaml
from pathlib import Path
from typing import Dict, List, Optional, Any

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'  # No Color

class ComposeGenerator:
    def __init__(self, config_file: str = "compose-config.json"):
        self.config_file = config_file
        self.config = self.load_config()
        self.services = {}
        
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
        
    def print_step(self, text: str):
        self.print_colored(f"→ {text}", Colors.WHITE)

    def load_config(self) -> Dict:
        """Load configuration from file or create default"""
        if os.path.exists(self.config_file):
            with open(self.config_file, 'r') as f:
                return json.load(f)
        
        return {
            "timezone": "America/New_York",
            "puid": "1000",
            "pgid": "1000",
            "data_path": "./data",
            "config_path": "./config",
            "domain": "localhost",
            "email": "admin@localhost"
        }
    
    def save_config(self):
        """Save current configuration to file"""
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def get_input(self, prompt: str, default: str = "", required: bool = False) -> str:
        """Get user input with default value"""
        while True:
            response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip()
            if response:
                return response
            elif default:
                return default
            elif not required:
                return ""
            else:
                self.print_error("This field is required!")
    
    def ask_yes_no(self, prompt: str, default: str = "n") -> bool:
        """Ask yes/no question"""
        while True:
            response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip().lower()
            response = response or default.lower()
            
            if response in ['y', 'yes', 'true', '1']:
                return True
            elif response in ['n', 'no', 'false', '0']:
                return False
            else:
                self.print_error("Please answer yes or no.")
    
    def configure_settings(self):
        """Interactive configuration setup"""
        self.print_step("Configuring settings...")
        
        self.config["timezone"] = self.get_input("Timezone", self.config["timezone"])
        self.config["puid"] = self.get_input("PUID (User ID)", self.config["puid"])
        self.config["pgid"] = self.get_input("PGID (Group ID)", self.config["pgid"])
        self.config["data_path"] = self.get_input("Data directory path", self.config["data_path"])
        self.config["config_path"] = self.get_input("Config directory path", self.config["config_path"])
        self.config["domain"] = self.get_input("Domain name", self.config["domain"])
        self.config["email"] = self.get_input("Email address", self.config["email"])
        
    def get_service_templates(self) -> Dict[str, Dict]:
        """Return service templates"""
        return {
            "portainer": {
                "image": "portainer/portainer-ce:latest",
                "container_name": "portainer",
                "restart": "unless-stopped",
                "ports": ["9000:9000"],
                "volumes": [
                    "/var/run/docker.sock:/var/run/docker.sock",
                    f"{self.config['config_path']}/portainer:/data"
                ],
                "environment": [f"TZ={self.config['timezone']}"]
            },
            "watchtower": {
                "image": "containrrr/watchtower:latest",
                "container_name": "watchtower",
                "restart": "unless-stopped",
                "volumes": ["/var/run/docker.sock:/var/run/docker.sock"],
                "environment": [
                    f"TZ={self.config['timezone']}",
                    "WATCHTOWER_CLEANUP=true",
                    "WATCHTOWER_SCHEDULE=0 0 4 * * *"
                ]
            },
            "nginx-proxy-manager": {
                "image": "jc21/nginx-proxy-manager:latest",
                "container_name": "nginx-proxy-manager",
                "restart": "unless-stopped",
                "ports": ["80:80", "443:443", "81:81"],
                "volumes": [
                    f"{self.config['config_path']}/nginx-proxy-manager:/data",
                    f"{self.config['config_path']}/nginx-proxy-manager/letsencrypt:/etc/letsencrypt"
                ],
                "environment": [f"TZ={self.config['timezone']}"]
            },
            "sonarr": {
                "image": "lscr.io/linuxserver/sonarr:latest",
                "container_name": "sonarr",
                "restart": "unless-stopped",
                "ports": ["8989:8989"],
                "volumes": [
                    f"{self.config['config_path']}/sonarr:/config",
                    f"{self.config['data_path']}/tv:/tv",
                    f"{self.config['data_path']}/downloads:/downloads"
                ],
                "environment": [
                    f"PUID={self.config['puid']}",
                    f"PGID={self.config['pgid']}",
                    f"TZ={self.config['timezone']}"
                ]
            },
            "radarr": {
                "image": "lscr.io/linuxserver/radarr:latest",
                "container_name": "radarr",
                "restart": "unless-stopped",
                "ports": ["7878:7878"],
                "volumes": [
                    f"{self.config['config_path']}/radarr:/config",
                    f"{self.config['data_path']}/movies:/movies",
                    f"{self.config['data_path']}/downloads:/downloads"
                ],
                "environment": [
                    f"PUID={self.config['puid']}",
                    f"PGID={self.config['pgid']}",
                    f"TZ={self.config['timezone']}"
                ]
            },
            "prowlarr": {
                "image": "lscr.io/linuxserver/prowlarr:latest",
                "container_name": "prowlarr",
                "restart": "unless-stopped",
                "ports": ["9696:9696"],
                "volumes": [f"{self.config['config_path']}/prowlarr:/config"],
                "environment": [
                    f"PUID={self.config['puid']}",
                    f"PGID={self.config['pgid']}",
                    f"TZ={self.config['timezone']}"
                ]
            },
            "qbittorrent": {
                "image": "lscr.io/linuxserver/qbittorrent:latest",
                "container_name": "qbittorrent",
                "restart": "unless-stopped",
                "ports": ["8080:8080", "6881:6881", "6881:6881/udp"],
                "volumes": [
                    f"{self.config['config_path']}/qbittorrent:/config",
                    f"{self.config['data_path']}/downloads:/downloads"
                ],
                "environment": [
                    f"PUID={self.config['puid']}",
                    f"PGID={self.config['pgid']}",
                    f"TZ={self.config['timezone']}",
                    "WEBUI_PORT=8080"
                ]
            },
            "jellyfin": {
                "image": "jellyfin/jellyfin:latest",
                "container_name": "jellyfin",
                "restart": "unless-stopped",
                "ports": ["8096:8096"],
                "volumes": [
                    f"{self.config['config_path']}/jellyfin:/config",
                    f"{self.config['data_path']}/movies:/data/movies",
                    f"{self.config['data_path']}/tv:/data/tv"
                ],
                "environment": [
                    f"PUID={self.config['puid']}",
                    f"PGID={self.config['pgid']}",
                    f"TZ={self.config['timezone']}"
                ]
            },
            "traefik": {
                "image": "traefik:v2.10",
                "container_name": "traefik",
                "restart": "unless-stopped",
                "ports": ["80:80", "443:443", "8080:8080"],
                "volumes": [
                    "/var/run/docker.sock:/var/run/docker.sock:ro",
                    f"{self.config['config_path']}/traefik:/etc/traefik"
                ],
                "environment": [f"TZ={self.config['timezone']}"],
                "command": [
                    "--api.dashboard=true",
                    "--providers.docker=true",
                    "--entrypoints.web.address=:80",
                    "--entrypoints.websecure.address=:443"
                ]
            }
        }
    
    def select_services(self) -> List[str]:
        """Interactive service selection"""
        self.print_step("Selecting services to include...")
        
        available_services = {
            "portainer": "Docker management UI",
            "watchtower": "Auto container updates",
            "nginx-proxy-manager": "Reverse proxy with SSL",
            "traefik": "Modern reverse proxy (alternative to NPM)",
            "sonarr": "TV Shows management",
            "radarr": "Movies management", 
            "prowlarr": "Indexer manager",
            "qbittorrent": "Torrent client",
            "jellyfin": "Media server"
        }
        
        selected = []
        for service, description in available_services.items():
            if self.ask_yes_no(f"Include {service} ({description})?", "n"):
                selected.append(service)
                
        return selected
    
    def generate_compose_file(self, services: List[str], filename: str = "docker-compose.yml"):
        """Generate docker-compose.yml file"""
        templates = self.get_service_templates()
        
        compose_data = {
            "version": "3.8",
            "services": {},
            "networks": {
                "default": {
                    "name": "homelab",
                    "driver": "bridge"
                }
            }
        }
        
        for service in services:
            if service in templates:
                compose_data["services"][service] = templates[service]
        
        # Write YAML file
        with open(filename, 'w') as f:
            yaml.dump(compose_data, f, default_flow_style=False, sort_keys=False)
        
        self.print_success(f"Generated {filename}")
    
    def create_directories(self, services: List[str]):
        """Create required directories"""
        self.print_step("Creating directories...")
        
        # Create base directories
        Path(self.config["data_path"]).mkdir(parents=True, exist_ok=True)
        Path(self.config["config_path"]).mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories
        data_subdirs = ["movies", "tv", "downloads", "books", "music"]
        for subdir in data_subdirs:
            Path(f"{self.config['data_path']}/{subdir}").mkdir(parents=True, exist_ok=True)
        
        # Create service config directories
        for service in services:
            Path(f"{self.config['config_path']}/{service}").mkdir(parents=True, exist_ok=True)
    
    def print_service_urls(self, services: List[str]):
        """Print service access URLs"""
        self.print_warning("Service URLs (once running):")
        
        url_map = {
            "portainer": "http://localhost:9000",
            "nginx-proxy-manager": "http://localhost:81", 
            "traefik": "http://localhost:8080",
            "sonarr": "http://localhost:8989",
            "radarr": "http://localhost:7878",
            "prowlarr": "http://localhost:9696",
            "qbittorrent": "http://localhost:8080",
            "jellyfin": "http://localhost:8096"
        }
        
        for service in services:
            if service in url_map:
                print(f"  - {service.title()}: {Colors.CYAN}{url_map[service]}{Colors.NC}")
    
    def run(self):
        """Main execution function"""
        self.print_header("Dynamic Docker Compose Generator (Python)")
        
        # Load or create configuration
        self.configure_settings()
        
        # Select services
        selected_services = self.select_services()
        
        if not selected_services:
            self.print_warning("No services selected. Exiting.")
            return
        
        # Generate files
        self.generate_compose_file(selected_services)
        self.create_directories(selected_services)
        self.save_config()
        
        # Summary
        self.print_success("Setup completed successfully!")
        self.print_info(f"Configuration saved to: {self.config_file}")
        
        print()
        self.print_info("Next steps:")
        print(f"  1. Review the generated docker-compose.yml")
        print(f"  2. Run: {Colors.YELLOW}docker-compose up -d{Colors.NC}")
        print(f"  3. Access services on their respective ports")
        
        print()
        self.print_service_urls(selected_services)

if __name__ == "__main__":
    try:
        generator = ComposeGenerator()
        generator.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Cancelled by user{Colors.NC}")
        sys.exit(1)
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
        sys.exit(1)
