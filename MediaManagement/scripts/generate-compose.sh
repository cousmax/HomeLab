#!/usr/bin/env bash
# Dynamic Docker Compose Generator Script
# Generates docker-compose.yml files based on user input and templates

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Helper functions
print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_step() { echo -e "${WHITE}→ $1${NC}"; }

# Configuration
COMPOSE_DIR="$(pwd)"
COMPOSE_FILE="docker-compose.yml"
CONFIG_FILE="compose-config.env"

# Default values
DEFAULT_TIMEZONE="America/New_York"
DEFAULT_PUID="1000"
DEFAULT_PGID="1000"
DEFAULT_DATA_PATH="./data"
DEFAULT_CONFIG_PATH="./config"

print_header "Dynamic Docker Compose Generator"

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    read -p "$(echo -e "${BLUE}$prompt${NC} [${YELLOW}$default${NC}]: ")" input
    eval "$var_name=\"\${input:-$default}\""
}

# Function to ask yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="$2"
    
    while true; do
        read -p "$(echo -e "${BLUE}$prompt${NC} [${YELLOW}$default${NC}]: ")" yn
        yn=${yn:-$default}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Please answer yes or no.${NC}";;
        esac
    done
}

# Collect configuration
print_step "Gathering configuration..."
get_input "Enter timezone" "$DEFAULT_TIMEZONE" "TIMEZONE"
get_input "Enter PUID (User ID)" "$DEFAULT_PUID" "PUID"
get_input "Enter PGID (Group ID)" "$DEFAULT_PGID" "PGID"
get_input "Enter data directory path" "$DEFAULT_DATA_PATH" "DATA_PATH"
get_input "Enter config directory path" "$DEFAULT_CONFIG_PATH" "CONFIG_PATH"

# Service selection
print_step "Selecting services to include..."

SERVICES=()
if ask_yes_no "Include Portainer (Docker management UI)?" "y"; then
    SERVICES+=("portainer")
fi

if ask_yes_no "Include Watchtower (Auto container updates)?" "y"; then
    SERVICES+=("watchtower")
fi

if ask_yes_no "Include Nginx Proxy Manager?" "n"; then
    SERVICES+=("nginx-proxy-manager")
fi

if ask_yes_no "Include Sonarr (TV Shows)?" "n"; then
    SERVICES+=("sonarr")
fi

if ask_yes_no "Include Radarr (Movies)?" "n"; then
    SERVICES+=("radarr")
fi

if ask_yes_no "Include Prowlarr (Indexer manager)?" "n"; then
    SERVICES+=("prowlarr")
fi

if ask_yes_no "Include qBittorrent?" "n"; then
    SERVICES+=("qbittorrent")
fi

if ask_yes_no "Include Jellyfin (Media server)?" "n"; then
    SERVICES+=("jellyfin")
fi

# Generate compose file
print_step "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" << EOF
version: '3.8'

services:
EOF

# Generate each service
for service in "${SERVICES[@]}"; do
    case $service in
        "portainer")
            cat >> "$COMPOSE_FILE" << EOF

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${CONFIG_PATH}/portainer:/data
    environment:
      - TZ=${TIMEZONE}
EOF
            ;;
        "watchtower")
            cat >> "$COMPOSE_FILE" << EOF

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - TZ=${TIMEZONE}
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
EOF
            ;;
        "nginx-proxy-manager")
            cat >> "$COMPOSE_FILE" << EOF

  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "81:81"
    volumes:
      - ${CONFIG_PATH}/nginx-proxy-manager:/data
      - ${CONFIG_PATH}/nginx-proxy-manager/letsencrypt:/etc/letsencrypt
    environment:
      - TZ=${TIMEZONE}
EOF
            ;;
        "sonarr")
            cat >> "$COMPOSE_FILE" << EOF

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    ports:
      - "8989:8989"
    volumes:
      - ${CONFIG_PATH}/sonarr:/config
      - ${DATA_PATH}/tv:/tv
      - ${DATA_PATH}/downloads:/downloads
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TIMEZONE}
EOF
            ;;
        "radarr")
            cat >> "$COMPOSE_FILE" << EOF

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    restart: unless-stopped
    ports:
      - "7878:7878"
    volumes:
      - ${CONFIG_PATH}/radarr:/config
      - ${DATA_PATH}/movies:/movies
      - ${DATA_PATH}/downloads:/downloads
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TIMEZONE}
EOF
            ;;
        "prowlarr")
            cat >> "$COMPOSE_FILE" << EOF

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    restart: unless-stopped
    ports:
      - "9696:9696"
    volumes:
      - ${CONFIG_PATH}/prowlarr:/config
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TIMEZONE}
EOF
            ;;
        "qbittorrent")
            cat >> "$COMPOSE_FILE" << EOF

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "6881:6881"
      - "6881:6881/udp"
    volumes:
      - ${CONFIG_PATH}/qbittorrent:/config
      - ${DATA_PATH}/downloads:/downloads
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TIMEZONE}
      - WEBUI_PORT=8080
EOF
            ;;
        "jellyfin")
            cat >> "$COMPOSE_FILE" << EOF

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    volumes:
      - ${CONFIG_PATH}/jellyfin:/config
      - ${DATA_PATH}/movies:/data/movies
      - ${DATA_PATH}/tv:/data/tv
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TIMEZONE}
EOF
            ;;
    esac
done

# Add networks section if needed
cat >> "$COMPOSE_FILE" << EOF

networks:
  default:
    name: homelab
    driver: bridge
EOF

# Create directories
print_step "Creating required directories..."
mkdir -p "$DATA_PATH"/{movies,tv,downloads}
mkdir -p "$CONFIG_PATH"

for service in "${SERVICES[@]}"; do
    case $service in
        "portainer"|"nginx-proxy-manager"|"sonarr"|"radarr"|"prowlarr"|"qbittorrent"|"jellyfin")
            mkdir -p "$CONFIG_PATH/$service"
            ;;
    esac
done

# Save configuration for future use
cat > "$CONFIG_FILE" << EOF
# Generated configuration
TIMEZONE=$TIMEZONE
PUID=$PUID
PGID=$PGID
DATA_PATH=$DATA_PATH
CONFIG_PATH=$CONFIG_PATH
SERVICES="${SERVICES[*]}"
EOF

print_success "Docker Compose file generated successfully!"
print_info "File location: $(pwd)/$COMPOSE_FILE"
print_info "Configuration saved to: $(pwd)/$CONFIG_FILE"

echo ""
print_info "Next steps:"
echo -e "${WHITE}  1. Review the generated $COMPOSE_FILE${NC}"
echo -e "${WHITE}  2. Modify any settings as needed${NC}"
echo -e "${WHITE}  3. Run: ${YELLOW}docker-compose up -d${NC}"
echo -e "${WHITE}  4. Access services on their respective ports${NC}"

echo ""
print_warning "Service URLs (once running):"
for service in "${SERVICES[@]}"; do
    case $service in
        "portainer") echo -e "${WHITE}  - Portainer: ${CYAN}http://localhost:9000${NC}";;
        "nginx-proxy-manager") echo -e "${WHITE}  - Nginx Proxy Manager: ${CYAN}http://localhost:81${NC}";;
        "sonarr") echo -e "${WHITE}  - Sonarr: ${CYAN}http://localhost:8989${NC}";;
        "radarr") echo -e "${WHITE}  - Radarr: ${CYAN}http://localhost:7878${NC}";;
        "prowlarr") echo -e "${WHITE}  - Prowlarr: ${CYAN}http://localhost:9696${NC}";;
        "qbittorrent") echo -e "${WHITE}  - qBittorrent: ${CYAN}http://localhost:8080${NC}";;
        "jellyfin") echo -e "${WHITE}  - Jellyfin: ${CYAN}http://localhost:8096${NC}";;
    esac
done
