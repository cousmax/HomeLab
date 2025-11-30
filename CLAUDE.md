# CLAUDE.md - AI Assistant Guide for HomeLab Repository

**Last Updated:** 2025-11-30
**Repository:** cousmax/HomeLab
**Main Branch:** Dynamic-Servarr

---

## 📋 Repository Overview

The HomeLab repository is a comprehensive automation suite for deploying self-hosted services on fresh VMs. It contains four major stacks with interactive Python and Shell scripts for automated deployment and maintenance.

### Purpose
- Provide one-command deployment for complete service stacks
- Follow industry best practices (Trash Guides for media management)
- Support both local and network storage
- Enable easy maintenance and updates
- Minimize configuration complexity for end users

### Technology Stack
- **Containerization:** Docker & Docker Compose
- **Languages:** Python 3, Bash
- **Target OS:** Ubuntu 20.04+, Debian 11+, and compatible Linux distributions
- **Configuration:** YAML (docker-compose), ENV files, JSON

---

## 🗂️ Repository Structure

```
HomeLab/
├── MediaManagement/          # *arr stack (Sonarr, Radarr, qBittorrent, etc.)
│   ├── scripts/
│   │   ├── generate-compose-simple.py    # Interactive compose generator
│   │   ├── maintain-stack.py             # Stack maintenance
│   │   └── install-docker-and-update-os.sh
│   ├── docker-compose.yml    # Generated compose file
│   └── README.md
│
├── Media Servers/            # Streaming & photo management
│   ├── Scripts/
│   │   ├── generate-media-servers.py     # Interactive setup
│   │   └── maintain-media-servers.py     # Maintenance tools
│   ├── docker-compose.yml    # Example configuration
│   └── README.md
│
├── DevTools/                 # Gitea development environment
│   ├── Scripts/
│   │   ├── generate-gitea-stack.py       # Stack generator
│   │   └── maintain-devtools.py          # Maintenance script
│   ├── docker-compose-example.yml
│   └── README.md
│
├── NextCloud/                # NextCloud AIO deployment
│   ├── scripts/              # Installation and setup scripts
│   │   ├── install-complete-stack.sh
│   │   ├── install-docker-complete.sh
│   │   ├── install-nextcloud-aio.sh
│   │   └── setup-nfs.sh
│   ├── examples/             # Configuration examples
│   ├── install.sh            # Main installer
│   ├── quick-install.sh      # Automated installer
│   └── README.md
│
├── setup-homelab.sh          # Linux VM quick setup
├── setup-homelab.ps1         # Windows VM quick setup
├── QUICK-SETUP.md            # Quick reference guide
└── README.md                 # Main documentation
```

---

## 🎯 Key Conventions

### Naming Conventions

1. **Scripts:**
   - Generator scripts: `generate-{stack-name}.py`
   - Maintenance scripts: `maintain-{stack-name}.py`
   - Installation scripts: `install-{component}.sh`
   - Setup scripts: `setup-{feature}.sh`

2. **Docker Services:**
   - Container names match service names
   - Network names: `{stack}network` (e.g., `servarrnetwork`, `mediaserver-network`)
   - Volume names: descriptive with service prefix (e.g., `gluetun_data`)

3. **Directories:**
   - Config directories: `./{service}/config`
   - Data directories: use environment variable `${DATA_PATH}`
   - Network shares typically mounted at: `/mnt/media` or `/mnt/{service}`

4. **Files:**
   - Docker compose: `docker-compose.yml` (generated) or `docker-compose-example.yml` (template)
   - Environment: `.env` (local, not committed)
   - Documentation: `README.md` in each major directory

### Code Style

#### Python Scripts
- **Shebang:** `#!/usr/bin/env python3`
- **Type hints:** Use typing module for function parameters and returns
- **Classes:**
  - Use PascalCase for class names
  - Include `Colors` class for terminal output formatting
  - Main logic in classes with descriptive method names
- **Color output:**
  ```python
  class Colors:
      RED = '\033[0;31m'
      GREEN = '\033[0;32m'
      YELLOW = '\033[1;33m'
      BLUE = '\033[0;34m'
      CYAN = '\033[0;36m'
      WHITE = '\033[1;37m'
      NC = '\033[0m'
  ```
- **User interaction:**
  - Use colored prompts with defaults: `[default]`
  - Provide clear success/error messages with appropriate colors
  - Implement confirmation prompts for destructive actions
  - Show summaries before execution

#### Shell Scripts
- **Shebang:** `#!/bin/bash`
- **Error handling:** Use `set -e` at the top of scripts
- **Color output:** Define color variables (RED, GREEN, YELLOW, BLUE, NC)
- **Functions:**
  - `print_status()`, `print_success()`, `print_warning()`, `print_error()`
  - Descriptive function names with snake_case
- **Main execution pattern:**
  ```bash
  main() {
      # Main logic
  }
  main "$@"
  ```

### Docker Compose Patterns

1. **Networks:**
   - Always define custom bridge networks with specific subnets
   - Use static IPs for services that need inter-service communication
   - Example:
     ```yaml
     networks:
       servarrnetwork:
         name: servarrnetwork
         ipam:
           config:
             - subnet: 172.39.0.0/24
     ```

2. **Services:**
   - Use LinuxServer.io images where available (`lscr.io/linuxserver/...`)
   - Include health checks for critical services
   - Set `restart: unless-stopped` for production services
   - Use environment variables for configuration:
     ```yaml
     environment:
       - PUID=${PUID}
       - PGID=${PGID}
       - TZ=${TZ}
     ```

3. **Volumes:**
   - Config: `./service:/config`
   - Data: `${DATA_PATH}/subpath:/data/subpath`
   - Named volumes for databases

4. **Dependencies:**
   - Use `depends_on` with conditions for proper startup order
   - Example:
     ```yaml
     depends_on:
       gluetun:
         condition: service_healthy
         restart: true
     ```

### Environment Variables

Standard variables across all stacks:
- `PUID` - User ID for file permissions (default: 1000)
- `PGID` - Group ID for file permissions (default: 1000)
- `TZ` - Timezone (default: America/New_York)
- `DATA_PATH` - Base path for media/data storage
- Service-specific variables in comments

---

## 🔄 Development Workflows

### Git Workflow

1. **Branching:**
   - Main development branch: `Dynamic-Servarr`
   - Feature branches: `claude/{feature-description}-{session-id}`
   - Always develop on designated feature branches

2. **Commits:**
   - Use descriptive commit messages
   - Focus on the "why" rather than the "what"
   - Example: "Add comprehensive backup restore functionality to maintenance script"
   - Group related changes in single commits

3. **Push Protocol:**
   - Always use: `git push -u origin <branch-name>`
   - Branch must start with 'claude/' and include session ID
   - Retry on network errors with exponential backoff (2s, 4s, 8s, 16s)
   - Maximum 4 retry attempts

### Making Changes

1. **Before Editing:**
   - Read existing files completely
   - Understand the current implementation
   - Check related files for patterns
   - Review README.md for context

2. **Generator Scripts:**
   - Maintain interactive prompts with colored output
   - Always show configuration summary before proceeding
   - Include retry logic for network operations
   - Provide clear error messages with solutions
   - Generate complete docker-compose.yml files
   - Create necessary directories
   - Show service URLs after completion

3. **Maintenance Scripts:**
   - Implement both interactive menu and CLI arguments
   - Include health checks and monitoring
   - Provide backup/restore functionality
   - Show clear status messages
   - Handle errors gracefully

4. **Documentation:**
   - Update README.md when adding features
   - Include usage examples
   - Document prerequisites
   - Add troubleshooting sections
   - Keep service URL tables current

### Testing Changes

1. **Script Validation:**
   - Test Python scripts: `python3 script.py --help`
   - Test shell scripts: `bash -n script.sh`
   - Verify file permissions: `chmod +x *.sh`

2. **Docker Compose Validation:**
   - Validate syntax: `docker compose config`
   - Check for missing variables
   - Verify network configurations
   - Test service dependencies

3. **Integration Testing:**
   - Test on clean VM when possible
   - Verify all interactive prompts
   - Test error handling paths
   - Confirm cleanup procedures work

---

## 📚 Component-Specific Guidelines

### MediaManagement Stack

**Key Files:**
- `scripts/generate-compose-simple.py` - Main generator (no external dependencies)
- `scripts/maintain-stack.py` - Stack maintenance
- `docker-compose.yml` - Generated file (not committed with services)

**Important Patterns:**
- Trash Guides directory structure (hardlinks optimization)
- VPN routing through Gluetun (optional)
- Network share support (NFS, SMB/CIFS)
- Service dependency management
- Health checks and retry logic

**Service Categories:**
- Download clients: qBittorrent, NZBGet
- Indexers: Prowlarr
- Media management: Sonarr, Radarr, Lidarr, Bazarr
- Media servers: Jellyfin, Jellyseerr
- Management: Portainer

**Configuration:**
- Always use environment variables for paths
- Support both local and network storage
- Include optional VPN configuration
- Maintain PUID/PGID consistency

### Media Servers Stack

**Key Files:**
- `Scripts/generate-media-servers.py` - Interactive generator
- `Scripts/maintain-media-servers.py` - Comprehensive maintenance
- `docker-compose.yml` - Example (actual is generated)

**Services:**
- Photo management: Immich (with PostgreSQL + Redis)
- Media servers: Jellyfin, Plex
- Request management: Petio
- Analytics: Tautulli (Plex monitoring)
- User management: Wizarr

**Patterns:**
- Pre-configured stack options (full, media-only, photo-only, custom)
- Storage path configuration per service
- Database password management
- Claim tokens for Plex
- Health monitoring and diagnostics

### DevTools Stack

**Key Files:**
- `Scripts/generate-gitea-stack.py` - Stack generator
- `Scripts/maintain-devtools.py` - Maintenance and admin tools
- `docker-compose-example.yml` - Template

**Services:**
- Git service: Gitea + PostgreSQL
- CI/CD: Gitea Actions Runner, Drone CI (alternatives)
- Management: Portainer
- Development: Code Server

**Patterns:**
- OAuth application setup for Drone
- Runner token configuration
- SSH port mapping (2222)
- Database initialization
- Admin CLI commands

### NextCloud Stack

**Key Files:**
- `install.sh` - Main installer wrapper
- `scripts/install-complete-stack.sh` - Complete installation
- `scripts/install-docker-complete.sh` - Docker setup
- `scripts/install-nextcloud-aio.sh` - NextCloud AIO deployment
- `scripts/setup-nfs.sh` - NFS client configuration

**Patterns:**
- Multi-distribution support (Ubuntu, Debian, CentOS, RHEL, Fedora, openSUSE, Arch)
- Interactive menu system
- NFS storage integration
- Docker group activation
- Systemd service management

---

## 🛠️ Common Operations

### Adding a New Service

1. **To Existing Stack:**
   - Add service template to generator script
   - Update service selection menu
   - Add to docker-compose template
   - Update README with service info
   - Add to service URL table
   - Update maintenance script if needed

2. **New Stack:**
   - Create directory: `StackName/`
   - Add `Scripts/` subdirectory
   - Create generator script: `generate-{stack}.py`
   - Create maintenance script: `maintain-{stack}.py`
   - Add `docker-compose-example.yml`
   - Write comprehensive `README.md`
   - Update main `README.md` with new stack

### Updating Documentation

1. **Service Changes:**
   - Update relevant README.md
   - Modify service URL tables
   - Update quick start commands
   - Revise troubleshooting if needed

2. **New Features:**
   - Add to Features section
   - Include usage examples
   - Document configuration options
   - Add troubleshooting entries

### Script Modifications

1. **Generator Scripts:**
   - Maintain backward compatibility with existing configs
   - Add new prompts in logical order
   - Update configuration summary
   - Test all code paths
   - Handle migration from old configs

2. **Maintenance Scripts:**
   - Add new operations to menu
   - Support CLI arguments for automation
   - Include dry-run mode for destructive operations
   - Log all actions
   - Provide clear success/failure messages

---

## 🔍 Important Implementation Details

### Directory Structure Standards

**Trash Guides Structure (MediaManagement):**
```
/mnt/media/
├── media/           # Final media (hardlinked from downloads)
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
├── torrents/        # Download client files
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
└── usenet/          # Usenet downloads
    ├── movies/
    ├── tv/
    ├── music/
    └── books/
```

**Why Hardlinks Matter:**
- Instant moves instead of copies
- Same file, multiple locations, one disk usage
- Dramatically faster import times
- Required: downloads and media on same filesystem

### Network Share Handling

**NFS Mounts:**
```bash
# Mount options
vers=3,proto=tcp,rsize=8192,wsize=8192

# Testing connectivity
nc -zv {server} 2049

# Verification
mount | grep nfs
```

**SMB/CIFS Mounts:**
```bash
# Credentials file
/etc/cifs-credentials
username=user
password=pass

# Mount options
vers=3.0,credentials=/etc/cifs-credentials,uid=1000,gid=1000
```

**Retry Logic:**
- 3 attempts for network operations
- Reconfiguration between attempts
- Fallback to local storage option
- Clear error messages with solutions

### Docker Group Management

**Pattern:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Activate group in current session
newgrp docker

# Verify
docker ps
```

**When to use `newgrp`:**
- After adding user to docker group
- Before docker compose commands
- In automated scripts for service startup

### Health Checks

**Service Health:**
```yaml
healthcheck:
  test: ping -c 1 www.google.com || exit 1
  interval: 60s
  retries: 3
  start_period: 20s
  timeout: 10s
```

**Database Health:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U user"]
  interval: 10s
  timeout: 5s
  retries: 5
```

---

## 🐛 Debugging and Troubleshooting

### Common Issues

1. **Permission Errors:**
   - Check PUID/PGID match host user
   - Verify directory ownership
   - Check mount point permissions
   - Solution: `sudo chown -R $USER:$USER /path`

2. **Network Share Failures:**
   - Test connectivity first
   - Verify credentials
   - Check mount options
   - Test with manual mount
   - Review `/etc/fstab` syntax

3. **Docker Issues:**
   - Check Docker daemon: `sudo systemctl status docker`
   - Verify group membership: `groups`
   - Test socket access: `docker ps`
   - Review logs: `journalctl -u docker`

4. **Service Startup Failures:**
   - Check logs: `docker compose logs {service}`
   - Verify depends_on conditions
   - Check health check status
   - Review environment variables
   - Validate network configuration

### Debugging Scripts

**Python Scripts:**
```bash
# Enable debug mode
python3 -u script.py  # Unbuffered output

# Check syntax
python3 -m py_compile script.py

# Interactive debugging
python3 -i script.py
```

**Shell Scripts:**
```bash
# Debug mode
bash -x script.sh

# Syntax check
bash -n script.sh

# Enable trace
set -x
```

**Docker Compose:**
```bash
# Validate configuration
docker compose config

# View computed config
docker compose convert

# Check specific service
docker compose config {service}
```

---

## 📖 Documentation Standards

### README Structure

Each stack README should include:

1. **Header:**
   - Title with stack name
   - Part of HomeLab suite reference
   - Links to other stacks

2. **Quick Start:**
   - One-command setup
   - Expected behavior
   - Prerequisites

3. **Services:**
   - Table or list of services
   - Ports and purposes
   - Brief descriptions

4. **Directory Structure:**
   - Tree view of generated structure
   - Explanation of organization

5. **Configuration:**
   - Environment variables
   - Configuration files
   - Customization options

6. **Management:**
   - Common commands
   - Maintenance procedures
   - Update process

7. **Troubleshooting:**
   - Common issues
   - Solutions
   - Log locations

8. **Integration:**
   - How it works with other stacks
   - External integrations
   - Advanced configurations

### Code Documentation

**Python:**
```python
def function_name(param: str) -> bool:
    """
    Brief description.

    Args:
        param: Description of parameter

    Returns:
        Description of return value
    """
    pass
```

**Shell:**
```bash
# Function description
# Args:
#   $1 - Description
#   $2 - Description
# Returns:
#   0 on success, 1 on failure
function_name() {
    local var=$1
}
```

### Inline Comments

- Explain "why" not "what"
- Complex logic needs comments
- Configuration sections need headers
- External references need URLs

---

## 🚀 Best Practices for AI Assistants

### When Making Changes

1. **Always Read First:**
   - Read entire files before editing
   - Check related files for patterns
   - Review existing implementations
   - Understand the context

2. **Maintain Consistency:**
   - Follow existing patterns
   - Use same naming conventions
   - Match code style
   - Keep formatting consistent

3. **Test Thoroughly:**
   - Validate syntax
   - Check for breaking changes
   - Test error paths
   - Verify backwards compatibility

4. **Document Everything:**
   - Update relevant README files
   - Add inline comments for complex logic
   - Update service tables
   - Include usage examples

### Interactive Scripts

**Required Elements:**
- Colored output for readability
- Clear prompts with defaults
- Configuration summaries
- Confirmation before destructive actions
- Progress indicators
- Success/failure messages
- Next steps guidance

**User Experience:**
- Assume minimal Docker knowledge
- Provide helpful error messages
- Suggest solutions
- Allow retry on failures
- Show examples in prompts
- Confirm important decisions

### Error Handling

**Pattern:**
```python
try:
    # Operation
except SpecificException as e:
    self.print_colored(f"❌ Error: {str(e)}", Colors.RED)
    self.print_colored("💡 Solution: {specific_solution}", Colors.YELLOW)
    # Retry logic or graceful degradation
```

**For Shell:**
```bash
if ! command; then
    print_error "Operation failed"
    print_warning "Try: suggested solution"
    return 1
fi
```

### Maintenance Scripts

**Must Include:**
- Health monitoring
- Log viewing
- Backup/restore
- Update procedures
- Cleanup operations
- Interactive menu
- CLI arguments support
- Status reporting

---

## 🔐 Security Considerations

### Secrets Management

- Never commit `.env` files
- Use placeholder values in examples
- Generate strong passwords
- Store credentials securely
- Document security requirements

### File Permissions

- Use non-root users (PUID/PGID)
- Set appropriate file permissions
- Restrict config directory access
- Audit permissions regularly

### Network Security

- Document firewall requirements
- Use VPN for download clients
- Recommend reverse proxy for SSL
- Suggest authentication layers
- Document port exposure

---

## 📊 Service Port Reference

### MediaManagement Stack
| Service | Port | Protocol |
|---------|------|----------|
| Prowlarr | 9696 | HTTP |
| qBittorrent | 8080 | HTTP |
| NZBGet | 6789 | HTTP |
| Sonarr | 8989 | HTTP |
| Radarr | 7878 | HTTP |
| Lidarr | 8686 | HTTP |
| Bazarr | 6767 | HTTP |
| Jellyfin | 8096 | HTTP |
| Jellyseerr | 5055 | HTTP |
| Portainer | 9000 | HTTP |

### Media Servers Stack
| Service | Port | Protocol |
|---------|------|----------|
| Immich | 2283 | HTTP |
| Jellyfin | 8097 | HTTP |
| Plex | 32400 | HTTP |
| Petio | 7777 | HTTP |
| Tautulli | 8181 | HTTP |
| Wizarr | 5690 | HTTP |

### DevTools Stack
| Service | Port | Protocol |
|---------|------|----------|
| Gitea | 3000 | HTTP |
| Gitea SSH | 2222 | SSH |
| Drone CI | 3001 | HTTP |
| Portainer | 9000 | HTTP |
| Code Server | 8443 | HTTPS |

### NextCloud
| Service | Port | Protocol |
|---------|------|----------|
| NextCloud AIO | 8080 | HTTP |

---

## 🔗 External Resources

### Documentation
- [Trash Guides](https://trash-guides.info/) - Media management best practices
- [Docker Compose Docs](https://docs.docker.com/compose/) - Official Docker documentation
- [LinuxServer.io](https://fleet.linuxserver.io/) - Container image documentation

### Service Documentation
- [Sonarr](https://wiki.servarr.com/sonarr) - TV management
- [Radarr](https://wiki.servarr.com/radarr) - Movie management
- [Gitea](https://docs.gitea.io/) - Git service
- [Immich](https://immich.app/docs) - Photo management
- [Nextcloud](https://docs.nextcloud.com/) - Cloud storage

---

## 📝 Changelog and Versioning

### Version Tracking
- No formal semantic versioning
- Git commit history as source of truth
- README updates reflect current state
- Breaking changes documented in commits

### Recent Major Changes
- Complete DevTools stack implementation
- Media Servers stack with Immich
- Enhanced backup/restore in maintenance scripts
- Docker permissions diagnostics
- Comprehensive network share support

---

## 🎯 Quick Reference

### Starting a New Feature

1. Understand the requirement
2. Read relevant existing code
3. Check for similar patterns
4. Plan implementation approach
5. Make changes following conventions
6. Test thoroughly
7. Update documentation
8. Commit with clear message
9. Push to feature branch

### Running Scripts

```bash
# MediaManagement
cd HomeLab/MediaManagement/scripts
python3 generate-compose-simple.py
python3 maintain-stack.py

# Media Servers
cd HomeLab/"Media Servers"/Scripts
python3 generate-media-servers.py
python3 maintain-media-servers.py

# DevTools
cd HomeLab/DevTools/Scripts
python3 generate-gitea-stack.py
python3 maintain-devtools.py

# NextCloud
cd HomeLab/NextCloud
./install.sh
```

### Docker Commands

```bash
# Start services
docker compose up -d

# View status
docker compose ps

# View logs
docker compose logs -f [service]

# Stop services
docker compose down

# Update services
docker compose pull
docker compose up -d
```

---

## 🤝 Contributing Guidelines

### For AI Assistants

1. **Understand Context:**
   - Read all relevant files completely
   - Understand user intent
   - Check for existing patterns
   - Consider backwards compatibility

2. **Make Focused Changes:**
   - One logical change per commit
   - Don't over-engineer
   - Maintain simplicity
   - Follow existing patterns

3. **Test Changes:**
   - Validate syntax
   - Check error handling
   - Test interactive prompts
   - Verify documentation

4. **Document Clearly:**
   - Update README files
   - Add helpful comments
   - Include usage examples
   - Document breaking changes

### Code Review Checklist

- [ ] Follows existing code style
- [ ] Uses consistent naming
- [ ] Includes error handling
- [ ] Has helpful user messages
- [ ] Updates relevant documentation
- [ ] Tests all code paths
- [ ] Maintains backwards compatibility
- [ ] No hardcoded secrets
- [ ] Proper file permissions
- [ ] Clear commit message

---

**End of CLAUDE.md**

*This document should be updated whenever significant changes are made to repository structure, conventions, or workflows.*
