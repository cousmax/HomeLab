#!/usr/bin/env python3
"""
Test script for directory creation functionality
"""

import os
import sys
import subprocess
from pathlib import Path

# Add the script directory to path so we can import the generator
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

try:
    from generate_compose_simple import SimpleComposeGenerator, Colors
except ImportError:
    # Fallback if module name is different
    exec(open('generate-compose-simple.py').read())

def test_directory_creation():
    print(f"{Colors.CYAN}Testing Trash Guides directory creation...{Colors.NC}")
    
    # Create a test generator
    generator = SimpleComposeGenerator()
    
    # Use a test directory in the current location
    test_path = "./test_media"
    generator.config["data_path"] = test_path
    
    # Test services
    test_services = ["sonarr", "radarr", "qbittorrent"]
    
    try:
        # Test directory creation
        generator.create_directories(test_services)
        
        print(f"{Colors.GREEN}✓ Test completed successfully!{Colors.NC}")
        print(f"{Colors.BLUE}Test directory created at: {test_path}{Colors.NC}")
        
        # Show the structure
        if os.path.exists(test_path):
            print(f"\n{Colors.CYAN}Created structure:{Colors.NC}")
            for root, dirs, files in os.walk(test_path):
                level = root.replace(test_path, '').count(os.sep)
                indent = ' ' * 2 * level
                print(f"{indent}{os.path.basename(root)}/")
                subindent = ' ' * 2 * (level + 1)
                for d in dirs:
                    print(f"{subindent}{d}/")
        
        # Cleanup option
        cleanup = input(f"\n{Colors.YELLOW}Remove test directory? [y/N]: {Colors.NC}").strip().lower()
        if cleanup in ['y', 'yes']:
            import shutil
            shutil.rmtree(test_path)
            print(f"{Colors.GREEN}✓ Test directory removed{Colors.NC}")
        
    except Exception as e:
        print(f"{Colors.RED}✗ Test failed: {e}{Colors.NC}")
        return False
    
    return True

if __name__ == "__main__":
    test_directory_creation()
