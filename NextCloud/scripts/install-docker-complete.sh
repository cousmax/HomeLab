#!/bin/bash

# Complete Docker Installation and Post-Installation Setup Script
# This script installs Docker and performs all post-installation configuration
# Based on official Docker documentation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root for security reasons."
    log_info "Run as a regular user with sudo privileges."
    exit 1
fi

# Function to check if user has sudo privileges
check_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        log_error "This script requires sudo privileges."
        log_info "Please ensure your user is in the sudo group."
        exit 1
    fi
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Function to update system packages
update_system() {
    log_info "Updating system packages..."
    
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            log_info "Detected Debian/Ubuntu system"
            sudo apt-get update -y
            sudo apt-get upgrade -y
            sudo apt-get autoremove -y
            sudo apt-get autoclean
            ;;
        centos|rhel|rocky|almalinux)
            log_info "Detected RHEL/CentOS system"
            if command -v dnf &> /dev/null; then
                sudo dnf update -y
                sudo dnf autoremove -y
            else
                sudo yum update -y
                sudo yum autoremove -y
            fi
            ;;
        fedora)
            log_info "Detected Fedora system"
            sudo dnf update -y
            sudo dnf autoremove -y
            ;;
        opensuse|sles)
            log_info "Detected openSUSE/SLES system"
            sudo zypper refresh
            sudo zypper update -y
            ;;
        arch)
            log_info "Detected Arch Linux system"
            sudo pacman -Syu --noconfirm
            ;;
        *)
            log_warning "Unknown distribution '$distro'. Attempting generic update..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update -y && sudo apt-get upgrade -y
            elif command -v dnf &> /dev/null; then
                sudo dnf update -y
            elif command -v yum &> /dev/null; then
                sudo yum update -y
            else
                log_error "Cannot determine how to update packages on this system."
                return 1
            fi
            ;;
    esac
    
    log_success "System packages updated successfully!"
}

# Function to install Docker using the official script
install_docker() {
    log_info "Starting Docker installation..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        log_warning "Docker is already installed. Version: $(docker --version)"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled."
            exit 0
        fi
    fi
    
    # Download and run the official Docker installation script
    if [ -f "./get-docker.sh" ]; then
        log_info "Using existing get-docker.sh script..."
        sudo sh ./get-docker.sh
    else
        log_info "Downloading Docker installation script..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
    fi
    
    log_success "Docker installation completed!"
}

# Function to perform post-installation steps
post_install_setup() {
    log_info "Starting post-installation setup..."
    
    # Create docker group (usually already exists)
    if ! getent group docker > /dev/null 2>&1; then
        log_info "Creating docker group..."
        sudo groupadd docker
    fi
    
    # Add current user to docker group
    log_info "Adding user '$USER' to docker group..."
    sudo usermod -aG docker $USER
    
    # Configure Docker to start on boot
    log_info "Configuring Docker to start on boot..."
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    
    # Start Docker service
    log_info "Starting Docker service..."
    sudo systemctl start docker
    
    # Create Docker daemon configuration directory
    sudo mkdir -p /etc/docker
    
    # Configure Docker daemon with optimized settings
    log_info "Configuring Docker daemon..."
    cat << 'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false
}
EOF
    
    # Restart Docker to apply configuration
    log_info "Restarting Docker to apply configuration..."
    sudo systemctl restart docker
    
    log_success "Post-installation setup completed!"
}

# Function to verify Docker installation
verify_installation() {
    log_info "Verifying Docker installation..."
    
    # Check Docker version
    if docker --version &> /dev/null; then
        log_success "Docker version: $(docker --version)"
    else
        log_error "Docker command not available. You may need to log out and log back in."
        log_info "Or run: newgrp docker"
        return 1
    fi
    
    # Check if Docker daemon is running
    if sudo docker info &> /dev/null; then
        log_success "Docker daemon is running"
    else
        log_error "Docker daemon is not running"
        return 1
    fi
    
    # Test Docker with hello-world (as root first, then as user with newgrp)
    log_info "Testing Docker with hello-world container..."
    if sudo docker run --rm hello-world &> /dev/null; then
        log_success "Docker test with hello-world successful (as root)!"
    else
        log_error "Docker test failed"
        return 1
    fi
    
    # Test Docker as regular user using newgrp
    log_info "Testing Docker as non-root user..."
    if newgrp docker << 'EOF'
docker run --rm hello-world &> /dev/null
EOF
    then
        log_success "Docker test as non-root user successful!"
        log_info "Docker group membership activated successfully!"
    else
        log_warning "Docker test as non-root user failed. You may need to log out and back in."
        log_info "Or manually run: newgrp docker"
    fi
    
    # Check Docker Compose
    if docker compose version &> /dev/null; then
        log_success "Docker Compose version: $(docker compose version)"
    else
        log_warning "Docker Compose not available"
    fi
    
    log_success "Docker installation verification completed!"
}

# Function to show next steps
show_next_steps() {
    echo
    log_success "Docker installation and configuration completed successfully!"
    echo
    echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
    echo "1. To use Docker without sudo, you have two options:"
    echo "   a) Run: newgrp docker  (immediate effect, current session only)"
    echo "   b) Log out and log back in (permanent effect)"
    echo "2. Test Docker as non-root user: docker run hello-world"
    echo "3. Consider setting up Docker log rotation if not using systemd"
    echo "4. Review Docker security best practices"
    echo
    echo -e "${BLUE}Quick Test (using newgrp):${NC}"
    echo "  newgrp docker"
    echo "  docker run hello-world"
    echo
    echo -e "${BLUE}Useful Docker commands:${NC}"
    echo "  docker --version                 # Check Docker version"
    echo "  docker info                      # Display system information"
    echo "  docker ps                        # List running containers"
    echo "  docker images                    # List images"
    echo "  docker system df                 # Show disk usage"
    echo "  docker system prune              # Clean up unused data"
    echo
    echo -e "${GREEN}You can now proceed with Nextcloud AIO installation!${NC}"
}

# Main execution
main() {
    log_info "Docker Complete Installation Script"
    echo "This script will update the system and install Docker with post-installation configuration."
    echo
    
    # Check prerequisites
    check_sudo
    
    # Ask user about system update
    read -p "Do you want to update system packages first? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        update_system
    else
        log_info "Skipping system update"
    fi
    
    # Install Docker
    install_docker
    
    # Post-installation setup
    post_install_setup
    
    # Verify installation
    verify_installation
    
    # Show next steps
    show_next_steps
    
    log_success "Installation script completed!"
}

# Run main function
main "$@"
