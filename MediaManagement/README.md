# Media Management Stack

Automated *arr stack deployment with Docker Compose following Trash Guides best practices for optimal hardlinks and performance.

## 🚀 Quick Start

### **One-Command Setup**

```bash
cd MediaManagement/scripts
python3 generate-compose-simple.py
```

This script will:

- ✅ Check and install Docker if needed
- ✅ Create Trash Guides directory structure  
- ✅ Generate optimized docker-compose.yml
- ✅ Handle permissions automatically
- ✅ **Interactive confirmations** at each major step
- ✅ **Retry capability** for failed configurations
- ✅ **Network share mounting** with error recovery
- ✅ **Automatic service startup** with verification
- ✅ **Service health monitoring** and troubleshooting
- ✅ Provide service URLs and next steps

### **Maintenance**

Keep your stack healthy with the maintenance script:

```bash
# Interactive maintenance menu
python3 scripts/maintain-stack.py

# Quick health check
python3 scripts/maintain-stack.py health

# Update containers
python3 scripts/maintain-stack.py update

# Full maintenance (all tasks)
python3 scripts/maintain-stack.py full
```

### **Manual Setup**

```bash
# Install Docker (if needed)
./scripts/install-docker-and-update-os.sh

# Generate compose file
python3 scripts/generate-compose-simple.py

# Start services  
docker-compose up -d
```

## 📦 Available Services

### **Download Clients**

- **qBittorrent** (Port 8080) - Torrent client
- **NZBGet** (Port 6789) - Usenet client  
- **Prowlarr** (Port 9696) - Indexer manager

### **Media Management**

- **Sonarr** (Port 8989) - TV show management
- **Radarr** (Port 7878) - Movie management
- **Lidarr** (Port 8686) - Music management
- **Bazarr** (Port 6767) - Subtitle management

### **Media Servers & Requests**

- **Jellyfin** (Port 8096) - Media server
- **Jellyseerr** (Port 5055) - Request management

### **Management Tools**

- **Portainer** (Port 9000) - Docker management UI
- **Gluetun** - Optional VPN client for secure downloads

## 🗂️ Directory Structure (Trash Guides)

The generator creates an optimal directory structure for hardlinks:

```
/mnt/media/
├── media/           # Final media files (for Plex/Jellyfin)
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
├── torrents/        # Download client files (qBittorrent)
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
├── usenet/          # Download client files (NZBGet)
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
└── youtube/         # YouTube downloads (ytdl-sub)
```

**Why This Structure?**

- **Hardlinks:** Instant moves instead of slow copies
- **No Duplicates:** Same file, multiple locations, one disk usage
- **Performance:** Dramatically faster import times
- **Trash Guides Compliant:** Follows community best practices

## 🌐 Network Share Support

The script supports mounting network shares for media storage:

### **Supported Share Types**

- **NFS** - Network File System (Linux/Unix)
- **SMB/CIFS** - Windows shares (Samba)
- **Manual** - Pre-configured custom mounts

### **Automatic Setup**

When you choose network share storage, the script will:

- ✅ Install required packages (nfs-common or cifs-utils)
- ✅ Create mount points with proper permissions
- ✅ Mount the share with optimized settings
- ✅ Add to /etc/fstab for persistence
- ✅ Handle credentials securely (SMB only)

### **Configuration Examples**

**NFS:**
- Server: `192.168.1.100`
- Export: `/mnt/media`
- Mount: `/mnt/media`
- Options: `vers=3,proto=tcp,rsize=8192,wsize=8192`

**SMB/CIFS:**
- Server: `192.168.1.100`
- Share: `media`
- Mount: `/mnt/media`
- Credentials: Stored securely in `/etc/cifs-credentials`

### **Benefits**

- **Centralized Storage:** All media on NAS/file server
- **Multiple Clients:** Access from multiple Docker hosts
- **Backup Integration:** Centralized backup strategies
- **Scalability:** Easy storage expansion

## ✨ Enhanced User Experience

The script now features comprehensive confirmations and retry capabilities:

### **Step-by-Step Confirmations**

- **Configuration Summary** - Review all settings before proceeding
- **Network Share Details** - Full connection details with examples
- **Service Selection** - Confirm your chosen services before generation
- **Mount Verification** - Test network shares before continuing

### **Intelligent Retry System**

- **3 Retry Attempts** - Multiple chances for network share mounting
- **Reconfiguration Options** - Fix settings between retry attempts  
- **Connectivity Testing** - Pre-mount validation for NFS servers
- **Fallback Options** - Continue with local storage if needed

### **Built-in Troubleshooting**

**NFS Issues:**
- Connectivity verification (port 2049)
- Export validation suggestions
- Alternative NFS version recommendations

**SMB/CIFS Issues:**  
- Share accessibility testing
- Credential validation prompts
- Protocol version adjustments

**Error Recovery:**
- Clear error messages with solutions
- Configuration modification prompts
- Graceful degradation to local storage

### **Example Enhanced Flow**

```text
📋 NFS Configuration Summary:
  Server: 192.168.1.100
  Export Path: /volume1/media  
  Mount Point: /mnt/media
  Full NFS Path: 192.168.1.100:/volume1/media

Is this network share configuration correct? [y]: n
Let's reconfigure the network share...

🔧 Setting up network share (attempt 1/3)...
🔍 Testing connectivity to NFS server 192.168.1.100...
✓ NFS share mounted successfully!
✓ Mount verification successful - read/write working
```

### **Automated Service Startup**

The script can now automatically start your Docker Compose stack:

- **Smart Group Handling** - Detects docker group membership and uses `newgrp docker` when needed
- **Service Verification** - Checks that all selected services are running properly
- **Health Monitoring** - Reports status of each service with clear indicators
- **Troubleshooting Logs** - Shows logs for any services that fail to start
- **Fallback Options** - Uses sudo when docker group access isn't working

### **Service Status Verification**

```text
🔍 Verifying services are running...

✅ Running services:
  ✓ sonarr
  ✓ radarr
  ✓ qbittorrent
  ✓ prowlarr

📊 Useful Commands:
docker compose ps          # Check service status
docker compose logs -f     # View live logs
docker compose restart [service]  # Restart a service
```

## 🔒 VPN Configuration (Optional)

The generator asks if you want VPN routing for download clients:

### **With VPN (Gluetun):**

- Download clients route through VPN
- Requires VPN provider configuration in `.env` file
- More secure but requires setup

### **Without VPN (Direct):**

- Download clients use direct internet connection
- Easier setup, no VPN configuration needed
- Services expose ports directly

## ⚙️ Configuration Files

### **Generated Files:**

- `docker-compose.yml` - Main service definitions
- `.env` - Environment variables (VPN settings, paths, etc.)
- Service config directories (`./sonarr/`, `./radarr/`, etc.)

### **Key Environment Variables:**

```bash
PUID=1000              # User ID for file permissions
PGID=1000              # Group ID for file permissions  
TZ=America/New_York    # Timezone
DATA_PATH=/mnt/media   # Base path for media storage
```

## 🔧 Management Commands

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f [service_name]

# Stop all services  
docker-compose down

# Update services
docker-compose pull
docker-compose up -d
```

## 🆘 Troubleshooting

### **Permission Issues:**

```bash
# Fix ownership
sudo chown -R $USER:$USER /mnt/media

# Fix permissions
sudo chmod -R 755 /mnt/media
```

### **Docker Issues:**

```bash
# Restart Docker
sudo systemctl restart docker

# Check Docker status
sudo systemctl status docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### **VPN Issues:**

- Check `.env` file for correct VPN credentials
- Verify VPN provider settings
- Check gluetun logs: `docker-compose logs gluetun`

## 📚 Learn More

- **Trash Guides:** <https://trash-guides.info/>
- **Docker Compose:** <https://docs.docker.com/compose/>
- **Hardlinks Explained:** <https://trash-guides.info/Hardlinks/>

---

**Generated by HomeLab Automation Suite**