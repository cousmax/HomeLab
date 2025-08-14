#!/bin/bash
# customize-arr-install.sh: interactively select which containers to include in your stack
set -e

COMPOSE_FILE="docker-compose.yml"
CUSTOM_FILE="docker-compose.custom.yml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if ! [ -f "$COMPOSE_FILE" ]; then
	echo "Error: $COMPOSE_FILE not found."
	exit 1
fi

# Extract service names from the compose file
SERVICES=($(awk '/^  [a-zA-Z0-9_-]+:$/ {gsub(":",""); print $2}' "$COMPOSE_FILE"))

echo -e "${BLUE}Available services:${NC}"
for s in "${SERVICES[@]}"; do
	echo -e "  ${GREEN}- $s${NC}"
done

echo -e "${YELLOW}Choose which services to include (space-separated, e.g. 'sonarr radarr qbittorrent'):${NC}"
read -r CHOSEN

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
