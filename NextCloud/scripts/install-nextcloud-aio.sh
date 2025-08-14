#!/bin/bash

# Nextcloud All-in-One (AIO) Installation Script with NFS Support
# This script sets up Nextcloud AIO with proper NFS mounting configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration - modify as needed
DEFAULT_NEXTCLOUD_PORT="8080"
DEFAULT_APACHE_PORT="11000"
DEFAULT_NFS_SERVER=""
DEFAULT_NFS_PATH=""
DEFAULT_LOCAL_MOUNT_PATH="/mnt/nextcloud-nfs"
DEFAULT_NEXTCLOUD_DATADIR="nextcloud_aio_nextcloud_data"

# Configuration variables
NEXTCLOUD_PORT="${NEXTCLOUD_PORT:-$DEFAULT_NEXTCLOUD_PORT}"
APACHE_PORT="${APACHE_PORT:-$DEFAULT_APACHE_PORT}"
NFS_SERVER="${NFS_SERVER:-$DEFAULT_NFS_SERVER}"
NFS_PATH="${NFS_PATH:-$DEFAULT_NFS_PATH}"
LOCAL_MOUNT_PATH="${LOCAL_MOUNT_PATH:-$DEFAULT_LOCAL_MOUNT_PATH}"
NEXTCLOUD_DATADIR="${NEXTCLOUD_DATADIR:-$DEFAULT_NEXTCLOUD_DATADIR}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Docker command wrapper - uses sudo if needed
docker_cmd() {
    if [ "$USE_SUDO_DOCKER" = "true" ]; then
        sudo docker "$@"
    else
        docker "$@"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons."
        log_info "Run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please run the Docker installation script first."
        exit 1
    fi
    
    # Check Docker daemon is running
    if ! sudo docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker service:"
        echo "  sudo systemctl start docker"
        exit 1
    fi
    
    # Check if user can run Docker commands (try without sudo first)
    if docker ps &> /dev/null 2>&1; then
        log_info "Docker is accessible without sudo"
    elif sudo docker ps &> /dev/null 2>&1; then
        log_warning "Docker requires sudo for current session"
        export USE_SUDO_DOCKER="true"
    else
        log_error "Cannot run Docker commands even with sudo"
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! docker_cmd compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please ensure it's installed."
        exit 1
    fi
    
    # Check for NFS utilities
    if ! command -v mount.nfs &> /dev/null && ! command -v mount.nfs4 &> /dev/null; then
        log_warning "NFS utilities not found. Installing nfs-common..."
        sudo apt-get update
        sudo apt-get install -y nfs-common
    fi
    
    log_success "Prerequisites check completed!"
}

# Get user configuration
get_user_config() {
    echo
    log_info "Nextcloud AIO Configuration"
    echo "Please provide the following configuration details:"
    echo
    
    # Nextcloud AIO web interface port
    read -p "Nextcloud AIO web interface port [$DEFAULT_NEXTCLOUD_PORT]: " input_port
    NEXTCLOUD_PORT="${input_port:-$DEFAULT_NEXTCLOUD_PORT}"
    
    # Apache port
    read -p "Apache port for Nextcloud [$DEFAULT_APACHE_PORT]: " input_apache
    APACHE_PORT="${input_apache:-$DEFAULT_APACHE_PORT}"
    
    # NFS configuration
    echo
    log_info "NFS Configuration for Data Directory"
    echo "If you want to use NFS for data storage, provide the following:"
    
    read -p "NFS Server IP/hostname (leave empty to skip NFS): " NFS_SERVER
    
    if [ -n "$NFS_SERVER" ]; then
        read -p "NFS export path: " NFS_PATH
        read -p "Local mount point [$DEFAULT_LOCAL_MOUNT_PATH]: " input_mount
        LOCAL_MOUNT_PATH="${input_mount:-$DEFAULT_LOCAL_MOUNT_PATH}"
        
        echo
        log_info "Configuration Summary:"
        echo "  Nextcloud AIO Port: $NEXTCLOUD_PORT"
        echo "  Apache Port: $APACHE_PORT"
        echo "  NFS Server: $NFS_SERVER"
        echo "  NFS Path: $NFS_PATH"
        echo "  Local Mount: $LOCAL_MOUNT_PATH"
        echo
        
        read -p "Is this configuration correct? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Configuration cancelled. Please run the script again."
            exit 0
        fi
    else
        log_info "Skipping NFS configuration. Using local storage."
        echo "  Nextcloud AIO Port: $NEXTCLOUD_PORT"
        echo "  Apache Port: $APACHE_PORT"
        echo "  Storage: Local Docker volumes"
    fi
}

# Setup NFS mount
setup_nfs_mount() {
    if [ -z "$NFS_SERVER" ]; then
        log_info "No NFS server specified, skipping NFS setup."
        return 0
    fi
    
    log_info "Setting up NFS mount..."
    
    # Create mount point
    sudo mkdir -p "$LOCAL_MOUNT_PATH"
    
    # Test NFS connection
    log_info "Testing NFS connection to $NFS_SERVER:$NFS_PATH..."
    if ! showmount -e "$NFS_SERVER" | grep -q "$NFS_PATH"; then
        log_warning "Could not verify NFS export. Continuing anyway..."
    fi
    
    # Create fstab entry
    local fstab_entry="$NFS_SERVER:$NFS_PATH $LOCAL_MOUNT_PATH nfs defaults,noatime,rsize=8192,wsize=8192,timeo=14 0 0"
    
    if ! grep -q "$LOCAL_MOUNT_PATH" /etc/fstab; then
        log_info "Adding NFS mount to /etc/fstab..."
        echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null
    else
        log_warning "Mount point already exists in /etc/fstab"
    fi
    
    # Mount the NFS share
    log_info "Mounting NFS share..."
    if sudo mount "$LOCAL_MOUNT_PATH"; then
        log_success "NFS share mounted successfully at $LOCAL_MOUNT_PATH"
    else
        log_error "Failed to mount NFS share"
        return 1
    fi
    
    # Create Nextcloud data directory on NFS
    log_info "Creating Nextcloud data directory on NFS..."
    
    # First, check the ownership of the NFS mount
    local nfs_owner=$(stat -c '%U' "$LOCAL_MOUNT_PATH" 2>/dev/null || echo "unknown")
    local nfs_group=$(stat -c '%G' "$LOCAL_MOUNT_PATH" 2>/dev/null || echo "unknown")
    
    log_info "NFS mount owned by: $nfs_owner:$nfs_group"
    
    # Try to create directory as the current user first
    if mkdir -p "$LOCAL_MOUNT_PATH/nextcloud-aio-data" 2>/dev/null; then
        log_success "Created directory as current user"
    # If that fails, try as sudo
    elif sudo mkdir -p "$LOCAL_MOUNT_PATH/nextcloud-aio-data" 2>/dev/null; then
        log_success "Created directory with sudo"
        # Try to set appropriate permissions
        sudo chown -R $(id -u):$(id -g) "$LOCAL_MOUNT_PATH/nextcloud-aio-data" 2>/dev/null || \
        log_warning "Could not change ownership - NFS server permissions may prevent this"
    # If sudo fails, try as the NFS owner
    elif [ "$nfs_owner" != "unknown" ] && [ "$nfs_owner" != "root" ]; then
        if sudo -u "$nfs_owner" mkdir -p "$LOCAL_MOUNT_PATH/nextcloud-aio-data" 2>/dev/null; then
            log_success "Created directory as NFS owner ($nfs_owner)"
            # Make it accessible to Docker containers (usually run as various users)
            sudo -u "$nfs_owner" chmod 755 "$LOCAL_MOUNT_PATH/nextcloud-aio-data" 2>/dev/null || \
            log_warning "Could not set directory permissions"
        else
            log_error "Failed to create directory. Please check NFS server permissions."
            log_info "You may need to create the directory manually on the NFS server:"
            log_info "  mkdir -p /path/to/nfs/export/nextcloud-aio-data"
            log_info "  chmod 755 /path/to/nfs/export/nextcloud-aio-data"
            return 1
        fi
    else
        log_error "Failed to create Nextcloud data directory on NFS"
        log_info "Please create the directory manually:"
        log_info "  On NFS server: mkdir -p /path/to/export/nextcloud-aio-data"
        log_info "  chmod 755 /path/to/export/nextcloud-aio-data"
        return 1
    fi
    
    log_success "NFS setup completed!"
}

# Create Docker Compose file for Nextcloud AIO
create_compose_file() {
    log_info "Creating Docker Compose configuration..."
    
    mkdir -p ~/nextcloud-aio
    cd ~/nextcloud-aio
    
    # Create the docker-compose.yml file
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    init: true
    restart: unless-stopped
    container_name: nextcloud-aio-mastercontainer
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
EOF

    # Add NFS volume mapping if NFS is configured
    if [ -n "$NFS_SERVER" ]; then
        cat >> docker-compose.yml << EOF
      - $LOCAL_MOUNT_PATH/nextcloud-aio-data:/mnt/docker-aio-config/data:rw
EOF
    fi

    cat >> docker-compose.yml << EOF
    ports:
      - $NEXTCLOUD_PORT:8080
    environment:
      - APACHE_PORT=$APACHE_PORT
      - APACHE_IP_BINDING=0.0.0.0
EOF

    # Add NFS-specific environment variables if configured
    if [ -n "$NFS_SERVER" ]; then
        cat >> docker-compose.yml << EOF
      - NEXTCLOUD_DATADIR=$LOCAL_MOUNT_PATH/nextcloud-aio-data
      - NEXTCLOUD_MOUNT=/mnt/docker-aio-config/data/
EOF
    fi

    cat >> docker-compose.yml << EOF

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer
EOF

    log_success "Docker Compose file created!"
}

# Create systemd service for auto-start
create_systemd_service() {
    log_info "Creating systemd service for Nextcloud AIO..."
    
    # Determine Docker command for systemd service
    if [ "$USE_SUDO_DOCKER" = "true" ]; then
        DOCKER_CMD="sudo /usr/bin/docker"
    else
        DOCKER_CMD="/usr/bin/docker"
    fi
    
    cat << EOF | sudo tee /etc/systemd/system/nextcloud-aio.service > /dev/null
[Unit]
Description=Nextcloud All-in-One
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=$HOME/nextcloud-aio
ExecStart=${DOCKER_CMD} compose up -d
ExecStop=${DOCKER_CMD} compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable the service
    sudo systemctl daemon-reload
    sudo systemctl enable nextcloud-aio.service
    
    log_success "Systemd service created and enabled!"
}

# Start Nextcloud AIO
start_nextcloud_aio() {
    log_info "Starting Nextcloud AIO..."
    
    cd ~/nextcloud-aio
    
    # Pull the latest image
    docker_cmd compose pull
    
    # Start the containers
    docker_cmd compose up -d
    
    # Wait for container to be ready
    log_info "Waiting for Nextcloud AIO to start..."
    sleep 10
    
    # Check if container is running
    if docker_cmd compose ps | grep -q "Up\|running"; then
        log_success "Nextcloud AIO started successfully!"
    else
        log_warning "Container may still be starting up..."
        docker_cmd compose logs --tail=10
        return 1
    fi
}

# Show completion information
show_completion_info() {
    echo
    log_success "Nextcloud AIO installation completed successfully!"
    echo
    echo -e "${YELLOW}IMPORTANT INFORMATION:${NC}"
    echo
    echo -e "${BLUE}Access Information:${NC}"
    echo "  Web Interface: http://$(hostname -I | awk '{print $1}'):$NEXTCLOUD_PORT"
    echo "  Admin Interface: https://$(hostname -I | awk '{print $1}'):$APACHE_PORT"
    echo
    
    if [ -n "$NFS_SERVER" ]; then
        echo -e "${BLUE}NFS Configuration:${NC}"
        echo "  NFS Server: $NFS_SERVER:$NFS_PATH"
        echo "  Local Mount: $LOCAL_MOUNT_PATH"
        echo "  Data Directory: $LOCAL_MOUNT_PATH/nextcloud-aio-data"
        echo
    fi
    
    echo -e "${BLUE}Management Commands:${NC}"
    echo "  Start:   sudo systemctl start nextcloud-aio"
    echo "  Stop:    sudo systemctl stop nextcloud-aio"
    echo "  Status:  sudo systemctl status nextcloud-aio"
    echo "  Logs:    cd ~/nextcloud-aio && docker compose logs -f"
    echo
    
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo "1. Open your web browser and navigate to the web interface"
    echo "2. Complete the Nextcloud AIO setup wizard"
    echo "3. Configure your domain and SSL certificates"
    echo "4. Set up your admin account"
    
    if [ -n "$NFS_SERVER" ]; then
        echo "5. Verify that data is being stored on the NFS share"
    fi
    
    echo
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Main execution function
main() {
    log_info "Nextcloud All-in-One (AIO) Installation Script"
    echo "This script will install and configure Nextcloud AIO with optional NFS support."
    echo
    
    # Check prerequisites
    check_root
    check_prerequisites
    
    # Get user configuration
    get_user_config
    
    # Setup NFS if configured
    setup_nfs_mount
    
    # Create Docker Compose configuration
    create_compose_file
    
    # Create systemd service
    create_systemd_service
    
    # Start Nextcloud AIO
    start_nextcloud_aio
    
    # Show completion information
    show_completion_info
}

# Run main function
main "$@"
