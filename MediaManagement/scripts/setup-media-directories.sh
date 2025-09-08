#!/bin/bash

# Media Directories Setup Script
# This script creates the necessary directory structure for the media management stack
# and sets proper permissions

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
DEFAULT_BASE_PATH="/mnt/media"
DEFAULT_USER=$(whoami)
DEFAULT_GROUP=$(id -gn)

# Get user input or use defaults
BASE_PATH=${1:-$DEFAULT_BASE_PATH}
MEDIA_USER=${2:-$DEFAULT_USER}
MEDIA_GROUP=${3:-$DEFAULT_GROUP}

print_status "Setting up media directories..."
echo "Base path: $BASE_PATH"
echo "User: $MEDIA_USER"
echo "Group: $MEDIA_GROUP"
echo

# Check if running as root for /mnt operations
if [[ "$BASE_PATH" == "/mnt"* ]] && [[ $EUID -ne 0 ]]; then
    print_error "Creating directories in /mnt requires root privileges."
    print_status "Please run with sudo or choose a different base path."
    print_status "Usage: $0 [base_path] [user] [group]"
    print_status "Example: sudo $0 /mnt/media stephen stephen"
    print_status "Or use home directory: $0 ~/media stephen stephen"
    exit 1
fi

# Create main directory structure
create_directory() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        print_status "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        print_success "Created: $dir_path"
    else
        print_warning "Directory already exists: $dir_path"
    fi
}

# Set permissions
set_permissions() {
    local dir_path="$1"
    print_status "Setting permissions for: $dir_path"
    chown -R "$MEDIA_USER:$MEDIA_GROUP" "$dir_path"
    chmod -R 755 "$dir_path"
    print_success "Permissions set for: $dir_path"
}

# Create all necessary directories
print_status "Creating media directory structure..."

# Main media directories
create_directory "$BASE_PATH"
create_directory "$BASE_PATH/movies"
create_directory "$BASE_PATH/tv"
create_directory "$BASE_PATH/music"
create_directory "$BASE_PATH/downloads"

# Download subdirectories
create_directory "$BASE_PATH/downloads/complete"
create_directory "$BASE_PATH/downloads/incomplete"
create_directory "$BASE_PATH/downloads/torrents"

# Configuration directories
create_directory "$BASE_PATH/config"
create_directory "$BASE_PATH/config/sonarr"
create_directory "$BASE_PATH/config/radarr"
create_directory "$BASE_PATH/config/lidarr"
create_directory "$BASE_PATH/config/bazarr"
create_directory "$BASE_PATH/config/jellyseerr"
create_directory "$BASE_PATH/config/portainer"
create_directory "$BASE_PATH/config/jellyfin"
create_directory "$BASE_PATH/config/transmission"
create_directory "$BASE_PATH/config/prowlarr"

# Set permissions on all directories
if [[ $EUID -eq 0 ]] || [[ "$BASE_PATH" != "/mnt"* ]]; then
    set_permissions "$BASE_PATH"
else
    print_warning "Skipping permission setting (not running as root)"
fi

# Display the created structure
print_success "Media directory structure created successfully!"
echo
print_status "Directory structure:"
tree "$BASE_PATH" 2>/dev/null || find "$BASE_PATH" -type d | sort

echo
print_status "Directory structure created at: $BASE_PATH"
print_status "Owner: $MEDIA_USER:$MEDIA_GROUP"
print_status "Permissions: 755 (rwxr-xr-x)"

# Show usage information
echo
print_success "Setup complete! Your media directories are ready."
echo
print_status "Next steps:"
echo "1. Run the docker-compose generation script"
echo "2. Start your media management stack: docker-compose up -d"
echo "3. Configure your applications through their web interfaces"