#!/bin/bash

# Docker Group Activation Script
# Use this script to activate Docker group membership without logging out

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Docker Group Activation${NC}"
echo "This script will activate your Docker group membership for the current session."
echo

# Check if user is in docker group
if groups | grep -q docker; then
    echo -e "${GREEN}✓ User is already showing docker group membership${NC}"
else
    # Check if user is actually in docker group
    if getent group docker | grep -q "$USER"; then
        echo -e "${YELLOW}User is in docker group but needs activation${NC}"
        echo "Activating docker group with newgrp..."
        echo
        echo "You can now run Docker commands without sudo:"
        echo "  docker --version"
        echo "  docker run hello-world"
        echo "  docker ps"
        echo
        exec newgrp docker
    else
        echo "Error: User $USER is not in the docker group."
        echo "Please run: sudo usermod -aG docker $USER"
        echo "Then use this script to activate the group."
        exit 1
    fi
fi

# Test Docker access
echo "Testing Docker access..."
if docker --version &> /dev/null; then
    echo -e "${GREEN}✓ Docker command available${NC}"
    echo "Docker version: $(docker --version)"
    
    echo
    echo "Testing with hello-world container..."
    if docker run --rm hello-world &> /dev/null; then
        echo -e "${GREEN}✓ Docker is working correctly!${NC}"
    else
        echo "Docker test failed. You may need to check Docker service status."
    fi
else
    echo "Docker command not available. Please check Docker installation."
    exit 1
fi

echo
echo -e "${GREEN}Docker group activation completed!${NC}"
echo "You can now use Docker without sudo in this session."
