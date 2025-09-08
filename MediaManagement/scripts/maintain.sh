#!/bin/bash
# HomeLab Media Stack Maintenance Wrapper

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

print_colored() {
    echo -e "${2}${1}${NC}"
}

print_header() {
    print_colored "=== $1 ===" $CYAN
}

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/maintain-stack.py"

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    print_colored "❌ Error: maintain-stack.py not found in $SCRIPT_DIR" $RED
    exit 1
fi

# Check if we're in the right directory (should have docker-compose.yml)
if [ ! -f "../docker-compose.yml" ] && [ ! -f "docker-compose.yml" ]; then
    print_colored "⚠ Warning: No docker-compose.yml found in current or parent directory" $YELLOW
    print_colored "Make sure you're running this from your media stack directory" $YELLOW
fi

# Check Python availability
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    print_colored "❌ Error: Python not found. Please install Python 3" $RED
    exit 1
fi

print_header "HomeLab Media Stack Maintenance"
print_colored "Using Python: $($PYTHON_CMD --version 2>&1)" $BLUE

# Run the Python maintenance script with all arguments
exec "$PYTHON_CMD" "$PYTHON_SCRIPT" "$@"
