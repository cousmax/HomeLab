#!/usr/bin/env bash
# Quick Docker Compose Test Runner
# Fast validation and testing tools

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

COMPOSE_FILE="${1:-docker-compose.yml}"

echo -e "${BLUE}🧪 Quick Docker Compose Test${NC}\n"

# Test 1: File exists
if [ -f "$COMPOSE_FILE" ]; then
    echo -e "${GREEN}✓ Compose file found: $COMPOSE_FILE${NC}"
else
    echo -e "${RED}✗ Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

# Test 2: Syntax validation
echo -e "\n${BLUE}🔍 Syntax Check${NC}"
if docker-compose -f "$COMPOSE_FILE" config --quiet 2>/dev/null; then
    echo -e "${GREEN}✓ Syntax is valid${NC}"
else
    echo -e "${RED}✗ Syntax errors found:${NC}"
    docker-compose -f "$COMPOSE_FILE" config 2>&1 | head -5
    echo -e "${YELLOW}⚠ Fix syntax errors before proceeding${NC}"
fi

# Test 3: Service list
echo -e "\n${BLUE}📋 Services${NC}"
services=$(docker-compose -f "$COMPOSE_FILE" config --services 2>/dev/null)
if [ $? -eq 0 ]; then
    service_count=$(echo "$services" | wc -l)
    echo -e "${GREEN}✓ Found $service_count services:${NC}"
    echo "$services" | sed 's/^/  • /'
else
    echo -e "${RED}✗ Could not list services${NC}"
fi

# Test 4: Port check
echo -e "\n${BLUE}🔌 Port Check${NC}"
ports=$(docker-compose -f "$COMPOSE_FILE" config 2>/dev/null | grep -E "^\s*-\s*[\"']?\d+:" | sed -E 's/.*"([0-9]+):.*/\1/' | sort -nu)

if [ -n "$ports" ]; then
    echo "Checking ports: $(echo $ports | tr '\n' ' ')"
    conflict_found=false
    for port in $ports; do
        if command -v netstat >/dev/null && netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${RED}✗ Port $port is in use${NC}"
            conflict_found=true
        elif command -v ss >/dev/null && ss -tuln 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${RED}✗ Port $port is in use${NC}"
            conflict_found=true
        else
            echo -e "  ${GREEN}✓ Port $port is available${NC}"
        fi
    done
    
    if [ "$conflict_found" = true ]; then
        echo -e "${YELLOW}⚠ Some ports are in use. Stop conflicting services or change ports.${NC}"
    fi
else
    echo -e "${BLUE}ℹ No exposed ports found${NC}"
fi

# Test 5: Image availability
echo -e "\n${BLUE}🐳 Image Check${NC}"
if docker-compose -f "$COMPOSE_FILE" config --quiet 2>/dev/null; then
    echo -e "${YELLOW}• Checking if images exist (this may take a moment)...${NC}"
    if timeout 30s docker-compose -f "$COMPOSE_FILE" pull --quiet 2>/dev/null; then
        echo -e "${GREEN}✓ All images are available${NC}"
    else
        echo -e "${YELLOW}⚠ Some images may not be available or pull timed out${NC}"
        echo -e "  Run manually: docker-compose pull"
    fi
else
    echo -e "${RED}✗ Cannot check images due to syntax errors${NC}"
fi

# Test 6: Quick dry run
echo -e "\n${BLUE}🔄 Dry Run Test${NC}"
read -p "Run quick dry run test? (creates but doesn't start containers) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}• Running dry run...${NC}"
    
    if docker-compose -f "$COMPOSE_FILE" up --no-start 2>/dev/null; then
        echo -e "${GREEN}✓ Containers created successfully${NC}"
        
        # Show created containers
        containers=$(docker-compose -f "$COMPOSE_FILE" ps -a --format "table {{.Name}}\t{{.Image}}\t{{.State}}" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo -e "\n${BLUE}Created containers:${NC}"
            echo "$containers"
        fi
        
        # Cleanup
        echo -e "\n${YELLOW}• Cleaning up test containers...${NC}"
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans >/dev/null 2>&1
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    else
        echo -e "${RED}✗ Container creation failed${NC}"
        echo -e "${YELLOW}Check the output above for errors${NC}"
    fi
else
    echo -e "${BLUE}ℹ Skipping dry run test${NC}"
fi

# Summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo -e "${GREEN}✓ File validation complete${NC}"
echo -e "${BLUE}ℹ Review any warnings above before running 'docker-compose up -d'${NC}"

# Quick commands
echo -e "\n${BLUE}🚀 Quick Commands${NC}"
echo -e "  Start stack:     ${YELLOW}docker-compose up -d${NC}"
echo -e "  View logs:       ${YELLOW}docker-compose logs -f${NC}"
echo -e "  Stop stack:      ${YELLOW}docker-compose down${NC}"
echo -e "  Check status:    ${YELLOW}docker-compose ps${NC}"
