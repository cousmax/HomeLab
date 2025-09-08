#!/usr/bin/env bash
# Docker Compose Stack Simulator (Bash Version)
# Quick validation and testing tools

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Helper functions
print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

COMPOSE_FILE="${1:-docker-compose.yml}"
ENV_FILE=".env"

print_header "Docker Compose Stack Simulator"

# Check if files exist
check_files() {
    print_header "File Existence Check"
    
    if [ -f "$COMPOSE_FILE" ]; then
        print_success "Found compose file: $COMPOSE_FILE"
    else
        print_error "Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    if [ -f "$ENV_FILE" ]; then
        print_success "Found environment file: $ENV_FILE"
    else
        print_warning "Environment file not found: $ENV_FILE"
    fi
}

# Validate Docker Compose syntax
validate_syntax() {
    print_header "Syntax Validation"
    
    if command -v docker-compose &> /dev/null; then
        if docker-compose config --quiet 2>/dev/null; then
            print_success "Docker Compose syntax is valid"
            return 0
        else
            print_error "Docker Compose syntax validation failed"
            docker-compose config 2>&1 | head -10
            return 1
        fi
    else
        print_warning "docker-compose not found, skipping syntax validation"
        return 0
    fi
}

# Check port availability
check_ports() {
    print_header "Port Availability Check"
    
    # Extract ports from compose file
    ports=$(docker-compose config 2>/dev/null | grep -E "^\s*-\s*[\"']?\d+:\d+" | sed -E 's/.*"([0-9]+):.*/\1/' | sort -u)
    
    if [ -z "$ports" ]; then
        print_info "No exposed ports found"
        return
    fi
    
    port_conflicts=0
    for port in $ports; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_warning "Port $port is already in use"
            ((port_conflicts++))
        else
            print_success "Port $port is available"
        fi
    done
    
    if [ $port_conflicts -gt 0 ]; then
        print_warning "$port_conflicts port conflicts detected"
    else
        print_success "No port conflicts found"
    fi
}

# Check Docker daemon
check_docker() {
    print_header "Docker Environment Check"
    
    if command -v docker &> /dev/null; then
        print_success "Docker CLI found"
        
        if docker info &> /dev/null; then
            print_success "Docker daemon is running"
            docker_version=$(docker --version)
            print_info "$docker_version"
        else
            print_error "Docker daemon is not running"
            return 1
        fi
    else
        print_error "Docker not found"
        return 1
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose found"
        compose_version=$(docker-compose --version)
        print_info "$compose_version"
    else
        print_error "Docker Compose not found"
        return 1
    fi
}

# Check directories and volumes
check_directories() {
    print_header "Directory Structure Check"
    
    # Extract volume mounts from compose file (simplified)
    volumes=$(docker-compose config 2>/dev/null | grep -E "^\s*-\s*[\"']?[^/]*/" | sed -E 's/.*"([^"]*):.*".*/\1/' | sort -u)
    
    if [ -z "$volumes" ]; then
        print_info "No local volume mounts found"
        return
    fi
    
    missing_dirs=0
    for volume in $volumes; do
        # Skip special Docker paths
        if [[ "$volume" == "/var/run/docker.sock" ]] || [[ "$volume" == "/etc/"* ]]; then
            continue
        fi
        
        if [ -d "$volume" ]; then
            print_success "Directory exists: $volume"
        else
            print_warning "Directory missing: $volume"
            ((missing_dirs++))
        fi
    done
    
    if [ $missing_dirs -gt 0 ]; then
        print_info "Run 'mkdir -p' to create missing directories"
    fi
}

# Simulate service startup
simulate_startup() {
    print_header "Service Startup Simulation"
    
    services=$(docker-compose config --services 2>/dev/null || echo "Unable to list services")
    
    if [ "$services" != "Unable to list services" ]; then
        print_info "Services that would be started:"
        echo "$services" | while read -r service; do
            echo -e "${WHITE}  → $service${NC}"
        done
    else
        print_warning "Could not determine service startup order"
    fi
}

# Dry run test
dry_run_test() {
    print_header "Dry Run Test"
    
    read -p "$(echo -e "${BLUE}Perform dry run test? This will pull images but not start containers (y/n): ${NC}")" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Running dry run test..."
        
        if docker-compose pull --quiet 2>/dev/null; then
            print_success "All images pulled successfully"
        else
            print_warning "Some images could not be pulled (may not exist yet)"
        fi
        
        if docker-compose config --quiet && docker-compose up --no-start 2>/dev/null; then
            print_success "Containers created successfully (not started)"
            
            # Clean up
            docker-compose down --remove-orphans &>/dev/null
            print_info "Test containers cleaned up"
        else
            print_warning "Container creation test failed"
        fi
    fi
}

# Network simulation
check_network() {
    print_header "Network Configuration Check"
    
    # Check if custom networks are defined
    networks=$(docker-compose config 2>/dev/null | grep -A5 "^networks:" | grep -E "^\s+[a-zA-Z]" | sed 's/://' | tr -d ' ')
    
    if [ -n "$networks" ]; then
        print_success "Custom networks defined:"
        echo "$networks" | while read -r network; do
            if [ -n "$network" ]; then
                echo -e "${WHITE}  → $network${NC}"
            fi
        done
    else
        print_info "Using default Docker network"
    fi
}

# Environment variables check
check_env_vars() {
    print_header "Environment Variables Check"
    
    if [ -f "$ENV_FILE" ]; then
        required_vars=("PUID" "PGID" "TZ" "DATA_PATH")
        missing_vars=()
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "$ENV_FILE"; then
                value=$(grep "^$var=" "$ENV_FILE" | cut -d'=' -f2)
                print_success "$var is set: $value"
            else
                print_warning "$var is not set in $ENV_FILE"
                missing_vars+=("$var")
            fi
        done
        
        if [ ${#missing_vars[@]} -gt 0 ]; then
            print_info "Consider adding missing variables to $ENV_FILE"
        fi
    else
        print_warning "No $ENV_FILE file found"
    fi
}

# Main execution
main() {
    check_files
    check_docker
    validate_syntax
    check_env_vars
    check_ports
    check_directories
    check_network
    simulate_startup
    dry_run_test
    
    print_header "Simulation Complete"
    print_success "Stack simulation finished"
    echo
    print_info "Next steps:"
    echo -e "  1. Fix any warnings shown above"
    echo -e "  2. Create missing directories: ${YELLOW}mkdir -p <path>${NC}"
    echo -e "  3. Update $ENV_FILE with your settings"
    echo -e "  4. Start the stack: ${YELLOW}docker-compose up -d${NC}"
    echo -e "  5. Monitor logs: ${YELLOW}docker-compose logs -f${NC}"
}

# Run main function
main "$@"
