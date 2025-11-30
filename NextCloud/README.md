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

---

**Part of the HomeLab Automation Suite - For more information, see the [main README](../README.md)**
