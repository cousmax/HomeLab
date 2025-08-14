#!/bin/bash

# One-Line VM Setup for *arr Stack
# Usage: curl -sSL https://raw.githubusercontent.com/your-repo/Servarr/main/quick-setup.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/your-repo/Servarr/main/quick-setup.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}*arr Stack Quick Setup${NC}"
echo -e "${BLUE}===================${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Please run as a regular user with sudo privileges, not as root${NC}"
    exit 1
fi

# Check for sudo
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}This script needs sudo privileges${NC}"
    sudo -v
fi

echo -e "${BLUE}Cloning repository...${NC}"
if [ -d "Servarr" ]; then
    echo -e "${YELLOW}Directory 'Servarr' already exists, using existing directory${NC}"
    cd Servarr
    git pull 2>/dev/null || echo -e "${YELLOW}Could not update repository${NC}"
else
    git clone https://github.com/cousmax/Servarr.git
    cd Servarr
fi

echo -e "${BLUE}Making scripts executable...${NC}"
chmod +x *.sh 2>/dev/null || true

echo -e "${BLUE}Running full VM setup...${NC}"
./vm-setup.sh

echo -e "${GREEN}Quick setup complete!${NC}"
echo -e "${YELLOW}The full setup script will now guide you through configuration.${NC}"
