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
- **Step-by-step confirmations** with retry capabilities
- **Network share mounting** with error recovery
- **Automated service startup** and health verification
- Handles permissions and system setup
- No external Python packages required

```bash
python3 generate-compose-simple.py
```

### Maintenance Script (`maintain-stack.py`)
**Comprehensive maintenance** - Keep your stack healthy and up-to-date
- **Health monitoring** - Check service status and container health
- **Automatic updates** - Pull latest images and restart services
- **System cleanup** - Remove unused containers, images, volumes, networks
- **Configuration backup** - Automated backups with rotation (keeps last 5)
- **Configuration restore** - Restore from any backup with safety checks
- **Disk usage monitoring** - Track space usage and clean large logs
- **Service log viewing** - Interactive log browser for troubleshooting
- **Full maintenance mode** - Run all tasks automatically

```bash
# Interactive menu
python3 maintain-stack.py

# Command line usage
python3 maintain-stack.py health    # Check service health
python3 maintain-stack.py update    # Update container images  
python3 maintain-stack.py cleanup   # Clean up system
python3 maintain-stack.py backup    # Backup configurations
python3 maintain-stack.py restore   # Restore from backup
python3 maintain-stack.py full      # Run all maintenance tasks
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

## Enhanced User Experience

The script now includes comprehensive safeguards and user-friendly features:

### **Configuration Confirmations**
- **Summary displays** before each major step
- **Full details** for network share configurations
- **Service selection review** with descriptions
- **Easy reconfiguration** if mistakes are spotted

### **Intelligent Retry System**
- **3 attempts** for network share mounting
- **Error-specific troubleshooting** suggestions
- **Connectivity testing** before mount attempts
- **Fallback options** when things don't work

### **Built-in Problem Solving**
- **NFS troubleshooting** - Port checks, export validation
- **SMB troubleshooting** - Credential verification, protocol suggestions
- **Mount verification** - Read/write testing after mounting
- **Clear error messages** with actionable solutions

This makes the script forgiving of configuration mistakes and provides clear guidance when issues occur.

### **Automated Service Management**

The script now handles complete service lifecycle:

- **Smart Docker Group Handling** - Uses `newgrp docker` when needed to avoid sudo requirements
- **Automatic Service Startup** - Optionally starts the compose stack after generation  
- **Service Health Verification** - Checks that all services are running properly
- **Failure Troubleshooting** - Shows logs for any services that don't start correctly
- **Status Reporting** - Clear indicators of which services are healthy vs problematic

### **Complete Workflow**

1. **Configuration** - Interactive setup with confirmations
2. **Generation** - Create compose file and directory structure  
3. **Startup** - Optional automatic service startup
4. **Verification** - Health check all running services
5. **Troubleshooting** - Automatic diagnosis of any issues

The script now provides a complete end-to-end solution from configuration to running services.

## Features

- **Zero dependencies** - Uses only Python standard library
- **Docker auto-install** - Detects and installs Docker if needed
- **VPN integration** - Optional VPN routing for download clients
- **Network share support** - NFS and SMB/CIFS mounting
- **Trash Guides structure** - Optimized directory layout
- **Permission handling** - Automatic PUID/PGID configuration
- **Interactive setup** - User-friendly prompts and configuration
- **Smart confirmations** - Review settings before proceeding
- **Retry capabilities** - Multiple attempts with error recovery

## Tips

- Run as a regular user (script handles sudo when needed)
- Make sure you have internet access for Docker installation
- Use VPN for download clients if accessing public trackers
- Back up your configuration directories regularly

For troubleshooting and advanced configuration, see the main [MediaManagement README](../README.md).
