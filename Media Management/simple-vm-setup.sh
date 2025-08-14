#!/bin/bash

# Ultra-Simple VM Setup for *arr Stack
# Run this on a fresh Ubuntu/Debian VM to get everything working quickly

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                     *arr Stack VM Setup                          ║"
echo "║                  Ultra-Simple Installation                       ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Don't run as root! Use a regular user with sudo access.${NC}"
    exit 1
fi

# Get current user info
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo -e "${BLUE}Setting up for user: $CURRENT_USER (UID: $CURRENT_UID, GID: $CURRENT_GID)${NC}"

# Update system
echo -e "${BLUE}Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}"

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $CURRENT_USER
    rm get-docker.sh
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo -e "${BLUE}Installing Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already available${NC}"
fi

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Create directory structure
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p {config,data}/{prowlarr,sonarr,radarr,lidarr,readarr,qbittorrent,nzbget,bazarr,jellyseerr,notifiarr,flaresolverr}
mkdir -p data/{media,torrents,usenet}/{movies,tv,music,books,audiobooks}
mkdir -p data/torrents/{incomplete,watch}
mkdir -p data/usenet/{complete,incomplete,intermediate}

# Set permissions
sudo chown -R $CURRENT_UID:$CURRENT_GID {config,data}
chmod -R 775 {config,data}

# Create simple environment file
echo -e "${BLUE}Creating environment configuration...${NC}"
cat > .env << EOF
# *arr Stack Configuration
PUID=$CURRENT_UID
PGID=$CURRENT_GID
TZ=America/New_York
DATA_PATH=./data
NETWORK_NAME=servarr

# Service Ports
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
LIDARR_PORT=8686
READARR_PORT=8787
QBITTORRENT_PORT=8080
QBITTORRENT_LISTEN_PORT=6881
NZBGET_PORT=6789
BAZARR_PORT=6767
JELLYSEERR_PORT=5055
NOTIFIARR_PORT=5454
FLARESOLVERR_PORT=8191
EOF

# Use VM-optimized docker-compose if it exists, otherwise use the standard one
if [ -f "docker-compose.vm.yml" ]; then
    COMPOSE_FILE="docker-compose.vm.yml"
    echo -e "${BLUE}Using VM-optimized configuration...${NC}"
else
    COMPOSE_FILE="docker-compose.yml"
    echo -e "${BLUE}Using standard configuration...${NC}"
fi

# Pull and start services
echo -e "${BLUE}Pulling Docker images (this may take a while)...${NC}"
docker-compose -f $COMPOSE_FILE pull

echo -e "${BLUE}Starting services...${NC}"
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to start
echo -e "${BLUE}Waiting for services to initialize...${NC}"
sleep 15

# Show status
echo -e "${BLUE}Service Status:${NC}"
docker-compose -f $COMPOSE_FILE ps

# Show final information
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                        Setup Complete!                           ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}🌐 Your services are now available at:${NC}"
echo ""
echo "  📺 Sonarr (TV):         http://$(hostname -I | awk '{print $1}'):8989"
echo "  🎬 Radarr (Movies):     http://$(hostname -I | awk '{print $1}'):7878"
echo "  🎵 Lidarr (Music):      http://$(hostname -I | awk '{print $1}'):8686"
echo "  📚 Readarr (Books):     http://$(hostname -I | awk '{print $1}'):8787"
echo "  🔍 Prowlarr (Indexers): http://$(hostname -I | awk '{print $1}'):9696"
echo "  ⬇️  qBittorrent:         http://$(hostname -I | awk '{print $1}'):8080"
echo "  📰 NZBGet:              http://$(hostname -I | awk '{print $1}'):6789"
echo "  💬 Bazarr (Subtitles):  http://$(hostname -I | awk '{print $1}'):6767"
echo "  🎭 Jellyseerr:          http://$(hostname -I | awk '{print $1}'):5055"
echo "  📢 Notifiarr:           http://$(hostname -I | awk '{print $1}'):5454"
echo "  🔥 Flaresolverr:        http://$(hostname -I | awk '{print $1}'):8191"
echo ""

echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Configure Prowlarr with your indexers"
echo "2. Add qBittorrent as download client in each *arr app"
echo "3. Set up root folders pointing to /data/media/movies, /data/media/tv, etc."
echo "4. Configure quality profiles and import lists"
echo ""

echo -e "${BLUE}🛠️  Management Commands:${NC}"
echo "  Start all:  docker-compose -f $COMPOSE_FILE up -d"
echo "  Stop all:   docker-compose -f $COMPOSE_FILE down"
echo "  View logs:  docker-compose -f $COMPOSE_FILE logs -f [service]"
echo "  Update:     docker-compose -f $COMPOSE_FILE pull && docker-compose -f $COMPOSE_FILE up -d"
echo ""

echo -e "${YELLOW}💡 Tips:${NC}"
echo "- Default qBittorrent login: admin/adminadmin (change this!)"
echo "- All data is stored in the ./data directory"
echo "- Configurations are in the ./config directory"
echo "- Add a firewall rule if accessing from other machines"
echo ""

if groups $CURRENT_USER | grep -q docker; then
    echo -e "${GREEN}✓ Setup complete! All services should be running.${NC}"
else
    echo -e "${YELLOW}⚠️  You may need to log out and back in for Docker group access.${NC}"
    echo -e "${YELLOW}   Or run: newgrp docker${NC}"
fi

echo ""
echo -e "${BLUE}📖 Full documentation available in README.md${NC}"
