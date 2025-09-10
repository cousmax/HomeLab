# HomeLab Automation Suite

A comprehensive HomeLab automation suite featuring three complete stacks: Media Management (*arr stack), Media Servers (streaming & photo management), DevTools (Gitea development environment), and NextCloud deployment scripts, all designed for easy setup on fresh VMs.

---

## 🚀 Quick Setup

### **For Fresh VMs (Recommended)**

**Linux/Ubuntu:**
```bash
curl -sSL https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/setup-homelab.sh | bash
```

**Windows PowerShell (as Administrator):**
```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/setup-homelab.ps1'))
```

**Manual Setup:**
```bash
git clone -b Dynamic-Servarr https://github.com/cousmax/HomeLab.git
cd HomeLab
```

---

## 📦 Components

### **🎬 Media Management Stack**
Complete *arr stack automation with Docker Compose following Trash Guides best practices.

**Features:**
- 🐳 **Automated Docker installation and setup**
- 📁 **Trash Guides directory structure** for optimal hardlinks
- 🔒 **Optional VPN routing** via Gluetun
- ⚙️ **Smart dependency management** 
- 🎯 **One-command deployment**
- 🔧 **Comprehensive maintenance tools**

**Services Available:**
- **Download Clients:** qBittorrent, NZBGet, Prowlarr
- **Media Management:** Sonarr, Radarr, Lidarr, Bazarr
- **Media Servers:** Jellyfin, Jellyseerr
- **Management:** Portainer

**Quick Start:**
```bash
cd HomeLab/MediaManagement/scripts
python3 generate-compose-simple.py  # Interactive setup
python3 maintain-stack.py          # Maintenance & management
```

### **📺 Media Servers Stack**
Complete media streaming and photo management environment with analytics and user management.

**Features:**
- 📸 **Photo management** with Immich
- 🎥 **Multiple media servers** (Jellyfin, Plex)
- 📊 **Analytics and monitoring** with Tautulli
- 👥 **User management** with Wizarr and Petio
- 🔄 **Full automation** and maintenance tools

**Services Available:**
- **Photo Management:** Immich
- **Media Servers:** Jellyfin, Plex
- **Request Management:** Petio
- **Analytics:** Tautulli
- **User Management:** Wizarr

**Quick Start:**
```bash
cd HomeLab/"Media Servers"/Scripts
python3 generate-media-servers.py    # Interactive setup
python3 maintain-media-servers.py    # Maintenance & management
```

### **🔧 DevTools Stack**
Self-hosted development environment with Git service, CI/CD, and development tools.

**Features:**
- 🔧 **Self-hosted Git** with Gitea
- 🚀 **CI/CD pipelines** (Gitea Actions, Drone)
- 🐳 **Container management** with Portainer
- 💻 **Remote development** with Code Server
- 🔒 **Complete security configuration**

**Services Available:**
- **Git Service:** Gitea with PostgreSQL
- **CI/CD:** Gitea Actions Runner, Drone CI
- **Management:** Portainer
- **Development:** Code Server (VS Code in browser)

**Quick Start:**
```bash
cd HomeLab/DevTools/Scripts
python3 generate-gitea-stack.py    # Interactive setup
python3 maintain-devtools.py       # Maintenance & management
```

### **☁️ NextCloud**
Automated NextCloud AIO deployment with NFS storage integration.

**Features:**
- 🔄 **Automated installation scripts**
- 💾 **NFS storage integration** 
- 🖥️ **VM deployment options**
- 📋 **Example configurations**

**Quick Start:**
```bash
cd HomeLab/NextCloud
./install.sh
```

---

## 🎯 Service URLs (Default Ports)

### **Media Management Stack**
| Service | URL | Purpose |
|---------|-----|---------|
| Prowlarr | http://localhost:9696 | Indexer Manager |
| qBittorrent | http://localhost:8080 | Torrent Client |
| NZBGet | http://localhost:6789 | Usenet Client |
| Sonarr | http://localhost:8989 | TV Show Management |
| Radarr | http://localhost:7878 | Movie Management |
| Lidarr | http://localhost:8686 | Music Management |
| Bazarr | http://localhost:6767 | Subtitle Management |
| Jellyfin | http://localhost:8096 | Media Server |
| Jellyseerr | http://localhost:5055 | Request Management |
| Portainer | http://localhost:9000 | Docker Management |

### **Media Servers Stack**
| Service | URL | Purpose |
|---------|-----|---------|
| Immich | http://localhost:2283 | Photo Management |
| Jellyfin | http://localhost:8097 | Media Server |
| Plex | http://localhost:32400 | Media Server |
| Petio | http://localhost:7777 | Request Management |
| Tautulli | http://localhost:8181 | Analytics |
| Wizarr | http://localhost:5690 | User Management |

### **DevTools Stack**
| Service | URL | Purpose |
|---------|-----|---------|
| Gitea | http://localhost:3000 | Git Service |
| Gitea SSH | ssh://git@localhost:2222 | Git SSH Access |
| Drone CI | http://localhost:3001 | CI/CD Platform |
| Portainer | http://localhost:9000 | Docker Management |
| Code Server | https://localhost:8443 | VS Code in Browser |

---

## 📚 Documentation

- **[Quick Setup Guide](QUICK-SETUP.md)** - One-liners for fresh VM setup
- **[MediaManagement/README.md](MediaManagement/README.md)** - Detailed media management stack
- **[Media Servers/README.md](Media%20Servers/README.md)** - Complete media streaming stack
- **[DevTools/README.md](DevTools/README.md)** - Gitea development environment
- **[NextCloud/README.md](NextCloud/README.md)** - NextCloud deployment guide

---

## 🔧 Requirements

- **OS:** Ubuntu 20.04+, Debian 11+, or compatible Linux distribution
- **Memory:** 4GB RAM minimum (8GB+ recommended)
- **Storage:** 20GB+ free space
- **Network:** Internet connection for downloads and updates

---

## 🤝 Support

- **Issues:** Use GitHub Issues for bug reports
- **Documentation:** Check individual component README files
- **Trash Guides:** https://trash-guides.info/ for media stack best practices

---

**Repository Structure:**
```text
HomeLab/
├── MediaManagement/          # *arr stack automation
│   ├── scripts/             # Setup and management scripts
│   └── docker-compose.yml   # Generated compose file
├── Media Servers/           # Media streaming stack
│   ├── Scripts/             # Generator and maintenance
│   └── docker-compose.yml   # Example configuration
├── DevTools/               # Development environment
│   ├── Scripts/            # Gitea stack automation
│   └── docker-compose-example.yml
├── NextCloud/              # NextCloud deployment
│   ├── scripts/            # Installation scripts
│   └── examples/           # Example configurations
├── setup-homelab.sh        # Linux VM setup script
├── setup-homelab.ps1       # Windows VM setup script
└── QUICK-SETUP.md          # Quick reference guide
```
