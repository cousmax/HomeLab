#!/bin/bash
# One-line installer for HomeLab Media Management
# Usage: curl -sSL https://raw.githubusercontent.com/cousmax/HomeLab/main/Media%20Management/scripts/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/cousmax/HomeLab"
BRANCH="Dynamic-Servarr"
TEMP_DIR="HomeLab-$(date +%s)"

echo -e "${BLUE}🚀 HomeLab Media Management Quick Installer${NC}"
echo -e "${YELLOW}Downloading and setting up your media management stack...${NC}"
echo

# Check requirements
for cmd in git curl; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not installed.${NC}"
    read -p "Would you like to install Docker automatically? [Y/n]: " install_docker
    install_docker=${install_docker,,}
    if [[ ! "$install_docker" =~ ^n(o)?$ ]]; then
        echo -e "${BLUE}📦 Installing Docker...${NC}"
        
        # Detect Linux distribution and install Docker
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            echo -e "${RED}Cannot detect Linux distribution${NC}"
            exit 1
        fi
        
        case "$DISTRO" in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
            centos|rhel|fedora)
                sudo dnf -y install dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/$DISTRO/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
            *)
                echo -e "${RED}Unsupported distribution. Please install Docker manually.${NC}"
                exit 1
                ;;
        esac
        
        # Start Docker
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker "$USER"
        sudo systemctl enable docker
        sudo systemctl start docker
        
        echo -e "${GREEN}✅ Docker installed successfully!${NC}"
        echo -e "${YELLOW}Note: You may need to log out and back in for Docker group permissions.${NC}"
    else
        echo -e "${RED}Docker is required for this installation. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Docker is already installed.${NC}"
fi

# Clone repository
echo -e "${BLUE}📥 Downloading HomeLab repository...${NC}"
git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$TEMP_DIR"

# Navigate to scripts directory
cd "$TEMP_DIR/Media Management/scripts"

# Make scripts executable
chmod +x *.sh

# Run the main installer
echo -e "${GREEN}✅ Repository downloaded. Starting installation...${NC}"
echo
./quick-install.sh

# Cleanup
cd ../../..
read -p "Remove temporary files? [Y/n]: " cleanup
if [[ ! "$cleanup" =~ ^[Nn] ]]; then
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}🧹 Cleanup completed.${NC}"
fi

echo -e "${GREEN}🎉 Installation complete!${NC}"
