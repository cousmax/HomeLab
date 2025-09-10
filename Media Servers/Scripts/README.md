# Media Server Scripts

**Part of the [HomeLab Automation Suite](../../README.md) - Automation scripts for deploying and managing media server applications.**

> 💡 **Also Available in HomeLab Suite:**
> - **[Media Management Stack](../../MediaManagement/README.md)** - Complete *arr stack for media automation
> - **[DevTools Stack](../../DevTools/README.md)** - Gitea development environment with CI/CD
> - **[NextCloud](../../NextCloud/README.md)** - Self-hosted cloud storage

## Scripts Overview

### `generate-media-servers.py`
**Main generator script** - Complete automation for media server stack deployment.

**Features:**
- Interactive service selection (Immich, Jellyfin, Plex, Petio, Tautulli, Wizarr)
- Storage path configuration
- Environment variable setup
- Docker Compose file generation
- Directory structure creation
- Service-specific configuration

**Usage:**
```bash
python3 generate-media-servers.py
```

### `maintain-media-servers.py`
**Maintenance script** - Keep your media server stack healthy and updated.

**Features:**
- Service health monitoring
- Container image updates
- Storage usage checks
- Configuration backups
- Log management
- System cleanup

**Usage:**
```bash
# Interactive mode
python3 maintain-media-servers.py

# Command line mode
python3 maintain-media-servers.py [command]
```

**Available Commands:**
- `health` - Check service status
- `update` - Update container images
- `restart` - Restart all services
- `storage` - Check disk usage
- `backup` - Backup configurations
- `logs` - Show service logs
- `cleanup` - Clean Docker system
- `urls` - Show service URLs
- `full` - Run all maintenance tasks

## Quick Start

1. **Generate your stack:**
   ```bash
   python3 generate-media-servers.py
   ```

2. **Start the services:**
   ```bash
   docker-compose up -d
   ```

3. **Monitor and maintain:**
   ```bash
   python3 maintain-media-servers.py
   ```

## Service Ports

- **Immich**: 2283 (Photo management)
- **Jellyfin**: 8096 (Media server)
- **Plex**: 32400 (Media server)
- **Petio**: 7777 (Request management)
- **Tautulli**: 8181 (Plex analytics)
- **Wizarr**: 5690 (User management)

## Requirements

- Python 3.6+
- Docker and Docker Compose
- Appropriate storage paths configured
- Network access for container pulls

For detailed information, see the main [Media Servers README](../README.md).
