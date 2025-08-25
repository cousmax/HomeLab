#!/bin/bash
# quick-install.github-draft.sh: GitHub-ready guided installer for HomeLab media stack
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/cousmax/HomeLab"
BRANCH="main"
SCRIPTS_DIR="HomeLab-temp"
MEDIA_SCRIPTS_PATH="Media Management/scripts"

step() { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}"; }

check_requirements() {
	local missing=()
	for tool in curl git; do
		if ! command -v $tool >/dev/null 2>&1; then
			missing+=("$tool")
		fi
	done
	if [ ${#missing[@]} -gt 0 ]; then
		error "Missing required tools: ${missing[*]}"
		warn "Please install them and re-run this script."
		exit 1
	fi
}

download_scripts() {
	if [ ! -d "$SCRIPTS_DIR" ]; then
		step "Cloning HomeLab repository from GitHub..."
		git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$SCRIPTS_DIR" || {
			error "Failed to clone repository!"
			exit 1
		}
		# Make scripts executable
		find "$SCRIPTS_DIR/$MEDIA_SCRIPTS_PATH" -name "*.sh" -exec chmod +x {} \;
		success "HomeLab repository cloned and scripts prepared."
	else
		step "Updating existing repository..."
		cd "$SCRIPTS_DIR" && git pull origin "$BRANCH" && cd ..
		find "$SCRIPTS_DIR/$MEDIA_SCRIPTS_PATH" -name "*.sh" -exec chmod +x {} \;
		success "Repository updated."
	fi
}

run_script() {
	local script="$1"
	local desc="$2"
	local script_path="$SCRIPTS_DIR/$MEDIA_SCRIPTS_PATH/$script"
	
	if [ ! -f "$script_path" ]; then
		error "Script $script not found at $script_path!"
		return 1
	fi
	
	step "$desc"
	read -p "Run $script now? [Y/n]: " CONFIRM
	CONFIRM=${CONFIRM,,}
	if [[ "$CONFIRM" == "n" || "$CONFIRM" == "no" ]]; then
		warn "Skipping $script."
		return 0
	fi
	
	# Run script from its proper directory
	cd "$SCRIPTS_DIR/$MEDIA_SCRIPTS_PATH"
	bash "./$script"
	cd - > /dev/null
	success "$script completed."
}

step "Welcome to the HomeLab Media Stack Quick Installer (GitHub Edition)!"
check_requirements
download_scripts

run_script "install-docker.sh" "Step 1: Update OS and install Docker."
run_script "setup-arr-folders.sh" "Step 2: Set up TRASHguides folder structure."
run_script "create-nfs-dirs.sh" "Step 3: Create directories on NFS host (if needed)."
run_script "customize-arr-install.sh" "Step 4: Customize your stack and generate docker-compose file."

step "Step 5: Manage your stack."
echo -e "${YELLOW}You can now use the management script to start, stop, and monitor your stack.${NC}"
echo -e "${BLUE}To manage your stack, run:${NC}"
echo -e "  ${GREEN}bash $SCRIPTS_DIR/$MEDIA_SCRIPTS_PATH/manage.sh [start|stop|status|logs|vpn-status|...etc]${NC}"

step "Cleanup (optional)."
read -p "Remove downloaded repository folder? [y/N]: " CLEANUP
CLEANUP=${CLEANUP,,}
if [[ "$CLEANUP" == "y" || "$CLEANUP" == "yes" ]]; then
	rm -rf "$SCRIPTS_DIR"
	success "Cleanup completed."
else
	warn "Repository folder kept at: $SCRIPTS_DIR"
fi

success "Quick install complete!"
