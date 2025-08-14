# Check if Gluetun is installed (Docker image present)
check_gluetun_installed() {
	if ! docker images --format '{{.Repository}}' | grep -q '^gluetun$'; then
		echo -e "${RED}Gluetun Docker image is not installed!${NC}"
		echo -e "${YELLOW}Install Gluetun with: docker pull qmcgaw/gluetun${NC}"
		exit 1
	fi
}
#!/bin/bash
# manage.sh: Simple management script for *arr stack
set -e

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
	# shellcheck disable=SC1090
	source "$ENV_FILE"
fi

show_help() {
	echo -e "${BLUE}Usage: $0 [start|stop|restart|status|logs|update|urls|vpn-status|vpn-connectivity|mount-check|backup|restore|clean]${NC}"
	echo -e "${YELLOW}Commands:${NC}"
	echo "  start         Start all services"
	echo "  stop          Stop all services"
	echo "  restart       Restart all services"
	echo "  status        Show service status"
	echo "  logs [app]    Show logs for all services or a specific app"
	echo "  update        Update all containers"
	echo "  urls          Show service URLs"
	echo "  vpn-status    Check Gluetun VPN health and public IP"
	echo "  vpn-connectivity  Check service connectivity from inside Gluetun"
	echo "  mount-check   Check NFS mount status"
	echo "  backup        Backup config and compose files"
	echo "  restore       Restore config from backup"
	echo "  clean         Remove unused containers and images"
}

# Alerting function (webhook or email)
send_alert() {
	MSG="$1"
	if [ -n "$ALERT_WEBHOOK_URL" ]; then
		curl -X POST -H 'Content-Type: application/json' -d "{\"text\": \"$MSG\"}" "$ALERT_WEBHOOK_URL" || echo "Webhook alert failed"
	fi
	if [ -n "$ALERT_EMAIL" ]; then
		echo "$MSG" | mail -s "VPN Alert" "$ALERT_EMAIL" || echo "Email alert failed"
	fi
}

# Check Docker permissions
if ! groups "$USER" | grep -q '\bdocker\b' && [ "$EUID" -ne 0 ]; then
  echo "Error: You must be in the docker group or run as root to use this script."
  read -p "Do you want to add $USER to the docker group automatically? [y/N]: " FIX
  FIX=${FIX,,}
  if [[ "$FIX" == "y" || "$FIX" == "yes" ]]; then
	sudo usermod -aG docker "$USER"
	echo "Added $USER to docker group. Please log out and back in, or run: exec bash -l"
	exit 0
  else
	echo "Please add your user to the docker group manually and re-run the script."
	exit 1
  fi
fi

case "$1" in
	start)
		echo -e "${BLUE}Starting all services...${NC}"
		docker compose up -d && echo -e "${GREEN}✓ All services started.${NC}"
		;;
	stop)
		echo -e "${BLUE}Stopping all services...${NC}"
		docker compose down && echo -e "${GREEN}✓ All services stopped.${NC}"
		;;
	restart)
		echo -e "${BLUE}Restarting all services...${NC}"
		docker compose restart && echo -e "${GREEN}✓ All services restarted.${NC}"
		;;
	status)
		echo -e "${BLUE}Service status:${NC}"
		docker compose ps
		;;
	logs)
		if [ -n "$2" ]; then
			echo -e "${YELLOW}Showing logs for $2...${NC}"
			docker compose logs -f "$2"
		else
			echo -e "${YELLOW}Showing logs for all services...${NC}"
			docker compose logs -f
		fi
		;;
	update)
		echo -e "${BLUE}Updating containers...${NC}"
		docker compose pull && docker compose up -d && echo -e "${GREEN}✓ All containers updated.${NC}"
		;;
	urls)
		echo -e "${BLUE}Service URLs:${NC}"
		printf "${GREEN}Prowlarr:${NC}     http://localhost:%s\n" "${PROWLARR_PORT:-9696}"
		printf "${GREEN}Sonarr:${NC}       http://localhost:%s\n" "${SONARR_PORT:-8989}"
		printf "${GREEN}Radarr:${NC}       http://localhost:%s\n" "${RADARR_PORT:-7878}"
		printf "${GREEN}Lidarr:${NC}       http://localhost:%s\n" "${LIDARR_PORT:-8686}"
		printf "${GREEN}Readarr:${NC}      http://localhost:%s\n" "${READARR_PORT:-8787}"
		printf "${GREEN}qBittorrent:${NC}  http://localhost:%s\n" "${QBITTORRENT_PORT:-8080}"
		printf "${GREEN}NZBGet:${NC}       http://localhost:%s\n" "${NZBGET_PORT:-6789}"
		printf "${GREEN}Bazarr:${NC}       http://localhost:%s\n" "${BAZARR_PORT:-6767}"
		printf "${GREEN}Jellyseerr:${NC}   http://localhost:%s\n" "${JELLYSEERR_PORT:-5055}"
		printf "${GREEN}Notifiarr:${NC}    http://localhost:%s\n" "${NOTIFIARR_PORT:-5454}"
		printf "${GREEN}Flaresolverr:${NC} http://localhost:%s\n" "${FLARESOLVERR_PORT:-8191}"
		;;
	vpn-status)
		check_gluetun_installed
		echo -e "${BLUE}Checking Gluetun VPN status...${NC}"
		if ! docker ps --format '{{.Names}}' | grep -q '^gluetun$'; then
			echo -e "${RED}Gluetun container is not running.${NC}"
			exit 1
		fi
		HEALTH=$(docker inspect --format='{{.State.Health.Status}}' gluetun 2>/dev/null || echo "none")
		echo -e "${YELLOW}Gluetun health: $HEALTH${NC}"
		echo -e "${BLUE}Public IP inside VPN container:${NC}"
		docker exec gluetun curl -s ifconfig.me || echo -e "${RED}(curl failed)${NC}"
		echo -e "${BLUE}Host public IP:${NC}"
		curl -s ifconfig.me || echo -e "${RED}(curl failed)${NC}"
		echo -e "${YELLOW}If the IPs are different, VPN is working.${NC}"
		;;
	vpn-connectivity)
		check_gluetun_installed
		echo -e "${BLUE}Checking service connectivity from inside Gluetun...${NC}"
		if ! docker ps --format '{{.Names}}' | grep -q '^gluetun$'; then
			echo -e "${RED}Gluetun container is not running!${NC}"
			send_alert "Gluetun container is not running!"
			exit 1
		fi
		TEST_URL="${SONARR_URL:-http://sonarr:8989}"
		echo -e "${YELLOW}Testing access to $TEST_URL from Gluetun...${NC}"
		docker exec gluetun curl -s --max-time 10 "$TEST_URL" >/dev/null
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Service connectivity OK.${NC}"
		else
			echo -e "${RED}Service connectivity FAILED!${NC}"
			send_alert "VPN connectivity test failed for $TEST_URL"
			exit 2
		fi
		;;
	mount-check)
		MOUNT_POINT="${NFS_MOUNT_POINT:-/mnt/media}"
		if mount | grep -q "$MOUNT_POINT"; then
			echo -e "${GREEN}NFS mount is active at $MOUNT_POINT.${NC}"
		else
			echo -e "${RED}NFS mount not found at $MOUNT_POINT.${NC}"
		fi
		;;
	backup)
		BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
		mkdir -p "$BACKUP_DIR"
		cp -r config "$BACKUP_DIR/" 2>/dev/null || true
		cp docker-compose.yml "$BACKUP_DIR/" 2>/dev/null || true
		cp .env "$BACKUP_DIR/" 2>/dev/null || true
		echo -e "${GREEN}Backup created at $BACKUP_DIR${NC}"
		;;
	restore)
		echo -e "${BLUE}Available backups:${NC}"
		ls -1d backups/* 2>/dev/null || echo -e "${YELLOW}No backups found.${NC}"
		read -p "Enter backup folder to restore from: " RESTORE_DIR
		if [ -d "$RESTORE_DIR" ]; then
			cp -r "$RESTORE_DIR/config"/* config/ 2>/dev/null || true
			cp "$RESTORE_DIR/docker-compose.yml" ./docker-compose.yml 2>/dev/null || true
			cp "$RESTORE_DIR/.env" ./.env 2>/dev/null || true
			echo -e "${GREEN}Restored from $RESTORE_DIR${NC}"
		else
			echo -e "${RED}Backup folder not found.${NC}"
		fi
		;;
	clean)
		echo -e "${BLUE}Cleaning up unused containers and images...${NC}"
		docker system prune -f && echo -e "${GREEN}Cleanup complete.${NC}"
		;;
	*)
		show_help
		;;
esac
