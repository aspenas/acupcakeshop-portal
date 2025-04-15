#!/usr/bin/env python3
# verify_paths.py
# Verifies that path resolution is working correctly in scripts
# Created: 2025-04-15

import os
import sys
import json

print("=== Path Verification ===")
print(f"Current script: {__file__}")
print(f"Current directory: {os.getcwd()}")
print(f"Script directory: {os.path.dirname(os.path.abspath(__file__))}")
print(f"Vault path (relative): {os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')}")
print(f"Vault path (absolute): {os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))}")

# Add lib directory to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(SCRIPT_DIR, "lib")
sys.path.append(LIB_DIR)

try:
    # Try to import from our libraries
    from logger import VaultLogger
    from config_manager import ConfigManager
    from file_utils import VaultFile
    
    print("\n=== Library Imports ===")
    print("Successfully imported library modules")
    
    # Try to use the config manager
    config = ConfigManager("script_consolidation_config.json", "script_consolidation")
    vault_path = config.get("vault_path", "unknown")
    print(f"Vault path from config: {vault_path}")
    
    # Try to read the script database
    script_db_path = os.path.join(os.path.abspath(os.path.join(SCRIPT_DIR, "..")), "System/Configuration/script_database.csv")
    if os.path.exists(script_db_path):
        with open(script_db_path, 'r') as f:
            print(f"\n=== Script Database ===")
            print(f"First 3 lines of script database:")
            for i, line in enumerate(f):
                if i < 3:
                    print(line.strip())
    
    print("\nAll path tests completed successfully")
except ImportError as e:
    print(f"\nError importing libraries: {str(e)}")
    print(f"Library directory: {LIB_DIR}")
    print(f"Files in library directory: {os.listdir(LIB_DIR) if os.path.exists(LIB_DIR) else 'Directory not found'}")
    
except Exception as e:
    print(f"\nError during test: {str(e)}")
    
print("\n=== Test Complete ===")