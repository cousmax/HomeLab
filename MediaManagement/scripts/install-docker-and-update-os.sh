#!/usr/bin/env bash
# Automated Docker installation and OS update script
# Follows latest Docker documentation and recommended post-install steps
# Compatible with Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux, and openSUSE

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Helper functions for colored output
print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_step() {
    echo -e "${WHITE}→ $1${NC}"
}

print_header "Docker Installation and OS Update Script"
print_info "Starting automated installation process..."

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION_ID=${VERSION_ID}
else
    print_error "Cannot detect Linux distribution. Exiting."
    exit 1
fi

print_success "Detected distribution: $PRETTY_NAME"

# Update OS packages
print_header "Updating system packages"
case "$DISTRO" in
    ubuntu|debian)
        print_step "Updating packages using apt..."
        sudo apt-get update && sudo apt-get upgrade -y
        ;;
    centos|rhel|fedora)
        if command -v dnf &> /dev/null; then
            print_step "Updating packages using dnf..."
            sudo dnf upgrade --refresh -y
        else
            print_step "Updating packages using yum..."
            sudo yum update -y
        fi
        ;;
    arch|manjaro)
        print_step "Updating packages using pacman..."
        sudo pacman -Syu --noconfirm
        ;;
    opensuse*|suse|sles)
        print_step "Updating packages using zypper..."
        sudo zypper refresh && sudo zypper update -y
        ;;
    *)
        print_warning "Unsupported distribution: $DISTRO. Attempting to continue with generic approach..."
        ;;
esac

# Uninstall old Docker versions according to official documentation
print_header "Removing old Docker installations"
case "$DISTRO" in
    ubuntu|debian)
        # Official Docker documentation for Ubuntu/Debian
        print_step "Removing conflicting packages for $DISTRO..."
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
            sudo apt-get remove $pkg -y 2>/dev/null || true
        done
        ;;
    centos|rhel|fedora)
        # Official Docker documentation for CentOS/RHEL/Fedora
        print_step "Removing conflicting packages for $DISTRO..."
        if command -v dnf &> /dev/null; then
            sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine -y 2>/dev/null || true
        else
            sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine -y 2>/dev/null || true
        fi
        ;;
    arch|manjaro)
        print_step "Removing conflicting packages for $DISTRO..."
        sudo pacman -Rns docker docker-compose 2>/dev/null || true
        ;;
    opensuse*|suse|sles)
        print_step "Removing conflicting packages for $DISTRO..."
        sudo zypper remove docker docker-compose 2>/dev/null || true
        ;;
esac

# Install Docker using official repository method (recommended by Docker)
print_header "Installing Docker Engine"
case "$DISTRO" in
    ubuntu|debian)
        print_step "Setting up Docker repository for $DISTRO..."
        # Add Docker's official GPG key
        sudo apt-get update
        sudo apt-get install ca-certificates curl -y
        sudo install -m 0755 -d /etc/apt/keyrings
        if [ "$DISTRO" = "ubuntu" ]; then
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        else
            sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        
        # Update apt and install Docker packages
        sudo apt-get update
        print_step "Installing Docker CE, CLI, containerd, buildx and compose plugins..."
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        ;;
    centos|rhel|fedora)
        print_step "Setting up Docker repository for $DISTRO..."
        # Install dnf-plugins-core
        if command -v dnf &> /dev/null; then
            sudo dnf -y install dnf-plugins-core
            if [ "$DISTRO" = "fedora" ]; then
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            else
                sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            fi
            print_step "Installing Docker CE, CLI, containerd, buildx and compose plugins..."
            sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        else
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            print_step "Installing Docker CE, CLI, containerd, buildx and compose plugins..."
            sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        fi
        ;;
    *)
        print_warning "Using convenience script for unsupported distribution..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        ;;
esac

print_header "Performing post-installation steps"

# Create docker group (may already exist)
sudo groupadd docker 2>/dev/null || true

# Add current user to docker group
sudo usermod -aG docker "$USER"
print_success "Added user '$USER' to docker group"

# Configure Docker to start on boot with systemd
print_step "Configuring Docker to start on boot..."
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Start Docker service if not already running
sudo systemctl start docker

print_header "Installation completed successfully!"
echo ""
print_warning "IMPORTANT NOTES:"
print_info "1. You need to log out and back in (or restart) for group changes to take effect"
print_info "2. Alternatively, run 'newgrp docker' to activate group membership in current session"
print_info "3. After logging back in, you can run Docker commands without sudo"
echo ""

# Verify Docker installation
print_header "Verifying Docker installation"
print_step "Running Docker hello-world container to verify installation..."
if sudo docker run hello-world; then
    echo ""
    print_success "Docker is installed and working correctly!"
    echo ""
    print_info "Next steps:"
    echo -e "${WHITE}  - Log out and log back in to use Docker without sudo${NC}"
    echo -e "${WHITE}  - Or run: ${YELLOW}newgrp docker${NC}"
    echo -e "${WHITE}  - Then test with: ${YELLOW}docker run hello-world${NC}"
else
    echo ""
    print_error "Docker installation verification failed. Please check:"
    echo -e "${WHITE}  - Docker service status: ${YELLOW}sudo systemctl status docker${NC}"
    echo -e "${WHITE}  - Docker logs: ${YELLOW}sudo journalctl -u docker.service${NC}"
fi

echo ""
print_info "Docker version information:"
sudo docker --version
echo ""
print_info "For more information, visit: ${CYAN}https://docs.docker.com/engine/install/linux-postinstall/${NC}"
