#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
if [ "$EUID" -ne 0 ]; then
	echo -e "${RED}Error: Please run as root or with sudo.${NC}"
	read -p "Do you want to re-run this script with sudo? [y/N]: " FIX
	FIX=${FIX,,}
	if [[ "$FIX" == "y" || "$FIX" == "yes" ]]; then
		exec sudo bash "$0" "$@"
	else
		echo -e "${YELLOW}Please run the script as root or with sudo.${NC}"
		exit 1
	fi
fi

# install-docker.sh: Universal Docker installer for Linux
set -e

# Detect distro
if [ -f /etc/os-release ]; then
	. /etc/os-release
	DISTRO=$ID
else
	echo "Cannot detect Linux distribution. Exiting."
	exit 1
fi

# Update system
case "$DISTRO" in
	ubuntu|debian)
		sudo apt update && sudo apt upgrade -y
		;;
	centos|rhel|fedora)
		sudo dnf upgrade --refresh -y || sudo yum update -y
		;;
	arch)
		sudo pacman -Syu --noconfirm
		;;
	*)
		echo "Unsupported distro: $DISTRO. Please update manually."
		;;
esac

# Install Docker (official docs)
case "$DISTRO" in
	ubuntu|debian)
		sudo apt-get remove docker docker-engine docker.io containerd runc -y || true
		sudo apt-get install ca-certificates curl gnupg lsb-release -y
		sudo install -m 0755 -d /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | \
			sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt-get update
		sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
		;;
	centos|rhel|fedora)
		sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine -y || true
		sudo dnf -y install dnf-plugins-core
		sudo dnf config-manager --add-repo https://download.docker.com/linux/$DISTRO/docker-ce.repo
		sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
		;;
	arch)
		sudo pacman -S --noconfirm docker
		;;
	*)
		echo "Unsupported distro: $DISTRO. Please install Docker manually."
		exit 1
		;;
esac

# Post-install steps
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER"
sudo systemctl enable docker
sudo systemctl start docker

# Test Docker
if docker --version && docker run --rm hello-world; then
	echo -e "${GREEN}Docker installed and working!${NC}"
	echo -e "${YELLOW}To activate docker group permissions, log out and back in.${NC}"
	echo -e "${BLUE}Examples:${NC}"
	echo "  CLI:  exec bash -l"
	echo "  SSH:  exit, then reconnect"
	echo "  Desktop: log out of your session and log back in"
	echo "  Or reboot: sudo reboot"
else
	echo -e "${RED}Docker install failed. Please check logs.${NC}"
	exit 1
fi
...existing code from install-docker.sh...
