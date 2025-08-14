#!/bin/bash

# System Update Script
# Updates the operating system packages to the latest versions

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

# Function to get distribution version
get_distro_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# Function to show system information
show_system_info() {
    local distro=$(detect_distro)
    local version=$(get_distro_version)
    
    echo
    log_info "System Information:"
    echo "  Distribution: $distro"
    echo "  Version: $version"
    echo "  Kernel: $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  Hostname: $(hostname)"
    echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo
}

# Function to check available updates
check_updates() {
    log_info "Checking for available updates..."
    
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            sudo apt-get update -qq
            local updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
            echo "Available package updates: $((updates - 1))"
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf &> /dev/null; then
                local updates=$(dnf check-update -q | wc -l || echo "0")
            else
                local updates=$(yum check-update -q | wc -l || echo "0")
            fi
            echo "Available package updates: $updates"
            ;;
        fedora)
            local updates=$(dnf check-update -q | wc -l || echo "0")
            echo "Available package updates: $updates"
            ;;
        opensuse|sles)
            sudo zypper refresh -q
            local updates=$(zypper list-updates | wc -l || echo "0")
            echo "Available package updates: $updates"
            ;;
        arch)
            sudo pacman -Sy
            local updates=$(pacman -Qu | wc -l || echo "0")
            echo "Available package updates: $updates"
            ;;
        *)
            log_warning "Cannot check updates for unknown distribution: $distro"
            ;;
    esac
}

# Function to update system packages
update_system() {
    log_info "Updating system packages..."
    
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            log_info "Updating Debian/Ubuntu packages..."
            sudo apt-get update
            sudo apt-get upgrade -y
            sudo apt-get dist-upgrade -y
            sudo apt-get autoremove -y
            sudo apt-get autoclean
            
            # Check if reboot is required
            if [ -f /var/run/reboot-required ]; then
                log_warning "System reboot is required to complete the update!"
                log_info "Reboot required packages:"
                cat /var/run/reboot-required.pkgs 2>/dev/null || echo "  (packages list not available)"
            fi
            ;;
        centos|rhel|rocky|almalinux)
            log_info "Updating RHEL/CentOS packages..."
            if command -v dnf &> /dev/null; then
                sudo dnf update -y
                sudo dnf autoremove -y
                sudo dnf clean all
            else
                sudo yum update -y
                sudo yum autoremove -y
                sudo yum clean all
            fi
            
            # Check if reboot is required
            if needs-restarting -r &>/dev/null; then
                log_warning "System reboot is required to complete the update!"
            fi
            ;;
        fedora)
            log_info "Updating Fedora packages..."
            sudo dnf update -y
            sudo dnf autoremove -y
            sudo dnf clean all
            
            # Check if reboot is required
            if needs-restarting -r &>/dev/null; then
                log_warning "System reboot is required to complete the update!"
            fi
            ;;
        opensuse|sles)
            log_info "Updating openSUSE/SLES packages..."
            sudo zypper refresh
            sudo zypper update -y
            sudo zypper clean -a
            ;;
        arch)
            log_info "Updating Arch Linux packages..."
            sudo pacman -Syu --noconfirm
            sudo pacman -Sc --noconfirm
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

# Function to install essential packages
install_essentials() {
    log_info "Installing essential packages..."
    
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            sudo apt-get install -y \
                curl \
                wget \
                vim \
                htop \
                unzip \
                ca-certificates \
                gnupg \
                lsb-release \
                software-properties-common \
                apt-transport-https
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y \
                    curl \
                    wget \
                    vim \
                    htop \
                    unzip \
                    ca-certificates \
                    gnupg2
            else
                sudo yum install -y \
                    curl \
                    wget \
                    vim \
                    htop \
                    unzip \
                    ca-certificates
            fi
            ;;
        fedora)
            sudo dnf install -y \
                curl \
                wget \
                vim \
                htop \
                unzip \
                ca-certificates \
                gnupg2
            ;;
        opensuse|sles)
            sudo zypper install -y \
                curl \
                wget \
                vim \
                htop \
                unzip \
                ca-certificates
            ;;
        arch)
            sudo pacman -S --noconfirm \
                curl \
                wget \
                vim \
                htop \
                unzip \
                ca-certificates
            ;;
        *)
            log_warning "Skipping essential packages installation for unknown distribution: $distro"
            ;;
    esac
    
    log_success "Essential packages installed!"
}

# Function to show disk space
show_disk_space() {
    log_info "Disk Space Usage:"
    df -h / /home 2>/dev/null | grep -E "(Filesystem|/dev/)" || df -h /
    echo
}

# Function to show system status
show_system_status() {
    echo
    log_info "System Status Summary:"
    echo "  Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    echo "  Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
    echo "  Disk Usage: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
    
    # Show services status
    if command -v systemctl &> /dev/null; then
        local failed_services=$(systemctl --failed --no-legend | wc -l)
        echo "  Failed Services: $failed_services"
        if [ "$failed_services" -gt 0 ]; then
            log_warning "Failed services detected. Run 'systemctl --failed' to see details."
        fi
    fi
    echo
}

# Main menu
show_menu() {
    echo
    log_info "System Update and Maintenance Script"
    echo "Choose an option:"
    echo "1. Show system information"
    echo "2. Check for available updates"
    echo "3. Update system packages"
    echo "4. Install essential packages"
    echo "5. Full update (packages + essentials)"
    echo "6. Show disk space usage"
    echo "7. Show system status"
    echo "8. Exit"
    echo
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1)
            show_system_info
            show_menu
            ;;
        2)
            check_updates
            show_menu
            ;;
        3)
            update_system
            show_menu
            ;;
        4)
            install_essentials
            show_menu
            ;;
        5)
            update_system
            install_essentials
            show_menu
            ;;
        6)
            show_disk_space
            show_menu
            ;;
        7)
            show_system_status
            show_menu
            ;;
        8)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice. Please select 1-8."
            show_menu
            ;;
    esac
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_system_info
        show_menu
    else
        case "$1" in
            info)
                show_system_info
                ;;
            check)
                check_updates
                ;;
            update)
                update_system
                ;;
            essentials)
                install_essentials
                ;;
            full)
                update_system
                install_essentials
                ;;
            status)
                show_system_status
                ;;
            disk)
                show_disk_space
                ;;
            *)
                echo "Usage: $0 [info|check|update|essentials|full|status|disk]"
                echo "  info       - Show system information"
                echo "  check      - Check for available updates"
                echo "  update     - Update system packages"
                echo "  essentials - Install essential packages"
                echo "  full       - Full update (packages + essentials)"
                echo "  status     - Show system status"
                echo "  disk       - Show disk space usage"
                echo
                echo "Run without arguments for interactive menu."
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
