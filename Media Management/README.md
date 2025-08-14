# *arr Stack with TRASHguides Structure

A complete media automation stack using Docker Compose, configured with TRASHguides best practices, NFS storage from TrueNAS, and AirVPN protection for download clients.

## ✅ Current Status
- **Docker Stack**: ✅ Working
- **VPN Routing**: ✅ Handled by router
- **NFS Storage**: ✅ Mounted from TrueNAS (10.84.2.60)
- **All Services**: ✅ Running and accessible

## 🚀 Quick Start

1. **Initial Setup** (requires sudo for NFS mounting):
   ```bash
   sudo ./setup.sh
   ```

2. **Start Services**:
   ```bash
   ./manage.sh start
   ```
   On Windows PowerShell:
   ```powershell
   ./manage.ps1 start
   ```

3. **Check Status**:
   ```bash
   ./manage.sh status
   ```

## 🌐 Service Access

### Services (Router-based VPN)
- **Prowlarr**: http://localhost:9696 (Indexer management)
- **qBittorrent**: http://localhost:8080 (Torrent client)  
- **NZBGet**: http://localhost:6789 (Usenet client)

### Direct Access Services
- **Sonarr**: http://localhost:8989 (TV Shows)
- **Radarr**: http://localhost:7878 (Movies)
- **Lidarr**: http://localhost:8686 (Music)
- **Readarr**: http://localhost:8787 (Books)
- **Bazarr**: http://localhost:6767 (Subtitles)
- **Jellyseerr**: http://localhost:5055 (Request management)
- **Notifiarr**: http://localhost:5454 (Notifications)
- **Flaresolverr**: http://localhost:8191 (Cloudflare solver)

## 📁 Storage Structure


### NFS Storage (Customizable)
```
/mnt/media/                 # NFS mounted from your NAS (e.g., 192.168.1.100)
├── media/                  # Final media library
│   ├── movies/            # Radarr movies
│   ├── tv/                # Sonarr TV shows
│   ├── music/             # Lidarr music
│   ├── books/             # Readarr books
│   └── audiobooks/        # Readarr audiobooks
├── torrents/              # Torrent downloads
│   ├── movies/            # Movie downloads
│   ├── tv/                # TV downloads
│   ├── music/             # Music downloads
│   ├── books/             # Book downloads
│   ├── audiobooks/        # Audiobook downloads
│   ├── incomplete/        # Active torrents
│   └── watch/             # Watch folder
└── usenet/                # NZBGet downloads (now using NFS)
   ├── complete/          # Completed downloads
   ├── incomplete/        # Active downloads
   └── intermediate/      # Processing directory
```
*Both the NFS IP address and mount location can be customized in your `.env` file and setup scripts.*

## 🐳 Included Services

| Service | Port | Purpose |
|---------|------|---------|
| Prowlarr | 9696 | Indexer management |
| Sonarr | 8989 | TV show automation |
| Radarr | 7878 | Movie automation |
| Lidarr | 8686 | Music automation |
| Readarr | 8787 | Book automation |
| qBittorrent | 8080 | Torrent client |
| NZBGet | 6789 | Usenet client |
| Bazarr | 6767 | Subtitle management |
| Jellyseerr | 5055 | Media request management |
| Notifiarr | 5454 | Notification system |
| Flaresolverr | 8191 | Cloudflare bypass |

## 🛠️ Management Commands

```bash
# Quick management
./manage.sh start          # Start all services
./manage.sh stop           # Stop all services
./manage.sh status         # Show service status
./manage.sh logs [app]     # View logs
./manage.sh update         # Update containers
./manage.sh urls           # Show all URLs
./manage.sh vpn-status     # Check VPN connection status

# Maintenance
./manage.sh backup         # Backup configs
./manage.sh fix-perms      # Fix permissions
./manage.sh mount-check    # Check NFS mount
./manage.sh clean          # Clean up Docker
```

## ⚙️ Configuration

### Environment Variables (.env)
- `NFS_SERVER`: NAS IP (e.g., 192.168.1.100)
- `NFS_SHARE`: Share path (e.g., /mnt/yourshare)
- `PUID/PGID`: User/Group IDs (1000)
- `TZ`: Timezone
 - `DATA_PATH`: Host media path (default /mnt/media)
 - Ports (override if needed): `PROWLARR_PORT`, `SONARR_PORT`, etc.
 - `NETWORK_NAME`: Custom Docker network name

Copy `.env.example` to `.env` and adjust values as needed.

### Compose Profiles
- `core`: Prowlarr, Sonarr, Radarr
- `torrent`: qBittorrent
- `usenet`: NZBGet
- `extras`: Lidarr, Readarr, Bazarr, Jellyseerr, Notifiarr, Flaresolverr

Enable/disable with Compose profiles env var:
```bash
export COMPOSE_PROFILES=core,torrent,usenet,extras
docker compose up -d
```
PowerShell:
```powershell
$env:COMPOSE_PROFILES = 'core,torrent,usenet,extras'
docker compose up -d
```

### First-Time Setup
1. Run `sudo ./setup.sh` to mount NFS and create folders
2. Start services with `./manage.sh start`
3. Configure Prowlarr with indexers
4. Add download client (qBittorrent) to *arr apps
5. Set up root folders and quality profiles
6. Import TRASHguides custom formats



## 📖 Service Guides

- [NZBGet Guide](GUIDE_NZBGet.md)
- [Gluetun Guide](GUIDE_Gluetun.md)
- [qBittorrent Guide](GUIDE_qBittorrent.md)

---

**[Configuration Guide](CONFIGURATION_GUIDE.md)** - Detailed setup instructions
**[Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md)** - Common issues and solutions
**[TRASHguides](https://trash-guides.info/)** - Best practices reference
**Application Wikis**: [Sonarr](https://wiki.servarr.com/sonarr) | [Radarr](https://wiki.servarr.com/radarr)

## 🔧 System Requirements

- **OS**: Linux with NFS support
- **Docker**: Docker Engine + Docker Compose
- **Storage**: NFS access to TrueNAS server
- **Network**: Access to TrueNAS on 10.84.2.60
- **Permissions**: sudo access for NFS mounting

## 🛡️ Security Notes

- Change default qBittorrent password (admin/adminadmin)
- Consider using reverse proxy for external access
- Configure firewall rules appropriately
- Regularly update containers with `./manage.sh update`

##  Updates

```bash
# Update all containers
./manage.sh update

# Update specific service
docker-compose pull sonarr
docker-compose up -d sonarr
```

## 🐛 Troubleshooting

### NFS Issues
```bash
# Check NFS exports
showmount -e 10.84.2.60

# Test manual mount
sudo mount -t nfs 10.84.2.60:/mnt/Pool1/MediaData /mnt/media
```

### Permission Issues
```bash
# Fix ownership and permissions
./manage.sh fix-perms
```

### Container Issues
```bash
# Check logs
./manage.sh logs [service_name]

# Restart service
docker-compose restart [service_name]
```

## 📄 License

This configuration is provided as-is for educational purposes. Please ensure compliance with your local laws and the terms of service of any indexers or content providers you use.
