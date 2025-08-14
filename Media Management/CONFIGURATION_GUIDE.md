# Configuration Guide

This guide will help you set up and customize your HomeLab Media Stack using Docker Compose and TRASHguides best practices.

---

## 1. Prerequisites
- Linux server (recommended) with Docker and Docker Compose installed
- NFS server (optional, for network storage)
- Sudo/root access for mounting and permissions

## 2. Clone the Repository
```bash
git clone <your-repo-url>
cd <repo-folder>
```

## 3. Environment Variables (`.env`)
Copy `.env.example` to `.env` and edit as needed:

```
NFS_SERVER=192.168.1.100           # Your NAS IP address
NFS_SHARE=/mnt/yourshare           # Your NFS share path
DATA_PATH=/mnt/media               # Local mount point for media
PUID=1000                          # User ID for containers
PGID=1000                          # Group ID for containers
TZ=America/New_York                # Timezone
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
QBITTORRENT_PORT=8080
NZBGET_PORT=6789
...etc
```

## 4. Folder Structure
The setup script will create all required folders:
- `/mnt/media/media` (movies, tv, music, books, audiobooks)
- `/mnt/media/torrents` (downloads, incomplete, watch)
- `/mnt/media/usenet` (complete, incomplete, intermediate)
- `config/` (service configs)
- `backups/` (backups)

## 5. NFS Mounting (Optional)
If using NFS:
- Ensure your NAS exports the share and your server has NFS client utilities installed.
- Run the setup script:
  ```bash
  sudo scripts/setup-arr-folders.sh
  ```
- Follow prompts to mount NFS and create folders.

## 6. Running the Stack
Use the quick installer:
```bash
scripts/quick-install.sh
```
Or run scripts individually for advanced setup.

## 7. Service Configuration
- Access web UIs at the ports listed in `.env`.
- Configure indexers, download clients, and root folders in Sonarr/Radarr/Lidarr/Readarr.
- Use TRASHguides for recommended custom formats and automation settings.

## 8. Management
Use `scripts/manage.sh` for:
- Starting/stopping services
- Checking VPN health
- Viewing logs
- Backups and restores
- Connectivity checks

## 9. Troubleshooting
- **NFS Issues**: Check exports, permissions, and mount status.
- **Permissions**: Use `manage.sh fix-perms` if you encounter access errors.
- **Container Issues**: View logs and restart services as needed.

## 10. Customization
- Edit `.env` to change ports, paths, and service options.
- Modify `docker-compose.yml` to add/remove services.
- Use `customize-arr-install.sh` for interactive stack selection.

---

For more details, see the individual service guides linked in the main README.
