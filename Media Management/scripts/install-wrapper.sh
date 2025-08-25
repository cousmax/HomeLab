#!/bin/bash
# HomeLab Media Management - Alternative Installer (Download & Execute)
# This version downloads the interactive installer first to handle sudo properly

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/cousmax/HomeLab"
BRANCH="Dynamic-Servarr"
INSTALLER_URL="https://raw.githubusercontent.com/cousmax/HomeLab/$BRANCH/Media%20Management/scripts/github-installer.sh"

echo -e "${BLUE}🚀 HomeLab Media Management Installer${NC}"
echo -e "${YELLOW}Downloading installer script for proper sudo handling...${NC}"
echo

# Check requirements
for cmd in curl; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

# Download the installer to a temporary file
TEMP_INSTALLER=$(mktemp -t homelab-installer.XXXXXX.sh)
echo -e "${BLUE}📥 Downloading installer...${NC}"

if curl -fsSL "$INSTALLER_URL" -o "$TEMP_INSTALLER"; then
    echo -e "${GREEN}✅ Installer downloaded successfully${NC}"
    chmod +x "$TEMP_INSTALLER"
    
    echo -e "${BLUE}🔧 Running installer with proper sudo handling...${NC}"
    echo
    
    # Execute the installer directly (not piped) so it can handle sudo properly
    exec "$TEMP_INSTALLER"
else
    echo -e "${RED}❌ Failed to download installer${NC}"
    echo -e "${YELLOW}You can try the manual method:${NC}"
    echo "1. wget $INSTALLER_URL -O installer.sh"
    echo "2. chmod +x installer.sh"
    echo "3. ./installer.sh"
    exit 1
fi

# Cleanup (this won't be reached due to exec, but good practice)
rm -f "$TEMP_INSTALLER" 2>/dev/null || true
