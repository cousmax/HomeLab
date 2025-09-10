# Media Servers Stack

**Part of the [HomeLab Automation Suite](../README.md) - Complete automation for deploying and managing media server applications including Immich, Jellyfin, Plex, Petio, Tautulli, and Wizarr.**

> 💡 **Other HomeLab Stacks Available:**
> - **[Media Management](../MediaManagement/README.md)** - Complete *arr stack for media automation
> - **[DevTools](../DevTools/README.md)** - Gitea development environment with CI/CD
> - **[NextCloud](../NextCloud/README.md)** - Self-hosted cloud storage

## Quick Start

**Run the generator script:**

```bash
cd "Media Servers/Scripts"
python3 generate-media-servers.py
```

This will:
- Guide you through service selection
- Configure storage paths and environment variables
- Generate docker-compose.yml and .env files
- Create necessary directory structure
- Provide access URLs and setup instructions

## Available Applications

### 📷 **Immich** - Self-hosted Photo Management
- **Port**: 2283
- **Purpose**: Google Photos alternative for personal photo/video management
- **Features**: AI-powered facial recognition, automatic backup, mobile apps
- **Requirements**: PostgreSQL database, Redis cache

### 🎬 **Jellyfin** - Open Source Media Server
- **Port**: 8096
- **Purpose**: Stream movies, TV shows, music to any device
- **Features**: No premium fees, transcoding, live TV, extensive client support
- **Best for**: Users wanting full control and customization

### 📺 **Plex** - Premium Media Server
- **Port**: 32400
- **Purpose**: Feature-rich media streaming platform
- **Features**: Premium features, excellent mobile apps, sharing capabilities
- **Best for**: Users wanting polished experience and premium features

### 🎫 **Petio** - Request Management
- **Port**: 7777
- **Purpose**: User request system for Plex/Jellyfin content
- **Features**: Modern UI, approval workflows, integration with *arr apps
- **Replaces**: Ombi with better performance and features

### 📊 **Tautulli** - Plex Analytics
- **Port**: 8181
- **Purpose**: Monitor and analyze Plex Media Server usage
- **Features**: Viewing statistics, notifications, user management
- **Requirements**: Works with Plex Media Server

### 👥 **Wizarr** - User Management
- **Port**: 5690
- **Purpose**: Automated user invitation system for media servers
- **Features**: Invitation links, user onboarding, server management
- **Integration**: Works with Plex, Jellyfin, and other services

## Scripts

### Main Generator (`generate-media-servers.py`)
**Complete automation** - Handles entire setup process with interactive prompts.

**Features:**
- **Service Selection** - Choose individual services or pre-configured stacks
- **Path Configuration** - Set up media storage, photo uploads, transcoding paths
- **Environment Setup** - Configure user IDs, timezones, service-specific settings
- **Docker Generation** - Create optimized docker-compose.yml files
- **Directory Creation** - Set up required folder structure
- **Security Configuration** - Handle passwords, claim tokens, database settings

**Usage:**
```bash
python3 generate-media-servers.py
```

**Selection Options:**
1. **Full Stack** - All services (complete media ecosystem)
2. **Media Servers Only** - Jellyfin + Plex + Tautulli
3. **Photo Management** - Immich only
4. **Custom Selection** - Pick individual services

### Maintenance Script (`maintain-media-servers.py`)
**Comprehensive maintenance** - Keep your media server stack healthy and updated.

**Features:**
- **Health Monitoring** - Check all service status and container health
- **Storage Monitoring** - Track disk usage for media paths
- **Container Updates** - Pull latest images and restart services
- **Configuration Backup** - Automated backup of all config files
- **Log Management** - View and analyze service logs
- **System Cleanup** - Remove unused Docker resources
- **Service Management** - Start, stop, restart individual or all services

**Usage:**
```bash
# Interactive menu
python3 maintain-media-servers.py

# Command line usage
python3 maintain-media-servers.py health    # Check service status
python3 maintain-media-servers.py update    # Update containers
python3 maintain-media-servers.py restart   # Restart all services
python3 maintain-media-servers.py backup    # Backup configurations
python3 maintain-media-servers.py full      # Run all maintenance tasks
```

## Directory Structure

After running the generator, your directory structure will look like:

```
Media Servers/
├── docker-compose.yml          # Main compose file
├── .env                        # Environment variables (Immich)
├── immich/
│   └── pgdata/                 # PostgreSQL database
├── jellyfin/
│   └── config/                 # Jellyfin configuration
├── plex/
│   └── config/                 # Plex configuration
├── petio/
│   └── config/                 # Petio configuration
├── tautulli/
│   └── config/                 # Tautulli configuration
├── wizarr/
│   └── database/               # Wizarr database
└── Scripts/
    ├── generate-media-servers.py
    ├── maintain-media-servers.py
    └── README.md
```

## Storage Configuration

### Media Library Structure
Recommended structure for media files:
```
/mnt/media/
├── movies/                     # Movie files
├── tv/                         # TV show files
├── music/                      # Music files
├── books/                      # Audiobooks/ebooks
└── photos/                     # Photo library (Immich)
```

### External Storage
The generator supports various storage configurations:
- **Local storage** - Direct attached storage
- **Network shares** - NFS, SMB/CIFS mounts
- **Cloud storage** - Mounted cloud drives
- **Mixed storage** - Different paths for different content types

## Service Integration

### Media Server Workflow
1. **Content Acquisition** - Use separate *arr stack for automation
2. **Media Serving** - Jellyfin/Plex streams content to devices
3. **User Requests** - Petio handles content requests from users
4. **Analytics** - Tautulli monitors usage and provides insights
5. **User Management** - Wizarr handles invitations and onboarding
6. **Photo Management** - Immich handles personal photo/video collections

### Recommended Setup Order
1. **Start with Jellyfin or Plex** - Core media server
2. **Add Tautulli** (if using Plex) - Monitoring and analytics
3. **Add Petio** - User request management
4. **Add Wizarr** - User invitation system
5. **Add Immich** - Photo management (separate from media server)

## Quick Setup Examples

### Home Media Server
```bash
# Select: Media servers only (Jellyfin + Plex + Tautulli)
python3 generate-media-servers.py
```

### Photo Management Only
```bash
# Select: Photo management (Immich)
python3 generate-media-servers.py
```

### Complete Media Ecosystem
```bash
# Select: All services
python3 generate-media-servers.py
```

## Advanced Configuration

### Custom Networks
Services use `mediaserver-network` by default. For integration with other stacks:

```yaml
networks:
  mediaserver-network:
    external: true  # Use existing network
```

### Resource Limits
Add resource limits for better performance:

```yaml
services:
  plex:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
```

### Hardware Acceleration
For GPU transcoding (Plex/Jellyfin):

```yaml
services:
  plex:
    devices:
      - /dev/dri:/dev/dri  # Intel QuickSync
    environment:
      - NVIDIA_VISIBLE_DEVICES=all  # NVIDIA
```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Ensure PUID/PGID match your user
   - Check folder permissions: `chown -R user:group /path/to/media`

2. **Network Issues**
   - Verify firewall settings
   - Check port conflicts: `netstat -tulpn | grep :8096`

3. **Storage Issues**
   - Verify mount points exist
   - Check disk space: `df -h`

4. **Database Issues (Immich)**
   - Check PostgreSQL logs: `docker-compose logs database`
   - Verify database password in .env file

### Health Checks
```bash
# Check all services
python3 maintain-media-servers.py health

# Check specific service logs
docker-compose logs -f jellyfin

# Check resource usage
docker stats
```

## Security Considerations

### Database Security
- Change default PostgreSQL password for Immich
- Use strong, unique passwords
- Regular database backups

### Network Security
- Use reverse proxy with SSL (Traefik, Nginx Proxy Manager)
- Configure firewall rules
- Use VPN for external access

### File Permissions
- Use non-root user (PUID/PGID)
- Restrict config directory access
- Regular permission audits

## Integration with Other Stacks

### With MediaManagement Stack
The media servers can integrate with the *arr stack for complete automation:

1. **MediaManagement** handles content acquisition
2. **Media Servers** handle content delivery
3. **Shared storage** connects both stacks

### External Integrations
- **Reverse Proxy** - Traefik, Nginx Proxy Manager
- **Authentication** - Authelia, Authentik
- **Monitoring** - Prometheus, Grafana
- **Backup Solutions** - Duplicati, Restic

## Support

For issues and questions:
1. Check the maintenance script diagnostics
2. Review Docker logs for specific services
3. Verify configuration files
4. Check storage and permissions

The maintenance script provides comprehensive diagnostics to help identify and resolve common issues.
