# HomeLab Quick Setup

This repository contains scripts and configurations for setting up a complete HomeLab environment.

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

# Install Python requirements
cd MediaManagement/scripts
python3 -m pip install -r requirements.txt
```

## What Gets Installed

### Prerequisites

- Git (if not already installed)
- Python 3 and pip (for MediaManagement scripts)

### Repository Structure

- **MediaManagement/**: Docker compose configurations and automation scripts
- **NextCloud/**: NextCloud deployment scripts and documentation

### Key Scripts Available After Setup

#### MediaManagement

- `./MediaManagement/scripts/install-docker-and-update-os.sh` - Install Docker and update OS
- `./MediaManagement/scripts/generate-compose.py` - Generate Docker Compose configurations
- `./MediaManagement/scripts/test-compose.sh` - Test Docker Compose setup

#### NextCloud

- `./NextCloud/install.sh` - Main NextCloud installation script
- `./NextCloud/quick-install.sh` - Quick NextCloud setup
- `./NextCloud/scripts/install-nextcloud-aio.sh` - NextCloud AIO installation

## Usage Examples:

### After running the setup script:
```bash
cd HomeLab

# For MediaManagement setup:
cd MediaManagement
./scripts/install-docker-and-update-os.sh

# For NextCloud setup:
cd NextCloud
./install.sh
```

## Troubleshooting:

### If git clone fails:
- Check internet connection
- Verify repository URL: https://github.com/cousmax/HomeLab.git
- Ensure Git is installed

### If Python requirements fail:
- Install Python 3: `sudo apt install python3 python3-pip` (Ubuntu/Debian)
- Update pip: `python3 -m pip install --upgrade pip`

### For Windows PowerShell execution policy issues:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
