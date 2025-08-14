#!/bin/bash

# NFS Setup and Configuration Script
# This script helps configure NFS client and prepare for Nextcloud AIO data mounting

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

# Install NFS utilities
install_nfs_utils() {
    log_info "Installing NFS utilities..."
    
    # Detect the distribution
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            # Debian/Ubuntu
            sudo apt-get update
            sudo apt-get install -y nfs-common
            ;;
        centos|rhel|rocky|almalinux)
            # RHEL/CentOS
            if command -v dnf &> /dev/null; then
                sudo dnf install -y nfs-utils
            else
                sudo yum install -y nfs-utils
            fi
            ;;
        fedora)
            # Fedora
            sudo dnf install -y nfs-utils
            ;;
        opensuse|sles)
            # openSUSE/SLES
            sudo zypper install -y nfs-client
            ;;
        arch)
            # Arch Linux
            sudo pacman -S --noconfirm nfs-utils
            ;;
        *)
            log_warning "Unknown distribution '$distro'. Attempting generic installation..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y nfs-common
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y nfs-utils
            elif command -v yum &> /dev/null; then
                sudo yum install -y nfs-utils
            else
                log_error "Unsupported distribution. Please install NFS utilities manually."
                exit 1
            fi
            ;;
    esac
    
    log_success "NFS utilities installed successfully!"
}

# Test NFS server connectivity
test_nfs_connection() {
    local nfs_server="$1"
    local nfs_path="$2"
    
    log_info "Testing NFS connection to $nfs_server:$nfs_path..."
    
    # Test if server is reachable
    if ! ping -c 1 "$nfs_server" &> /dev/null; then
        log_warning "Cannot ping NFS server $nfs_server"
        return 1
    fi
    
    # Test if NFS export is available
    if showmount -e "$nfs_server" | grep -q "$nfs_path"; then
        log_success "NFS export $nfs_path is available on $nfs_server"
        return 0
    else
        log_warning "NFS export $nfs_path not found on $nfs_server"
        log_info "Available exports:"
        showmount -e "$nfs_server" || log_warning "Could not list exports"
        return 1
    fi
}

# Configure NFS mount
configure_nfs_mount() {
    local nfs_server="$1"
    local nfs_path="$2"
    local mount_point="$3"
    local mount_options="${4:-defaults,noatime,rsize=8192,wsize=8192,timeo=14}"
    
    log_info "Configuring NFS mount..."
    
    # Create mount point
    sudo mkdir -p "$mount_point"
    
    # Create fstab entry
    local fstab_entry="$nfs_server:$nfs_path $mount_point nfs $mount_options 0 0"
    
    # Check if entry already exists
    if grep -q "$mount_point" /etc/fstab; then
        log_warning "Mount point $mount_point already exists in /etc/fstab"
        read -p "Do you want to replace it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove existing entry
            sudo sed -i "\|$mount_point|d" /etc/fstab
        else
            log_info "Skipping fstab modification"
            return 0
        fi
    fi
    
    # Add new entry
    echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null
    log_success "Added NFS mount to /etc/fstab"
    
    # Test mount
    log_info "Testing NFS mount..."
    if sudo mount "$mount_point"; then
        log_success "NFS mount successful!"
        
        # Test write permissions
        local test_file="$mount_point/.nextcloud_test_$(date +%s)"
        if sudo touch "$test_file" 2>/dev/null; then
            sudo rm -f "$test_file"
            log_success "Write permissions confirmed"
        else
            log_warning "Cannot write to NFS mount. Check permissions."
        fi
        
        # Show mount information
        log_info "Mount information:"
        df -h "$mount_point"
        
        return 0
    else
        log_error "Failed to mount NFS share"
        return 1
    fi
}

# Interactive NFS configuration
interactive_nfs_setup() {
    echo
    log_info "Interactive NFS Setup"
    echo "This will help you configure NFS mounting for Nextcloud AIO."
    echo
    
    # Get NFS server details
    read -p "NFS Server IP or hostname: " nfs_server
    read -p "NFS export path: " nfs_path
    read -p "Local mount point [/mnt/nextcloud-nfs]: " mount_point
    mount_point="${mount_point:-/mnt/nextcloud-nfs}"
    
    echo
    log_info "Advanced Options (press Enter for defaults)"
    read -p "Mount options [defaults,noatime,rsize=8192,wsize=8192,timeo=14]: " mount_options
    mount_options="${mount_options:-defaults,noatime,rsize=8192,wsize=8192,timeo=14}"
    
    echo
    log_info "Configuration Summary:"
    echo "  NFS Server: $nfs_server"
    echo "  NFS Path: $nfs_path"
    echo "  Mount Point: $mount_point"
    echo "  Mount Options: $mount_options"
    echo
    
    read -p "Proceed with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Configuration cancelled"
        exit 0
    fi
    
    # Test connection first
    test_nfs_connection "$nfs_server" "$nfs_path"
    
    # Configure mount
    configure_nfs_mount "$nfs_server" "$nfs_path" "$mount_point" "$mount_options"
}

# Show NFS mount status
show_nfs_status() {
    log_info "Current NFS Mounts:"
    echo
    
    # Show mounted NFS filesystems
    if mount | grep -q "type nfs"; then
        mount | grep "type nfs" | while read line; do
            echo "  $line"
        done
    else
        echo "  No NFS mounts currently active"
    fi
    
    echo
    log_info "NFS entries in /etc/fstab:"
    if grep -q "nfs" /etc/fstab; then
        grep "nfs" /etc/fstab | while read line; do
            echo "  $line"
        done
    else
        echo "  No NFS entries in /etc/fstab"
    fi
}

# Main menu
show_menu() {
    echo
    log_info "NFS Configuration Script"
    echo "Choose an option:"
    echo "1. Install NFS utilities"
    echo "2. Interactive NFS setup"
    echo "3. Test NFS connection"
    echo "4. Show NFS status"
    echo "5. Exit"
    echo
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            install_nfs_utils
            ;;
        2)
            install_nfs_utils
            interactive_nfs_setup
            ;;
        3)
            read -p "NFS Server: " server
            read -p "NFS Path: " path
            test_nfs_connection "$server" "$path"
            ;;
        4)
            show_nfs_status
            ;;
        5)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice. Please select 1-5."
            show_menu
            ;;
    esac
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_menu
    else
        case "$1" in
            install)
                install_nfs_utils
                ;;
            setup)
                install_nfs_utils
                interactive_nfs_setup
                ;;
            status)
                show_nfs_status
                ;;
            test)
                if [ $# -lt 3 ]; then
                    log_error "Usage: $0 test <nfs_server> <nfs_path>"
                    exit 1
                fi
                test_nfs_connection "$2" "$3"
                ;;
            *)
                echo "Usage: $0 [install|setup|status|test]"
                echo "  install - Install NFS utilities"
                echo "  setup   - Interactive NFS configuration"
                echo "  status  - Show current NFS status"
                echo "  test    - Test NFS connection"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
