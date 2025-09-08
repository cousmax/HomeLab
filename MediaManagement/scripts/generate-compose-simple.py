#!/usr/bin/env python3
"""
Simple Docker Compose Generator (No external dependencies)
Uses Jinja2-style templating with basic string replacement
"""

import os
import sys
import json
import subprocess
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
        self.compose_command = "docker compose"  # Default to modern syntax
        
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

            "qbittorrent_vpn": """
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
      - {data_path}/torrents:/data/torrents
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

            "qbittorrent_direct": """
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
      - WEBUI_PORT=8080
    volumes:
      - ./qbittorrent:/config
      - {data_path}/torrents:/data/torrents
    ports:
      - 8080:8080 # qbittorrent web interface
      - 6881:6881 # qbittorrent torrent port
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.12""",

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

            "nzbget_vpn": """
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
      - {data_path}/usenet:/data/usenet
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    restart: unless-stopped
    network_mode: service:gluetun""",

            "nzbget_direct": """
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
      - {data_path}/usenet:/data/usenet
    ports:
      - 6789:6789
    restart: unless-stopped
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.13""",

            "prowlarr_vpn": """
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

            "prowlarr_direct": """
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
    ports:
      - 9696:9696
    restart: unless-stopped
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.14""",

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
      - {data_path}:/data
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
      - {data_path}:/data
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
      - {data_path}:/data
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
      - {data_path}:/data
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
      - {data_path}/media:/data/media
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
        
        # Network share configuration
        self.print_colored("\n🌐 Storage Configuration:", Colors.CYAN)
        use_network_share = self.ask_yes_no("Do you want to use a network share (NFS/SMB) for media storage?", "n")
        
        if use_network_share:
            self._configure_network_share()
        else:
            self.config["data_path"] = self.get_input("Data path", self.config["data_path"])
            self.config["use_network_share"] = False
        
        self.config["config_path"] = self.get_input("Config path", self.config["config_path"])
        self.config["firewall_vpn_input_ports"] = self.get_input("VPN forwarded port", self.config["firewall_vpn_input_ports"])

    def _configure_network_share(self):
        """Configure network share (NFS/SMB) mounting"""
        self.print_colored("Setting up network share configuration...", Colors.BLUE)
        
        # Get share type
        share_types = {
            "1": "NFS",
            "2": "SMB/CIFS (Windows Share)",
            "3": "Manual (I'll configure it myself)"
        }
        
        print("\nShare types:")
        for key, value in share_types.items():
            print(f"  {key}. {value}")
        
        share_choice = self.get_input("Select share type", "1")
        share_type = share_types.get(share_choice, "NFS")
        
        if share_choice == "3":
            # Manual configuration
            self.config["data_path"] = self.get_input("Mount path (where network share will be mounted)", "/mnt/media")
            self.config["use_network_share"] = True
            self.config["share_type"] = "manual"
            self.print_colored("⚠ Manual setup selected. Make sure to mount your network share before running docker-compose.", Colors.YELLOW)
            return
        
        # Get connection details
        self.config["share_host"] = self.get_input("Server IP/hostname", "192.168.1.100")
        
        if share_choice == "1":  # NFS
            self.config["share_path"] = self.get_input("NFS export path", "/mnt/media")
            self.config["mount_path"] = self.get_input("Local mount point", "/mnt/media")
            self.config["nfs_options"] = self.get_input("NFS mount options", "vers=3,proto=tcp,rsize=8192,wsize=8192,hard,intr")
            
        elif share_choice == "2":  # SMB
            self.config["share_name"] = self.get_input("Share name", "media")
            self.config["share_username"] = self.get_input("Username", "mediauser")
            self.config["mount_path"] = self.get_input("Local mount point", "/mnt/media")
            self.config["smb_options"] = self.get_input("SMB mount options", "uid=1000,gid=1000,iocharset=utf8,file_mode=0644,dir_mode=0755")
            
            # Password handling
            use_credentials_file = self.ask_yes_no("Store credentials in a file (recommended)?", "y")
            if use_credentials_file:
                self.config["use_credentials_file"] = True
                self.print_colored("💡 We'll create a credentials file at /etc/cifs-credentials", Colors.BLUE)
            else:
                self.config["use_credentials_file"] = False
                self.print_colored("⚠ You'll need to provide credentials during mount", Colors.YELLOW)
        
        self.config["data_path"] = self.config["mount_path"]
        self.config["use_network_share"] = True
        self.config["share_type"] = share_type.lower().replace("/", "_")
        
        self.print_colored(f"✓ Network share configured: {share_type}", Colors.GREEN)

    def _setup_network_share(self) -> bool:
        """Set up network share mounting"""
        share_type = self.config.get("share_type", "")
        mount_path = self.config.get("mount_path", "/mnt/media")
        
        if share_type == "manual":
            # Check if already mounted
            if self._is_mounted(mount_path):
                self.print_colored(f"✓ Network share already mounted at {mount_path}", Colors.GREEN)
                return True
            else:
                self.print_colored(f"⚠ Please mount your network share at {mount_path} before continuing", Colors.YELLOW)
                continue_anyway = self.ask_yes_no("Continue anyway (will create local directories)?", "n")
                return continue_anyway
        
        # Install required packages
        if not self._install_mount_dependencies(share_type):
            return False
        
        # Create mount point
        try:
            subprocess.run(['sudo', 'mkdir', '-p', mount_path], check=True, capture_output=True)
            self.print_colored(f"✓ Created mount point: {mount_path}", Colors.GREEN)
        except subprocess.CalledProcessError:
            self.print_colored(f"❌ Failed to create mount point: {mount_path}", Colors.RED)
            return False
        
        # Mount the share
        if share_type == "nfs":
            return self._mount_nfs()
        elif share_type in ["smb", "cifs"]:
            return self._mount_smb()
        
        return False

    def _is_mounted(self, path: str) -> bool:
        """Check if a path is already mounted"""
        try:
            result = subprocess.run(['mountpoint', '-q', path], capture_output=True)
            return result.returncode == 0
        except:
            return False

    def _install_mount_dependencies(self, share_type: str) -> bool:
        """Install required packages for mounting"""
        try:
            if share_type == "nfs":
                self.print_colored("📦 Installing NFS utilities...", Colors.BLUE)
                # Try different package managers
                for cmd in [
                    ['sudo', 'apt-get', 'update'],
                    ['sudo', 'apt-get', 'install', '-y', 'nfs-common']
                ]:
                    try:
                        subprocess.run(cmd, check=True, capture_output=True)
                    except subprocess.CalledProcessError:
                        # Try yum/dnf for RHEL-based systems
                        try:
                            subprocess.run(['sudo', 'yum', 'install', '-y', 'nfs-utils'], check=True, capture_output=True)
                        except subprocess.CalledProcessError:
                            try:
                                subprocess.run(['sudo', 'dnf', 'install', '-y', 'nfs-utils'], check=True, capture_output=True)
                            except subprocess.CalledProcessError:
                                self.print_colored("⚠ Could not install NFS utilities automatically", Colors.YELLOW)
                                return True  # Continue anyway
            
            elif share_type in ["smb", "cifs"]:
                self.print_colored("📦 Installing CIFS utilities...", Colors.BLUE)
                for cmd in [
                    ['sudo', 'apt-get', 'update'],
                    ['sudo', 'apt-get', 'install', '-y', 'cifs-utils']
                ]:
                    try:
                        subprocess.run(cmd, check=True, capture_output=True)
                    except subprocess.CalledProcessError:
                        # Try yum/dnf
                        try:
                            subprocess.run(['sudo', 'yum', 'install', '-y', 'cifs-utils'], check=True, capture_output=True)
                        except subprocess.CalledProcessError:
                            try:
                                subprocess.run(['sudo', 'dnf', 'install', '-y', 'cifs-utils'], check=True, capture_output=True)
                            except subprocess.CalledProcessError:
                                self.print_colored("⚠ Could not install CIFS utilities automatically", Colors.YELLOW)
                                return True  # Continue anyway
            
            return True
        except Exception as e:
            self.print_colored(f"❌ Error installing dependencies: {e}", Colors.RED)
            return False

    def _mount_nfs(self) -> bool:
        """Mount NFS share"""
        host = self.config["share_host"]
        share_path = self.config["share_path"]
        mount_path = self.config["mount_path"]
        options = self.config.get("nfs_options", "vers=3,proto=tcp")
        
        mount_cmd = [
            'sudo', 'mount', '-t', 'nfs',
            '-o', options,
            f'{host}:{share_path}',
            mount_path
        ]
        
        try:
            self.print_colored(f"🔗 Mounting NFS share {host}:{share_path} to {mount_path}...", Colors.BLUE)
            result = subprocess.run(mount_cmd, capture_output=True, text=True, check=True)
            self.print_colored("✓ NFS share mounted successfully!", Colors.GREEN)
            
            # Add to fstab for persistence
            self._add_to_fstab("nfs")
            return True
            
        except subprocess.CalledProcessError as e:
            self.print_colored(f"❌ Failed to mount NFS share: {e.stderr}", Colors.RED)
            return False

    def _mount_smb(self) -> bool:
        """Mount SMB/CIFS share"""
        host = self.config["share_host"]
        share_name = self.config["share_name"]
        mount_path = self.config["mount_path"]
        options = self.config.get("smb_options", "uid=1000,gid=1000")
        
        # Handle credentials
        if self.config.get("use_credentials_file", False):
            if not self._create_smb_credentials():
                return False
            options += ",credentials=/etc/cifs-credentials"
        
        mount_cmd = [
            'sudo', 'mount', '-t', 'cifs',
            '-o', options,
            f'//{host}/{share_name}',
            mount_path
        ]
        
        try:
            self.print_colored(f"🔗 Mounting SMB share //{host}/{share_name} to {mount_path}...", Colors.BLUE)
            result = subprocess.run(mount_cmd, capture_output=True, text=True, check=True)
            self.print_colored("✓ SMB share mounted successfully!", Colors.GREEN)
            
            # Add to fstab for persistence
            self._add_to_fstab("smb")
            return True
            
        except subprocess.CalledProcessError as e:
            self.print_colored(f"❌ Failed to mount SMB share: {e.stderr}", Colors.RED)
            return False

    def _create_smb_credentials(self) -> bool:
        """Create SMB credentials file"""
        username = self.config["share_username"]
        password = input(f"{Colors.BLUE}Enter password for {username}: {Colors.NC}")
        domain = self.get_input("Domain (optional)", "")
        
        credentials_content = f"username={username}\npassword={password}\n"
        if domain:
            credentials_content += f"domain={domain}\n"
        
        try:
            # Write credentials file
            subprocess.run([
                'sudo', 'tee', '/etc/cifs-credentials'
            ], input=credentials_content, text=True, capture_output=True, check=True)
            
            # Set secure permissions
            subprocess.run(['sudo', 'chmod', '600', '/etc/cifs-credentials'], check=True)
            subprocess.run(['sudo', 'chown', 'root:root', '/etc/cifs-credentials'], check=True)
            
            self.print_colored("✓ Credentials file created at /etc/cifs-credentials", Colors.GREEN)
            return True
            
        except subprocess.CalledProcessError as e:
            self.print_colored(f"❌ Failed to create credentials file: {e}", Colors.RED)
            return False

    def _add_to_fstab(self, share_type: str):
        """Add mount to /etc/fstab for persistence"""
        add_to_fstab = self.ask_yes_no("Add mount to /etc/fstab for automatic mounting at boot?", "y")
        
        if not add_to_fstab:
            return
        
        host = self.config["share_host"]
        mount_path = self.config["mount_path"]
        
        if share_type == "nfs":
            share_path = self.config["share_path"]
            options = self.config.get("nfs_options", "vers=3,proto=tcp")
            fstab_line = f"{host}:{share_path} {mount_path} nfs {options} 0 0"
        else:  # SMB
            share_name = self.config["share_name"]
            options = self.config.get("smb_options", "uid=1000,gid=1000")
            if self.config.get("use_credentials_file", False):
                options += ",credentials=/etc/cifs-credentials"
            fstab_line = f"//{host}/{share_name} {mount_path} cifs {options} 0 0"
        
        try:
            # Backup current fstab
            subprocess.run(['sudo', 'cp', '/etc/fstab', '/etc/fstab.backup'], check=True)
            
            # Add line to fstab
            subprocess.run([
                'sudo', 'sh', '-c', f'echo "{fstab_line}" >> /etc/fstab'
            ], check=True)
            
            self.print_colored("✓ Added to /etc/fstab for automatic mounting", Colors.GREEN)
            
        except subprocess.CalledProcessError:
            self.print_colored("⚠ Could not add to /etc/fstab automatically", Colors.YELLOW)
            self.print_colored(f"Manual fstab entry: {fstab_line}", Colors.WHITE)

    def select_services(self) -> List[str]:
        services_info = {
            "gluetun": "VPN client (routes download traffic through VPN)",
            "qbittorrent": "Torrent client",
            "deunhealth": "Health monitor for qBittorrent (recommended with VPN)",
            "nzbget": "Usenet client",
            "prowlarr": "Indexer manager",
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
        
        # First ask about VPN
        self.print_colored("🔒 VPN Configuration:", Colors.CYAN)
        use_vpn = self.ask_yes_no("Do you want to route download traffic through VPN (gluetun)?", "n")
        
        if use_vpn:
            selected.append("gluetun")
            self.print_colored("✓ VPN enabled - download clients will route through gluetun", Colors.GREEN)
        else:
            self.print_colored("✓ VPN disabled - download clients will use direct connection", Colors.YELLOW)
        
        print()
        self.print_colored("📥 Download Clients:", Colors.CYAN)
        
        # qBittorrent
        if self.ask_yes_no(f"Include qbittorrent ({services_info['qbittorrent']})?", "y"):
            selected.append("qbittorrent")
            
            # Only offer deunhealth if VPN is enabled
            if use_vpn and self.ask_yes_no(f"Include deunhealth ({services_info['deunhealth']})?", "y"):
                selected.append("deunhealth")
        
        # Other download clients
        if self.ask_yes_no(f"Include nzbget ({services_info['nzbget']})?", "n"):
            selected.append("nzbget")
            
        if self.ask_yes_no(f"Include prowlarr ({services_info['prowlarr']})?", "y"):
            selected.append("prowlarr")
        
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
        
        # Store VPN choice for use in template generation
        self.use_vpn = use_vpn
        
        return selected

    def generate_compose(self, selected_services: List[str]):
        templates = self.get_service_templates()
        
        # Generate services section
        services_content = ""
        
        for service in selected_services:
            template_key = service
            
            # Use appropriate template based on VPN choice
            if hasattr(self, 'use_vpn'):
                if service == "qbittorrent":
                    template_key = "qbittorrent_vpn" if self.use_vpn else "qbittorrent_direct"
                elif service == "nzbget":
                    template_key = "nzbget_vpn" if self.use_vpn else "nzbget_direct"
                elif service == "prowlarr":
                    template_key = "prowlarr_vpn" if self.use_vpn else "prowlarr_direct"
            
            if template_key in templates:
                service_config = templates[template_key].format(**self.config)
                services_content += service_config + "\n"
        
        # Generate full compose file
        compose_content = self.get_compose_template().format(services=services_content)
        
        # Write to file
        with open("docker-compose.yml", "w") as f:
            f.write(compose_content)
            
        self.print_colored("✓ Generated docker-compose.yml", Colors.GREEN)
        
        # Show configuration summary
        if hasattr(self, 'use_vpn'):
            vpn_status = "enabled" if self.use_vpn else "disabled"
            self.print_colored(f"ℹ️ VPN routing: {vpn_status}", Colors.BLUE)

    def check_and_install_docker(self):
        """Check if Docker is installed and offer to install if needed"""
        self.print_colored("🐳 Checking Docker installation...", Colors.BLUE)
        
        # Check if Docker is installed and running
        try:
            result = subprocess.run(['docker', '--version'], capture_output=True, text=True, check=True)
            docker_version = result.stdout.strip()
            self.print_colored(f"✓ Docker found: {docker_version}", Colors.GREEN)
            
            # Check if Docker daemon is running
            try:
                subprocess.run(['docker', 'info'], capture_output=True, text=True, check=True, timeout=5)
                self.print_colored("✓ Docker daemon is running", Colors.GREEN)
                
                # Check Docker Compose availability
                self._check_docker_compose()
                return True
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                self.print_colored("⚠ Docker is installed but daemon is not running", Colors.YELLOW)
                self.print_colored("Try starting Docker: sudo systemctl start docker", Colors.WHITE)
                return False
                
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.print_colored("❌ Docker is not installed", Colors.RED)
            
            # Offer to install Docker
            install_docker = self.ask_yes_no("Would you like to install Docker automatically?", "y")
            
            if install_docker:
                return self._install_docker()
            else:
                self.print_colored("Please install Docker manually and run this script again.", Colors.YELLOW)
                self.print_colored("Installation guide: https://docs.docker.com/engine/install/", Colors.BLUE)
                return False
    
    def _check_docker_compose(self):
        """Check Docker Compose availability and set the right command"""
        # Check for Docker Compose plugin (modern way)
        try:
            result = subprocess.run(['docker', 'compose', 'version'], capture_output=True, text=True, check=True)
            self.compose_command = "docker compose"
            self.print_colored("✓ Docker Compose plugin available", Colors.GREEN)
            return True
        except subprocess.CalledProcessError:
            pass
        
        # Check for standalone docker-compose (legacy)
        try:
            result = subprocess.run(['docker-compose', '--version'], capture_output=True, text=True, check=True)
            self.compose_command = "docker-compose"
            self.print_colored("✓ Docker Compose standalone available", Colors.GREEN)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        # Neither available - provide installation instructions
        self.print_colored("⚠ Docker Compose not found", Colors.YELLOW)
        self.print_colored("Installing Docker Compose...", Colors.BLUE)
        
        # Try to install docker-compose via apt (Ubuntu/Debian)
        try:
            result = subprocess.run(['sudo', 'apt', 'install', '-y', 'docker-compose'], 
                                  capture_output=True, text=True, check=True)
            self.compose_command = "docker-compose"
            self.print_colored("✓ Docker Compose installed successfully", Colors.GREEN)
            return True
        except subprocess.CalledProcessError:
            self.print_colored("❌ Failed to install docker-compose automatically", Colors.RED)
            self.print_colored("Please install manually:", Colors.YELLOW)
            self.print_colored("sudo apt install docker-compose", Colors.WHITE)
            self.compose_command = "docker compose"  # Default to plugin syntax
            return False
    
    def _install_docker(self):
        """Install Docker using the bash script"""
        try:
            # Find the Docker installation script
            script_dir = os.path.dirname(os.path.abspath(__file__))
            install_script = os.path.join(script_dir, "install-docker-and-update-os.sh")
            
            if not os.path.exists(install_script):
                self.print_colored("❌ Docker installation script not found", Colors.RED)
                self.print_colored(f"Expected location: {install_script}", Colors.WHITE)
                return False
            
            # Make script executable
            os.chmod(install_script, 0o755)
            
            self.print_colored("🚀 Running Docker installation script...", Colors.CYAN)
            self.print_colored("This may take a few minutes and will require sudo privileges.", Colors.YELLOW)
            
            # Run the installation script
            result = subprocess.run(['bash', install_script], text=True)
            
            if result.returncode == 0:
                self.print_colored("✓ Docker installation completed!", Colors.GREEN)
                self.print_colored("", Colors.WHITE)
                self.print_colored("⚠ IMPORTANT: You need to log out and back in for Docker group changes to take effect", Colors.YELLOW)
                self.print_colored("   Or run: newgrp docker", Colors.WHITE)
                self.print_colored("", Colors.WHITE)
                
                # Ask if user wants to continue or restart
                continue_setup = self.ask_yes_no("Continue with compose generation? (Docker commands will need sudo)", "y")
                return continue_setup
            else:
                self.print_colored("❌ Docker installation failed", Colors.RED)
                return False
                
        except Exception as e:
            self.print_colored(f"❌ Error running Docker installation: {e}", Colors.RED)
            return False

    def create_directories(self, selected_services: List[str]):
        """
        Create directories using Trash Guides recommended structure for optimal hardlinks
        https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/
        """
        import subprocess
        import stat
        
        data_path = self.config["data_path"]
        
        # Handle network share mounting first
        if self.config.get("use_network_share", False):
            if not self._setup_network_share():
                self.print_colored("❌ Network share setup failed. Continuing with local directories...", Colors.RED)
                # Update data_path to a local fallback
                self.config["data_path"] = "/tmp/media"
                data_path = self.config["data_path"]
        
        self.print_colored("🗂️ Creating Trash Guides recommended directory structure...", Colors.CYAN)
        
        # Trash Guides recommended structure for hardlinks
        directories = [
            # Root data directory
            data_path,
            
            # Media directories (for Plex/Jellyfin/Emby)
            f"{data_path}/media",
            f"{data_path}/media/movies",
            f"{data_path}/media/tv",
            f"{data_path}/media/music",
            f"{data_path}/media/books",
            f"{data_path}/media/audiobooks",
            
            # Download client directories (qBittorrent/Transmission/SABnzbd/NZBGet)
            f"{data_path}/torrents",
            f"{data_path}/torrents/movies",
            f"{data_path}/torrents/tv", 
            f"{data_path}/torrents/music",
            f"{data_path}/torrents/books",
            f"{data_path}/torrents/audiobooks",
            
            f"{data_path}/usenet",
            f"{data_path}/usenet/movies",
            f"{data_path}/usenet/tv",
            f"{data_path}/usenet/music", 
            f"{data_path}/usenet/books",
            f"{data_path}/usenet/audiobooks",
            
            # Additional directories
            f"{data_path}/watch",  # For watch folders
            f"{data_path}/youtube",  # For ytdl-sub
        ]
        
        # Service config directories (local)
        config_dirs = [service for service in selected_services]
        
        # Check if we need elevated permissions for system directories
        needs_sudo = data_path.startswith(("/mnt", "/media", "/opt")) and os.geteuid() != 0
        
        if needs_sudo:
            self.print_colored("🔐 System directory detected, requesting sudo privileges...", Colors.YELLOW)
            self._create_directories_with_sudo(directories, config_dirs)
        else:
            self._create_directories_direct(directories, config_dirs)
    
    def _create_directories_with_sudo(self, directories: List[str], config_dirs: List[str]):
        """Create directories with sudo for system paths"""
        try:
            # Get current user info
            import pwd
            current_user = pwd.getpwuid(os.getuid())
            username = current_user.pw_name
            groupname = current_user.pw_name  # Usually same as username
            
            self.print_colored(f"Creating directories for user: {username}:{groupname}", Colors.BLUE)
            
            # Create directories with sudo
            for directory in directories:
                try:
                    # Create directory
                    result = subprocess.run([
                        'sudo', 'mkdir', '-p', directory
                    ], capture_output=True, text=True, check=True)
                    
                    # Set ownership
                    subprocess.run([
                        'sudo', 'chown', f'{username}:{groupname}', directory
                    ], capture_output=True, text=True, check=True)
                    
                    # Set permissions (755 for directories)
                    subprocess.run([
                        'sudo', 'chmod', '755', directory
                    ], capture_output=True, text=True, check=True)
                    
                    self.print_colored(f"✓ Created: {directory}", Colors.GREEN)
                    
                except subprocess.CalledProcessError as e:
                    self.print_colored(f"⚠ Failed to create {directory}: {e}", Colors.YELLOW)
                    continue
            
            # Create local config directories (no sudo needed)
            self._create_config_directories(config_dirs)
            
            self.print_colored("✓ Trash Guides directory structure created successfully!", Colors.GREEN)
            self._print_directory_structure()
            
        except Exception as e:
            self.print_colored(f"❌ Error creating directories with sudo: {e}", Colors.RED)
            self._provide_manual_instructions(directories, config_dirs)
    
    def _create_directories_direct(self, directories: List[str], config_dirs: List[str]):
        """Create directories directly (no sudo needed)"""
        try:
            # Create data directories
            for directory in directories:
                Path(directory).mkdir(parents=True, exist_ok=True)
                self.print_colored(f"✓ Created: {directory}", Colors.GREEN)
            
            # Create local config directories
            self._create_config_directories(config_dirs)
            
            self.print_colored("✓ Trash Guides directory structure created successfully!", Colors.GREEN)
            self._print_directory_structure()
            
        except PermissionError as e:
            self.print_colored(f"❌ Permission denied: {e}", Colors.RED)
            self._provide_manual_instructions(directories, config_dirs)
    
    def _create_config_directories(self, config_dirs: List[str]):
        """Create local config directories for Docker services"""
        for service in config_dirs:
            config_path = f"./{service}"
            Path(config_path).mkdir(parents=True, exist_ok=True)
            self.print_colored(f"✓ Created config: {config_path}", Colors.GREEN)
    
    def _print_directory_structure(self):
        """Print the created directory structure"""
        self.print_colored("\n📁 Created Trash Guides directory structure:", Colors.CYAN)
        data_path = self.config["data_path"]
        
        structure = f"""
{data_path}/
├── media/                 # Media for Plex/Jellyfin/Emby
│   ├── movies/           # Movies
│   ├── tv/               # TV Shows  
│   ├── music/            # Music
│   ├── books/            # Books
│   └── audiobooks/       # Audiobooks
├── torrents/             # qBittorrent/Transmission downloads
│   ├── movies/           # Movie torrents
│   ├── tv/               # TV torrents
│   ├── music/            # Music torrents
│   ├── books/            # Book torrents
│   └── audiobooks/       # Audiobook torrents
├── usenet/               # SABnzbd/NZBGet downloads
│   ├── movies/           # Movie usenet
│   ├── tv/               # TV usenet
│   ├── music/            # Music usenet
│   ├── books/            # Book usenet
│   └── audiobooks/       # Audiobook usenet
├── watch/                # Watch folders
└── youtube/              # YouTube downloads (ytdl-sub)
        """
        
        print(structure)
        
        self.print_colored("💡 This structure enables hardlinks between downloads and media!", Colors.YELLOW)
        self.print_colored("📚 Learn more: https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/", Colors.BLUE)
    
    def _provide_manual_instructions(self, directories: List[str], config_dirs: List[str]):
        """Provide manual instructions when automatic creation fails"""
        self.print_colored("\n🛠️ Manual Setup Required", Colors.YELLOW)
        self.print_colored("Run the following commands to create the directory structure:", Colors.WHITE)
        
        data_path = self.config["data_path"]
        user = os.environ.get('USER', 'your_username')
        
        print(f"\n# Create main directory structure:")
        print(f"sudo mkdir -p {data_path}")
        
        for directory in directories:
            print(f"sudo mkdir -p {directory}")
        
        print(f"\n# Set ownership:")
        print(f"sudo chown -R {user}:{user} {data_path}")
        
        print(f"\n# Set permissions:")
        print(f"sudo chmod -R 755 {data_path}")
        
        print(f"\n# Create local config directories:")
        for service in config_dirs:
            print(f"mkdir -p ./{service}")
        
        self.print_colored(f"\nAfter running these commands, re-run the script.", Colors.BLUE)

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
        
        # Determine if VPN is enabled
        vpn_enabled = hasattr(self, 'use_vpn') and self.use_vpn
        
        urls = {
            "gluetun": "VPN status (check logs with: docker-compose logs gluetun)",
            "qbittorrent": "http://localhost:8080" + (" (via VPN)" if vpn_enabled else ""),
            "nzbget": "http://localhost:6789" + (" (via VPN)" if vpn_enabled else ""), 
            "prowlarr": "http://localhost:9696" + (" (via VPN)" if vpn_enabled else ""),
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
        
        if vpn_enabled and "gluetun" in services:
            print()
            self.print_colored("🔒 VPN Configuration:", Colors.YELLOW)
            print(f"  - Download services route through VPN for privacy")
            print(f"  - Check VPN status: docker-compose exec gluetun wget -qO- ifconfig.me")
            print(f"  - Update .env file with your VPN credentials before starting")
        elif not vpn_enabled:
            print()
            self.print_colored("🌐 Direct Connection:", Colors.YELLOW)
            print(f"  - Download services use direct internet connection")
            print(f"  - No VPN configuration needed")
        
        print()
        self.print_colored("📚 Trash Guides Setup:", Colors.CYAN)
        self.print_colored("Your directory structure follows Trash Guides recommendations for optimal hardlinks:", Colors.WHITE)
        print(f"  • Downloads: {self.config['data_path']}/torrents/ and {self.config['data_path']}/usenet/")
        print(f"  • Media: {self.config['data_path']}/media/")
        print(f"  • This enables instant moves (hardlinks) instead of slow copies!")
        print()
        self.print_colored("🔗 Learn more about hardlinks:", Colors.BLUE)
        print(f"  https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/")
        print()
        self.print_colored("⚙️ Next Steps:", Colors.CYAN)
        print(f"  1. Configure your download clients to use the correct category folders")
        print(f"  2. Set up your *arr apps to monitor the correct media folders")
        print(f"  3. Configure hardlink-friendly settings in your applications")

    def run(self):
        self.print_header("Simple Docker Compose Generator")
        
        # Check Docker installation first
        if not self.check_and_install_docker():
            self.print_colored("❌ Docker is required to continue. Exiting.", Colors.RED)
            return
        
        self.configure()
        services = self.select_services()
        
        if not services:
            self.print_colored("No services selected!", Colors.YELLOW)
            return
            
        self.generate_compose(services)
        self.create_directories(services)
        self.save_env_file()
        
        self.print_colored("\n✅ Setup complete!", Colors.GREEN)
        
        # Show Docker commands based on user's group membership
        print()
        self.print_colored("🚀 Start your media stack:", Colors.CYAN)
        
        # Use the detected compose command
        compose_cmd = getattr(self, 'compose_command', 'docker compose')
        
        # Check if user is in docker group
        try:
            import grp
            docker_group = grp.getgrnam('docker')
            current_user = os.environ.get('USER')
            if current_user in docker_group.gr_mem:
                self.print_colored(f"{compose_cmd} up -d", Colors.WHITE)
            else:
                self.print_colored(f"sudo {compose_cmd} up -d", Colors.WHITE)
                self.print_colored("(Note: Run 'newgrp docker' first to avoid needing sudo)", Colors.YELLOW)
        except (KeyError, ImportError):
            self.print_colored(f"{compose_cmd} up -d", Colors.WHITE)
        
        print()
        self.print_colored("📊 Monitor your stack:", Colors.CYAN)
        self.print_colored(f"{compose_cmd} ps          # Check service status", Colors.WHITE)
        self.print_colored(f"{compose_cmd} logs -f     # View logs", Colors.WHITE)
        self.print_colored(f"{compose_cmd} down        # Stop all services", Colors.WHITE)
        
        self.print_urls(services)

if __name__ == "__main__":
    try:
        generator = SimpleComposeGenerator()
        generator.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
