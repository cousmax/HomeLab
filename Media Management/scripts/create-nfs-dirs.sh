RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
if [ "$EUID" -ne 0 ]; then
	echo -e "${RED}Error: Please run as root or with sudo.${NC}"
	exit 1
fi

if ! [ -w "$NFS_SHARE" ]; then
	echo -e "${RED}Error: No write access to $NFS_SHARE.${NC}"
	read -p "Do you want to attempt to fix permissions for $NFS_SHARE automatically? [y/N]: " FIX
	FIX=${FIX,,}
	if [[ "$FIX" == "y" || "$FIX" == "yes" ]]; then
		sudo chown -R $USER:$USER "$NFS_SHARE"
		sudo chmod -R 775 "$NFS_SHARE"
		if ! [ -w "$NFS_SHARE" ]; then
	echo -e "${RED}Automatic fix failed. Please fix manually.${NC}"
			exit 2
		fi
	else
	echo -e "${YELLOW}Please fix permissions manually and re-run the script.${NC}"
		exit 2
	fi
fi
#!/bin/bash
# create-nfs-dirs.sh: Create TRASHguides *arr folders directly on NFS host
set -e

# Set this to your NFS share root (e.g., /mnt/Pool1/MediaData)
NFS_SHARE="/mnt/Pool1/MediaData"

# Media library folders
mkdir -p "$NFS_SHARE/media/movies"
mkdir -p "$NFS_SHARE/media/tv"
mkdir -p "$NFS_SHARE/media/music"
mkdir -p "$NFS_SHARE/media/books"
mkdir -p "$NFS_SHARE/media/audiobooks"

# Torrent download folders
mkdir -p "$NFS_SHARE/torrents/movies"
mkdir -p "$NFS_SHARE/torrents/tv"
mkdir -p "$NFS_SHARE/torrents/music"
mkdir -p "$NFS_SHARE/torrents/books"
mkdir -p "$NFS_SHARE/torrents/audiobooks"
mkdir -p "$NFS_SHARE/torrents/incomplete"
mkdir -p "$NFS_SHARE/torrents/watch"

# Usenet download folders
mkdir -p "$NFS_SHARE/usenet/complete"
mkdir -p "$NFS_SHARE/usenet/incomplete"
mkdir -p "$NFS_SHARE/usenet/intermediate"

# Print summary
echo -e "${GREEN}TRASHguides *arr stack folders created on NFS host:${NC}"
echo "- Media:      $NFS_SHARE/media/{movies,tv,music,books,audiobooks}"
echo "- Torrents:   $NFS_SHARE/torrents/{movies,tv,music,books,audiobooks,incomplete,watch}"
echo "- Usenet:     $NFS_SHARE/usenet/{complete,incomplete,intermediate}"
echo -e "${YELLOW}You may want to set ownership/permissions:${NC}"
echo "  sudo chown -R <youruser>:<yourgroup> $NFS_SHARE"
