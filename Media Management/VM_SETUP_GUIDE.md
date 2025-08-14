# Quick Start Guide for Fresh VMs

This guide will get your *arr stack running on a freshly installed Ubuntu/Debian VM with minimal manual steps.

## 🚀 One-Command Setup

For the fastest setup on a fresh Ubuntu/Debian VM:

```bash
curl -sSL https://raw.githubusercontent.com/cousmax/Servarr/main/vm-setup.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/cousmax/Servarr/main/vm-setup.sh
chmod +x vm-setup.sh
./vm-setup.sh
```

## 📋 What the Script Does

The `vm-setup.sh` script automatically handles:

1. **System Updates & Dependencies**
   - Updates package lists
   - Installs curl, wget, and other prerequisites

2. **Docker Installation**
   - Removes old Docker versions
   - Installs Docker CE from official repository
   - Installs Docker Compose
   - Adds current user to docker group
   - Enables and starts Docker service

3. **NFS Setup (Optional)**
   - Installs NFS client utilities
   - Prompts for NFS server configuration
   - Mounts NFS shares
   - Adds persistent mounts to `/etc/fstab`

4. **Directory Structure**
   - Creates TRASHguides-compliant folder structure
   - Sets proper permissions (PUID/PGID)
   - Creates config directories

5. **Service Deployment**
   - Generates `.env` file with your settings
   - Pulls Docker images
   - Starts all services
   - Shows service status and URLs

## 🖥️ Manual Setup Steps

If you prefer manual installation or need to troubleshoot:

### 1. Clone Repository
```bash
git clone https://github.com/cousmax/Servarr.git
cd Servarr
```

### 2. Create Environment File
```bash
cp .env.example .env
nano .env  # Edit with your settings
```

### 3. Run Setup
```bash
sudo ./setup.sh        # Full setup with NFS
# OR
sudo ./simple-setup.sh  # NFS only (if directories exist)
```

### 4. Start Services
```bash
./manage.sh start
```

## ⚙️ Configuration Options

During setup, you'll be prompted for:

- **NFS Server IP**: Your TrueNAS IP (e.g., `10.84.2.60`)
- **NFS Share Path**: Path on NFS server (e.g., `/mnt/Pool1/MediaData`)
- **Local Mount Point**: Where to mount locally (default: `/mnt/media`)
- **Timezone**: Your timezone (default: `America/New_York`)
- **User IDs**: PUID/PGID for file permissions (auto-detected)

## 🌐 Default Service Ports

After setup, access your services at:

| Service | URL | Purpose |
|---------|-----|---------|
| Prowlarr | http://localhost:9696 | Indexer management |
| Sonarr | http://localhost:8989 | TV show automation |
| Radarr | http://localhost:7878 | Movie automation |
| Lidarr | http://localhost:8686 | Music automation |
| Readarr | http://localhost:8787 | Book automation |
| qBittorrent | http://localhost:8080 | Torrent client |
| NZBGet | http://localhost:6789 | Usenet client |
| Bazarr | http://localhost:6767 | Subtitle management |
| Jellyseerr | http://localhost:5055 | Media request management |
| Notifiarr | http://localhost:5454 | Notification system |
| Flaresolverr | http://localhost:8191 | Cloudflare bypass |

## 🐛 Troubleshooting

### Script Fails to Run
```bash
# Make sure script is executable
chmod +x vm-setup.sh

# Check system compatibility
cat /etc/os-release
```

### Docker Issues
```bash
# Check Docker installation
docker --version
docker-compose --version

# Test Docker
docker run hello-world
```

### NFS Issues
```bash
# Test NFS server connection
showmount -e YOUR_NFS_SERVER_IP

# Check mount
mount | grep nfs

# Manual mount test
sudo mount -t nfs SERVER_IP:/path /mnt/test
```

### Permission Issues
```bash
# Check current user IDs
id

# Fix permissions
./manage.sh fix-perms
```

## 💡 Tips for Fresh VMs

1. **Update System First**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Set Hostname** (optional):
   ```bash
   sudo hostnamectl set-hostname mediaserver
   ```

3. **Configure Static IP** (recommended):
   ```bash
   sudo nano /etc/netplan/00-installer-config.yaml
   sudo netplan apply
   ```

4. **Install SSH Server** (if needed):
   ```bash
   sudo apt install -y openssh-server
   sudo systemctl enable ssh
   ```

5. **Setup Firewall** (optional):
   ```bash
   sudo ufw enable
   sudo ufw allow 22    # SSH
   sudo ufw allow 8080  # qBittorrent
   sudo ufw allow 9696  # Prowlarr
   # ... add other ports as needed
   ```

## 🔄 Post-Installation

After running the setup script:

1. **Configure Prowlarr**:
   - Add your indexers
   - Test connections
   - Configure categories

2. **Setup Download Clients**:
   - Add qBittorrent to each *arr app
   - Configure download paths
   - Set up categories

3. **Configure Media Libraries**:
   - Add root folders in each *arr app
   - Set quality profiles
   - Import custom formats from TRASHguides

4. **Test Downloads**:
   - Add a test movie/show
   - Verify file placement
   - Check permissions

## 📚 Additional Resources

- [Full Configuration Guide](CONFIGURATION_GUIDE.md)
- [TRASHguides Documentation](https://trash-guides.info/)
- [Docker Troubleshooting](https://docs.docker.com/engine/install/troubleshooting/)
- [NFS Client Setup](https://help.ubuntu.com/community/NFSv4Howto)

## ⚠️ Important Notes

- The script requires `sudo` privileges for Docker and NFS setup
- Docker group membership requires logout/login to take effect
- NFS setup is optional - local storage will be used if skipped
- All services use default passwords initially - change them after setup
- Regular updates recommended: `./manage.sh update`

---

**Need Help?** Check the logs at `/tmp/servarr-setup.log` or open an issue on GitHub.
