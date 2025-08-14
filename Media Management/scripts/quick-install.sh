#!/bin/bash
# quick-install.sh: Guided installer for HomeLab media stack
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step() {
	echo -e "${BLUE}$1${NC}"
}
success() {
	echo -e "${GREEN}$1${NC}"
}
warn() {
	echo -e "${YELLOW}$1${NC}"
}
error() {
	echo -e "${RED}$1${NC}"
}

run_script() {
	local script="$1"
	local desc="$2"
	if [ ! -f "$script" ]; then
		error "Script $script not found!"
		return 1
	fi
	if [ ! -x "$script" ]; then
		warn "Making $script executable."
		chmod +x "$script"
	fi
	step "$desc"
	read -p "Run $script now? [Y/n]: " CONFIRM
	CONFIRM=${CONFIRM,,}
	if [[ "$CONFIRM" == "n" || "$CONFIRM" == "no" ]]; then
		warn "Skipping $script."
		return 0
	fi
	./$script
	success "$script completed."
}

step "Welcome to the HomeLab Media Stack Quick Installer!"
echo -e "${YELLOW}This will guide you through installing Docker, setting up folders, NFS, customizing your stack, and managing services.${NC}"

run_script "install-docker.sh" "Step 1: Update OS and install Docker."
run_script "setup-arr-folders.sh" "Step 2: Set up TRASHguides folder structure."
run_script "create-nfs-dirs.sh" "Step 3: Create directories on NFS host (if needed)."
run_script "customize-arr-install.sh" "Step 4: Customize your stack and generate docker-compose file."

step "Step 5: Manage your stack."
echo -e "${YELLOW}You can now use the management script to start, stop, and monitor your stack.${NC}"
echo -e "${BLUE}To manage your stack, run:${NC}"
echo -e "  ${GREEN}./manage.sh [start|stop|status|logs|vpn-status|...etc]${NC}"

success "Quick install complete!"
