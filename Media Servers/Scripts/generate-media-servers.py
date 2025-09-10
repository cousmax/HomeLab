#!/usr/bin/env python3
"""
Media Server Stack Generator
Automated setup for Immich, Jellyfin, Plex, Petio, Tautulli, and Wizarr
"""

import os
import sys
import subprocess
import json
import getpass
from typing import List, Dict, Optional
from pathlib import Path

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'

class MediaServerGenerator:
    def __init__(self):
        self.config = {}
        self.selected_services = []
        
    def print_colored(self, text: str, color: str = Colors.NC):
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self, text: str):
        self.print_colored(f"=== {text} ===", Colors.CYAN)
        
    def ask_yes_no(self, prompt: str, default: str = "n") -> bool:
        response = input(f"{Colors.BLUE}{prompt}{Colors.NC} [{Colors.YELLOW}{default}{Colors.NC}]: ").strip().lower()
        return (response or default.lower()) in ['y', 'yes', 'true', '1']

    def get_service_templates(self) -> Dict[str, str]:
        """Docker service templates for media server applications"""
        return {
            "immich": """
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    command: ['start.sh', 'immich']
    volumes:
      - {upload_path}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    depends_on:
      - redis
      - database
    restart: always
    networks:
      - mediaserver-network
    ports:
      - "2283:3001"

  immich-microservices:
    container_name: immich_microservices
    image: ghcr.io/immich-app/immich-server:release
    command: ['start.sh', 'microservices']
    volumes:
      - {upload_path}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    depends_on:
      - redis
      - database
    restart: always
    networks:
      - mediaserver-network

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - model-cache:/cache
    env_file:
      - .env
    restart: always
    networks:
      - mediaserver-network

  redis:
    container_name: immich_redis
    image: registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672
    restart: always
    networks:
      - mediaserver-network

  database:
    container_name: immich_postgres
    image: registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
    environment:
      POSTGRES_PASSWORD: {db_password}
      POSTGRES_USER: postgres
      POSTGRES_DB: immich
    volumes:
      - ./immich/pgdata:/var/lib/postgresql/data
    restart: always
    networks:
      - mediaserver-network
""",

            "jellyfin": """
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
      - JELLYFIN_PublishedServerUrl={jellyfin_url} #optional
    volumes:
      - ./jellyfin/config:/config
      - {media_path}:/data/media
      - {transcode_path}:/data/transcode #optional
    ports:
      - 8096:8096
      - 8920:8920 #optional
      - 7359:7359/udp #optional
      - 1900:1900/udp #optional
    restart: unless-stopped
    networks:
      - mediaserver-network
""",

            "plex": """
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
      - VERSION=docker
      - PLEX_CLAIM={plex_claim} #optional
    volumes:
      - ./plex/config:/config
      - {media_path}:/data/media
      - {transcode_path}:/transcode #optional
    restart: unless-stopped
    # Note: Using host network mode for better performance and auto-discovery
""",

            "petio": """
  petio:
    image: ghcr.io/petio-team/petio:latest
    container_name: petio
    environment:
      - TZ={timezone}
    volumes:
      - ./petio/config:/app/api/config
      - ./petio/logs:/app/logs
    ports:
      - "7777:7777"
    restart: unless-stopped
    networks:
      - mediaserver-network
""",

            "tautulli": """
  tautulli:
    image: lscr.io/linuxserver/tautulli:latest
    container_name: tautulli
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
    volumes:
      - ./tautulli/config:/config
    ports:
      - 8181:8181
    restart: unless-stopped
    networks:
      - mediaserver-network
""",

            "wizarr": """
  wizarr:
    image: ghcr.io/wizarrrr/wizarr:latest
    container_name: wizarr
    environment:
      - TZ={timezone}
    volumes:
      - ./wizarr/database:/data/database
    ports:
      - "5690:5690"
    restart: unless-stopped
    networks:
      - mediaserver-network
"""
        }

    def get_service_descriptions(self) -> Dict[str, str]:
        """Service descriptions for user selection"""
        return {
            "immich": "🖼️  Self-hosted photo and video management solution (like Google Photos)",
            "jellyfin": "🎬 Open-source media server for movies, TV shows, music",
            "plex": "📺 Popular media server with premium features and excellent clients", 
            "petio": "🎫 Request management for Plex/Jellyfin (replaces Ombi)",
            "tautulli": "📊 Analytics and monitoring for Plex Media Server",
            "wizarr": "👥 User invitation and management system for media servers"
        }

    def select_services(self) -> List[str]:
        """Interactive service selection"""
        self.print_header("Media Server Selection")
        
        descriptions = self.get_service_descriptions()
        
        print("Available services:")
        for service, desc in descriptions.items():
            self.print_colored(f"  • {service.upper()}: {desc}", Colors.WHITE)
        
        print(f"\n{Colors.YELLOW}Selection Options:{Colors.NC}")
        self.print_colored("  1. All services (complete media server stack)", Colors.WHITE)
        self.print_colored("  2. Media servers only (Jellyfin + Plex)", Colors.WHITE)
        self.print_colored("  3. Photo management (Immich)", Colors.WHITE)
        self.print_colored("  4. Custom selection", Colors.WHITE)
        
        while True:
            choice = input(f"\n{Colors.BLUE}Select option (1-4):{Colors.NC} ").strip()
            
            if choice == "1":
                return list(descriptions.keys())
            elif choice == "2":
                return ["jellyfin", "plex", "tautulli"]
            elif choice == "3":
                return ["immich"]
            elif choice == "4":
                return self._custom_service_selection(descriptions)
            else:
                self.print_colored("Invalid selection. Please choose 1-4.", Colors.RED)

    def _custom_service_selection(self, descriptions: Dict[str, str]) -> List[str]:
        """Custom service selection"""
        selected = []
        
        print(f"\n{Colors.CYAN}Custom Selection:{Colors.NC}")
        for service, desc in descriptions.items():
            if self.ask_yes_no(f"Include {service.upper()}? {desc}", "n"):
                selected.append(service)
        
        if not selected:
            self.print_colored("No services selected! Selecting Jellyfin as default.", Colors.YELLOW)
            selected = ["jellyfin"]
            
        return selected

    def configure_paths(self):
        """Configure storage paths"""
        self.print_header("Storage Configuration")
        
        print("Configure paths for your media and data storage:")
        
        # Media library path
        default_media = "/mnt/media"
        media_path = input(f"{Colors.BLUE}Media library path{Colors.NC} [{Colors.YELLOW}{default_media}{Colors.NC}]: ").strip()
        self.config['media_path'] = media_path or default_media
        
        # Photo upload path (for Immich)
        if "immich" in self.selected_services:
            default_upload = "/mnt/photos"
            upload_path = input(f"{Colors.BLUE}Photo upload path (Immich){Colors.NC} [{Colors.YELLOW}{default_upload}{Colors.NC}]: ").strip()
            self.config['upload_path'] = upload_path or default_upload
        
        # Transcoding path (optional)
        if any(service in self.selected_services for service in ["jellyfin", "plex"]):
            default_transcode = "/tmp/transcode"
            transcode_path = input(f"{Colors.BLUE}Transcoding path (optional){Colors.NC} [{Colors.YELLOW}{default_transcode}{Colors.NC}]: ").strip()
            self.config['transcode_path'] = transcode_path or default_transcode

    def configure_environment(self):
        """Configure environment variables"""
        self.print_header("Environment Configuration")
        
        # PUID/PGID
        try:
            default_puid = str(os.getuid())
            default_pgid = str(os.getgid())
        except AttributeError:
            # Windows doesn't have getuid/getgid
            default_puid = "1000"
            default_pgid = "1000"
        
        puid = input(f"{Colors.BLUE}PUID (User ID){Colors.NC} [{Colors.YELLOW}{default_puid}{Colors.NC}]: ").strip()
        self.config['puid'] = puid or default_puid
        
        pgid = input(f"{Colors.BLUE}PGID (Group ID){Colors.NC} [{Colors.YELLOW}{default_pgid}{Colors.NC}]: ").strip()
        self.config['pgid'] = pgid or default_pgid
        
        # Timezone
        default_tz = "UTC"
        timezone = input(f"{Colors.BLUE}Timezone{Colors.NC} [{Colors.YELLOW}{default_tz}{Colors.NC}]: ").strip()
        self.config['timezone'] = timezone or default_tz
        
        # Service-specific configuration
        if "immich" in self.selected_services:
            self._configure_immich()
        
        if "plex" in self.selected_services:
            self._configure_plex()
        
        if "jellyfin" in self.selected_services:
            self._configure_jellyfin()

    def _configure_immich(self):
        """Configure Immich-specific settings"""
        print(f"\n{Colors.CYAN}Immich Configuration:{Colors.NC}")
        
        # Database password
        db_password = getpass.getpass(f"{Colors.BLUE}Database password for Immich: {Colors.NC}")
        if not db_password:
            db_password = "immich_password"
            self.print_colored("Using default password. Change this in production!", Colors.YELLOW)
        self.config['db_password'] = db_password

    def _configure_plex(self):
        """Configure Plex-specific settings"""
        print(f"\n{Colors.CYAN}Plex Configuration:{Colors.NC}")
        
        print("Get your Plex claim token from: https://plex.tv/claim")
        claim_token = input(f"{Colors.BLUE}Plex claim token (optional): {Colors.NC}").strip()
        self.config['plex_claim'] = claim_token

    def _configure_jellyfin(self):
        """Configure Jellyfin-specific settings"""
        print(f"\n{Colors.CYAN}Jellyfin Configuration:{Colors.NC}")
        
        jellyfin_url = input(f"{Colors.BLUE}Jellyfin public URL (optional): {Colors.NC}").strip()
        self.config['jellyfin_url'] = jellyfin_url or "http://localhost:8096"

    def generate_compose(self):
        """Generate docker-compose.yml file"""
        self.print_header("Generating Docker Compose")
        
        templates = self.get_service_templates()
        
        # Start compose file
        compose_content = """# Media Server Stack Docker Compose
# Generated for: {services}

networks:
  mediaserver-network:
    name: mediaserver-network
    driver: bridge

volumes:
  model-cache:

services:
""".format(services=", ".join(self.selected_services))
        
        # Add selected services
        for service in self.selected_services:
            if service in templates:
                service_template = templates[service].format(**self.config)
                compose_content += service_template + "\n"
        
        # Write compose file
        with open("docker-compose.yml", "w", encoding='utf-8') as f:
            f.write(compose_content)
        
        self.print_colored("✅ Generated docker-compose.yml", Colors.GREEN)

    def generate_env_file(self):
        """Generate .env file for Immich and other services"""
        if "immich" in self.selected_services:
            env_content = f"""# Immich Environment Variables
# You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

# The location where your uploaded files are stored
UPLOAD_LOCATION={self.config.get('upload_path', '/mnt/photos')}

# The Immich version to use. You can pin this to a specific version like "v1.71.0"
IMMICH_VERSION=release

# Connection secret for postgres. You should change this to a random password
DB_PASSWORD={self.config.get('db_password', 'immich_password')}

# The values below this line do not need to be changed
###################################################################################
DB_HOSTNAME=database
DB_USERNAME=postgres
DB_DATABASE_NAME=immich

REDIS_HOSTNAME=redis
"""
            with open(".env", "w", encoding='utf-8') as f:
                f.write(env_content)
            
            self.print_colored("✅ Generated .env file", Colors.GREEN)

    def create_directories(self):
        """Create necessary directories"""
        self.print_header("Creating Directory Structure")
        
        directories = []
        
        # Service config directories
        for service in self.selected_services:
            if service == "immich":
                directories.extend(["immich/pgdata"])
            elif service in ["jellyfin", "plex", "petio", "tautulli", "wizarr"]:
                directories.append(f"{service}/config")
        
        # Media directories
        media_path = self.config.get('media_path', '/mnt/media')
        if not media_path.startswith('./'):
            self.print_colored(f"📁 Media path: {media_path} (external mount)", Colors.BLUE)
        
        # Photo directories (for Immich)
        if "immich" in self.selected_services:
            upload_path = self.config.get('upload_path', '/mnt/photos') 
            if not upload_path.startswith('./'):
                self.print_colored(f"📷 Photo path: {upload_path} (external mount)", Colors.BLUE)
        
        # Create local config directories
        for directory in directories:
            try:
                os.makedirs(directory, exist_ok=True)
                self.print_colored(f"✅ Created: {directory}", Colors.GREEN)
            except Exception as e:
                self.print_colored(f"⚠️  Could not create {directory}: {e}", Colors.YELLOW)

    def print_service_urls(self):
        """Print service access URLs"""
        self.print_header("Service URLs")
        
        urls = {
            "immich": "http://localhost:2283 (Photos & Videos)",
            "jellyfin": "http://localhost:8096 (Media Server)",
            "plex": "http://localhost:32400/web (Media Server)",
            "petio": "http://localhost:7777 (Request Management)",
            "tautulli": "http://localhost:8181 (Plex Analytics)",
            "wizarr": "http://localhost:5690 (User Management)"
        }
        
        for service in self.selected_services:
            if service in urls:
                self.print_colored(f"  {service.upper()}: {urls[service]}", Colors.CYAN)

    def print_next_steps(self):
        """Print setup instructions"""
        self.print_header("Next Steps")
        
        print("1. Start the services:")
        self.print_colored("   docker-compose up -d", Colors.WHITE)
        
        print("\n2. Check service status:")
        self.print_colored("   docker-compose ps", Colors.WHITE)
        
        print("\n3. View logs if needed:")
        self.print_colored("   docker-compose logs -f [service-name]", Colors.WHITE)
        
        if "immich" in self.selected_services:
            print(f"\n{Colors.CYAN}Immich Setup:{Colors.NC}")
            print("  • First time setup will take a few minutes")
            print("  • Access http://localhost:2283 to create admin account")
            print("  • Configure external libraries if needed")
        
        if "plex" in self.selected_services:
            print(f"\n{Colors.CYAN}Plex Setup:{Colors.NC}")
            if self.config.get('plex_claim'):
                print("  • Server should be automatically claimed")
            else:
                print("  • Visit http://localhost:32400/web to set up")
                print("  • Add media libraries pointing to /data/media")
        
        if "jellyfin" in self.selected_services:
            print(f"\n{Colors.CYAN}Jellyfin Setup:{Colors.NC}")
            print("  • Visit http://localhost:8096 for initial setup")
            print("  • Add media libraries pointing to /data/media")

    def run(self):
        """Main execution flow"""
        self.print_header("Media Server Stack Generator")
        
        # Service selection
        self.selected_services = self.select_services()
        
        if not self.selected_services:
            self.print_colored("No services selected. Exiting.", Colors.YELLOW)
            return
        
        print(f"\n{Colors.GREEN}Selected services:{Colors.NC}")
        for service in self.selected_services:
            descriptions = self.get_service_descriptions()
            self.print_colored(f"  • {service.upper()}: {descriptions[service]}", Colors.WHITE)
        
        if not self.ask_yes_no("Continue with this selection?", "y"):
            return self.run()  # Restart selection
        
        # Configuration
        self.configure_paths()
        self.configure_environment()
        
        # Generation
        self.generate_compose()
        self.generate_env_file()
        self.create_directories()
        
        # Information
        self.print_service_urls()
        self.print_next_steps()
        
        self.print_colored("\n✅ Media server stack setup complete!", Colors.GREEN)

if __name__ == "__main__":
    try:
        generator = MediaServerGenerator()
        generator.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Setup cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
