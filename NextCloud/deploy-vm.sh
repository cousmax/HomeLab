#!/bin/bash

# Quick VM Deployment Script
# This demonstrates the recommended deployment method for new VMs

set -e

echo "🚀 Nextcloud AIO VM Deployment - Recommended Method"
echo "=================================================="
echo ""

# Function to detect if we're running interactively
check_interactive() {
    if [ -t 0 ] && [ -t 1 ]; then
        echo "✅ Interactive terminal detected - proceeding with download-first method"
        return 0
    else
        echo "⚠️  Non-interactive environment detected"
        return 1
    fi
}

# Function to download and run installer
download_and_run() {
    local install_url="https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh"
    local install_file="nextcloud-aio-install.sh"
    
    echo "📥 Downloading installer from GitHub..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$install_url" -o "$install_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$install_file" "$install_url"
    else
        echo "❌ Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    echo "✅ Installer downloaded successfully"
    
    # Make executable
    chmod +x "$install_file"
    echo "✅ Made installer executable"
    
    echo ""
    echo "🎯 Starting Nextcloud AIO installation..."
    echo "   The installer will present you with interactive menu options."
    echo ""
    
    # Execute the installer
    exec "./$install_file"
}

# Main execution
main() {
    if check_interactive; then
        download_and_run
    else
        echo ""
        echo "For best results with interactive menus, run this script in an interactive terminal:"
        echo "  1. SSH into your VM"
        echo "  2. Run this deployment script"
        echo ""
        echo "Proceeding anyway..."
        download_and_run
    fi
}

# Run main function
main "$@"
