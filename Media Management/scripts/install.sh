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
