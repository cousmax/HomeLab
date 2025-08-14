# *arr Stack for Fresh VMs 🚀

Get a complete media automation stack running on a fresh Ubuntu/Debian VM in under 5 minutes!

## Quick Start (One Command)

```bash
curl -sSL https://raw.githubusercontent.com/cousmax/Servarr/main/simple-vm-setup.sh | bash
```

That's it! The script will:
- Install Docker & Docker Compose
- Create the directory structure
- Download and start all services
- Show you the URLs to access everything

## What You Get

| Service | Purpose | Default Port |
|---------|---------|--------------|
| **Prowlarr** | Indexer management | 9696 |
| **Sonarr** | TV show automation | 8989 |
| **Radarr** | Movie automation | 7878 |
| **Lidarr** | Music automation | 8686 |
| **Readarr** | Book automation | 8787 |
| **qBittorrent** | Torrent downloads | 8080 |
| **NZBGet** | Usenet downloads | 6789 |
| **Bazarr** | Subtitle management | 6767 |
| **Jellyseerr** | Request management | 5055 |
| **Notifiarr** | Notifications | 5454 |
| **Flaresolverr** | Cloudflare bypass | 8191 |

## Manual Setup

If you prefer to do it manually:

```bash
# Clone the repository
git clone https://github.com/cousmax/Servarr.git
cd Servarr

# Run the simple setup
./simple-vm-setup.sh
```

## System Requirements

- **OS**: Ubuntu 20.04+ or Debian 10+
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 20GB free space minimum
- **Network**: Internet access for downloads

## Directory Structure

After setup, your directory structure will be:

```
./
├── config/          # Application configurations
├── data/            # Media and downloads
│   ├── media/       # Final media library
│   │   ├── movies/
│   │   ├── tv/
│   │   ├── music/
│   │   └── books/
│   ├── torrents/    # Torrent downloads
│   └── usenet/      # Usenet downloads
├── docker-compose.yml
└── .env
```

## First-Time Configuration

After the services are running:

### 1. Configure Prowlarr (http://YOUR_IP:9696)
- Add your favorite indexers
- Test connections
- Configure categories

### 2. Add Download Client to *arr apps
In each app (Sonarr, Radarr, etc.):
- Go to Settings → Download Clients
- Add qBittorrent:
  - Host: `qbittorrent`
  - Port: `8080`
  - Username: `admin`
  - Password: `adminadmin` (change this!)

### 3. Configure Root Folders
In each *arr app:
- Add root folder `/data/media/movies` (for Radarr)
- Add root folder `/data/media/tv` (for Sonarr)
- Add root folder `/data/media/music` (for Lidarr)
- Add root folder `/data/media/books` (for Readarr)

### 4. Set Quality Profiles
- Import TRASHguides quality profiles
- Set preferred quality settings
- Configure custom formats

## Management

### Start/Stop Services
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Update all services
docker-compose pull && docker-compose up -d
```

### Accessing from Other Machines

To access the services from other computers on your network:

1. **Find your VM's IP**:
   ```bash
   ip addr show | grep inet
   ```

2. **Open firewall ports** (if needed):
   ```bash
   sudo ufw allow 8080  # qBittorrent
   sudo ufw allow 9696  # Prowlarr
   # ... add other ports as needed
   ```

3. **Access via browser**: `http://YOUR_VM_IP:PORT`

## Troubleshooting

### Services won't start
```bash
# Check Docker status
sudo systemctl status docker

# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Permission issues
```bash
# Fix ownership
sudo chown -R $(id -u):$(id -g) config/ data/

# Fix permissions
chmod -R 775 config/ data/
```

### Can't access from other machines
```bash
# Check if ports are listening
ss -tlnp | grep :8080

# Check firewall
sudo ufw status
```

## Upgrading to NFS Storage

Once you have a NAS or want to use network storage:

1. Install NFS utilities:
   ```bash
   sudo apt install nfs-common
   ```

2. Mount your NFS share:
   ```bash
   sudo mkdir -p /mnt/media
   sudo mount -t nfs YOUR_NAS_IP:/path/to/share /mnt/media
   ```

3. Update your `.env` file:
   ```bash
   DATA_PATH=/mnt/media
   ```

4. Restart services:
   ```bash
   docker-compose up -d
   ```

## Security Notes

- Change default qBittorrent password immediately
- Consider using a reverse proxy for external access
- Keep services updated regularly
- Don't expose services directly to the internet without proper security

## Need Help?

- Check the logs: `docker-compose logs -f [service_name]`
- Join the community: [r/sonarr](https://reddit.com/r/sonarr), [r/radarr](https://reddit.com/r/radarr)
- TRASHguides: https://trash-guides.info/
- Service wikis: [Sonarr](https://wiki.servarr.com/sonarr) | [Radarr](https://wiki.servarr.com/radarr)

---

**Enjoy your automated media setup! 🎬📺🎵📚**
