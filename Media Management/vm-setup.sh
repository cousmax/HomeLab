#!/bin/bash

# *arr Stack VM Setup Script
# Automated setup script for newly installed Ubuntu/Debian VMs
# This script handles everything needed to get the stack running on a fresh VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script info
SCRIPT_VERSION="1.0.0"
LOG_FILE="/tmp/servarr-setup.log"

# Default values (can be overridden with environment variables)
DEFAULT_PUID=1000
DEFAULT_PGID=1000
DEFAULT_TZ="America/New_York"
DEFAULT_NFS_SERVER=""
DEFAULT_NFS_SHARE="/mnt/Pool1/MediaData"
DEFAULT_NFS_MOUNT="/mnt/media"

print_header() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    *arr Stack VM Setup v${SCRIPT_VERSION}                    ║${NC}"
    echo -e "${BLUE}║               Automated setup for fresh Ubuntu/Debian VMs         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This script will:${NC}"
    echo "  • Install Docker and Docker Compose"
    echo "  • Install NFS utilities"
    echo "  • Configure environment settings"
    echo "  • Set up TRASHguides folder structure"
    echo "  • Mount NFS storage (if configured)"
    echo "  • Create and start the *arr stack"
    echo ""
}

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_message "${RED}This script should NOT be run as root!${NC}"
        log_message "${YELLOW}Please run as a regular user with sudo privileges${NC}"
        exit 1
    fi
    
    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_message "${YELLOW}This script requires sudo privileges${NC}"
        log_message "${YELLOW}Please run: sudo -v${NC}"
        sudo -v
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        log_message "${RED}Cannot detect OS. This script requires Ubuntu or Debian.${NC}"
        exit 1
    fi
    
    log_message "${BLUE}Detected OS: $PRETTY_NAME${NC}"
    
    case $OS in
        ubuntu|debian)
            PACKAGE_MANAGER="apt"
            ;;
        centos|rhel|fedora)
            PACKAGE_MANAGER="yum"
            log_message "${YELLOW}Warning: This OS is not fully tested${NC}"
            ;;
        arch)
            PACKAGE_MANAGER="pacman"
            log_message "${YELLOW}Warning: This OS is not fully tested${NC}"
            ;;
        *)
            log_message "${RED}Unsupported OS: $OS${NC}"
            exit 1
            ;;
    esac
}

update_system() {
    log_message "${BLUE}Updating system packages...${NC}"
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update
            sudo apt upgrade -y
            ;;
        yum)
            sudo yum update -y
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
    esac
    
    log_message "${GREEN}✓ System updated${NC}"
}

install_prerequisites() {
    log_message "${BLUE}Installing prerequisites...${NC}"
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
            ;;
        yum)
            sudo yum install -y curl wget gnupg2
            ;;
        pacman)
            sudo pacman -S --noconfirm curl wget gnupg
            ;;
    esac
    
    log_message "${GREEN}✓ Prerequisites installed${NC}"
}

install_docker() {
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        log_message "${GREEN}✓ Docker is already installed${NC}"
        return 0
    fi
    
    log_message "${BLUE}Installing Docker...${NC}"
    
    case $PACKAGE_MANAGER in
        apt)
            # Remove old versions
            sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        yum)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        pacman)
            sudo pacman -S --noconfirm docker docker-compose
            ;;
    esac
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Install docker-compose if not available via package
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_message "${BLUE}Installing docker-compose binary...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    log_message "${GREEN}✓ Docker installed successfully${NC}"
    log_message "${YELLOW}Note: You may need to log out and back in for Docker group membership to take effect${NC}"
}

install_nfs_utils() {
    log_message "${BLUE}Installing NFS utilities...${NC}"
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt install -y nfs-common
            ;;
        yum)
            sudo yum install -y nfs-utils
            ;;
        pacman)
            sudo pacman -S --noconfirm nfs-utils
            ;;
    esac
    
    log_message "${GREEN}✓ NFS utilities installed${NC}"
}

gather_configuration() {
    log_message "${BLUE}Gathering configuration...${NC}"
    
    # Get current user info
    CURRENT_USER=$(whoami)
    CURRENT_UID=$(id -u)
    CURRENT_GID=$(id -g)
    
    echo -e "${YELLOW}Current user: $CURRENT_USER (UID: $CURRENT_UID, GID: $CURRENT_GID)${NC}"
    
    # Ask for NFS configuration
    echo ""
    echo -e "${BLUE}NFS Configuration:${NC}"
    read -p "Enter NFS server IP (leave blank to skip NFS setup): " NFS_SERVER
    
    if [[ -n "$NFS_SERVER" ]]; then
        read -p "Enter NFS share path [$DEFAULT_NFS_SHARE]: " NFS_SHARE
        NFS_SHARE=${NFS_SHARE:-$DEFAULT_NFS_SHARE}
        
        read -p "Enter local mount point [$DEFAULT_NFS_MOUNT]: " NFS_MOUNT_POINT
        NFS_MOUNT_POINT=${NFS_MOUNT_POINT:-$DEFAULT_NFS_MOUNT}
        
        USE_NFS=true
    else
        log_message "${YELLOW}Skipping NFS setup - will use local storage${NC}"
        USE_NFS=false
        NFS_MOUNT_POINT="/opt/servarr/data"
    fi
    
    # Ask for timezone
    echo ""
    read -p "Enter timezone [$DEFAULT_TZ]: " TZ
    TZ=${TZ:-$DEFAULT_TZ}
    
    # Use current user's UID/GID by default
    read -p "Enter PUID [$CURRENT_UID]: " PUID
    PUID=${PUID:-$CURRENT_UID}
    
    read -p "Enter PGID [$CURRENT_GID]: " PGID
    PGID=${PGID:-$CURRENT_GID}
    
    log_message "${GREEN}✓ Configuration gathered${NC}"
}

create_env_file() {
    log_message "${BLUE}Creating .env file...${NC}"
    
    cat > .env << EOF
# Docker Compose Environment Variables
# Generated by vm-setup.sh on $(date)

# === User Configuration ===
PUID=$PUID
PGID=$PGID
TZ=$TZ

# === NFS Configuration ===
NFS_SERVER=$NFS_SERVER
NFS_SHARE=$NFS_SHARE
NFS_MOUNT_POINT=$NFS_MOUNT_POINT

# === Network ===
NETWORK_NAME=servarr

# === Service Ports ===
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
READARR_PORT=8787
QBITTORRENT_PORT=8080
QBITTORRENT_LISTEN_PORT=6881
NZBGET_PORT=6789
BAZARR_PORT=6767
JELLYSEERR_PORT=5055
NOTIFIARR_PORT=5454
FLARESOLVERR_PORT=8191

# === Storage Paths ===
DOCKER_CONFIG_PATH=./config
DOCKER_DATA_PATH=$NFS_MOUNT_POINT
EOF
    
    log_message "${GREEN}✓ Environment file created${NC}"
}

setup_storage() {
    log_message "${BLUE}Setting up storage...${NC}"
    
    if [[ "$USE_NFS" == "true" ]]; then
        setup_nfs_storage
    else
        setup_local_storage
    fi
}

setup_nfs_storage() {
    log_message "${BLUE}Setting up NFS storage...${NC}"
    
    # Create mount point
    sudo mkdir -p "$NFS_MOUNT_POINT"
    
    # Test NFS connection
    log_message "${BLUE}Testing NFS connection to ${NFS_SERVER}:${NFS_SHARE}${NC}"
    if ! showmount -e "$NFS_SERVER" | grep -q "$NFS_SHARE"; then
        log_message "${RED}✗ NFS share not accessible${NC}"
        log_message "${YELLOW}Please ensure:${NC}"
        log_message "  1. NFS server is running on $NFS_SERVER"
        log_message "  2. Share $NFS_SHARE is exported and accessible"
        log_message "  3. No firewall blocking NFS traffic"
        exit 1
    fi
    
    # Mount NFS share
    log_message "${BLUE}Mounting NFS share...${NC}"
    if ! sudo mount -t nfs -o rw,sync,hard,intr "$NFS_SERVER:$NFS_SHARE" "$NFS_MOUNT_POINT"; then
        log_message "${RED}✗ Failed to mount NFS share${NC}"
        exit 1
    fi
    
    # Add to fstab for persistence
    FSTAB_ENTRY="$NFS_SERVER:$NFS_SHARE $NFS_MOUNT_POINT nfs defaults,_netdev 0 0"
    if ! grep -q "$NFS_SERVER:$NFS_SHARE" /etc/fstab; then
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
        log_message "${GREEN}✓ Added NFS mount to fstab${NC}"
    fi
    
    create_directory_structure "$NFS_MOUNT_POINT"
    
    log_message "${GREEN}✓ NFS storage configured${NC}"
}

setup_local_storage() {
    log_message "${BLUE}Setting up local storage...${NC}"
    
    # Create data directory
    sudo mkdir -p "$NFS_MOUNT_POINT"
    sudo chown $PUID:$PGID "$NFS_MOUNT_POINT"
    
    create_directory_structure "$NFS_MOUNT_POINT"
    
    log_message "${GREEN}✓ Local storage configured${NC}"
}

create_directory_structure() {
    local BASE_PATH="$1"
    
    log_message "${BLUE}Creating TRASHguides directory structure...${NC}"
    
    # Create main directories
    sudo mkdir -p "$BASE_PATH"/{media,torrents,usenet}
    
    # Create media subdirectories
    sudo mkdir -p "$BASE_PATH"/media/{movies,tv,music,books,audiobooks}
    
    # Create torrent subdirectories
    sudo mkdir -p "$BASE_PATH"/torrents/{movies,tv,music,books,audiobooks,incomplete,watch}
    
    # Create usenet subdirectories
    sudo mkdir -p "$BASE_PATH"/usenet/{complete,incomplete,intermediate}
    sudo mkdir -p "$BASE_PATH"/usenet/complete/{movies,tv,music,books,audiobooks}
    
    # Set permissions
    sudo chown -R $PUID:$PGID "$BASE_PATH"
    sudo chmod -R 775 "$BASE_PATH"
    
    log_message "${GREEN}✓ Directory structure created${NC}"
}

setup_config_directories() {
    log_message "${BLUE}Creating configuration directories...${NC}"
    
    mkdir -p config/{prowlarr,sonarr,radarr,lidarr,readarr,qbittorrent,nzbget,bazarr,jellyseerr,notifiarr,flaresolverr}
    sudo chown -R $PUID:$PGID config/
    chmod -R 775 config/
    
    log_message "${GREEN}✓ Configuration directories created${NC}"
}

start_services() {
    log_message "${BLUE}Starting services...${NC}"
    
    # Pull images first
    log_message "${BLUE}Pulling Docker images...${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose pull
    else
        docker compose pull
    fi
    
    # Start services
    log_message "${BLUE}Starting containers...${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    # Wait a moment for services to start
    sleep 10
    
    # Check status
    log_message "${BLUE}Checking service status...${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi
    
    log_message "${GREEN}✓ Services started${NC}"
}

show_final_info() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        Setup Complete!                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}🌐 Service URLs:${NC}"
    echo "  Prowlarr (Indexers):     http://localhost:9696"
    echo "  Sonarr (TV Shows):       http://localhost:8989"
    echo "  Radarr (Movies):         http://localhost:7878"
    echo "  Lidarr (Music):          http://localhost:8686"
    echo "  Readarr (Books):         http://localhost:8787"
    echo "  qBittorrent (Torrents):  http://localhost:8080"
    echo "  NZBGet (Usenet):         http://localhost:6789"
    echo "  Bazarr (Subtitles):      http://localhost:6767"
    echo "  Jellyseerr (Requests):   http://localhost:5055"
    echo "  Notifiarr (Notifications): http://localhost:5454"
    echo "  Flaresolverr:            http://localhost:8191"
    echo ""
    
    echo -e "${BLUE}📁 Storage Structure:${NC}"
    if [[ "$USE_NFS" == "true" ]]; then
        echo "  NFS Mount: $NFS_SERVER:$NFS_SHARE → $NFS_MOUNT_POINT"
    else
        echo "  Local Storage: $NFS_MOUNT_POINT"
    fi
    echo "  ├── media/          (Final media library)"
    echo "  ├── torrents/       (Torrent downloads)"
    echo "  └── usenet/         (Usenet downloads)"
    echo ""
    
    echo -e "${BLUE}🛠️  Management Commands:${NC}"
    echo "  ./manage.sh start   - Start all services"
    echo "  ./manage.sh stop    - Stop all services"
    echo "  ./manage.sh status  - Check service status"
    echo "  ./manage.sh logs    - View logs"
    echo "  ./manage.sh urls    - Show service URLs"
    echo ""
    
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Configure Prowlarr with your indexers"
    echo "  2. Set up download clients in each *arr app"
    echo "  3. Configure root folders and quality profiles"
    echo "  4. Import TRASHguides custom formats"
    echo ""
    
    if [[ "$USE_NFS" == "false" ]]; then
        echo -e "${YELLOW}💡 Note: Using local storage. Consider setting up NFS for better performance.${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}📖 Documentation:${NC}"
    echo "  • README.md - Full documentation"
    echo "  • CONFIGURATION_GUIDE.md - Setup instructions"
    echo "  • TRASHguides: https://trash-guides.info/"
    echo ""
    
    echo -e "${GREEN}Setup log saved to: $LOG_FILE${NC}"
}

# Main execution
main() {
    print_header
    
    # Pre-flight checks
    check_root
    detect_os
    
    # Gather user input
    gather_configuration
    
    echo ""
    echo -e "${YELLOW}About to install:${NC}"
    echo "  • Docker and Docker Compose"
    echo "  • NFS utilities"
    if [[ "$USE_NFS" == "true" ]]; then
        echo "  • NFS mount: $NFS_SERVER:$NFS_SHARE"
    else
        echo "  • Local storage: $NFS_MOUNT_POINT"
    fi
    echo "  • *arr stack containers"
    echo ""
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "${YELLOW}Setup cancelled by user${NC}"
        exit 0
    fi
    
    # Installation steps
    update_system
    install_prerequisites
    install_docker
    install_nfs_utils
    create_env_file
    setup_storage
    setup_config_directories
    start_services
    
    # Final information
    show_final_info
    
    log_message "${GREEN}VM setup completed successfully!${NC}"
}

# Run main function
main "$@"
