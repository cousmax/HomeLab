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

check_requirements() {
    step "Checking system requirements..."
    local missing=()
    
    for tool in curl git docker; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        warn "Please install them and re-run this script."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo -e "${YELLOW}On Ubuntu/Debian, run:${NC}"
            echo "  sudo apt update && sudo apt install -y curl git docker.io"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}On macOS, install Docker Desktop and run:${NC}"
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
    echo -e "${GREEN}3.${NC} Update Existing Setup"
    echo -e "   ${YELLOW}→${NC} Update existing media management stack"
    echo
    echo -e "${GREEN}4.${NC} View Documentation"
    echo -e "   ${YELLOW}→${NC} Open guides and configuration help"
    echo
    echo -e "${GREEN}5.${NC} Exit"
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
    read -p "Remove downloaded files? [y/N]: " cleanup_choice
    if [[ "$cleanup_choice" =~ ^[Yy] ]]; then
        rm -rf "$INSTALL_DIR"
        success "Cleanup completed"
    else
        warn "Files kept in: $PWD/$INSTALL_DIR"
    fi
}

main() {
    show_banner
    check_requirements
    
    while true; do
        show_options
        read -p "Select an option (1-5): " choice
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
                update_setup
                ;;
            4)
                download_repository
                show_documentation
                ;;
            5)
                step "Exiting..."
                cleanup
                exit 0
                ;;
            *)
                error "Invalid choice. Please select 1-5."
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
