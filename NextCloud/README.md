# NextCloud AIO Setup

**Part of the [HomeLab Automation Suite](../README.md) - Automated installation scripts for Docker and Nextcloud All-in-One (AIO) with optional NFS storage integration.**

> 💡 **Other HomeLab Stacks Available:**
> - **[Media Management](../MediaManagement/README.md)** - Complete *arr stack for media automation
> - **[Media Servers](../Media%20Servers/README.md)** - Immich, Jellyfin, Plex, Petio, Tautulli, Wizarr
> - **[DevTools](../DevTools/README.md)** - Gitea development environment with CI/CD

## 🚀 Quick Start

### Option 1: Download and Run (Recommended)

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/NextCloud/install.sh -o install.sh

# Make it executable and run
chmod +x install.sh && ./install.sh
```

### Option 2: One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/NextCloud/install.sh | bash
```

### Option 3: Clone Repository

```bash
# Clone the repository
git clone -b Dynamic-Servarr https://github.com/cousmax/HomeLab.git
cd HomeLab/NextCloud

# Run the complete installation
./scripts/install-complete-stack.sh
```

## 🆕 New VM Deployment

For brand new VMs or servers:

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/NextCloud/install.sh -o install.sh

# Make executable and run
chmod +x install.sh && ./install.sh
```

This will:

- Install Git and Docker
- Clone this repository
- Set up Nextcloud AIO container
- Configure system dependencies
- Provide setup guidance

## 📁 What's Included

### Core Scripts

- `install.sh` - Main installer script
- `quick-install.sh` - Fast setup without prompts
- `deploy-vm.sh` - VM deployment automation

### Helper Scripts (in `scripts/`)

- `install-complete-stack.sh` - Full stack installation
- `install-docker-complete.sh` - Docker installation only
- `install-nextcloud-aio.sh` - Nextcloud AIO setup
- `run-nextcloud-aio.sh` - Start Nextcloud AIO
- `setup-nfs.sh` - NFS storage configuration
- `update-system.sh` - System updates and preparation

## 🔧 Configuration

### Basic Setup

The installer will prompt for:

- **Domain/IP** - Your server address
- **Email** - For SSL certificates  
- **Storage** - Local or NFS storage options
- **Ports** - Custom port configuration if needed

### Advanced Options

- **NFS Storage** - External NFS server integration
- **Custom Docker Networks** - Network configuration
- **SSL Configuration** - Let's Encrypt or custom certificates
- **Backup Settings** - Automated backup configuration

## 🌐 Access Your Installation

After installation, access Nextcloud AIO at:

- **Local**: `http://your-server-ip:8080`
- **Domain**: `https://your-domain.com:8080`

Default AIO admin interface credentials will be displayed during installation.

## 📋 System Requirements

### Minimum Requirements

- **OS**: Ubuntu 20.04+, Debian 11+, CentOS 8+, or similar
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 10GB minimum, 50GB+ recommended
- **Network**: Internet access for downloads

### Recommended Setup

- **RAM**: 8GB or more
- **Storage**: SSD with 100GB+ available
- **CPU**: 2+ cores
- **Network**: Gigabit connection for optimal performance

## 🔒 Security Notes

- Change default passwords immediately after installation
- Configure firewall rules appropriately
- Use SSL/TLS in production environments
- Regular security updates via the update scripts
- Consider VPN access for remote administration

## 🛠️ Troubleshooting

### Common Issues

1. **Port 8080 already in use**
   ```bash
   sudo netstat -tulpn | grep :8080
   sudo systemctl stop service-using-port
   ```

2. **Docker not starting**
   ```bash
   sudo systemctl status docker
   sudo systemctl restart docker
   ```

3. **Permission issues**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

4. **Domain not resolving**
   - Check DNS configuration
   - Verify domain points to your server IP
   - Check firewall settings

### Getting Help

- Check container logs: `docker logs nextcloud-aio-mastercontainer`
- Verify system status: `./scripts/install-complete-stack.sh --check`
- Review installation logs in `/var/log/`

## 📚 Additional Documentation

- `CONTRIBUTING.md` - How to contribute to this project
- `VM-DEPLOYMENT.md` - Detailed VM deployment guide
- `GITHUB-SETUP.md` - GitHub integration setup
- `examples/` - Example configurations

## 🔄 Updates and Maintenance

### Update System

```bash
# Update system packages
./scripts/update-system.sh

# Update Nextcloud AIO
docker pull nextcloud/all-in-one:latest
docker restart nextcloud-aio-mastercontainer
```

### Backup

Nextcloud AIO includes built-in backup features. Configure automated backups through the AIO admin interface.

For advanced backup setups, consider:

- External storage mounting
- Database backup scripts  
- Configuration backup automation
1. ✅ **Auto-detect your Linux distribution**
2. ✅ **Install required dependencies** (curl, git)
3. ✅ **Download all installation scripts**
4. ✅ **Present interactive menu** for installation options
5. ✅ **Handle all permissions and configurations**

### Automated Complete Installation
For fully automated deployment without prompts:
```bash
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/quick-install.sh | bash -s -- --auto-install
```

### Custom Installation Options
```bash
# Download installer and run with specific options
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/quick-install.sh -o install.sh
chmod +x install.sh

# Run with custom options
./install.sh --nfs-server 192.168.1.100 --nfs-path /mnt/data
```

## �📋 What This Does

This repository provides a complete automated setup for:

1. **System Updates** - Updates your Linux system (Ubuntu/Debian/CentOS/RHEL/Fedora/openSUSE/Arch)
2. **Docker Installation** - Installs Docker following official documentation
3. **Docker Post-Install** - Configures Docker for non-root usage
4. **NFS Client Setup** (Optional) - Configures NFS client for external storage
5. **Nextcloud AIO Deployment** - Deploys Nextcloud All-in-One with Docker Compose

## 📁 Repository Structure

```
nextcloud-aio-automated-installer/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── install.sh                         # Simple installer script (recommended)
├── quick-install.sh                   # Advanced installer with more options
├── deploy-vm.sh                       # VM deployment script
├── VM-DEPLOYMENT.md                   # Detailed VM deployment guide
├── CONTRIBUTING.md                    # Contribution guidelines
├── scripts/
│   ├── install-complete-stack.sh      # Master installer script
│   ├── install-docker-complete.sh     # Docker installation & configuration
│   ├── install-nextcloud-aio.sh       # Nextcloud AIO deployment
│   ├── setup-nfs.sh                   # NFS client configuration
│   ├── update-system.sh               # System update for multiple distros
│   ├── run-nextcloud-aio.sh           # Docker group activation wrapper
│   └── activate-docker-group.sh       # Docker group membership utility
└── examples/
    └── docker-compose-example.yml     # Example Docker Compose configuration
```

## 🛠 Individual Scripts

### Master Installer
- **`install-complete-stack.sh`** - Interactive menu system for complete installation

### Core Components
- **`install-docker-complete.sh`** - Complete Docker installation following official docs
- **`install-nextcloud-aio.sh`** - Nextcloud AIO deployment with optional NFS integration
- **`setup-nfs.sh`** - NFS client setup with multi-distribution support
- **`update-system.sh`** - System updates for various Linux distributions

### Utilities
- **`run-nextcloud-aio.sh`** - Wrapper for Docker group activation
- **`activate-docker-group.sh`** - Immediate Docker group membership activation

## 🔧 Prerequisites

- Linux system (Ubuntu, Debian, CentOS, RHEL, Fedora, openSUSE, or Arch)
- Root or sudo access
- Internet connection
- (Optional) NFS server for external storage

## 🚀 Installation Options

### Option 1: Complete Automated Installation

```bash
./scripts/install-complete-stack.sh
```

This provides an interactive menu with options for:
- System updates
- Docker installation
- Nextcloud AIO installation
- Complete stack installation

### Option 2: Individual Components

```bash
# System update only
./scripts/update-system.sh

# Docker installation only
./scripts/install-docker-complete.sh

# Nextcloud AIO only (requires Docker)
./scripts/install-nextcloud-aio.sh

# NFS setup only
./scripts/setup-nfs.sh
```

### Option 3: Command Line Arguments

```bash
# Install everything with command line options
./scripts/install-complete-stack.sh --install-all --nfs-server 10.84.2.60 --nfs-path /mnt/Pool1/ncdata

# Skip system update
./scripts/install-complete-stack.sh --install-all --skip-update

# Custom domain
./scripts/install-complete-stack.sh --install-all --domain yourdomain.com
```

## 🌐 NFS Integration

To use external NFS storage:

```bash
# With NFS server details
./scripts/install-complete-stack.sh --nfs-server YOUR_NFS_IP --nfs-path /path/to/nfs/share

# Or configure during interactive installation
./scripts/install-complete-stack.sh
```

**Supported NFS versions:** NFSv3, NFSv4, NFSv4.1, NFSv4.2

## 📝 Configuration

### Environment Variables

You can set these environment variables to customize the installation:

```bash
export NEXTCLOUD_DATADIR="/mnt/nextcloud-nfs"    # Custom data directory
export APACHE_PORT="8080"                        # Custom Apache port
export DOMAIN="yourdomain.com"                   # Custom domain
export NFS_SERVER="10.84.2.60"                   # NFS server IP
export NFS_PATH="/mnt/Pool1/ncdata"               # NFS server path
```

### Post-Installation

After installation completes:

1. Open your web browser
2. Navigate to `http://YOUR_SERVER_IP:8080`
3. Complete the Nextcloud AIO setup wizard
4. Configure SSL certificates and domain as needed

## 🐳 Docker Configuration

The scripts automatically configure:
- Docker daemon with optimal settings
- User permissions for Docker group
- Systemd service for auto-start
- Docker Compose for container orchestration

## 📊 Supported Distributions

- **Ubuntu** 20.04, 22.04, 24.04
- **Debian** 10, 11, 12
- **CentOS** 7, 8, 9
- **RHEL** 8, 9
- **Fedora** 36+
- **openSUSE** Leap 15.4+, Tumbleweed
- **Arch Linux**

## 🔒 Security Features

- Follows Docker official installation guidelines
- Proper user permission management
- Secure NFS mount options
- Systemd service hardening
- Container isolation with Docker

## 🆘 Troubleshooting

### Docker Group Issues
```bash
# If Docker group permissions aren't working
./scripts/activate-docker-group.sh
```

### NFS Mount Issues
```bash
# Check NFS mount status
mount | grep nfs
systemctl status nfs-client.target
```

### Container Status
```bash
# Check Nextcloud AIO status
docker ps
docker logs nextcloud-aio-mastercontainer
```

### Log Files
Check installation logs in:
- `/var/log/nextcloud-aio-install.log`
- System journal: `journalctl -u nextcloud-aio`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Docker](https://docker.com) for containerization platform
- [Nextcloud](https://nextcloud.com) for the amazing self-hosted cloud solution
- [Nextcloud AIO](https://github.com/nextcloud/all-in-one) for the All-in-One solution

## 🔗 Related Links

- [Nextcloud AIO Documentation](https://github.com/nextcloud/all-in-one)
- [Docker Installation Guide](https://docs.docker.com/engine/install/)
- [NFS Client Setup](https://help.ubuntu.com/community/SettingUpNFSHowTo)

## 📈 Project Status

- ✅ Docker automated installation
- ✅ Multi-distribution support  
- ✅ NFS storage integration
- ✅ Nextcloud AIO deployment
- ✅ Systemd service integration
- ✅ Comprehensive error handling
- ✅ Interactive installation menus
- 🔄 SSL/Let's Encrypt integration (planned)
- 🔄 Backup automation (planned)

---

**⭐ If this project helped you, please give it a star on GitHub!**
