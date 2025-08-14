RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
if [ "$EUID" -ne 0 ]; then
	echo -e "${RED}Error: Please run as root or with sudo.${NC}"
	exit 1
fi

for DIR in "/mnt/media" "$(pwd)/config"; do
	if ! [ -w "$DIR" ]; then
	echo -e "${RED}Error: No write access to $DIR.${NC}"
		read -p "Do you want to attempt to fix permissions for $DIR automatically? [y/N]: " FIX
		FIX=${FIX,,}
		if [[ "$FIX" == "y" || "$FIX" == "yes" ]]; then
			sudo chown -R $USER:$USER "$DIR"
			sudo chmod -R 775 "$DIR"
			if ! [ -w "$DIR" ]; then
	echo -e "${RED}Automatic fix failed. Please fix manually.${NC}"
				exit 2
			fi
		else
	echo -e "${YELLOW}Please fix permissions manually and re-run the script.${NC}"
			exit 2
		fi
	fi
done
# Optionally install NFS client
read -p "Do you want to check and install NFS client utilities? [y/N]: " INSTALL_NFS_CLIENT
INSTALL_NFS_CLIENT=${INSTALL_NFS_CLIENT,,}
if [[ "$INSTALL_NFS_CLIENT" == "y" || "$INSTALL_NFS_CLIENT" == "yes" ]]; then
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		DISTRO=$ID
	else
		DISTRO="unknown"
	fi
	case "$DISTRO" in
		ubuntu|debian)
			PKG="nfs-common"
			CMD="sudo apt update && sudo apt install -y $PKG"
			;;
		centos|rhel|fedora)
			PKG="nfs-utils"
			CMD="sudo dnf install -y $PKG || sudo yum install -y $PKG"
			;;
		arch)
			PKG="nfs-utils"
			CMD="sudo pacman -Sy --noconfirm $PKG"
			;;
		*)
			echo "Unknown or unsupported distro. Please install NFS client manually."
			CMD=""
			;;
	esac
	if [ -n "$CMD" ]; then
		echo "Installing NFS client package ($PKG)..."
		eval "$CMD"
	fi
fi
#!/bin/bash
# setup-arr-folders.sh: Create TRASHguides-compliant *arr stack folder structure
set -e


ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
	# shellcheck disable=SC1090
	source "$ENV_FILE"
fi

read -p "Do you want to mount media/torrents/usenet folders to an NFS share? [y/N]: " USE_NFS
USE_NFS=${USE_NFS,,} # to lowercase
if [[ "$USE_NFS" == "y" || "$USE_NFS" == "yes" ]]; then
	DEFAULT_NFS_SERVER="${NFS_SERVER:-10.84.2.60}"
	DEFAULT_NFS_SHARE="${NFS_SHARE:-/mnt/Pool1/MediaData}"
	DEFAULT_NFS_MOUNT="${NFS_MOUNT_POINT:-/mnt/media}"
	read -p "Enter NFS server (default: $DEFAULT_NFS_SERVER): " NFS_SERVER
	NFS_SERVER=${NFS_SERVER:-$DEFAULT_NFS_SERVER}
	read -p "Enter NFS share path (default: $DEFAULT_NFS_SHARE): " NFS_SHARE
	NFS_SHARE=${NFS_SHARE:-$DEFAULT_NFS_SHARE}
	read -p "Enter local mount point (default: $DEFAULT_NFS_MOUNT): " NFS_MOUNT
	NFS_MOUNT=${NFS_MOUNT:-$DEFAULT_NFS_MOUNT}
	echo "Mounting NFS share..."
	sudo mkdir -p "$NFS_MOUNT"
	if ! mount | grep -q "$NFS_MOUNT"; then
		sudo mount -t nfs "$NFS_SERVER:$NFS_SHARE" "$NFS_MOUNT"
	else
		echo "NFS already mounted at $NFS_MOUNT"
	fi
	MEDIA_ROOT="$NFS_MOUNT"
else
	MEDIA_ROOT="/mnt/media"
fi
CONFIG_ROOT="$(pwd)/config"


# Media library folders
mkdir -p "$MEDIA_ROOT/media/movies"
mkdir -p "$MEDIA_ROOT/media/tv"
mkdir -p "$MEDIA_ROOT/media/music"
mkdir -p "$MEDIA_ROOT/media/books"
mkdir -p "$MEDIA_ROOT/media/audiobooks"

# Torrent download folders
mkdir -p "$MEDIA_ROOT/torrents/movies"
mkdir -p "$MEDIA_ROOT/torrents/tv"
mkdir -p "$MEDIA_ROOT/torrents/music"
mkdir -p "$MEDIA_ROOT/torrents/books"
mkdir -p "$MEDIA_ROOT/torrents/audiobooks"
mkdir -p "$MEDIA_ROOT/torrents/incomplete"
mkdir -p "$MEDIA_ROOT/torrents/watch"

# Usenet download folders
mkdir -p "$MEDIA_ROOT/usenet/complete"
mkdir -p "$MEDIA_ROOT/usenet/incomplete"
mkdir -p "$MEDIA_ROOT/usenet/intermediate"

# Config folders for each app
mkdir -p "$CONFIG_ROOT/prowlarr"
mkdir -p "$CONFIG_ROOT/sonarr"
mkdir -p "$CONFIG_ROOT/radarr"
mkdir -p "$CONFIG_ROOT/lidarr"
mkdir -p "$CONFIG_ROOT/readarr"
mkdir -p "$CONFIG_ROOT/qbittorrent"
mkdir -p "$CONFIG_ROOT/nzbget"
mkdir -p "$CONFIG_ROOT/bazarr"
mkdir -p "$CONFIG_ROOT/jellyseerr"
mkdir -p "$CONFIG_ROOT/notifiarr"

# Print summary
echo -e "${GREEN}TRASHguides *arr stack folders created:${NC}"
echo "- Media:      $MEDIA_ROOT/media/{movies,tv,music,books,audiobooks}"
echo "- Torrents:   $MEDIA_ROOT/torrents/{movies,tv,music,books,audiobooks,incomplete,watch}"
echo "- Usenet:     $MEDIA_ROOT/usenet/{complete,incomplete,intermediate}"
echo "- Config:     $CONFIG_ROOT/{prowlarr,sonarr,radarr,lidarr,readarr,qbittorrent,nzbget,bazarr,jellyseerr,notifiarr}"
echo -e "${YELLOW}NFS mount:   ${USE_NFS^^}${NC}"
if [ "$USE_NFS" == "y" ] ; then
	echo -e "${BLUE}NFS mounted at $MEDIA_ROOT from $NFS_SERVER:$NFS_SHARE${NC}"
fi
echo -e "${YELLOW}You may want to set ownership/permissions:${NC}"
echo "  sudo chown -R $USER:$USER $MEDIA_ROOT $CONFIG_ROOT"
