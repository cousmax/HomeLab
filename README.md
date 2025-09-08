# HomeLab Automation Suite

A comprehensive HomeLab automation suite featuring media management (*arr stack) and NextCloud deployment scripts, designed for easy setup on fresh VMs.

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

### **🎬 Media Management**
Complete *arr stack automation with Docker Compose following Trash Guides best practices.

**Features:**
- 🐳 **Automated Docker installation and setup**
- 📁 **Trash Guides directory structure** for optimal hardlinks
- 🔒 **Optional VPN routing** via Gluetun
- ⚙️ **Smart dependency management** 
- 🎯 **One-command deployment**

**Services Available:**
- **Download Clients:** qBittorrent, NZBGet, Prowlarr
- **Media Management:** Sonarr, Radarr, Lidarr, Bazarr
- **Media Servers:** Jellyfin, Jellyseerr
- **Management:** Portainer

**Quick Start:**
```bash
cd HomeLab/MediaManagement/scripts
python3 generate-compose-simple.py  # All-in-one setup
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

---

## 📚 Documentation

- **[Quick Setup Guide](QUICK-SETUP.md)** - One-liners for fresh VM setup
- **[MediaManagement/README.md](MediaManagement/README.md)** - Detailed media stack info
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
```
HomeLab/
├── MediaManagement/          # Media stack automation
│   ├── scripts/             # Setup and management scripts
│   └── docker-compose.yml   # Generated compose file
├── NextCloud/               # NextCloud deployment
│   ├── scripts/            # Installation scripts
│   └── examples/           # Example configurations
├── setup-homelab.sh        # Linux VM setup script
├── setup-homelab.ps1       # Windows VM setup script
└── QUICK-SETUP.md          # Quick reference guide
```
