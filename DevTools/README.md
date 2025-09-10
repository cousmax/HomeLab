# DevTools Stack - Gitea & Development Environment

**Part of the [HomeLab Automation Suite](../README.md) - Complete self-hosted development environment with Git service, CI/CD, and development tools**

> 💡 **Other HomeLab Stacks Available:**
> - **[Media Management](../MediaManagement/README.md)** - Complete *arr stack for media automation
> - **[Media Servers](../Media%20Servers/README.md)** - Immich, Jellyfin, Plex, Petio, Tautulli, Wizarr
> - **[NextCloud](../NextCloud/README.md)** - Self-hosted cloud storage

## 📋 Overview

This DevTools stack provides a comprehensive self-hosted development environment built around Gitea (self-hosted Git service). It includes optional CI/CD pipelines, container management, and browser-based development tools.

### 🚀 Available Services

| Service | Description | Default Port | Purpose |
|---------|-------------|--------------|---------|
| **Gitea** | Self-hosted Git service | 3000 | Git repositories, web interface, user management |
| **PostgreSQL** | Database backend | - | Gitea data storage |
| **Gitea Actions Runner** | CI/CD pipeline runner | - | Automated builds and deployments |
| **Drone CI** | Alternative CI/CD platform | 3001 | Continuous integration (alternative to Gitea Actions) |
| **Portainer** | Docker management UI | 9000 | Container and stack management |
| **Code Server** | VS Code in browser | 8443 | Remote development environment |

### 🎯 Service Combinations

- **Minimal Git Server**: Gitea only
- **Git + CI/CD**: Gitea + Gitea Actions Runner
- **Complete DevTools**: All services for full development environment
- **Custom Selection**: Pick and choose services

## 🛠️ Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Sufficient disk space for repositories and data
- Network ports available (3000, 2222, 3001, 9000, 8443)

### 1. Generate Stack Configuration

```bash
# Navigate to DevTools directory
cd /path/to/HomeLab/DevTools

# Run the interactive generator
python Scripts/generate-gitea-stack.py
```

The generator will ask you to:
- Select services to include
- Configure domain and ports
- Set up database passwords
- Configure user IDs and timezone
- Set up service-specific options

### 2. Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 3. Access Services

After startup, access your services:
- **Gitea**: http://localhost:3000
- **Drone CI**: http://localhost:3001 (if selected)
- **Portainer**: http://localhost:9000 (if selected)  
- **Code Server**: https://localhost:8443 (if selected)

## 📖 Detailed Setup Guide

### Gitea Initial Setup

1. **Access Web Interface**
   - Navigate to http://your-domain:3000
   - Complete the installation wizard

2. **Database Configuration** (Pre-configured)
   - Database Type: PostgreSQL
   - Host: gitea-db:5432
   - Database: gitea
   - Username: gitea
   - Password: (from .env file)

3. **Administrator Account**
   - Create your admin account during setup
   - Configure site settings as needed

4. **SSH Access** (Optional)
   ```bash
   # Clone via SSH (port 2222 by default)
   git clone ssh://git@your-domain:2222/username/repository.git
   
   # Add SSH key in Gitea user settings
   ```

### Gitea Actions Runner Setup

If you selected the Gitea Actions runner:

1. **Generate Runner Token**
   - Go to Gitea → Site Administration → Actions → Runners
   - Click "Create new runner"
   - Copy the registration token

2. **Update Configuration**
   ```bash
   # Edit .env file
   RUNNER_TOKEN=your-actual-token-here
   
   # Restart runner
   docker-compose restart gitea-runner
   ```

3. **Verify Runner**
   - Check runner appears in Gitea admin panel
   - Test with a simple workflow in a repository

### Drone CI Setup (Alternative to Gitea Actions)

If you selected Drone CI:

1. **Create OAuth Application in Gitea**
   - Go to Gitea → Settings → Applications → OAuth2 Applications
   - Application Name: Drone
   - Redirect URI: http://your-domain:3001/login
   - Save and copy Client ID and Secret

2. **Update Configuration**
   ```bash
   # Edit .env file
   GITEA_OAUTH_ID=your-client-id
   GITEA_OAUTH_SECRET=your-client-secret
   
   # Restart Drone
   docker-compose restart drone drone-runner
   ```

3. **Access Drone**
   - Navigate to http://your-domain:3001
   - Login with Gitea credentials
   - Activate repositories for CI/CD

### Code Server Setup

If you selected Code Server:

1. **Access Interface**
   - Navigate to https://your-domain:8443
   - Use password from .env file

2. **Install Extensions**
   - Install Git extension
   - Add development language extensions as needed
   - Configure terminal and workspace

3. **Workspace Configuration**
   - Default workspace: /config/workspace
   - Clone repositories directly in the interface
   - Configure Git credentials

## 📁 Directory Structure

```
DevTools/
├── docker-compose.yml          # Main service definitions
├── .env                       # Environment variables
├── README.md                  # This file
├── Scripts/
│   ├── generate-gitea-stack.py    # Interactive setup generator
│   └── maintain-devtools.py       # Maintenance and management
├── gitea/
│   ├── data/                  # Gitea application data
│   ├── postgres/              # PostgreSQL database
│   └── runner/                # Actions runner data (if enabled)
├── drone/                     # Drone CI data (if enabled)
│   └── data/
├── portainer/                 # Portainer data (if enabled)
│   └── data/
├── code-server/               # Code Server configuration (if enabled)
│   └── config/
└── backups/                   # Automated backups
```

## 🔧 Management & Maintenance

### Using the Maintenance Script

The maintenance script provides comprehensive management:

```bash
# Interactive menu
python Scripts/maintain-devtools.py

# Direct commands
python Scripts/maintain-devtools.py status
python Scripts/maintain-devtools.py logs
python Scripts/maintain-devtools.py backup
python Scripts/maintain-devtools.py update
python Scripts/maintain-devtools.py cleanup
python Scripts/maintain-devtools.py gitea-admin
```

### Common Management Tasks

#### Service Status
```bash
# Check all services
docker-compose ps

# View logs
docker-compose logs gitea
docker-compose logs -f --tail 50 gitea  # Follow recent logs
```

#### Updates
```bash
# Update all services
python Scripts/maintain-devtools.py update

# Update specific service
docker-compose pull gitea
docker-compose up -d gitea
```

#### Backup & Restore
```bash
# Create backup
python Scripts/maintain-devtools.py backup

# Restore from backup
python Scripts/maintain-devtools.py restore --backup-file backups/devtools_backup_20240101_120000.tar
```

### Gitea Administration

#### User Management
```bash
# Create user via CLI
docker-compose exec gitea gitea admin user create \
  --username newuser \
  --email user@example.com \
  --password secretpassword

# List users
docker-compose exec gitea gitea admin user list

# Make user admin
docker-compose exec gitea gitea admin user change-password \
  --username username --admin
```

#### Repository Management
```bash
# Repository statistics
docker-compose exec gitea-db psql -U gitea -d gitea \
  -c "SELECT COUNT(*) as repositories FROM repository;"

# Database maintenance
docker-compose exec gitea-db psql -U gitea -d gitea -c "VACUUM;"
```

## 🔒 Security Configuration

### Essential Security Steps

1. **Change Default Passwords**
   ```bash
   # Update .env file with strong passwords
   DB_PASSWORD=strong-database-password
   CODE_PASSWORD=strong-code-server-password
   ```

2. **Configure Firewall**
   ```bash
   # Example UFW rules
   sudo ufw allow 3000  # Gitea web
   sudo ufw allow 2222  # Gitea SSH
   sudo ufw allow 3001  # Drone (if used)
   sudo ufw allow 9000  # Portainer (if used)
   sudo ufw allow 8443  # Code Server (if used)
   ```

3. **SSL/TLS Setup** (Recommended for production)
   - Use reverse proxy (nginx, Traefik)
   - Obtain SSL certificates (Let's Encrypt)
   - Configure secure headers

4. **Gitea Security Settings**
   - Enable 2FA for admin accounts
   - Configure repository access controls
   - Set up organization permissions
   - Review and audit user access regularly

### Network Security

```yaml
# Example reverse proxy configuration (nginx)
server {
    listen 443 ssl;
    server_name git.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 Monitoring & Troubleshooting

### Health Checks

```bash
# Service health status
python Scripts/maintain-devtools.py monitoring

# Resource usage
docker stats

# Log analysis
docker-compose logs --tail 100 gitea | grep ERROR
```

### Common Issues

#### Gitea Won't Start
```bash
# Check database connectivity
docker-compose logs gitea-db

# Verify file permissions
sudo chown -R 1000:1000 gitea/data

# Check configuration
docker-compose config
```

#### Actions Runner Not Connecting
```bash
# Verify token in .env
cat .env | grep RUNNER_TOKEN

# Check runner logs
docker-compose logs gitea-runner

# Re-register runner
docker-compose restart gitea-runner
```

#### Database Issues
```bash
# Check database status
docker-compose exec gitea-db pg_isready -U gitea

# Database backup
docker-compose exec gitea-db pg_dump -U gitea gitea > backup.sql

# Restore database
docker-compose exec -T gitea-db psql -U gitea gitea < backup.sql
```

## 🔄 CI/CD Examples

### Gitea Actions Workflow

Create `.gitea/workflows/ci.yml` in your repository:

```yaml
name: CI Pipeline
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          echo "Running tests..."
          # Your test commands here
      - name: Build
        run: |
          echo "Building application..."
          # Your build commands here
```

### Drone Pipeline

Create `.drone.yml` in your repository:

```yaml
kind: pipeline
type: docker
name: default

steps:
- name: test
  image: node:16
  commands:
  - npm install
  - npm test

- name: build
  image: node:16
  commands:
  - npm run build
  when:
    branch:
    - main
```

## 📈 Performance Optimization

### Database Optimization

```bash
# PostgreSQL tuning
docker-compose exec gitea-db psql -U gitea -d gitea -c "
  ALTER SYSTEM SET shared_buffers = '256MB';
  ALTER SYSTEM SET effective_cache_size = '1GB';
  SELECT pg_reload_conf();
"
```

### Storage Management

```bash
# Clean up old data
python Scripts/maintain-devtools.py cleanup

# Monitor disk usage
du -sh gitea/data/*
du -sh gitea/postgres/*
```

## 🚀 Advanced Configuration

### External Database

To use an external PostgreSQL database, modify docker-compose.yml:

```yaml
services:
  gitea:
    environment:
      - GITEA__database__HOST=external-db-host:5432
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea_user
      - GITEA__database__PASSWD=gitea_password
    # Remove depends_on: gitea-db
  
  # Remove gitea-db service entirely
```

### LDAP Integration

Configure LDAP in Gitea web interface:
- Go to Site Administration → Authentication Sources
- Add LDAP authentication source
- Configure LDAP server settings

### S3 Storage Backend

For large installations, configure S3 storage:

```ini
[storage]
STORAGE_TYPE = minio
MINIO_ENDPOINT = s3.amazonaws.com
MINIO_ACCESS_KEY_ID = your-access-key
MINIO_SECRET_ACCESS_KEY = your-secret-key
MINIO_BUCKET = gitea-storage
```

## 📚 Additional Resources

- [Gitea Documentation](https://docs.gitea.io/)
- [Drone CI Documentation](https://docs.drone.io/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Code Server Documentation](https://coder.com/docs/code-server)

## 📞 Support

For issues with this HomeLab setup:
1. Check the troubleshooting section above
2. Review logs using the maintenance script
3. Consult official documentation for each service
4. Check Docker and system logs

---

**Happy Coding! 🚀**
