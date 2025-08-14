# VM Deployment Guide

## 🚀 Deploy to New VM - Recommended Method

### Step 1: Download the Installer (Best for Interactive Use)
On any new Linux VM (Ubuntu, Debian, CentOS, RHEL, Fedora, openSUSE, Arch):

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh -o install.sh

# Make executable and run
chmod +x install.sh && ./install.sh
```

**Why download first?**
- ✅ Preserves interactive terminal for menu selections
- ✅ Better handling of user input and prompts
- ✅ More reliable than piped execution

### Step 2: Choose Installation Type
The installer will present you with options:
1. **Complete automated installation** (Docker + Nextcloud AIO)
2. **Update system only**
3. **Install Docker only**
4. **Setup NFS only**
5. **Install Nextcloud AIO only** (requires Docker)
6. **Custom installation** (step by step)
7. **Exit**

### Step 3: Access Your Nextcloud
After installation completes:
- Open browser: `http://YOUR_VM_IP:8080`
- Complete Nextcloud AIO setup wizard

## 💾 Alternative Methods

### One-Line Download and Execute
```bash
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

### Using wget
```bash
# Download with wget
wget -qO install.sh https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh
chmod +x install.sh && ./install.sh
```

### Traditional Git Clone
```bash
git clone https://github.com/cousmax/nextcloud-aio-automated-installer.git
cd nextcloud-aio-automated-installer
./scripts/install-complete-stack.sh
```

### Piped Execution (May Have Interactive Issues)
```bash
# Simple installer (may not handle interactive input properly in all environments)
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh | bash
```

## 🔧 Advanced Options

### With NFS Storage
```bash
# Download and configure with NFS
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/quick-install.sh | bash
# Then follow prompts to configure NFS server details
```

### Fully Automated (No Prompts)
```bash
# Set environment variables first
export NFS_SERVER="192.168.1.100"
export NFS_PATH="/mnt/nextcloud-data"
export SKIP_PROMPTS="true"

# Run automated installation
curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/quick-install.sh | bash
```

### Multiple VMs Deployment
For deploying to multiple VMs, create a deployment script:

```bash
#!/bin/bash
# deploy-multiple.sh

VMS=("192.168.1.10" "192.168.1.11" "192.168.1.12")

for vm in "${VMS[@]}"; do
    echo "Deploying to $vm..."
    ssh root@$vm 'curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/quick-install.sh | bash -s -- --auto'
done
```

## 🛠️ What Gets Installed

### Automatic Detection and Installation:
- ✅ **System Updates** (all supported distributions)
- ✅ **Docker** (latest version via official installer)
- ✅ **Docker Compose** (if not included with Docker)
- ✅ **NFS Client** (if NFS storage is configured)
- ✅ **Nextcloud AIO** (latest container)
- ✅ **Required Dependencies** (curl, git, etc.)

### Automatic Configuration:
- ✅ **User Permissions** (Docker group membership)
- ✅ **System Services** (Docker auto-start)
- ✅ **Network Configuration** (Port 8080 for web access)
- ✅ **Storage Integration** (Local or NFS)
- ✅ **Security Settings** (Firewall considerations)

## 🔍 Troubleshooting

### If Installation Fails:
```bash
# Check the downloaded repository
ls -la ~/nextcloud-aio-installer/

# Run individual components
cd ~/nextcloud-aio-installer
./scripts/install-docker-complete.sh
./scripts/install-nextcloud-aio.sh
```

### Check Installation Status:
```bash
# Check Docker status
docker --version
docker ps

# Check Nextcloud AIO container
docker logs nextcloud-aio-mastercontainer

# Check system services
systemctl status docker
```

### Manual Recovery:
If something goes wrong, you can always:
1. Download the full repository: `git clone https://github.com/cousmax/nextcloud-aio-automated-installer.git`
2. Run individual scripts from the `scripts/` directory
3. Check logs and troubleshooting guides in the README

## 🎯 Supported Platforms

✅ **Ubuntu** 20.04, 22.04, 24.04  
✅ **Debian** 10, 11, 12  
✅ **CentOS** 7, 8, 9  
✅ **RHEL** 8, 9  
✅ **Fedora** 36+  
✅ **openSUSE** Leap 15.4+, Tumbleweed  
✅ **Arch Linux**  

Works on: Physical servers, VMs, VPS, cloud instances (AWS, DigitalOcean, etc.)
