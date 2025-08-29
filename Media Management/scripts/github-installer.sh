#!/bin/bash

# HomeLab Media Management Installer
# Inspired by Proxmox Helper Scripts design
# Author: cousmax
# License: MIT

function header_info {
clear
cat <<"EOF"
    __  __                      __          __  
   / / / /___  ____ ___  ___   / /   ____ _/ /_ 
  / /_/ / __ \/ __ `__ \/ _ \ / /   / __ `/ __ \
 / __  / /_/ / / / / / /  __// /___/ /_/ / /_/ /
/_/ /_/\____/_/ /_/ /_/\___//_____/\__,_/_.___/ 
                                               
EOF
}

RD='\033[01;31m'
BL='\033[36m'
GN='\033[1;92m'
CL='\033[m'
YW='\033[33m'
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
INFO="${BL}ⓘ${CL}"
WARN="${YW}⚠${CL}"

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    if [[ -n "${SPINNER_PID-}" ]] && ps -p $SPINNER_PID > /dev/null 2>&1; then
        kill $SPINNER_PID > /dev/null 2>&1
    fi
}

msg_info() {
    local msg="$1"
    echo -ne " ${INFO} ${msg}..."
}

msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${msg}"
}

msg_error() {
    local msg="$1"
    echo -e "${BFR} ${CROSS} ${msg}"
}

msg_warn() {
    local msg="$1"
    echo -e "${BFR} ${WARN} ${msg}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

REPO_URL="https://github.com/cousmax/HomeLab"
BRANCH="Dynamic-Servarr"
INSTALL_DIR="HomeLab-Media-Setup"
MEDIA_PATH="Media Management"

show_banner() {
    header_info
    echo -e " ${BL}Media Management Stack Installer${CL}"
    echo -e " ${YW}Automated *arr Stack with Docker${CL}"
    echo
    echo -e " ${BL}Services:${CL} Prowlarr, Sonarr, Radarr, qBittorrent, NZBGet"
    echo -e " ${BL}Features:${CL} NFS Storage, VPN Integration, TRASHguides Config"
    echo -e " ${BL}Platform:${CL} Docker Compose with LinuxServer.io Images"
    echo
}

install_docker_system() {
    header_info
    echo -e " ${BL}Docker Installation${CL}"
    echo
    
    # Check for sudo/root permissions first
    if [ "$EUID" -ne 0 ]; then
        msg_info "Checking for sudo privileges"
        if ! sudo -n true 2>/dev/null; then
            echo -e "${BFR} ${INFO} Please enter your sudo password when prompted"
        fi
        msg_ok "Sudo access confirmed"
    fi
    
    # Detect Linux distribution
    msg_info "Detecting Linux distribution"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        msg_ok "Distribution detected: $PRETTY_NAME"
    else
        msg_error "Cannot detect Linux distribution"
        exit 1
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            msg_info "Installing Docker on Ubuntu/Debian"
            (
                sudo apt-get update -qq >/dev/null 2>&1 &&
                sudo apt-get remove docker docker-engine docker.io containerd runc -y -qq >/dev/null 2>&1 || true &&
                sudo apt-get install -y ca-certificates curl gnupg lsb-release -qq >/dev/null 2>&1 &&
                sudo mkdir -p /etc/apt/keyrings &&
                curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null &&
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
                sudo apt-get update -qq >/dev/null 2>&1 &&
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -qq >/dev/null 2>&1
            ) &
            spinner $!
            wait $! && msg_ok "Docker installed successfully" || { msg_error "Docker installation failed"; exit 1; }
            ;;
        centos|rhel|fedora)
            msg_info "Installing Docker on CentOS/RHEL/Fedora"
            (
                sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine -q >/dev/null 2>&1 || true &&
                sudo dnf -y install dnf-plugins-core -q >/dev/null 2>&1 &&
                sudo dnf config-manager --add-repo https://download.docker.com/linux/$DISTRO/docker-ce.repo -q >/dev/null 2>&1 &&
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -q >/dev/null 2>&1
            ) &
            spinner $!
            wait $! && msg_ok "Docker installed successfully" || { msg_error "Docker installation failed"; exit 1; }
            ;;
        arch)
            msg_info "Installing Docker on Arch Linux"
            (
                sudo pacman -Sy --noconfirm docker docker-compose >/dev/null 2>&1
            ) &
            spinner $!
            wait $! && msg_ok "Docker installed successfully" || { msg_error "Docker installation failed"; exit 1; }
            ;;
        *)
            msg_error "Unsupported distribution: $DISTRO"
            echo -e " ${WARN} Please install Docker manually from https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # Post-install configuration
    msg_info "Configuring Docker service"
    (
        sudo groupadd docker 2>/dev/null || true &&
        sudo usermod -aG docker "$USER" &&
        sudo systemctl enable docker >/dev/null 2>&1 &&
        sudo systemctl start docker >/dev/null 2>&1 &&
        sleep 3
    ) &
    spinner $!
    wait $! && msg_ok "Docker service configured" || { msg_error "Docker configuration failed"; exit 1; }
    
    # Test Docker installation
    msg_info "Testing Docker installation"
    if command -v docker >/dev/null 2>&1; then
        msg_ok "Docker installation completed successfully"
        echo -e " ${YW} Note: You may need to log out and back in for Docker group changes to take effect${CL}"
    else
        msg_error "Docker installation verification failed"
        exit 1
    fi
}
        if docker run --rm hello-world >/dev/null 2>&1; then
            success "Docker is working correctly"
        else
            warn "Docker installed but group permissions need refresh"
            echo -e "${YELLOW}Docker group permissions will be active after you log out and back in.${NC}"
            echo -e "${YELLOW}For immediate use, you can run: newgrp docker${NC}"
            echo -e "${YELLOW}Or continue - the setup scripts will use sudo when needed.${NC}"
        fi
        
        # Show Docker version
        docker --version 2>/dev/null || sudo docker --version
    else
        error "Docker installation failed"
        return 1
    fi
}

check_requirements() {
    step "Checking system requirements..."
    local missing=()
    
    # First, ensure we can use sudo if needed
    step "Verifying sudo access for setup scripts..."
    if ! sudo -n true 2>/dev/null; then
        warn "Some setup scripts require sudo privileges. Please enter your password:"
        sudo -v || {
            error "Sudo access required for NFS mounting and directory operations"
            exit 1
        }
    fi
    success "Sudo access confirmed"
    
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
        warn "Directory $INSTALL_DIR already exists. Removing old version..."
        rm -rf "$INSTALL_DIR"
    fi
    
    step "Cloning fresh copy from GitHub..."
    git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR" || {
        error "Failed to clone repository!"
        exit 1
    }
    
    # Make all scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    success "Repository downloaded and prepared"
}

show_options() {
    echo -e " ${YW}Select Installation Option:${CL}"
    echo
    echo -e " ${GN}[1]${CL} Quick Install ${BL}(Recommended)${CL}"
    echo -e "     Automated setup with guided prompts"
    echo
    echo -e " ${GN}[2]${CL} Custom Install"
    echo -e "     Manual step-by-step installation"
    echo
    echo -e " ${GN}[3]${CL} Install Docker Only"
    echo -e "     Install Docker if not already present"
    echo
    echo -e " ${GN}[4]${CL} Update Existing Setup"
    echo -e "     Update existing media management stack"
    echo
    echo -e " ${GN}[5]${CL} View Documentation"
    echo -e "     Open guides and configuration help"
    echo
    echo -e " ${GN}[6]${CL} Exit"
    echo
    echo -ne " ${BL}Please select an option [1-6]:${CL} "
}

run_quick_install() {
    step "Starting Quick Installation..."
    cd "$INSTALL_DIR/$MEDIA_PATH/scripts"
    
    # Check if Docker is installed and working
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not available. Please install Docker first."
        return 1
    fi
    
    success "Docker is available - proceeding with setup"
    
    # Run individual scripts, skipping Docker installation
    step "Step 2: Set up TRASHguides folder structure"
    if [ -f "setup-arr-folders.sh" ]; then
        if [[ -t 0 ]]; then
            read -p "Run folder setup? [Y/n]: " run_setup
            run_setup=${run_setup,,}
        else
            warn "Auto-running folder setup (requires sudo privileges)"
            run_setup="y"
        fi
        
        if [[ ! "$run_setup" =~ ^n(o)?$ ]]; then
            chmod +x setup-arr-folders.sh
            warn "This script requires sudo privileges for NFS mounting and directory creation"
            echo -e "${YELLOW}Please enter your sudo password when prompted:${NC}"
            
            # Run with sudo since the script checks for root
            if sudo ./setup-arr-folders.sh; then
                success "setup-arr-folders.sh completed."
            else
                error "setup-arr-folders.sh failed. You may need to run it manually."
                warn "To run manually: cd '$INSTALL_DIR/$MEDIA_PATH/scripts' && sudo ./setup-arr-folders.sh"
            fi
        else
            warn "Skipping setup-arr-folders.sh."
        fi
    else
        error "setup-arr-folders.sh not found!"
    fi
    
    step "Step 3: Create directories on NFS host (if needed)"
    if [ -f "create-nfs-dirs.sh" ]; then
        if [[ -t 0 ]]; then
            read -p "Run NFS directory creation? [Y/n]: " run_nfs
            run_nfs=${run_nfs,,}
        else
            warn "Auto-running NFS directory creation (may require sudo privileges)"
            run_nfs="y"
        fi
        
        if [[ ! "$run_nfs" =~ ^n(o)?$ ]]; then
            chmod +x create-nfs-dirs.sh
            
            # Check if this script also requires root
            if grep -q "EUID.*-ne.*0" create-nfs-dirs.sh 2>/dev/null; then
                warn "This script requires sudo privileges"
                echo -e "${YELLOW}Please enter your sudo password when prompted:${NC}"
                if sudo ./create-nfs-dirs.sh; then
                    success "create-nfs-dirs.sh completed."
                else
                    error "create-nfs-dirs.sh failed. You may need to run it manually."
                fi
            else
                ./create-nfs-dirs.sh
                success "create-nfs-dirs.sh completed."
            fi
        else
            warn "Skipping create-nfs-dirs.sh."
        fi
    else
        warn "create-nfs-dirs.sh not found - this is optional"
    fi
    
    step "Step 4: Customize your stack and generate docker-compose file"
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  This step will let you choose which services to include      ║${NC}"
    echo -e "${BLUE}║  in your media management stack.                              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Available services include:${NC}"
    echo -e "  ${GREEN}•${NC} Core: prowlarr, sonarr, radarr (recommended)"
    echo -e "  ${GREEN}•${NC} Download: qbittorrent, nzbget (with VPN via gluetun)"
    echo -e "  ${GREEN}•${NC} Media: lidarr (music), bazarr (subtitles)"
    echo -e "  ${GREEN}•${NC} Request: jellyseerr (media requests)"
    echo
    
    if [ -f "customize-arr-install.sh" ]; then
        if [[ -t 0 ]]; then
            read -p "Run stack customization? [Y/n]: " run_custom
            run_custom=${run_custom,,}
        else
            warn "Auto-running stack customization"
            run_custom="y"
        fi
        
        if [[ ! "$run_custom" =~ ^n(o)?$ ]]; then
            chmod +x customize-arr-install.sh
            
            # This script usually doesn't need sudo, but check to be sure
            if grep -q "EUID.*-ne.*0" customize-arr-install.sh 2>/dev/null; then
                warn "This script requires sudo privileges"
                sudo ./customize-arr-install.sh
            else
                ./customize-arr-install.sh
            fi
            success "customize-arr-install.sh completed."
        else
            warn "Skipping customize-arr-install.sh."
        fi
    else
        error "customize-arr-install.sh not found!"
    fi
    
    step "Step 5: Manage your stack"
    echo -e "${YELLOW}You can now use the management script to start, stop, and monitor your stack.${NC}"
    echo -e "${BLUE}To manage your stack, run:${NC}"
    echo -e "  ${GREEN}cd '$INSTALL_DIR/$MEDIA_PATH/scripts' && ./manage.sh [start|stop|status|logs|vpn-status]${NC}"
    
    success "Quick install complete!"
}

run_custom_install() {
    step "Custom Installation Menu"
    cd "$INSTALL_DIR/$MEDIA_PATH/scripts"
    
    echo -e "${YELLOW}Available installation scripts:${NC}"
    echo -e "${GREEN}1.${NC} Install Docker                 (install-docker.sh)"
    echo -e "${GREEN}2.${NC} Setup Folder Structure        (setup-arr-folders.sh)"
    echo -e "${GREEN}3.${NC} Create NFS Directories        (create-nfs-dirs.sh)"
    echo -e "${GREEN}4.${NC} Customize Stack               (customize-arr-install.sh)"
    echo -e "   ${BLUE}→ Choose services: prowlarr, sonarr, radarr, qbittorrent, etc.${NC}"
    echo -e "${GREEN}5.${NC} Manage Services               (manage.sh)"
    echo
    
    read -p "Select script to run (1-5) or 'q' to quit: " choice
    
    case $choice in
        1) ./install-docker.sh ;;
        2) ./setup-arr-folders.sh ;;
        3) ./create-nfs-dirs.sh ;;
        4) 
            echo -e "${BLUE}The customize script will show you all available services${NC}"
            echo -e "${BLUE}including prowlarr, sonarr, radarr, qbittorrent, lidarr, etc.${NC}"
            echo
            ./customize-arr-install.sh
            ;;
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
            if [ -d "$INSTALL_DIR" ]; then
                rm -rf "$INSTALL_DIR"
                success "Cleanup completed"
            fi
        else
            if [ -d "$INSTALL_DIR" ]; then
                warn "Files kept in: $PWD/$INSTALL_DIR"
            fi
        fi
    else
        if [ -d "$INSTALL_DIR" ]; then
            warn "Auto-cleanup: keeping downloaded files at: $PWD/$INSTALL_DIR"
        fi
    fi
}

main() {
    show_banner
    
    # Clean up any existing installations first
    if [ -d "$INSTALL_DIR" ]; then
        msg_warn "Found existing installation directory. Cleaning up..."
        rm -rf "$INSTALL_DIR"
        msg_ok "Old installation cleaned up"
    fi
    
    check_requirements
    
    # Check if running in non-interactive mode (piped from curl)
    if [[ ! -t 0 ]]; then
        msg_warn "Running in non-interactive mode - starting Quick Install automatically"
        download_repository
        run_quick_install
        msg_ok "Installation completed!"
        return 0
    fi
    
    while true; do
        show_options
        read choice
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
                msg_info "Exiting installer"
                cleanup
                msg_ok "Goodbye!"
                exit 0
                ;;
            *)
                msg_error "Invalid choice. Please select 1-6."
                ;;
        esac
        echo
        echo -ne " ${BL}Press Enter to continue...${CL}"
        read
        clear
    done
    
    msg_ok "Installation completed successfully!"
    cleanup
}

# Handle Ctrl+C gracefully
trap 'echo; warn "Installation cancelled by user"; exit 1' INT

main "$@"
