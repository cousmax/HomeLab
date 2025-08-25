#!/bin/bash
# HomeLab Media Management GitHub Installer
# Download and run: curl -sSL https://raw.githubusercontent.com/cousmax/HomeLab/main/Media%20Management/scripts/github-installer.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/cousmax/HomeLab"
BRANCH="Dynamic-Servarr"
INSTALL_DIR="HomeLab-Media-Setup"
MEDIA_PATH="Media Management"

step() { echo -e "${BLUE}► $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; }

show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║        HomeLab Media Management Setup        ║"
    echo "║              GitHub Installer                ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

install_docker_system() {
    step "Installing Docker..."
    
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        error "Cannot detect Linux distribution"
        return 1
    fi
    
    # Check for sudo/root
    if [ "$EUID" -ne 0 ]; then
        step "Docker installation requires sudo privileges"
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            step "Installing Docker on Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get remove docker docker-engine docker.io containerd runc -y 2>/dev/null || true
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|fedora)
            step "Installing Docker on CentOS/RHEL/Fedora..."
            sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/$DISTRO/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        arch)
            step "Installing Docker on Arch Linux..."
            sudo pacman -Sy --noconfirm docker docker-compose
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            warn "Please install Docker manually from https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac
    
    # Post-install configuration
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker "$USER"
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Test Docker installation
    if docker --version >/dev/null 2>&1; then
        success "Docker installed successfully!"
        warn "You may need to log out and back in for Docker group permissions to take effect"
        
        # Try to run a test container
        if docker run --rm hello-world >/dev/null 2>&1; then
            success "Docker is working correctly"
        else
            warn "Docker installed but may need group permission refresh"
            echo -e "${YELLOW}If you get permission errors, try:${NC}"
            echo "  newgrp docker"
            echo "  Or log out and back in"
        fi
    else
        error "Docker installation failed"
        return 1
    fi
}

check_requirements() {
    step "Checking system requirements..."
    local missing=()
    
    for tool in curl git; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        warn "Docker is not installed"
        
        # Check if we're in an interactive session
        if [[ -t 0 ]]; then
            read -p "Would you like to install Docker automatically? [Y/n]: " install_docker
            install_docker=${install_docker,,}
        else
            warn "Running in non-interactive mode - will install Docker automatically"
            install_docker="y"
        fi
        
        if [[ ! "$install_docker" =~ ^n(o)?$ ]]; then
            install_docker_system
        else
            missing+=("docker")
        fi
    else
        success "Docker is already installed"
        # Check if Docker service is running
        if ! systemctl is-active --quiet docker 2>/dev/null; then
            warn "Docker service is not running"
            if [[ -t 0 ]]; then
                read -p "Would you like to start Docker service? [Y/n]: " start_docker
                start_docker=${start_docker,,}
            else
                warn "Auto-starting Docker service"
                start_docker="y"
            fi
            
            if [[ ! "$start_docker" =~ ^n(o)?$ ]]; then
                sudo systemctl start docker
                sudo systemctl enable docker
                success "Docker service started"
            fi
        fi
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        warn "Please install them and re-run this script."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo -e "${YELLOW}On Ubuntu/Debian, run:${NC}"
            echo "  sudo apt update && sudo apt install -y curl git"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}On macOS, run:${NC}"
            echo "  brew install git curl"
        fi
        exit 1
    fi
    
    success "All requirements satisfied"
}

download_repository() {
    step "Downloading HomeLab repository..."
    
    if [ -d "$INSTALL_DIR" ]; then
        warn "Directory $INSTALL_DIR already exists. Updating..."
        cd "$INSTALL_DIR" && git pull origin "$BRANCH" && cd ..
    else
        git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    fi
    
    # Make all scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    success "Repository downloaded and prepared"
}

show_options() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               Installation Options           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}1.${NC} Quick Install (Recommended)"
    echo -e "   ${YELLOW}→${NC} Automated setup with guided prompts"
    echo
    echo -e "${GREEN}2.${NC} Custom Install"
    echo -e "   ${YELLOW}→${NC} Manual step-by-step installation"
    echo
    echo -e "${GREEN}3.${NC} Install Docker Only"
    echo -e "   ${YELLOW}→${NC} Install Docker if not already present"
    echo
    echo -e "${GREEN}4.${NC} Update Existing Setup"
    echo -e "   ${YELLOW}→${NC} Update existing media management stack"
    echo
    echo -e "${GREEN}5.${NC} View Documentation"
    echo -e "   ${YELLOW}→${NC} Open guides and configuration help"
    echo
    echo -e "${GREEN}6.${NC} Exit"
    echo
}

run_quick_install() {
    step "Starting Quick Installation..."
    cd "$INSTALL_DIR/$MEDIA_PATH/scripts"
    
    if [ -f "quick-install.sh" ]; then
        ./quick-install.sh
    else
        error "Quick install script not found!"
        return 1
    fi
}

run_custom_install() {
    step "Custom Installation Menu"
    cd "$INSTALL_DIR/$MEDIA_PATH/scripts"
    
    echo -e "${YELLOW}Available installation scripts:${NC}"
    echo -e "${GREEN}1.${NC} Install Docker                 (install-docker.sh)"
    echo -e "${GREEN}2.${NC} Setup Folder Structure        (setup-arr-folders.sh)"
    echo -e "${GREEN}3.${NC} Create NFS Directories        (create-nfs-dirs.sh)"
    echo -e "${GREEN}4.${NC} Customize Stack               (customize-arr-install.sh)"
    echo -e "${GREEN}5.${NC} Manage Services               (manage.sh)"
    echo
    
    read -p "Select script to run (1-5) or 'q' to quit: " choice
    
    case $choice in
        1) ./install-docker.sh ;;
        2) ./setup-arr-folders.sh ;;
        3) ./create-nfs-dirs.sh ;;
        4) ./customize-arr-install.sh ;;
        5) ./manage.sh ;;
        q|Q) return 0 ;;
        *) error "Invalid choice" ;;
    esac
}

update_setup() {
    step "Updating existing setup..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        warn "No existing setup found. Use option 1 for new installation."
        return 1
    fi
    
    cd "$INSTALL_DIR"
    git pull origin "$BRANCH"
    find . -name "*.sh" -exec chmod +x {} \;
    success "Setup updated successfully"
}

show_documentation() {
    step "Opening documentation..."
    
    if [ -d "$INSTALL_DIR/$MEDIA_PATH" ]; then
        echo -e "${YELLOW}Available documentation:${NC}"
        ls "$INSTALL_DIR/$MEDIA_PATH"/*.md 2>/dev/null | while read -r doc; do
            echo -e "${GREEN}→${NC} $(basename "$doc")"
        done
        
        if command -v less >/dev/null 2>&1; then
            read -p "View README? [y/N]: " view_readme
            if [[ "$view_readme" =~ ^[Yy] ]]; then
                less "$INSTALL_DIR/$MEDIA_PATH/README.md"
            fi
        fi
    else
        warn "Please download repository first (option 1 or 2)"
    fi
}

cleanup() {
    if [[ -t 0 ]]; then
        read -p "Remove downloaded files? [y/N]: " cleanup_choice
        if [[ "$cleanup_choice" =~ ^[Yy] ]]; then
            rm -rf "$INSTALL_DIR"
            success "Cleanup completed"
        else
            warn "Files kept in: $PWD/$INSTALL_DIR"
        fi
    else
        warn "Auto-cleanup: keeping downloaded files at: $PWD/$INSTALL_DIR"
    fi
}

main() {
    show_banner
    check_requirements
    
    # Check if running in non-interactive mode (piped from curl)
    if [[ ! -t 0 ]]; then
        warn "Running in non-interactive mode - starting Quick Install automatically"
        download_repository
        run_quick_install
        success "Installation completed!"
        return 0
    fi
    
    while true; do
        show_options
        read -p "Select an option (1-6): " choice
        echo
        
        case $choice in
            1)
                download_repository
                run_quick_install
                break
                ;;
            2)
                download_repository
                run_custom_install
                ;;
            3)
                install_docker_system
                ;;
            4)
                update_setup
                ;;
            5)
                download_repository
                show_documentation
                ;;
            6)
                step "Exiting..."
                cleanup
                exit 0
                ;;
            *)
                error "Invalid choice. Please select 1-6."
                ;;
        esac
        echo
        read -p "Press Enter to continue..."
        clear
    done
    
    success "Installation completed!"
    cleanup
}

# Handle Ctrl+C gracefully
trap 'echo; warn "Installation cancelled by user"; exit 1' INT

main "$@"
