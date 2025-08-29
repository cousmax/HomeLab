#!/bin/bash
# filepath: Media Management/install.sh

# HomeLab Media Stack Installer
# Proxmox Helper Scripts Style
# Author: cousmax

# Color definitions
RD='\033[01;31m'
BL='\033[36m' 
GN='\033[1;92m'
YW='\033[33m'
CL='\033[m'
BFR="\\r\\033[K"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

function header_info {
clear
cat <<"EOF"
    __  __          _ _         _____ _             _    
   |  \/  | ___  __| (_) __ _  / ____| |_ __ _  ___| | __
   | |\/| |/ _ \/ _` | |/ _` | \___ \| __/ _` |/ __| |/ /
   | |  | |  __/ (_| | | (_| |  ___) | || (_| | (__|   < 
   |_|  |_|\___|\__,_|_|\__,_| |____/ \__\__,_|\___|_|\_\
                                                         
         Automated *arr Stack Deployment
EOF
echo -e " ${BL}Using TRASHguides Folder Structure & NFS Storage${CL}"
echo
}

msg_info() { echo -ne " ${BL}ⓘ${CL} $1..."; }
msg_ok() { echo -e "${BFR} ${CM} $1"; }
msg_error() { echo -e "${BFR} ${CROSS} $1"; }
msg_warn() { echo -e "${BFR} ${YW}⚠${CL} $1"; }

spinner() {
    local pid=$1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

update_system() {
    header_info
    msg_info "Updating system packages"
    
    if command -v apt &> /dev/null; then
        (sudo apt update && sudo apt upgrade -y) &> /dev/null &
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y &> /dev/null &
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm &> /dev/null &
    else
        msg_error "Unsupported package manager"
        exit 1
    fi
    
    spinner $!
    wait $! && msg_ok "System updated" || { msg_error "Update failed"; exit 1; }
}

install_docker() {
    header_info
    msg_info "Installing Docker"
    
    # Detect distro
    . /etc/os-release
    DISTRO=$ID
    
    case "$DISTRO" in
        ubuntu|debian)
            (
                sudo apt remove docker docker-engine docker.io containerd runc -y &> /dev/null || true
                sudo apt install ca-certificates curl gnupg lsb-release -y &> /dev/null
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list &> /dev/null
                sudo apt update &> /dev/null
                sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y &> /dev/null
            ) &
            ;;
        fedora|centos|rhel)
            (
                sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine -y &> /dev/null || true
                sudo dnf install dnf-plugins-core -y &> /dev/null
                sudo dnf config-manager --add-repo https://download.docker.com/linux/$DISTRO/docker-ce.repo &> /dev/null
                sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y &> /dev/null
            ) &
            ;;
        arch)
            (sudo pacman -S docker docker-compose --noconfirm) &> /dev/null &
            ;;
    esac
    
    spinner $!
    wait $! && msg_ok "Docker installed" || { msg_error "Docker installation failed"; exit 1; }
    
    # Post-install steps
    msg_info "Configuring Docker"
    (
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
    ) &> /dev/null &
    
    spinner $!
    wait $! && msg_ok "Docker configured" || { msg_error "Docker configuration failed"; exit 1; }
}

setup_folders() {
    header_info
    msg_info "Setting up TRASHguides folder structure"
    
    # Get data path from user
    echo -ne " ${BL}Enter your data path [/mnt/media]: ${CL}"
    read -r DATA_PATH
    DATA_PATH=${DATA_PATH:-/mnt/media}
    
    # Create TRASHguides folder structure
    (
        sudo mkdir -p "$DATA_PATH"/{torrents,usenet,media}/{movies,tv,music}
        sudo mkdir -p "$DATA_PATH"/torrents/{books,software}
        sudo mkdir -p "$DATA_PATH"/usenet/{books,software}
        sudo mkdir -p "$DATA_PATH"/media/youtube
        sudo chown -R $USER:$USER "$DATA_PATH"
    ) &> /dev/null &
    
    spinner $!
    wait $! && msg_ok "Folder structure created" || { msg_error "Folder creation failed"; exit 1; }
    
    echo "$DATA_PATH" > /tmp/data_path
}

setup_nfs() {
    header_info
    msg_info "Setting up NFS share"
    
    DATA_PATH=$(cat /tmp/data_path)
    
    echo -ne " ${BL}Enter NFS server IP: ${CL}"
    read -r NFS_SERVER
    echo -ne " ${BL}Enter NFS share path [/mnt/media]: ${CL}"
    read -r NFS_SHARE
    NFS_SHARE=${NFS_SHARE:-/mnt/media}
    
    (
        sudo apt install nfs-common -y &> /dev/null || sudo dnf install nfs-utils -y &> /dev/null || sudo pacman -S nfs-utils --noconfirm &> /dev/null
        sudo mkdir -p "$DATA_PATH"
        echo "$NFS_SERVER:$NFS_SHARE $DATA_PATH nfs defaults 0 0" | sudo tee -a /etc/fstab &> /dev/null
        sudo mount -a
    ) &> /dev/null &
    
    spinner $!
    wait $! && msg_ok "NFS share configured" || msg_warn "NFS setup failed - you can mount manually later"
}

deploy_stack() {
    header_info
    msg_info "Downloading docker-compose.yml"
    
    DATA_PATH=$(cat /tmp/data_path)
    
    # Create deployment directory
    mkdir -p ~/media-stack
    cd ~/media-stack
    
    # Download docker-compose.yml
    curl -fsSL "https://raw.githubusercontent.com/cousmax/HomeLab/Dynamic-Servarr/Media%20Management/docker-compose.yml" -o docker-compose.yml &
    
    spinner $!
    wait $! && msg_ok "Downloaded docker-compose.yml" || { msg_error "Download failed"; exit 1; }
    
    msg_info "Creating .env file"
    
    # Create .env file with user input
    cat > .env << EOF
# User/Group IDs
PUID=$(id -u)
PGID=$(id -g)
TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")

# Data path
DATA_PATH=$DATA_PATH

# VPN settings (configure these for your VPN provider)
FIREWALL_VPN_INPUT_PORTS=8080
EOF
    
    msg_ok ".env file created"
    
    msg_info "Starting media stack"
    docker compose up -d &> /dev/null &
    
    spinner $!
    wait $! && msg_ok "Media stack deployed" || { msg_error "Deployment failed"; exit 1; }
}

show_completion() {
    header_info
    echo -e " ${GN}🎉 Installation Complete!${CL}"
    echo
    echo -e " ${BL}Your media stack is now running at:${CL}"
    echo -e "   • Sonarr (TV):      http://$(hostname -I | awk '{print $1}'):8989"
    echo -e "   • Radarr (Movies):  http://$(hostname -I | awk '{print $1}'):7878"
    echo -e "   • Lidarr (Music):   http://$(hostname -I | awk '{print $1}'):8686"
    echo -e "   • Bazarr (Subs):    http://$(hostname -I | awk '{print $1}'):6767"
    echo -e "   • Prowlarr:         http://$(hostname -I | awk '{print $1}'):9696"
    echo -e "   • qBittorrent:      http://$(hostname -I | awk '{print $1}'):8080"
    echo -e "   • Jellyseerr:       http://$(hostname -I | awk '{print $1}'):5055"
    echo
    echo -e " ${BL}Stack management:${CL}"
    echo -e "   • Start:  ${YW}cd ~/media-stack && docker compose up -d${CL}"
    echo -e "   • Stop:   ${YW}cd ~/media-stack && docker compose down${CL}"
    echo -e "   • Logs:   ${YW}cd ~/media-stack && docker compose logs -f${CL}"
    echo
    echo -e " ${YW}⚠ Don't forget to configure your VPN settings in ~/media-stack/.env${CL}"
}

main() {
    header_info
    echo -e " ${BL}This installer will:${CL}"
    echo -e "   1. Update your system"
    echo -e "   2. Install Docker"  
    echo -e "   3. Setup TRASHguides folder structure"
    echo -e "   4. Configure NFS storage"
    echo -e "   5. Deploy your media stack"
    echo
    echo -ne " ${YW}Continue? [Y/n]: ${CL}"
    read -r CONTINUE
    
    if [[ ! "$CONTINUE" =~ ^[Nn] ]]; then
        update_system
        
        if ! command -v docker &> /dev/null; then
            install_docker
        else
            msg_ok "Docker already installed"
        fi
        
        setup_folders
        setup_nfs
        deploy_stack
        show_completion
        
        # Cleanup
        rm -f /tmp/data_path
        
        echo -e " ${GN}✓ Setup complete! Enjoy your media stack!${CL}"
    else
        msg_warn "Installation cancelled"
        exit 0
    fi
}

main "$@"