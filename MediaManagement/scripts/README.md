# MediaManagement Scripts

This directory contains automation scripts for setting up and managing your media stack.

## Quick Start

**Recommended approach** - Use the all-in-one Python script:

```bash
python3 generate-compose-simple.py
```

This script will:
- Detect and install Docker/Docker Compose if needed
- Create optimized directory structure (Trash Guides compliant)
- Generate docker-compose.yml with your selected services
- Handle VPN configuration automatically
- Set proper permissions

## Available Scripts

### Main Generator (`generate-compose-simple.py`)
**Primary tool** - Complete automation with no external dependencies
- Detects and installs Docker/Docker Compose automatically
- Creates Trash Guides directory structure for optimal hardlinks
- Interactive service selection with VPN support
- Handles permissions and system setup
- No external Python packages required

```bash
python3 generate-compose-simple.py
```

### System Setup (`install-docker-and-update-os.sh`)
**Standalone installer** - Used by main script but can run independently
- Installs Docker and Docker Compose
- Updates system packages
- Adds user to docker group
- Optimizes system for containers

```bash
chmod +x install-docker-and-update-os.sh
sudo ./install-docker-and-update-os.sh
```

## Supported Services

The main generator supports these HomeLab services:

### Management & Monitoring

- **Portainer** - Docker management UI (port 9000)
- **Watchtower** - Automatic container updates

### Reverse Proxy

- **Nginx Proxy Manager** - Easy reverse proxy with SSL (port 81)

### Media Management (*arr stack)

- **Sonarr** - TV show management (port 8989)
- **Radarr** - Movie management (port 7878)  
- **Prowlarr** - Indexer manager (port 9696)

### Download Clients

- **qBittorrent** - Modern torrent client (port 8080)

### Media Servers

- **Jellyfin** - Open source media server (port 8096)

### VPN Support

- **Gluetun** - VPN container for securing download clients

## Directory Structure

The script creates a Trash Guides compliant directory structure for optimal hardlinks:

```text
/mnt/media/
├── media/
│   ├── movies/
│   └── tv/
├── torrents/
│   ├── movies/
│   └── tv/
└── usenet/
    ├── movies/
    └── tv/
```

## Quick Usage

1. **Run the main script**:
   ```bash
   python3 generate-compose-simple.py
   ```

2. **Follow the prompts**:
   - Choose your services
   - Select VPN provider (optional)
   - Configure settings

3. **Start your stack**:
   ```bash
   docker-compose up -d
   ```

4. **Access your services**:
   - Portainer: http://your-server:9000
   - Sonarr: http://your-server:8989
   - Radarr: http://your-server:7878
   - And more...

## Network Share Support

The script can automatically mount and configure network shares for media storage:

### **Automatic NFS Setup**
- Installs nfs-common packages
- Mounts with optimized settings
- Adds to /etc/fstab for persistence

### **Automatic SMB/CIFS Setup**  
- Installs cifs-utils packages
- Securely stores credentials
- Configures proper permissions

### **Manual Configuration**
- Use pre-existing mounts
- Custom mount configurations
- Advanced setups

**Example:**
When prompted for storage, choose network share and provide:
- Share type (NFS/SMB)
- Server IP/hostname
- Share path/name
- Mount options (optional)

## Features

- **Zero dependencies** - Uses only Python standard library
- **Docker auto-install** - Detects and installs Docker if needed
- **VPN integration** - Optional VPN routing for download clients
- **Network share support** - NFS and SMB/CIFS mounting
- **Trash Guides structure** - Optimized directory layout
- **Permission handling** - Automatic PUID/PGID configuration
- **Interactive setup** - User-friendly prompts and configuration

## Tips

- Run as a regular user (script handles sudo when needed)
- Make sure you have internet access for Docker installation
- Use VPN for download clients if accessing public trackers
- Back up your configuration directories regularly

For troubleshooting and advanced configuration, see the main [MediaManagement README](../README.md).
