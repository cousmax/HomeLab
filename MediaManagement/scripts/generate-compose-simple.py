#!/usr/bin/env python3
"""
Simple Docker Compose Generator (No external dependencies)
Uses Jinja2-style templating with basic string replacement
"""

import os
import sys
import json
from pathlib import Path
from typing import Dict, List

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'

class SimpleComposeGenerator:
    def __init__(self):
        self.config = {
            "timezone": "America/New_York",
            "puid": "1000", 
            "pgid": "1000",
            "data_path": "/mnt/media",
            "config_path": "./config",
            "domain": "localhost",
            "firewall_vpn_input_ports": "12345"
        }
        
    def print_colored(self, text: str, color: str = Colors.NC):
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self, text: str):
        self.print_colored(f"=== {text} ===", Colors.CYAN)
        
    def get_input(self, prompt: str, default: str = "") -> str:
        response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip()
        return response if response else default
        
    def ask_yes_no(self, prompt: str, default: str = "n") -> bool:
        while True:
            response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip().lower()
            response = response or default.lower()
            return response in ['y', 'yes', 'true', '1']

    def get_compose_template(self) -> str:
        return """# Compose file for the *arr stack.

# All media/torrents/usenet folders use ${{DATA_PATH}} from .env (edit as needed).
# Config folders remain local in ./[service]/config.

networks:
  servarrnetwork:
    name: servarrnetwork
    ipam:
      config:
        - subnet: 172.39.0.0/24

services:
{services}

volumes:
  gluetun_data:
"""

    def get_service_templates(self) -> Dict[str, str]:
        return {
            "gluetun": """
  # airvpn recommended (referral url: https://airvpn.org/?referred_by=673908)
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun # If running on an LXC see readme for more info.
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.2
    ports:
      - {firewall_vpn_input_ports}:{firewall_vpn_input_ports} # airvpn forwarded port, pulled from .env
      - 8080:8080 # qbittorrent web interface
      - 6881:6881 # qbittorrent torrent port
      - 6789:6789 # nzbget
      - 9696:9696 # prowlarr
    volumes:
      - ./gluetun:/gluetun
    # Make a '.env' file in the same directory.
    env_file:
      - .env
    healthcheck:
      interval: 20s
      timeout: 10s
      retries: 5
    restart: unless-stopped""",

            "qbittorrent": """
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    labels:
      - deunhealth.restart.on.unhealthy=true
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
      - WEBUI_PORT=8080 # must match "qbittorrent web interface" port number in gluetun's service above
      - TORRENTING_PORT={firewall_vpn_input_ports} # airvpn forwarded port, pulled from .env
    volumes:
      - ./qbittorrent:/config
      - {data_path}/torrents:/data
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    network_mode: service:gluetun
    healthcheck:
      test: ping -c 1 www.google.com || exit 1
      interval: 60s
      retries: 3
      start_period: 20s
      timeout: 10s""",

            "deunhealth": """
  # See the 'qBittorrent Stalls with VPN Timeout' section for more information.
  deunhealth:
    image: qmcgaw/deunhealth
    container_name: deunhealth
    environment:
      - LOG_LEVEL=info
      - HEALTH_SERVER_ADDRESS=127.0.0.1:9999
      - TZ={timezone}
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock""",

            "nzbget": """
  nzbget:
    image: lscr.io/linuxserver/nzbget:latest
    container_name: nzbget
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./nzbget:/config
      - {data_path}/usenet:/data
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    restart: unless-stopped
    network_mode: service:gluetun""",

            "prowlarr": """
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./prowlarr:/config
    restart: unless-stopped
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    network_mode: service:gluetun""",

            "sonarr": """
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./sonarr:/config
      - {data_path}/media:/data
    ports:
      - 8989:8989
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.3""",

            "radarr": """
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    restart: unless-stopped
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./radarr:/config
      - {data_path}/media:/data
    ports:
      - 7878:7878
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.4""",

            "lidarr": """
  lidarr:
    container_name: lidarr
    image: lscr.io/linuxserver/lidarr:latest
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./lidarr:/config
      - {data_path}/media:/data
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    ports:
      - 8686:8686
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.5""",

            "bazarr": """
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    restart: unless-stopped
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./bazarr:/config
      - {data_path}/media:/data
    ports:
      - 6767:6767
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.6""",

            "ytdl-sub": """
  ytdl-sub:
    image: ghcr.io/jmbannon/ytdl-sub:latest
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
      - DOCKER_MODS=linuxserver/mods:universal-cron
    volumes:
      - ./ytdl-sub:/config
      - {data_path}/youtube:/youtube
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.8
    restart: unless-stopped""",

            "jellyseerr": """
  jellyseerr:
    container_name: jellyseerr
    image: fallenbagel/jellyseerr:latest
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - ./jellyseerr:/app/config
    ports:
      - 5055:5055
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.9
    restart: unless-stopped""",

            # Legacy services for compatibility
            "portainer": """
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer:/data
    environment:
      - TZ={timezone}
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.10""",

            "jellyfin": """
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    volumes:
      - ./jellyfin:/config
      - {data_path}/media/movies:/data/movies
      - {data_path}/media/tv:/data/tv
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.11"""
        }

    def configure(self):
        self.print_header("Configuration Setup")
        
        self.config["timezone"] = self.get_input("Timezone", self.config["timezone"])
        self.config["puid"] = self.get_input("PUID (User ID)", self.config["puid"])
        self.config["pgid"] = self.get_input("PGID (Group ID)", self.config["pgid"])
        self.config["data_path"] = self.get_input("Data path", self.config["data_path"])
        self.config["config_path"] = self.get_input("Config path", self.config["config_path"])
        self.config["firewall_vpn_input_ports"] = self.get_input("VPN forwarded port", self.config["firewall_vpn_input_ports"])

    def select_services(self) -> List[str]:
        services_info = {
            "gluetun": "VPN client (required for secure downloading)",
            "qbittorrent": "Torrent client (routes through VPN)",
            "deunhealth": "Health monitor for qBittorrent (recommended with VPN)",
            "nzbget": "Usenet client (routes through VPN)",
            "prowlarr": "Indexer manager (routes through VPN)",
            "sonarr": "TV show management",
            "radarr": "Movie management",
            "lidarr": "Music management", 
            "bazarr": "Subtitle management",
            "ytdl-sub": "YouTube downloader with subscriptions",
            "jellyseerr": "Request management for Jellyfin/Plex",
            "portainer": "Docker management UI",
            "jellyfin": "Media server"
        }
        
        selected = []
        self.print_header("Service Selection")
        
        # Recommend VPN stack first
        self.print_colored("🔒 VPN & Download Stack (Recommended together):", Colors.CYAN)
        for service in ["gluetun", "qbittorrent", "deunhealth", "nzbget", "prowlarr"]:
            if self.ask_yes_no(f"Include {service} ({services_info[service]})?", "y" if service in ["gluetun", "qbittorrent"] else "n"):
                selected.append(service)
        
        print()
        self.print_colored("📺 Media Management (*arr stack):", Colors.CYAN)
        for service in ["sonarr", "radarr", "lidarr", "bazarr"]:
            if self.ask_yes_no(f"Include {service} ({services_info[service]})?", "y" if service in ["sonarr", "radarr"] else "n"):
                selected.append(service)
                
        print()
        self.print_colored("🎬 Media & Request Management:", Colors.CYAN)
        for service in ["jellyseerr", "ytdl-sub", "jellyfin"]:
            if self.ask_yes_no(f"Include {service} ({services_info[service]})?"):
                selected.append(service)
                
        print()
        self.print_colored("🛠️ Management Tools:", Colors.CYAN)
        for service in ["portainer"]:
            if self.ask_yes_no(f"Include {service} ({services_info[service]})?"):
                selected.append(service)
                
        return selected

    def generate_compose(self, selected_services: List[str]):
        templates = self.get_service_templates()
        
        # Generate services section
        services_content = ""
        for service in selected_services:
            if service in templates:
                service_config = templates[service].format(**self.config)
                services_content += service_config + "\n"
        
        # Generate full compose file
        compose_content = self.get_compose_template().format(services=services_content)
        
        # Write to file
        with open("docker-compose.yml", "w") as f:
            f.write(compose_content)
            
        self.print_colored("✓ Generated docker-compose.yml", Colors.GREEN)

    def create_directories(self, selected_services: List[str]):
        # Create base directories
        Path(self.config["data_path"]).mkdir(parents=True, exist_ok=True)
        Path(self.config["config_path"]).mkdir(parents=True, exist_ok=True)
        
        # Create data subdirectories based on your existing structure
        data_subdirs = [
            "media/movies", "media/tv", "media/music", 
            "torrents", "usenet", "youtube", "downloads"
        ]
        for subdir in data_subdirs:
            Path(f"{self.config['data_path']}/{subdir}").mkdir(parents=True, exist_ok=True)
            
        # Create service config directories  
        for service in selected_services:
            Path(f"./{service}").mkdir(parents=True, exist_ok=True)
            
        self.print_colored("✓ Created directories", Colors.GREEN)

    def save_env_file(self):
        """Create .env file for docker-compose matching your existing format"""
        env_content = f"""# Docker Compose Environment Variables
# Generated by Simple Compose Generator

# User/Group IDs for file permissions
PUID={self.config['puid']}
PGID={self.config['pgid']}

# Timezone
TZ={self.config['timezone']}

# Data path for media storage
DATA_PATH={self.config['data_path']}

# VPN Configuration - Update these with your VPN details
FIREWALL_VPN_INPUT_PORTS={self.config['firewall_vpn_input_ports']}

# VPN Provider Configuration (update as needed)
VPN_SERVICE_PROVIDER=airvpn
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=your_private_key_here
WIREGUARD_ADDRESSES=10.x.x.x/32
SERVER_COUNTRIES=Netherlands

# Optional: Add your VPN configuration below
# OPENVPN_USER=your_username
# OPENVPN_PASSWORD=your_password
"""
        with open(".env", "w") as f:
            f.write(env_content)
            
        self.print_colored("✓ Generated .env file", Colors.GREEN)
        self.print_colored("⚠ Remember to update VPN settings in .env file!", Colors.YELLOW)

    def print_urls(self, services: List[str]):
        self.print_header("Service URLs")
        
        urls = {
            "gluetun": "VPN status (check logs with: docker-compose logs gluetun)",
            "qbittorrent": "http://localhost:8080 (via VPN)",
            "nzbget": "http://localhost:6789 (via VPN)", 
            "prowlarr": "http://localhost:9696 (via VPN)",
            "sonarr": "http://localhost:8989", 
            "radarr": "http://localhost:7878",
            "lidarr": "http://localhost:8686",
            "bazarr": "http://localhost:6767",
            "jellyseerr": "http://localhost:5055",
            "portainer": "http://localhost:9000",
            "jellyfin": "http://localhost:8096",
            "ytdl-sub": "Check logs: docker-compose logs ytdl-sub"
        }
        
        for service in services:
            if service in urls:
                if "localhost:" in urls[service]:
                    print(f"  {service}: {Colors.CYAN}{urls[service]}{Colors.NC}")
                else:
                    print(f"  {service}: {Colors.YELLOW}{urls[service]}{Colors.NC}")
        
        if "gluetun" in services:
            print()
            self.print_colored("🔒 VPN Notes:", Colors.YELLOW)
            print(f"  - Services using VPN will be accessible through Gluetun container")
            print(f"  - Check VPN status: docker-compose exec gluetun wget -qO- ifconfig.me")
            print(f"  - Update .env file with your VPN credentials before starting")

    def run(self):
        self.print_header("Simple Docker Compose Generator")
        
        self.configure()
        services = self.select_services()
        
        if not services:
            self.print_colored("No services selected!", Colors.YELLOW)
            return
            
        self.generate_compose(services)
        self.create_directories(services)
        self.save_env_file()
        
        self.print_colored("\n✓ Setup complete!", Colors.GREEN)
        self.print_colored("Run: docker-compose up -d", Colors.WHITE)
        
        self.print_urls(services)

if __name__ == "__main__":
    try:
        generator = SimpleComposeGenerator()
        generator.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
