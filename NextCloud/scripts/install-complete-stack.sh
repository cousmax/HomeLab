#!/bin/bash

# Master Installation Script for Docker + Nextcloud AIO with NFS
# This script orchestrates the complete installation process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Check if script exists and is executable
check_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        log_error "Script $script_name not found in $SCRIPT_DIR"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        log_info "Making $script_name executable..."
        chmod +x "$script_path"
    fi
    
    return 0
}

# Run a script with error handling
run_script() {
    local script_name="$1"
    local script_args="${@:2}"  # Get all arguments after the first one
    local script_path="$SCRIPT_DIR/$script_name"
    
    log_info "Running $script_name $script_args..."
    
    if ! check_script "$script_name"; then
        return 1
    fi
    
    if "$script_path" $script_args; then
        log_success "$script_name completed successfully!"
        return 0
    else
        log_error "$script_name failed!"
        return 1
    fi
}

# Show welcome message
show_welcome() {
    echo
    echo "=========================================="
    echo "  Docker + Nextcloud AIO Setup Script"
    echo "=========================================="
    echo
    echo "This master script will guide you through:"
    echo "1. Installing Docker with proper post-installation setup"
    echo "2. Configuring NFS (optional)"
    echo "3. Installing Nextcloud All-in-One (AIO)"
    echo
    echo "Required scripts:"
    echo "  - install-docker-complete.sh"
    echo "  - setup-nfs.sh"
    echo "  - install-nextcloud-aio.sh"
    echo
}

# Check all required scripts
check_all_scripts() {
    log_info "Checking for required scripts..."
    
    local scripts=("install-docker-complete.sh" "setup-nfs.sh" "install-nextcloud-aio.sh" "update-system.sh")
    local missing_scripts=()
    
    for script in "${scripts[@]}"; do
        if ! check_script "$script"; then
            # update-system.sh is optional
            if [ "$script" != "update-system.sh" ]; then
                missing_scripts+=("$script")
            fi
        fi
    done
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        log_error "Missing required scripts:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
        log_info "Please ensure all scripts are in the same directory as this master script."
        exit 1
    fi
    
    log_success "All required scripts found!"
}

# Interactive installation menu
show_installation_menu() {
    echo
    log_info "Installation Options:"
    echo "1. Complete automated installation (Update OS + Docker + Nextcloud AIO)"
    echo "2. Update system only"
    echo "3. Install Docker only"
    echo "4. Setup NFS only"
    echo "5. Install Nextcloud AIO only (requires Docker)"
    echo "6. Custom installation (step by step)"
    echo "7. Exit"
    echo
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1)
            complete_installation
            ;;
        2)
            if check_script "update-system.sh"; then
                run_script "update-system.sh" "update"
            else
                log_warning "update-system.sh not found, skipping system update"
            fi
            ;;
        3)
            run_script "install-docker-complete.sh"
            ;;
        4)
            run_script "setup-nfs.sh"
            ;;
        5)
            run_script "install-nextcloud-aio.sh"
            ;;
        6)
            custom_installation
            ;;
        7)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice. Please select 1-7."
            show_installation_menu
            ;;
    esac
}

# Complete automated installation
complete_installation() {
    log_info "Starting complete automated installation..."
    
    # Step 0: Update system (optional)
    if check_script "update-system.sh"; then
        echo
        log_info "Step 0: System Update (Recommended)"
        read -p "Do you want to update the system packages first? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            run_script "update-system.sh" "update"
        fi
    fi
    
    echo
    log_info "Step 1: Installing Docker..."
    if run_script "install-docker-complete.sh"; then
        echo
        log_success "Docker installation completed!"
        
        # Inform user about group membership
        echo
        log_info "Docker group membership has been configured."
        log_info "You can use Docker without sudo by running: newgrp docker"
        echo
        read -p "Do you want to continue with the installation? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "Installation paused. To continue later, run:"
            log_info "  newgrp docker"
            log_info "  $0 nextcloud"
            exit 0
        fi
    else
        log_error "Docker installation failed. Cannot continue."
        exit 1
    fi
    
    echo
    log_info "Step 2: NFS Setup (optional)"
    read -p "Do you want to configure NFS for data storage? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_script "setup-nfs.sh"
    else
        log_info "Skipping NFS setup. Will use local storage."
    fi
    
    echo
    log_info "Step 3: Installing Nextcloud AIO..."
    if check_script "run-nextcloud-aio.sh"; then
        if run_script "run-nextcloud-aio.sh"; then
            echo
            log_success "Complete installation finished!"
            show_completion_summary
        else
            log_error "Nextcloud AIO installation failed."
            exit 1
        fi
    else
        # Fallback to direct execution with user guidance
        log_warning "Wrapper script not found. Running direct installation."
        log_info "If this fails, please run: newgrp docker"
        log_info "Then run: ./install-nextcloud-aio.sh"
        
        if run_script "install-nextcloud-aio.sh"; then
            echo
            log_success "Complete installation finished!"
            show_completion_summary
        else
            log_error "Nextcloud AIO installation failed."
            log_info "Please run the following commands:"
            echo "  newgrp docker"
            echo "  ./install-nextcloud-aio.sh"
            exit 1
        fi
    fi
}

# Custom step-by-step installation
custom_installation() {
    log_info "Custom Installation - Step by Step"
    
    # System update
    if check_script "update-system.sh"; then
        echo
        log_info "Step 0: System Update"
        read -p "Do you want to update the system? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_script "update-system.sh" "update"
        fi
    fi
    
    # Check if Docker is installed
    if command -v docker &> /dev/null; then
        log_info "Docker is already installed."
        read -p "Do you want to reinstall Docker? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_script "install-docker-complete.sh"
        fi
    else
        echo
        log_info "Step 1: Docker Installation"
        read -p "Install Docker now? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            run_script "install-docker-complete.sh"
        fi
    fi
    
    echo
    log_info "Step 2: NFS Configuration (Optional)"
    read -p "Do you want to setup NFS? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_script "setup-nfs.sh"
    fi
    
    echo
    log_info "Step 3: Nextcloud AIO Installation"
    read -p "Install Nextcloud AIO now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        run_script "install-nextcloud-aio.sh"
    fi
    
    log_success "Custom installation completed!"
}

# Show completion summary
show_completion_summary() {
    echo
    echo "=========================================="
    echo "         Installation Completed!"
    echo "=========================================="
    echo
    log_success "Your Nextcloud AIO installation is ready!"
    echo
    echo -e "${BLUE}Quick Access:${NC}"
    echo "  • Nextcloud AIO Interface: http://$(hostname -I | awk '{print $1}'):8080"
    echo "  • System Status: sudo systemctl status nextcloud-aio"
    echo
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  • Complete the setup wizard in your web browser"
    echo "  • Configure your domain and SSL certificates"
    echo "  • Set up your admin account"
    echo "  • Consider setting up regular backups"
    echo
    echo -e "${GREEN}Enjoy your new Nextcloud instance!${NC}"
}

# Main execution
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root."
        log_info "Run as a regular user with sudo privileges."
        exit 1
    fi
    
    show_welcome
    check_all_scripts
    
    if [ $# -eq 0 ]; then
        show_installation_menu
    else
        case "$1" in
            complete|full|auto)
                complete_installation
                ;;
            update)
                if check_script "update-system.sh"; then
                    run_script "update-system.sh" "update"
                else
                    log_error "update-system.sh script not found"
                    exit 1
                fi
                ;;
            docker)
                run_script "install-docker-complete.sh"
                ;;
            nfs)
                run_script "setup-nfs.sh"
                ;;
            nextcloud)
                run_script "install-nextcloud-aio.sh"
                ;;
            custom)
                custom_installation
                ;;
            *)
                echo "Usage: $0 [complete|update|docker|nfs|nextcloud|custom]"
                echo "  complete  - Full automated installation (OS update + Docker + Nextcloud AIO)"
                echo "  update    - Update system packages only"
                echo "  docker    - Install Docker only"
                echo "  nfs       - Setup NFS only"
                echo "  nextcloud - Install Nextcloud AIO only"
                echo "  custom    - Step-by-step installation"
                echo
                echo "Run without arguments for interactive menu."
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
