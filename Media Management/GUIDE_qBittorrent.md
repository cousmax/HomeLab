
# qBittorrent Guide

## Overview
qBittorrent is a free, open-source BitTorrent client with a user-friendly interface and powerful features for automation, privacy, and remote management.

## Features
- Web UI for remote management
- Advanced search engine (optional)
- Sequential downloading
- IP filtering and encryption
- Category/tag support for automation
- RSS feed support
- Torrent queueing and prioritization

## Setup
Included in the stack. Config files are stored in `config/qbittorrent`.

## Access
- Web UI: [http://localhost:8080](http://localhost:8080)
- Default credentials: `admin` / `adminadmin` (change immediately)

## Initial Configuration
1. Log in to the Web UI.
2. Change the default password under `Tools > Options > Web UI`.
3. Set your download folder under `Tools > Options > Downloads` (e.g., `/downloads/complete`).
4. (Optional) Enable HTTPS for secure remote access.
5. Configure port forwarding if accessing outside your local network.

## Recommended Settings for Automation
- **Categories**: Create categories for Sonarr/Radarr (e.g., `tv`, `movies`).
- **Save Path**: Assign each category a specific folder (e.g., `/downloads/complete/tv`).
- **Completed Download Handling**: Enable "Run external program on torrent completion" for post-processing scripts if needed.
- **RSS**: Use RSS feeds for automatic downloading (optional).

### Example Category Setup
1. Go to `Tools > Options > Downloads > Torrent Category`.
2. Add categories: `tv`, `movies`.
3. Set save paths:
	- `tv` → `/downloads/complete/tv`
	- `movies` → `/downloads/complete/movies`
4. In Sonarr/Radarr, set the download client category to match.

## Privacy & Security
- Route qBittorrent through Gluetun VPN for privacy (see `customize-arr-install.sh`).
- Enable IP filtering (Tools > Options > Connection > IP Filtering).
- Use encryption settings for peer connections.

## Troubleshooting
- If the Web UI is inaccessible, check port mapping and firewall settings.
- For slow downloads, verify tracker status and port forwarding.
- Monitor disk space to avoid incomplete downloads.

## Tips
- Change the default password immediately.
- Use categories for automation with Sonarr/Radarr.
- Monitor disk space and download health.
- Regularly update qBittorrent for security and new features.
