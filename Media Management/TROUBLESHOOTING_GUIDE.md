# Troubleshooting Guide

This guide covers common issues and solutions for your HomeLab Media Stack.

---

## NFS Issues

### NFS Share Not Mounting
- Check that your NAS exports the share and your server has NFS client utilities installed.
- Test manual mount:

```bash
sudo mount -t nfs <NAS_IP>:/mnt/yourshare /mnt/media
```
- Check NFS exports:

```bash
showmount -e <NAS_IP>
```
- Verify permissions on the NAS and local mount point.

### Permission Errors
- Run the permission fix script:

```bash
scripts/manage.sh fix-perms
```
- Ensure your user has write access to all media and config folders.

## Docker & Container Issues

### Container Won't Start
- Check logs:

```bash
docker compose logs <service_name>
```
- Restart the service:

```bash
docker compose restart <service_name>
```
- Verify environment variables in `.env` are correct.

### Service Not Accessible
- Confirm the container is running:

```bash
docker compose ps
```
- Check port mappings in `docker-compose.yml` and `.env`.
- Ensure no firewall is blocking the port.

## VPN (Gluetun) Issues

### VPN Not Connecting
- Check Gluetun logs:

```bash
docker compose logs gluetun
```
- Verify VPN credentials and provider settings in `.env` or `config/gluetun`.
- Use `scripts/manage.sh vpn-status` to check public IP.

### Services Not Routing Through VPN
- Ensure network mode is set correctly in `docker-compose.yml` (e.g., `network_mode: service:gluetun`).
- Use `customize-arr-install.sh` to adjust service routing.

## Application-Specific Issues

### NZBGet
- Check NZBGet logs in the web UI or with `docker compose logs nzbget`.
- Verify indexer and download client settings.

### qBittorrent
- Check logs and ensure the web UI is accessible.
- Change default password and review category setup for automation.

## General Tips
- Always check logs for error messages.
- Restart containers after making config changes.
- Update containers regularly with `scripts/manage.sh update`.
- Consult TRASHguides for best practices and advanced troubleshooting.

---

For further help, see the main README and individual service guides.
