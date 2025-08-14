#!/bin/bash

# Nextcloud AIO Installation Wrapper
# Handles Docker group activation and runs Nextcloud AIO installation

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

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please run the Docker installation script first."
    exit 1
fi

# Check if Docker daemon is running
if ! sudo docker info &> /dev/null; then
    log_error "Docker daemon is not running. Please start Docker service:"
    echo "  sudo systemctl start docker"
    exit 1
fi

# Check if user is in docker group
if ! getent group docker | grep -q "$USER"; then
    log_error "User is not in docker group. Please run:"
    echo "  sudo usermod -aG docker $USER"
    exit 1
fi

# Test if user can run docker commands directly
if docker ps &> /dev/null 2>&1; then
    log_success "Docker is accessible without sudo. Running Nextcloud AIO installation..."
    exec ./install-nextcloud-aio.sh "$@"
else
    log_info "Docker group membership needs activation."
    log_warning "Docker group is configured but not yet active in current session."
    log_info "Running Nextcloud AIO installation with sudo for Docker commands..."
    
    # Set environment variable to indicate we need sudo for docker
    export USE_SUDO_DOCKER="true"
    exec ./install-nextcloud-aio.sh "$@"
fi
