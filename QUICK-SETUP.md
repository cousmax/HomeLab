# HomeLab Quick Setup

This repository contains scripts and configurations for setting up a complete HomeLab environment with four integrated stacks: Media Management, Media Servers, DevTools, and NextCloud.

## Quick Setup on Fresh VM

### Linux/Ubuntu VM

```bash
# One-liner setup command:
curl -sSL https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/setup-homelab.sh | bash

# Or download and run manually:
wget https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/setup-homelab.sh
chmod +x setup-homelab.sh
./setup-homelab.sh
```

### Windows VM (PowerShell as Administrator)

```powershell
# One-liner setup command:
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/setup-homelab.ps1'))

# Or download and run manually:
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/setup-homelab.ps1" -OutFile "setup-homelab.ps1"
.\setup-homelab.ps1
```

## Manual Git Clone Method

```bash
# Clone the repository
git clone -b Dynamic-Servarr https://github.com/cousmax/HomeLab.git
cd HomeLab

# Make scripts executable (Linux)
find . -name "*.sh" -type f -exec chmod +x {} \;
```

## What Gets Installed

### Prerequisites

- Git (if not already installed)
- Python 3 (for automation scripts)
- Docker and Docker Compose (installed automatically by setup scripts)

### Repository Structure

- **MediaManagement/**: *arr stack with Docker automation
- **Media Servers/**: Immich, Jellyfin, Plex, and companion services
- **DevTools/**: Gitea development environment with CI/CD
- **NextCloud/**: NextCloud AIO deployment scripts

### Key Scripts Available After Setup

#### Media Management Stack

- `./MediaManagement/scripts/install-docker-and-update-os.sh` - Install Docker and update OS
- `./MediaManagement/scripts/generate-compose-simple.py` - Generate Docker Compose configurations
- `./MediaManagement/scripts/maintain-stack.py` - Maintenance and management tools

#### Media Servers Stack

- `./Media Servers/Scripts/generate-media-servers.py` - Generate media server stack
- `./Media Servers/Scripts/maintain-media-servers.py` - Maintenance and health checks

#### DevTools Stack

- `./DevTools/Scripts/generate-gitea-stack.py` - Generate Gitea development environment
- `./DevTools/Scripts/maintain-devtools.py` - DevTools maintenance and management

#### NextCloud

- `./NextCloud/install.sh` - Main NextCloud installation script
- `./NextCloud/scripts/install-complete-stack.sh` - Complete automated installation
- `./NextCloud/scripts/install-nextcloud-aio.sh` - NextCloud AIO installation

## Usage Examples

### After running the setup script:

```bash
cd HomeLab

# For Media Management setup (*arr stack):
cd MediaManagement/scripts
python3 generate-compose-simple.py

# For Media Servers setup (Immich, Jellyfin, Plex):
cd "Media Servers/Scripts"
python3 generate-media-servers.py

# For DevTools setup (Gitea):
cd DevTools/Scripts
python3 generate-gitea-stack.py

# For NextCloud setup:
cd NextCloud
./install.sh
```

## Available Services by Stack

### Media Management
- qBittorrent, NZBGet, Prowlarr
- Sonarr, Radarr, Lidarr, Bazarr
- Jellyfin, Jellyseerr, Portainer

### Media Servers
- Immich (Photo Management)
- Jellyfin, Plex (Media Servers)
- Petio (Request Management)
- Tautulli (Analytics)
- Wizarr (User Management)

### DevTools
- Gitea (Git Service)
- Gitea Actions / Drone CI
- Portainer (Container Management)
- Code Server (VS Code in Browser)

### NextCloud
- NextCloud AIO (All-in-One)
- NFS Storage Integration

## Troubleshooting

### If git clone fails:
- Check internet connection
- Verify repository URL: https://github.com/cousmax/HomeLab.git
- Ensure Git is installed

### If Python scripts fail:
- Install Python 3: `sudo apt install python3` (Ubuntu/Debian)
- Python scripts use standard library only (no additional packages required)

### For Windows PowerShell execution policy issues:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Docker installation issues:
- Run the Docker installer: `./MediaManagement/scripts/install-docker-and-update-os.sh`
- Verify Docker is running: `sudo systemctl status docker`
- Add user to docker group: `sudo usermod -aG docker $USER` (then log out and back in)

---

**For detailed documentation, see the [main README](README.md) or individual stack READMEs.**
