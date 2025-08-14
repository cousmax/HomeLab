#!/bin/bash

# Nextcloud AIO Quick Installer - Direct from GitHub
# This script downloads and runs the complete installation from GitHub
# Usage: curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/quick-install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# GitHub repository details
REPO_OWNER="cousmax"
REPO_NAME="nextcloud-aio-automated-installer"
BRANCH="main"
GITHUB_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# Installation directory
INSTALL_DIR="$HOME/nextcloud-aio-installer"

# Auto mode flag
AUTO_MODE="false"

echo -e "${CYAN}🚀 Nextcloud AIO Quick Installer${NC}"
echo -e "${CYAN}=================================${NC}"
echo -e "${GREEN}Repository: ${GITHUB_URL}${NC}"
echo -e "${GREEN}Installing to: ${INSTALL_DIR}${NC}"
echo ""

# Function to log messages
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

# Check if required tools are available
check_requirements() {
    log_info "Checking requirements..."
    
    local missing_tools=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Installing missing tools..."
        
        # Detect package manager and install
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y ${missing_tools[*]}
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y ${missing_tools[*]}
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y ${missing_tools[*]}
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm ${missing_tools[*]}
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install -y ${missing_tools[*]}
        else
            log_error "Cannot install missing tools automatically. Please install: ${missing_tools[*]}"
            exit 1
        fi
    fi
    
    log_success "All requirements satisfied"
}

# Download repository
download_repository() {
    log_info "Downloading repository from GitHub..."
    
    # Remove existing directory if it exists
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "Removing existing installation directory..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone the repository
    if git clone "$GITHUB_URL.git" "$INSTALL_DIR"; then
        log_success "Repository downloaded successfully"
    else
        log_error "Failed to download repository"
        exit 1
    fi
    
    # Verify the directory structure
    if [ ! -d "$INSTALL_DIR/scripts" ]; then
        log_error "Scripts directory not found after download"
        exit 1
    fi
    
    # Make all scripts executable
    if chmod +x "$INSTALL_DIR"/scripts/*.sh; then
        log_success "Scripts made executable"
    else
        log_error "Failed to make scripts executable"
        exit 1
    fi
    
    # List downloaded files for debugging
    log_info "Downloaded files:"
    ls -la "$INSTALL_DIR/scripts/"
}

# Display installation options
show_menu() {
    echo ""
    echo -e "${PURPLE}📋 Installation Options:${NC}"
    echo "1. Complete automated installation (Docker + Nextcloud AIO)"
    echo "2. Interactive installation with menu"
    echo "3. Docker installation only"
    echo "4. Nextcloud AIO installation only (requires Docker)"
    echo "5. System update only"
    echo "6. Browse scripts manually"
    echo ""
    
    if [ "$AUTO_MODE" = "true" ]; then
        echo -e "${CYAN}Running in automatic mode - selecting option 2 (Interactive installation)${NC}"
        choice=2
    else
        read -p "Choose an option (1-6): " choice
    fi
    
    case $choice in
        1)
            log_info "Starting complete automated installation..."
            if [ -f "$INSTALL_DIR/scripts/install-complete-stack.sh" ]; then
                cd "$INSTALL_DIR" && bash "./scripts/install-complete-stack.sh" --install-all
            else
                log_error "Installation script not found at $INSTALL_DIR/scripts/install-complete-stack.sh"
                exit 1
            fi
            ;;
        2)
            log_info "Starting interactive installation..."
            if [ -f "$INSTALL_DIR/scripts/install-complete-stack.sh" ]; then
                cd "$INSTALL_DIR" && bash "./scripts/install-complete-stack.sh"
            else
                log_error "Installation script not found at $INSTALL_DIR/scripts/install-complete-stack.sh"
                exit 1
            fi
            ;;
        3)
            log_info "Installing Docker only..."
            if [ -f "$INSTALL_DIR/scripts/install-docker-complete.sh" ]; then
                cd "$INSTALL_DIR" && bash "./scripts/install-docker-complete.sh"
            else
                log_error "Docker installation script not found at $INSTALL_DIR/scripts/install-docker-complete.sh"
                exit 1
            fi
            ;;
        4)
            log_info "Installing Nextcloud AIO only..."
            if [ -f "$INSTALL_DIR/scripts/install-nextcloud-aio.sh" ]; then
                cd "$INSTALL_DIR" && bash "./scripts/install-nextcloud-aio.sh"
            else
                log_error "Nextcloud AIO installation script not found at $INSTALL_DIR/scripts/install-nextcloud-aio.sh"
                exit 1
            fi
            ;;
        5)
            log_info "Updating system only..."
            if [ -f "$INSTALL_DIR/scripts/update-system.sh" ]; then
                cd "$INSTALL_DIR" && bash "./scripts/update-system.sh"
            else
                log_error "System update script not found at $INSTALL_DIR/scripts/update-system.sh"
                exit 1
            fi
            ;;
        6)
            log_info "Opening installation directory..."
            if [ -d "$INSTALL_DIR/scripts" ]; then
                cd "$INSTALL_DIR"
                echo -e "${GREEN}Available scripts:${NC}"
                ls -la scripts/
                echo ""
                echo -e "${CYAN}Installation directory: ${INSTALL_DIR}${NC}"
                echo -e "${CYAN}Run any script with: cd ${INSTALL_DIR} && ./scripts/script-name.sh${NC}"
            else
                log_error "Scripts directory not found at $INSTALL_DIR/scripts"
                exit 1
            fi
            ;;
        *)
            log_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# Main installation process
main() {
    # Check if running in non-interactive mode (piped input)
    if [ ! -t 0 ]; then
        echo -e "${YELLOW}⚠️  Running in non-interactive mode (piped from curl)${NC}"
        echo -e "${CYAN}Proceeding with automatic installation...${NC}"
        AUTO_MODE="true"
    else
        echo -e "${YELLOW}⚠️  This installer will:${NC}"
        echo "   • Download the complete installation suite from GitHub"
        echo "   • Install Docker and/or Nextcloud AIO based on your choice"
        echo "   • Configure system services and permissions"
        echo "   • Optionally set up NFS storage integration"
        echo ""
        
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
    
    check_requirements
    download_repository
    
    if [ "$AUTO_MODE" = "true" ]; then
        log_info "Running in automatic mode - starting interactive installation..."
        echo -e "${CYAN}Available installation options will be shown after download${NC}"
    fi
    
    show_menu
    
    echo ""
    log_success "🎉 Installation process completed!"
    echo -e "${GREEN}Repository location: ${INSTALL_DIR}${NC}"
    echo -e "${GREEN}GitHub repository: ${GITHUB_URL}${NC}"
    
    if [ -f "$INSTALL_DIR/README.md" ]; then
        echo -e "${CYAN}📖 For more information, check: ${INSTALL_DIR}/README.md${NC}"
    fi
}

# Run main function
main "$@"
