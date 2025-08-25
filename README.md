# CousmaxHomeLab

A comprehensive HomeLab automation suite with media management and NextCloud deployment scripts.

---

## 🚀 Quick Installation

### Media Management Stack

**Option 1: One-Line Install (Recommended)**

```bash
curl -sSL https://raw.githubusercontent.com/cousmax/HomeLab/main/Media%20Management/scripts/install.sh | bash
```

**Option 2: Interactive Installer**

```bash
curl -sSL https://raw.githubusercontent.com/cousmax/HomeLab/main/Media%20Management/scripts/github-installer.sh | bash
```

**Option 3: Manual Clone**

```bash
git clone https://github.com/cousmax/HomeLab.git
cd "HomeLab/Media Management/scripts"
chmod +x *.sh
./quick-install.sh
```

### NextCloud Deployment

```bash
curl -fsSL https://raw.githubusercontent.com/cousmax/HomeLab/main/NextCloud/install.sh -o install.sh
chmod +x install.sh && ./install.sh
```

---

# Workspace Overview & Quick Start

## Media Management

**Purpose:**  
Automates the setup and management of a complete media stack using Docker Compose, following TRASHguides best practices. Integrates NFS storage (e.g., from TrueNAS) and supports VPN protection for download clients.

**Key Features:**
- Docker Compose stack for media automation (Sonarr, Radarr, Prowlarr, qBittorrent, NZBGet, etc.)
- NFS storage integration for centralized media storage
- VPN routing for secure downloads
- Scripts for setup, management, and troubleshooting

**How to Run:**
- Initial setup (mount NFS, configure stack):
	```bash
	sudo ./setup.sh
	```
- Start all services:
	```bash
	./manage.sh start
	```
- Check status:
	```bash
	./manage.sh status
	```
- Access services via browser (default ports):
	- Prowlarr: `http://localhost:9696`
	- qBittorrent: `http://localhost:8080`
	- NZBGet: `http://localhost:6789`
	- Sonarr: `http://localhost:8989`
	- Radarr: `http://localhost:7878`

---

## NextCloud

**Purpose:**  
Automates the installation and deployment of Nextcloud (All-in-One) using Docker, with NFS storage integration. Includes scripts for both Docker and VM-based deployments.

**Key Features:**
- Automated installer scripts for Nextcloud AIO
- NFS storage setup for persistent data
- VM deployment options for more advanced setups
- Example Docker Compose files and helper scripts

**How to Run:**
- Recommended: Download and run the installer script:
	```bash
	curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/install.sh -o install.sh
	chmod +x install.sh && ./install.sh
	```
- VM deployment:
	```bash
	curl -fsSL https://raw.githubusercontent.com/cousmax/nextcloud-aio-automated-installer/main/deploy-vm.sh -o deploy.sh
	chmod +x deploy.sh && ./deploy.sh
	```
- Clone full repository for advanced/manual setup:
	```bash
	git clone https://github.com/cousmax/nextcloud-aio-automated-installer.git
	cd nextcloud-aio-automated-installer
	./scripts/install-complete-stack.sh
	```

---
For more details, see the individual folder README and guides.

# Workspace Overview & Quick Start

## 1. Media Management
**Purpose:** Manage media services (NZBGet, qBittorrent, etc.) with Docker and scripts.

**How to Run:**
- Navigate to the `Media Management` folder.
- To start all services:

```bash
docker-compose up -d
```

- For scripted setup:
	- Bash (WSL/Git Bash):

```bash
bash ./quick-install.sh
```

## 2. NextCloud
**Purpose:** Deploy NextCloud via VM or Docker, with supporting scripts and guides.

**How to Run:**
- For Docker deployment:
	- Navigate to the `NextCloud` folder.
	- Run:

```bash
bash ./scripts/install-docker-complete.sh
```

	- Or use the example compose file:

```bash
docker-compose -f ./examples/docker-compose-example.yml up -d
```

- For VM deployment:
	- Run:

```bash
bash ./deploy-vm.sh
```

---
For more details, see the individual folder README and guides.