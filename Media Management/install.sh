#!/bin/bash
# HomeLab Media Management - One-Line Installer with Proper Sudo Handling
# Usage: curl -fsSL https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/Media%20Management/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/cousmax/HomeLab"
BRANCH="Dynamic-Servarr"
WRAPPER_URL="https://raw.githubusercontent.com/cousmax/HomeLab/$BRANCH/Media%20Management/scripts/install-wrapper.sh"

echo -e "${BLUE}🚀 HomeLab Media Management - One-Line Installer${NC}"
echo -e "${YELLOW}This installer handles Docker installation and proper sudo permissions${NC}"
echo

# Check requirements
for cmd in curl; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

echo -e "${BLUE}📥 Downloading and running installer with proper sudo handling...${NC}"
echo -e "${YELLOW}Note: You may be prompted for your sudo password during installation${NC}"
echo

# Use the wrapper that downloads and executes properly
if curl -fsSL "$WRAPPER_URL" | bash; then
    echo
    echo -e "${GREEN}🎉 Installation process initiated successfully!${NC}"
else
    echo -e "${RED}❌ Installation failed${NC}"
    echo -e "${YELLOW}💡 Try the manual method:${NC}"
    echo "1. wget https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/Media%20Management/scripts/github-installer.sh -O installer.sh"
    echo "2. chmod +x installer.sh"
    echo "3. ./installer.sh"
    exit 1
fi
