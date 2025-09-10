#!/usr/bin/env python3
"""
DevTools Stack Generator - Gitea Edition
Automated setup for Gitea self-hosted Git service with optional development tools
"""

import os
import sys
import subprocess
import secrets
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

class GiteaGenerator:
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
        """Docker service templates for development tools"""
        return {
            "gitea": """
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID={puid}
      - USER_GID={pgid}
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=gitea-db:5432
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD={db_password}
      - GITEA__server__DOMAIN={domain}
      - GITEA__server__SSH_DOMAIN={domain}
      - GITEA__server__ROOT_URL={root_url}
      - GITEA__server__SSH_PORT={ssh_port}
      - GITEA__security__INSTALL_LOCK=false
      - GITEA__log__LEVEL=Info
    restart: unless-stopped
    networks:
      - gitea-network
    volumes:
      - ./gitea/data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "{web_port}:3000"
      - "{ssh_port}:22"
    depends_on:
      - gitea-db

  gitea-db:
    image: postgres:15-alpine
    container_name: gitea-db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD={db_password}
      - POSTGRES_DB=gitea
    networks:
      - gitea-network
    volumes:
      - ./gitea/postgres:/var/lib/postgresql/data
""",

            "gitea-runner": """
  gitea-runner:
    image: gitea/act_runner:latest
    container_name: gitea-runner
    restart: unless-stopped
    environment:
      - GITEA_INSTANCE_URL={root_url}
      - GITEA_RUNNER_REGISTRATION_TOKEN={runner_token}
      - GITEA_RUNNER_NAME=docker-runner
    volumes:
      - ./gitea/runner:/data
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - gitea-network
    depends_on:
      - gitea
""",

            "drone": """
  drone:
    image: drone/drone:latest
    container_name: drone
    restart: unless-stopped
    environment:
      - DRONE_GITEA_SERVER={root_url}
      - DRONE_GITEA_CLIENT_ID={gitea_oauth_id}
      - DRONE_GITEA_CLIENT_SECRET={gitea_oauth_secret}
      - DRONE_RPC_SECRET={drone_rpc_secret}
      - DRONE_SERVER_HOST={drone_host}
      - DRONE_SERVER_PROTO=http
      - DRONE_USER_CREATE=username:{admin_user},admin:true
    ports:
      - "3001:80"
    volumes:
      - ./drone/data:/data
    networks:
      - gitea-network
    depends_on:
      - gitea

  drone-runner:
    image: drone/drone-runner-docker:latest
    container_name: drone-runner
    restart: unless-stopped
    environment:
      - DRONE_RPC_PROTO=http
      - DRONE_RPC_HOST=drone:80
      - DRONE_RPC_SECRET={drone_rpc_secret}
      - DRONE_RUNNER_CAPACITY=2
      - DRONE_RUNNER_NAME=docker-runner
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - gitea-network
    depends_on:
      - drone
""",

            "portainer": """
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer/data:/data
    networks:
      - gitea-network
""",

            "code-server": """
  code-server:
    image: lscr.io/linuxserver/code-server:latest
    container_name: code-server
    environment:
      - PUID={puid}
      - PGID={pgid}
      - TZ={timezone}
      - PASSWORD={code_password}
      - SUDO_PASSWORD={code_password}
    volumes:
      - ./code-server/config:/config
      - {workspace_path}:/config/workspace
    ports:
      - "8443:8443"
    restart: unless-stopped
    networks:
      - gitea-network
"""
        }

    def get_service_descriptions(self) -> Dict[str, str]:
        """Service descriptions for user selection"""
        return {
            "gitea": "🔧 Self-hosted Git service with web interface (like GitHub)",
            "gitea-runner": "🏃 Gitea Actions runner for CI/CD pipelines",
            "drone": "🚁 Continuous integration platform (alternative to Gitea Actions)",
            "portainer": "🐳 Docker container management web UI",
            "code-server": "💻 VS Code in the browser for remote development"
        }

    def select_services(self) -> List[str]:
        """Interactive service selection"""
        self.print_header("DevTools Selection")
        
        descriptions = self.get_service_descriptions()
        
        print("Available services:")
        for service, desc in descriptions.items():
            self.print_colored(f"  • {service.upper()}: {desc}", Colors.WHITE)
        
        print(f"\n{Colors.YELLOW}Selection Options:{Colors.NC}")
        self.print_colored("  1. Gitea only (minimal Git server)", Colors.WHITE)
        self.print_colored("  2. Gitea + CI/CD (Gitea with Actions runner)", Colors.WHITE)
        self.print_colored("  3. Complete DevTools (Gitea + CI/CD + Code Server + Portainer)", Colors.WHITE)
        self.print_colored("  4. Custom selection", Colors.WHITE)
        
        while True:
            choice = input(f"\n{Colors.BLUE}Select option (1-4):{Colors.NC} ").strip()
            
            if choice == "1":
                return ["gitea"]
            elif choice == "2":
                return ["gitea", "gitea-runner"]
            elif choice == "3":
                return ["gitea", "gitea-runner", "portainer", "code-server"]
            elif choice == "4":
                return self._custom_service_selection(descriptions)
            else:
                self.print_colored("Invalid selection. Please choose 1-4.", Colors.RED)

    def _custom_service_selection(self, descriptions: Dict[str, str]) -> List[str]:
        """Custom service selection"""
        selected = []
        
        print(f"\n{Colors.CYAN}Custom Selection:{Colors.NC}")
        
        # Gitea is mandatory
        selected.append("gitea")
        self.print_colored("✓ GITEA: Required (core Git service)", Colors.GREEN)
        
        for service, desc in descriptions.items():
            if service != "gitea":
                if self.ask_yes_no(f"Include {service.upper()}? {desc}", "n"):
                    selected.append(service)
        
        return selected

    def configure_gitea(self):
        """Configure Gitea-specific settings"""
        self.print_header("Gitea Configuration")
        
        # Domain configuration
        default_domain = "localhost"
        domain = input(f"{Colors.BLUE}Domain name{Colors.NC} [{Colors.YELLOW}{default_domain}{Colors.NC}]: ").strip()
        self.config['domain'] = domain or default_domain
        
        # Port configuration
        default_web_port = "3000"
        web_port = input(f"{Colors.BLUE}Web port{Colors.NC} [{Colors.YELLOW}{default_web_port}{Colors.NC}]: ").strip()
        self.config['web_port'] = web_port or default_web_port
        
        default_ssh_port = "2222"
        ssh_port = input(f"{Colors.BLUE}SSH port{Colors.NC} [{Colors.YELLOW}{default_ssh_port}{Colors.NC}]: ").strip()
        self.config['ssh_port'] = ssh_port or default_ssh_port
        
        # Root URL
        self.config['root_url'] = f"http://{self.config['domain']}:{self.config['web_port']}"
        
        # Database password
        print(f"\n{Colors.CYAN}Database Configuration:{Colors.NC}")
        db_password = getpass.getpass(f"{Colors.BLUE}PostgreSQL password: {Colors.NC}")
        if not db_password:
            db_password = secrets.token_urlsafe(16)
            self.print_colored(f"Generated password: {db_password}", Colors.YELLOW)
        self.config['db_password'] = db_password

    def configure_additional_services(self):
        """Configure additional service settings"""
        
        if "gitea-runner" in self.selected_services:
            self._configure_gitea_runner()
        
        if "drone" in self.selected_services:
            self._configure_drone()
        
        if "code-server" in self.selected_services:
            self._configure_code_server()

    def _configure_gitea_runner(self):
        """Configure Gitea Actions runner"""
        print(f"\n{Colors.CYAN}Gitea Actions Runner Configuration:{Colors.NC}")
        print("After starting Gitea, generate a runner token in:")
        print("  Site Administration → Actions → Runners")
        
        runner_token = input(f"{Colors.BLUE}Runner registration token (leave empty for now): {Colors.NC}").strip()
        self.config['runner_token'] = runner_token or "REPLACE_WITH_ACTUAL_TOKEN"

    def _configure_drone(self):
        """Configure Drone CI"""
        print(f"\n{Colors.CYAN}Drone CI Configuration:{Colors.NC}")
        print("You'll need to set up OAuth application in Gitea after installation")
        
        # Generate RPC secret
        self.config['drone_rpc_secret'] = secrets.token_urlsafe(32)
        
        # Drone host
        default_drone_host = f"{self.config['domain']}:3001"
        drone_host = input(f"{Colors.BLUE}Drone host{Colors.NC} [{Colors.YELLOW}{default_drone_host}{Colors.NC}]: ").strip()
        self.config['drone_host'] = drone_host or default_drone_host
        
        # Admin user
        admin_user = input(f"{Colors.BLUE}Drone admin username: {Colors.NC}").strip()
        self.config['admin_user'] = admin_user or "admin"
        
        # OAuth placeholders (to be configured later)
        self.config['gitea_oauth_id'] = "REPLACE_WITH_OAUTH_CLIENT_ID"
        self.config['gitea_oauth_secret'] = "REPLACE_WITH_OAUTH_CLIENT_SECRET"

    def _configure_code_server(self):
        """Configure VS Code server"""
        print(f"\n{Colors.CYAN}Code Server Configuration:{Colors.NC}")
        
        # Password
        code_password = getpass.getpass(f"{Colors.BLUE}Code Server password: {Colors.NC}")
        if not code_password:
            code_password = secrets.token_urlsafe(12)
            self.print_colored(f"Generated password: {code_password}", Colors.YELLOW)
        self.config['code_password'] = code_password
        
        # Workspace path
        default_workspace = "/mnt/workspace"
        workspace_path = input(f"{Colors.BLUE}Workspace path{Colors.NC} [{Colors.YELLOW}{default_workspace}{Colors.NC}]: ").strip()
        self.config['workspace_path'] = workspace_path or default_workspace

    def configure_environment(self):
        """Configure basic environment variables"""
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

    def generate_compose(self):
        """Generate docker-compose.yml file"""
        self.print_header("Generating Docker Compose")
        
        templates = self.get_service_templates()
        
        # Start compose file
        compose_content = """# DevTools Stack - Gitea and Development Tools
# Generated services: {services}

networks:
  gitea-network:
    name: gitea-network
    driver: bridge

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
        """Generate .env file with configuration"""
        env_content = f"""# DevTools Stack Environment Variables
# Generated on {self._get_timestamp()}

# Gitea Configuration
GITEA_DOMAIN={self.config.get('domain', 'localhost')}
GITEA_WEB_PORT={self.config.get('web_port', '3000')}
GITEA_SSH_PORT={self.config.get('ssh_port', '2222')}
GITEA_ROOT_URL={self.config.get('root_url', 'http://localhost:3000')}

# Database Configuration
DB_PASSWORD={self.config.get('db_password', 'changeme')}

# User Configuration
PUID={self.config.get('puid', '1000')}
PGID={self.config.get('pgid', '1000')}
TIMEZONE={self.config.get('timezone', 'UTC')}
"""
        
        # Add service-specific variables
        if "gitea-runner" in self.selected_services:
            env_content += f"\n# Gitea Actions Runner\nRUNNER_TOKEN={self.config.get('runner_token', 'REPLACE_WITH_ACTUAL_TOKEN')}\n"
        
        if "drone" in self.selected_services:
            env_content += f"""
# Drone CI Configuration
DRONE_RPC_SECRET={self.config.get('drone_rpc_secret', 'changeme')}
DRONE_HOST={self.config.get('drone_host', 'localhost:3001')}
DRONE_ADMIN_USER={self.config.get('admin_user', 'admin')}
GITEA_OAUTH_ID={self.config.get('gitea_oauth_id', 'REPLACE_WITH_OAUTH_CLIENT_ID')}
GITEA_OAUTH_SECRET={self.config.get('gitea_oauth_secret', 'REPLACE_WITH_OAUTH_CLIENT_SECRET')}
"""
        
        if "code-server" in self.selected_services:
            env_content += f"""
# Code Server Configuration
CODE_PASSWORD={self.config.get('code_password', 'changeme')}
WORKSPACE_PATH={self.config.get('workspace_path', '/mnt/workspace')}
"""
        
        with open(".env", "w", encoding='utf-8') as f:
            f.write(env_content)
        
        self.print_colored("✅ Generated .env file", Colors.GREEN)

    def _get_timestamp(self):
        """Get current timestamp"""
        from datetime import datetime
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def create_directories(self):
        """Create necessary directories"""
        self.print_header("Creating Directory Structure")
        
        directories = []
        
        # Service-specific directories
        if "gitea" in self.selected_services:
            directories.extend(["gitea/data", "gitea/postgres"])
        
        if "gitea-runner" in self.selected_services:
            directories.append("gitea/runner")
        
        if "drone" in self.selected_services:
            directories.append("drone/data")
        
        if "portainer" in self.selected_services:
            directories.append("portainer/data")
        
        if "code-server" in self.selected_services:
            directories.append("code-server/config")
        
        # Create directories
        for directory in directories:
            try:
                os.makedirs(directory, exist_ok=True)
                self.print_colored(f"✅ Created: {directory}", Colors.GREEN)
            except Exception as e:
                self.print_colored(f"⚠️  Could not create {directory}: {e}", Colors.YELLOW)
        
        # External directories
        workspace_path = self.config.get('workspace_path')
        if workspace_path and not workspace_path.startswith('./'):
            self.print_colored(f"📁 Workspace path: {workspace_path} (external - ensure it exists)", Colors.BLUE)

    def print_service_urls(self):
        """Print service access URLs"""
        self.print_header("Service URLs")
        
        domain = self.config.get('domain', 'localhost')
        web_port = self.config.get('web_port', '3000')
        ssh_port = self.config.get('ssh_port', '2222')
        
        if "gitea" in self.selected_services:
            self.print_colored(f"  🔧 Gitea Web: http://{domain}:{web_port}", Colors.CYAN)
            self.print_colored(f"  🔧 Gitea SSH: ssh://git@{domain}:{ssh_port}", Colors.CYAN)
        
        if "drone" in self.selected_services:
            self.print_colored(f"  🚁 Drone CI: http://{domain}:3001", Colors.CYAN)
        
        if "portainer" in self.selected_services:
            self.print_colored(f"  🐳 Portainer: http://{domain}:9000", Colors.CYAN)
        
        if "code-server" in self.selected_services:
            self.print_colored(f"  💻 Code Server: https://{domain}:8443", Colors.CYAN)

    def print_setup_instructions(self):
        """Print detailed setup instructions"""
        self.print_header("Setup Instructions")
        
        print("1. Start the services:")
        self.print_colored("   docker-compose up -d", Colors.WHITE)
        
        print("\n2. Check service status:")
        self.print_colored("   docker-compose ps", Colors.WHITE)
        
        if "gitea" in self.selected_services:
            print(f"\n{Colors.CYAN}Gitea Setup:{Colors.NC}")
            print(f"  • Access http://{self.config.get('domain', 'localhost')}:{self.config.get('web_port', '3000')}")
            print("  • Complete the installation wizard")
            print("  • Database is pre-configured (PostgreSQL)")
            print("  • Create your admin account")
            print("  • Configure SSH access if needed")
        
        if "gitea-runner" in self.selected_services:
            print(f"\n{Colors.CYAN}Gitea Actions Runner:{Colors.NC}")
            print("  • Go to Gitea: Site Administration → Actions → Runners")
            print("  • Generate a runner registration token")
            print("  • Update .env file with the token")
            print("  • Restart the runner: docker-compose restart gitea-runner")
        
        if "drone" in self.selected_services:
            print(f"\n{Colors.CYAN}Drone CI Setup:{Colors.NC}")
            print("  • Set up OAuth application in Gitea:")
            print("    - Go to Gitea Settings → Applications → OAuth2 Applications")
            print("    - Create new OAuth2 application")
            print(f"    - Redirect URI: http://{self.config.get('drone_host', 'localhost:3001')}/login")
            print("  • Update .env with OAuth Client ID and Secret")
            print("  • Restart Drone: docker-compose restart drone drone-runner")
        
        if "code-server" in self.selected_services:
            print(f"\n{Colors.CYAN}Code Server:{Colors.NC}")
            print(f"  • Access https://{self.config.get('domain', 'localhost')}:8443")
            print(f"  • Password: {self.config.get('code_password', '[check .env file]')}")
            print("  • Install Git and other development tools as needed")

    def print_security_notes(self):
        """Print important security notes"""
        self.print_header("Security Notes")
        
        print("🔒 Important security considerations:")
        print("  • Change default passwords in .env file")
        print("  • Use reverse proxy with SSL for production")
        print("  • Configure firewall rules")
        print("  • Regular backups of data directories")
        print("  • Keep containers updated")
        
        if "gitea" in self.selected_services:
            print("  • Configure Gitea security settings")
            print("  • Set up 2FA for admin accounts")
            print("  • Review repository permissions")

    def run(self):
        """Main execution flow"""
        self.print_header("DevTools Stack Generator - Gitea Edition")
        
        # Service selection
        self.selected_services = self.select_services()
        
        print(f"\n{Colors.GREEN}Selected services:{Colors.NC}")
        descriptions = self.get_service_descriptions()
        for service in self.selected_services:
            self.print_colored(f"  • {service.upper()}: {descriptions[service]}", Colors.WHITE)
        
        if not self.ask_yes_no("Continue with this selection?", "y"):
            return self.run()  # Restart selection
        
        # Configuration
        self.configure_environment()
        self.configure_gitea()
        self.configure_additional_services()
        
        # Generation
        self.generate_compose()
        self.generate_env_file()
        self.create_directories()
        
        # Information
        self.print_service_urls()
        self.print_setup_instructions()
        self.print_security_notes()
        
        self.print_colored("\n✅ DevTools stack setup complete!", Colors.GREEN)
        self.print_colored("Review the generated files and start with: docker-compose up -d", Colors.BLUE)

if __name__ == "__main__":
    try:
        generator = GiteaGenerator()
        generator.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Setup cancelled{Colors.NC}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.NC}")
