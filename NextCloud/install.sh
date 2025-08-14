#!/bin/bash

# Simple Nextcloud AIO Installer - Direct from GitHub
# This script downloads and runs the installation automatically
# Usage: curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# GitHub repository details
REPO_OWNER="cousmax"
REPO_NAME="nextcloud-aio-automated-installer"
GITHUB_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"

# Installation directory
INSTALL_DIR="$HOME/nextcloud-aio-installer"

echo -e "${CYAN}🚀 Nextcloud AIO Auto-Installer${NC}"
echo -e "${CYAN}================================${NC}"
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
log_info "Checking requirements..."

if ! command -v git >/dev/null 2>&1; then
    log_info "Installing git..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm git
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y git
    else
        log_error "Cannot install git automatically. Please install git manually."
        exit 1
    fi
fi

log_success "Requirements satisfied"

# Download repository
log_info "Downloading repository from GitHub..."

# Remove existing directory if it exists
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
fi

# Clone the repository
if git clone "$GITHUB_URL.git" "$INSTALL_DIR"; then
    log_success "Repository downloaded successfully"
else
    log_error "Failed to download repository"
    exit 1
fi

# Make all scripts executable
chmod +x "$INSTALL_DIR"/scripts/*.sh
log_success "Scripts made executable"

# Show what we downloaded
log_info "Available scripts:"
ls -la "$INSTALL_DIR/scripts/"
echo ""

# Run the interactive installer
log_info "Starting interactive installation menu..."

# Check for automation environment variables
if [ "$AUTO_INSTALL" = "true" ] && [ -n "$INSTALL_OPTION" ]; then
    log_info "Automation mode detected - using INSTALL_OPTION=$INSTALL_OPTION"
    cd "$INSTALL_DIR"
    case "$INSTALL_OPTION" in
        1)
            exec "./scripts/install-complete-stack.sh" --install-all
            ;;
        2)
            exec "./scripts/update-system.sh"
            ;;
        3)
            exec "./scripts/install-docker-complete.sh"
            ;;
        4)
            exec "./scripts/setup-nfs.sh"
            ;;
        5)
            exec "./scripts/install-nextcloud-aio.sh"
            ;;
        *)
            log_info "Invalid INSTALL_OPTION, falling back to interactive mode"
            exec "./scripts/install-complete-stack.sh"
            ;;
    esac
else
    cd "$INSTALL_DIR"
    exec "./scripts/install-complete-stack.sh"
fi
