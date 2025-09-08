# Dynamic Docker Compose Generators

This directory contains several tools for dynamically creating Docker Compose files for your HomeLab setup.

## Available Generators

### 1. Bash Script (`generate-compose.sh`)
- **No dependencies required**
- Interactive bash script
- Creates docker-compose.yml with selected services
- Supports all major HomeLab services

```bash
chmod +x generate-compose.sh
./generate-compose.sh
```

### 2. Simple Python Script (`generate-compose-simple.py`)
- **No external dependencies** (uses only Python stdlib)
- Clean, simple interface
- Template-based generation
- Creates .env file for variables

```bash
python3 generate-compose-simple.py
```

### 3. Advanced Python Script (`generate-compose.py`)
- **Requires PyYAML** (`pip install -r requirements.txt`)
- More advanced features
- JSON configuration saving/loading
- Better error handling

```bash
pip install -r requirements.txt
python3 generate-compose.py
```

## Supported Services

All generators support these popular HomeLab services:

### Management & Monitoring
- **Portainer** - Docker management UI (port 9000)
- **Watchtower** - Automatic container updates

### Reverse Proxy
- **Nginx Proxy Manager** - Easy reverse proxy with SSL (port 81)
- **Traefik** - Modern reverse proxy (advanced version only)

### Media Management (*arr stack)
- **Sonarr** - TV show management (port 8989)
- **Radarr** - Movie management (port 7878)  
- **Prowlarr** - Indexer manager (port 9696)

### Download Clients
- **qBittorrent** - Modern torrent client (port 8080)
- **Transmission** - Lightweight torrent client (port 9091)

### Media Servers
- **Jellyfin** - Open source media server (port 8096)

## Features

### Configuration Options
- **Timezone** - Set your local timezone
- **PUID/PGID** - User and group IDs for file permissions
- **Data Path** - Where to store media files
- **Config Path** - Where to store application configs
- **Domain** - Your domain name (for reverse proxy)

### Directory Structure Created
```
./data/
├── movies/
├── tv/
├── downloads/
├── music/
└── books/

./config/
├── sonarr/
├── radarr/
├── prowlarr/
├── qbittorrent/
├── jellyfin/
├── portainer/
└── nginx-proxy-manager/
```

### Generated Files
- `docker-compose.yml` - Main compose file
- `.env` - Environment variables (Python versions)
- `compose-config.json` - Saved configuration (advanced version)

## Usage Examples

### Quick Start (Bash)
```bash
# Make executable and run
chmod +x generate-compose.sh
./generate-compose.sh

# Follow prompts to select services
# Generated compose file will be ready to use
docker-compose up -d
```

### Quick Start (Python Simple)
```bash
# Run the simple Python generator
python3 generate-compose-simple.py

# Select your services interactively
# Start your stack
docker-compose up -d
```

### Advanced Usage (Python Advanced)
```bash
# Install dependencies
pip install -r requirements.txt

# Run advanced generator
python3 generate-compose.py

# Configuration is saved for reuse
# Modify compose-config.json for automation
```

## Automation Examples

### Headless Generation (Bash)
You can automate the bash script by pre-setting environment variables:

```bash
export TIMEZONE="America/New_York"
export PUID="1000"
export PGID="1000"
export DATA_PATH="./data"
export CONFIG_PATH="./config"

# Then modify the script to read these variables
```

### Configuration File (Advanced Python)
Create `compose-config.json` for automated runs:

```json
{
  "timezone": "America/New_York",
  "puid": "1000",
  "pgid": "1000", 
  "data_path": "./data",
  "config_path": "./config",
  "domain": "homelab.local",
  "email": "admin@homelab.local"
}
```

### Programmatic Service Selection
Modify the Python scripts to accept command-line arguments:

```bash
python3 generate-compose-simple.py --services portainer,sonarr,radarr,jellyfin
```

## Tips & Best Practices

### File Permissions
Make sure your PUID/PGID match your user:
```bash
id $USER  # Shows your UID/GID
```

### Directory Paths
- Use absolute paths in production
- Ensure directories exist and have proper permissions
- Consider using Docker volumes for important data

### Service Dependencies
Some services work better together:
- Sonarr + Radarr + Prowlarr + qBittorrent (full *arr stack)
- Nginx Proxy Manager + any web services (for SSL/domains)
- Watchtower + any services (for auto-updates)

### Network Configuration
All services use the `homelab` Docker network for easy communication between containers.

### Security Considerations
- Change default passwords immediately
- Use strong passwords
- Consider VPN access for external exposure
- Regular backups of config directories

## Troubleshooting

### Common Issues
1. **Permission denied**: Check PUID/PGID settings
2. **Port conflicts**: Ensure no other services use the same ports
3. **Directory not found**: Verify paths exist and are accessible
4. **Container won't start**: Check Docker logs: `docker-compose logs [service]`

### Getting Help
- Check service logs: `docker-compose logs -f [service_name]`
- Verify network: `docker network ls`
- Check running containers: `docker-compose ps`

## Customization

Feel free to modify these scripts for your specific needs:
- Add new services by creating templates
- Modify port mappings
- Add custom environment variables
- Integrate with your existing infrastructure

The scripts are designed to be educational and easily extensible!
