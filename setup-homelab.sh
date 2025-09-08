#!/bin/bash

# HomeLab Repository Setup Script
# This script clones the HomeLab repository and sets up the environment on a fresh VM

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository details
REPO_URL="https://github.com/cousmax/HomeLab.git"
REPO_NAME="HomeLab"
BRANCH="Dynamic-Servarr"

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

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Installing git..."
        sudo apt update
        sudo apt install -y git
    else
        print_success "Git is already installed"
    fi
}

# Clone or update repository
setup_repository() {
    print_status "Setting up HomeLab repository..."
    
    if [ -d "$REPO_NAME" ]; then
        print_warning "Repository directory already exists. Updating..."
        cd "$REPO_NAME"
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
        print_success "Repository updated successfully"
    else
        print_status "Cloning repository from GitHub..."
        git clone -b "$BRANCH" "$REPO_URL"
        cd "$REPO_NAME"
        print_success "Repository cloned successfully"
    fi
}

# Set up Python environment for MediaManagement scripts
setup_python_environment() {
    print_status "Setting up Python environment..."
    
    # Check if python3 is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed. Installing..."
        sudo apt update
        sudo apt install -y python3 python3-pip python3-venv
    fi
    
    # Install requirements if they exist
    if [ -f "MediaManagement/scripts/requirements.txt" ]; then
        print_status "Installing Python requirements..."
        cd MediaManagement/scripts
        python3 -m pip install -r requirements.txt
        cd ../..
        print_success "Python requirements installed"
    fi
}

# Make scripts executable
make_scripts_executable() {
    print_status "Making scripts executable..."
    
    # Make all shell scripts executable
    find . -name "*.sh" -type f -exec chmod +x {} \;
    
    print_success "All shell scripts are now executable"
}

# Display next steps
show_next_steps() {
    echo
    print_success "HomeLab repository setup complete!"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Navigate to the repository: cd $REPO_NAME"
    echo "2. For MediaManagement setup: cd MediaManagement"
    echo "3. For NextCloud setup: cd NextCloud"
    echo
    echo -e "${BLUE}Available scripts:${NC}"
    echo "📦 MediaManagement:"
    echo "   - ./scripts/install-docker-and-update-os.sh"
    echo "   - ./scripts/generate-compose.sh"
    echo "   - ./scripts/test-compose.sh"
    echo
    echo "☁️  NextCloud:"
    echo "   - ./install.sh"
    echo "   - ./quick-install.sh"
    echo "   - ./scripts/install-nextcloud-aio.sh"
    echo
}

# Main execution
main() {
    print_status "Starting HomeLab setup on fresh VM..."
    echo
    
    check_git
    setup_repository
    setup_python_environment
    make_scripts_executable
    show_next_steps
}

# Run main function
main "$@"
