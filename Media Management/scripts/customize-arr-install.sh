#!/bin/bash

# HomeLab Media Management - Service Customization
# Inspired by Proxmox Helper Scripts design
# Author: cousmax
# License: MIT

function header_info {
clear
cat <<"EOF"
  ______           __                  _          
 / ____/_  _______/ /_____  ____ ___  (_)___  ___ 
/ /   / / / / ___/ __/ __ \/ __ `__ \/ /_  / / _ \
/ /___/ /_/ (__  ) /_/ /_/ / / / / / / / / /_/  __/
\____/\__,_/____/\__/\____/_/ /_/ /_/_/ /___/\___/ 
                                                   
EOF
}

RD='\033[01;31m'
BL='\033[36m'
GN='\033[1;92m'
CL='\033[m'
YW='\033[33m'
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
INFO="${BL}ⓘ${CL}"
WARN="${YW}⚠${CL}"

msg_info() {
    local msg="$1"
    echo -ne " ${INFO} ${msg}..."
}

msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${msg}"
}

msg_error() {
    local msg="$1"
    echo -e "${BFR} ${CROSS} ${msg}"
}

msg_warn() {
    local msg="$1"
    echo -e "${BFR} ${WARN} ${msg}"
}

set -e

COMPOSE_FILE="docker-compose.yml"
CUSTOM_FILE="docker-compose.custom.yml"

# Check for command line arguments to bypass interactive mode
if [[ $# -gt 0 ]]; then
    echo -e "${GREEN}Command line services provided: $*${NC}"
    CHOSEN="$*"
    SKIP_INTERACTIVE=true
else
    SKIP_INTERACTIVE=false
fi

# Show usage help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0                                    # Interactive mode"
    echo -e "  $0 prowlarr sonarr radarr            # Direct service selection"
    echo -e "  $0 --preset basic                    # Use basic preset"
    echo -e "  $0 --preset complete                 # Use complete preset"
    echo
    echo -e "${BLUE}Available presets:${NC}"
    echo -e "  basic:    prowlarr sonarr radarr qbittorrent gluetun"
    echo -e "  complete: gluetun prowlarr sonarr radarr lidarr bazarr qbittorrent nzbget jellyseerr"
    echo -e "  tv:       gluetun prowlarr sonarr qbittorrent"
    echo -e "  movies:   gluetun prowlarr radarr qbittorrent"
    exit 0
fi

# Handle preset selections
if [[ "$1" == "--preset" ]]; then
    case "$2" in
        basic)
            CHOSEN="prowlarr sonarr radarr qbittorrent gluetun"
            ;;
        complete)
            CHOSEN="gluetun prowlarr sonarr radarr lidarr bazarr qbittorrent nzbget jellyseerr"
            ;;
        tv)
            CHOSEN="gluetun prowlarr sonarr qbittorrent"
            ;;
        movies)
            CHOSEN="gluetun prowlarr radarr qbittorrent"
            ;;
        *)
            echo -e "${RED}Unknown preset: $2${NC}"
            echo "Available presets: basic, complete, tv, movies"
            exit 1
            ;;
    esac
    echo -e "${GREEN}Using preset '$2': $CHOSEN${NC}"
    SKIP_INTERACTIVE=true
fi

# Check if docker-compose.yml exists, if not try to find it in parent directory
if ! [ -f "$COMPOSE_FILE" ]; then
    if [ -f "../docker-compose.yml" ]; then
        echo -e "${YELLOW}Found docker-compose.yml in parent directory, copying...${NC}"
        cp "../docker-compose.yml" "$COMPOSE_FILE"
    elif [ -f "../../docker-compose.yml" ]; then
        echo -e "${YELLOW}Found docker-compose.yml in grandparent directory, copying...${NC}"
        cp "../../docker-compose.yml" "$COMPOSE_FILE"
    else
        echo -e "${RED}Error: $COMPOSE_FILE not found in current, parent, or grandparent directory.${NC}"
        echo -e "${YELLOW}Please ensure docker-compose.yml is available in the working directory.${NC}"
        exit 1
    fi
fi

# Extract service names from the compose file
SERVICES=($(awk '/^  [a-zA-Z0-9_-]+:$/ {gsub(":",""); print $2}' "$COMPOSE_FILE"))

header_info
echo -e " ${BL}Service Selection & Stack Customization${CL}"
echo -e " ${YW}Choose which services to include in your media stack${CL}"
echo

echo -e " ${GN}📋 CORE SERVICES${CL}"
echo -e " ├─ ${BL}gluetun${CL}      VPN container for secure downloads"
echo -e " ├─ ${BL}prowlarr${CL}     Indexer management (finds content)"
echo -e " ├─ ${BL}sonarr${CL}       TV show automation"
echo -e " └─ ${BL}radarr${CL}       Movie automation"
echo

echo -e " ${GN}📥 DOWNLOAD CLIENTS${CL}"
echo -e " ├─ ${BL}qbittorrent${CL}  Torrent client (uses VPN)"
echo -e " └─ ${BL}nzbget${CL}       Usenet client (uses VPN)"
echo

echo -e " ${GN}🎵 ADDITIONAL MEDIA${CL}"
echo -e " ├─ ${BL}lidarr${CL}       Music automation"
echo -e " ├─ ${BL}bazarr${CL}       Subtitle management"
echo -e " └─ ${BL}jellyseerr${CL}   Media request interface"
echo

echo -e " ${GN}🔧 OPTIONAL SERVICES${CL}"
echo -e " ├─ ${BL}ytdl-sub${CL}     YouTube downloader"
echo -e " └─ ${BL}deunhealth${CL}   Container health monitoring"
echo

echo -e " ${YW}💡 EXAMPLE CONFIGURATIONS${CL}"
echo -e " ${GN}Basic:${CL}     prowlarr sonarr radarr qbittorrent gluetun"
echo -e " ${GN}Complete:${CL}  gluetun prowlarr sonarr radarr lidarr bazarr qbittorrent nzbget jellyseerr"
echo -e " ${GN}TV Only:${CL}   gluetun prowlarr sonarr qbittorrent"
echo -e " ${GN}No VPN:${CL}    prowlarr sonarr radarr"
echo

echo -e " ${WARN} Include 'gluetun' for VPN protection with download clients"
echo -e " ${INFO} 'prowlarr' is recommended as your indexer manager"
echo

echo -ne " ${BL}Enter services (space-separated):${CL} "

# Skip interactive input if command line arguments were provided
if [[ "$SKIP_INTERACTIVE" == "true" ]]; then
    echo -e "${CHOSEN}"
    msg_ok "Using command line selection: $CHOSEN"
else
    # Try multiple input methods to handle different terminal situations
    CHOSEN=""

    # Check if we're in a proper interactive terminal
    if [[ -t 0 && -t 1 ]]; then
        # Use a simple read without timeout
        if read -r CHOSEN_INPUT; then
            CHOSEN="$CHOSEN_INPUT"
        else
            msg_warn "Read failed, falling back to preset menu"
            CHOSEN=""
        fi
    else
        # Non-interactive or piped mode - provide default selection
        msg_warn "Non-interactive mode detected"
        CHOSEN="prowlarr sonarr radarr qbittorrent gluetun"
        echo -e "${CHOSEN}"
        msg_ok "Auto-selected basic configuration"
        sleep 2
    fi
fi

# If input is empty, offer suggestions
if [[ -z "$CHOSEN" ]]; then
    echo -e "${RED}No services selected!${NC}"
    echo -e "${YELLOW}Would you like to use one of these preset configurations?${NC}"
    echo -e "${GREEN}1.${NC} Basic setup: prowlarr sonarr radarr qbittorrent gluetun"
    echo -e "${GREEN}2.${NC} Complete stack: gluetun prowlarr sonarr radarr lidarr bazarr qbittorrent nzbget jellyseerr"
    echo -e "${GREEN}3.${NC} TV only: gluetun prowlarr sonarr qbittorrent"
    echo -e "${GREEN}4.${NC} Movies only: gluetun prowlarr radarr qbittorrent"
    echo -e "${GREEN}5.${NC} Custom (try again)"
    
    if [[ -t 0 ]]; then
        read -p "Select preset (1-5): " preset_choice
        case $preset_choice in
            1) CHOSEN="prowlarr sonarr radarr qbittorrent gluetun" ;;
            2) CHOSEN="gluetun prowlarr sonarr radarr lidarr bazarr qbittorrent nzbget jellyseerr" ;;
            3) CHOSEN="gluetun prowlarr sonarr qbittorrent" ;;
            4) CHOSEN="gluetun prowlarr radarr qbittorrent" ;;
            5) 
                echo -e "${YELLOW}Enter your custom selection:${NC}"
                read -r CHOSEN
                ;;
            *) 
                echo -e "${YELLOW}Invalid choice, using basic setup...${NC}"
                CHOSEN="prowlarr sonarr radarr qbittorrent gluetun" 
                ;;
        esac
    else
        echo -e "${YELLOW}Using basic setup in non-interactive mode...${NC}"
        CHOSEN="prowlarr sonarr radarr qbittorrent gluetun"
    fi
    
    echo -e "${GREEN}Selected: $CHOSEN${NC}"
fi

# Validate selection
CHOSEN_SERVICES=()
for s in $CHOSEN; do
	if [[ " ${SERVICES[*]} " == *" $s "* ]]; then
		CHOSEN_SERVICES+=("$s")
	else
		echo "Warning: '$s' is not a valid service name. Skipping."
	fi

done
if [ ${#CHOSEN_SERVICES[@]} -eq 0 ]; then
	echo -e "${RED}No valid services selected. Exiting.${NC}"
	exit 1
fi

# Copy networks section
awk '/^networks:/,/^services:/' "$COMPOSE_FILE" > "$CUSTOM_FILE"

# Add services section
echo "services:" >> "$CUSTOM_FILE"

# Determine if Gluetun is selected
GLUETUN_SELECTED=false
for s in "${CHOSEN_SERVICES[@]}"; do
	if [[ "$s" == "gluetun" ]]; then
		GLUETUN_SELECTED=true
		break
	fi
done

# Copy only selected services, patching network_mode as needed
for s in "${CHOSEN_SERVICES[@]}"; do
	# Extract service block
	SERVICE_BLOCK=$(awk "/^  $s:/,/^  [a-zA-Z0-9_-]+:/" "$COMPOSE_FILE" | sed "/^  [a-zA-Z0-9_-]+:/q" | grep -v '^$')
	# Patch network_mode for passthrough if Gluetun is selected and service is nzbget or qbittorrent
	if $GLUETUN_SELECTED && ([[ "$s" == "nzbget" ]] || [[ "$s" == "qbittorrent" ]]); then
		# Remove any existing network_mode or networks lines
		SERVICE_BLOCK=$(echo "$SERVICE_BLOCK" | grep -v '^    network_mode:' | grep -v '^    networks:')
		# Add network_mode: service:gluetun
		SERVICE_BLOCK=$(echo "$SERVICE_BLOCK" | sed "/^    restart:/a\    network_mode: service:gluetun")
	elif ! $GLUETUN_SELECTED; then
		# Remove any existing network_mode lines
		SERVICE_BLOCK=$(echo "$SERVICE_BLOCK" | grep -v '^    network_mode:')
		# If not Gluetun, ensure all services use servarrnetwork
		if ! echo "$SERVICE_BLOCK" | grep -q '^    networks:'; then
			SERVICE_BLOCK=$(echo "$SERVICE_BLOCK" | sed "/^    restart:/a\    networks:\n      servarrnetwork:")
		fi
	fi
	echo "$SERVICE_BLOCK" >> "$CUSTOM_FILE"
done

# Print result
cat <<EOF
${GREEN}Custom compose file created: $CUSTOM_FILE${NC}
To use it, run:
	docker compose -f $CUSTOM_FILE up -d
EOF

read -p "Do you want to start your custom stack now? [y/N]: " RUN_COMPOSE
RUN_COMPOSE=${RUN_COMPOSE,,}
if [[ "$RUN_COMPOSE" == "y" || "$RUN_COMPOSE" == "yes" ]]; then
	echo -e "${BLUE}Starting custom stack...${NC}"
	docker compose -f "$CUSTOM_FILE" up -d && echo -e "${GREEN}Custom stack started.${NC}"
fi
...existing code from customize-arr-install.sh...
