#!/usr/bin/env python3
# config_manager.py
# Configuration management for Obsidian vault scripts

import os
import sys
import json
import yaml
from pathlib import Path

# Try to import logger, but provide fallback if not available
try:
    from logger import VaultLogger
    logger = VaultLogger("config_manager")
except ImportError:
    import logging
    logger = logging.getLogger("config_manager")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler()
    logger.addHandler(handler)

# Vault path configuration
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
CONFIG_DIR = os.path.join(VAULT_PATH, "System/Configuration")

# Ensure config directory exists
os.makedirs(CONFIG_DIR, exist_ok=True)

class ConfigManager:
    """Manages configuration for the vault scripts"""
    
    def __init__(self, config_file=None, config_name=None):
        self.config_name = config_name or 'default'
        
        # Set config file path
        if config_file is None:
            self.config_file = os.path.join(CONFIG_DIR, f"{self.config_name}_config.json")
        elif os.path.isabs(config_file):
            self.config_file = config_file
        else:
            self.config_file = os.path.join(CONFIG_DIR, config_file)
        
        # Initialize config
        self.config = {}
        self.load_config()
    
    def load_config(self):
        """Load configuration from file"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r') as f:
                    # Determine file type and parse accordingly
                    if self.config_file.endswith('.json'):
                        self.config = json.load(f)
                    elif self.config_file.endswith(('.yaml', '.yml')):
                        self.config = yaml.safe_load(f)
                    else:
                        logger.warning(f"Unknown config file type: {self.config_file}")
                        return False
                        
                logger.debug(f"Loaded configuration from {self.config_file}")
                return True
            else:
                logger.debug(f"Config file does not exist: {self.config_file}")
                return False
        except Exception as e:
            logger.error(f"Error loading config: {str(e)}")
            return False
    
    def save_config(self):
        """Save configuration to file"""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
            
            # Write config file
            with open(self.config_file, 'w') as f:
                if self.config_file.endswith('.json'):
                    json.dump(self.config, f, indent=2)
                elif self.config_file.endswith(('.yaml', '.yml')):
                    yaml.dump(self.config, f, default_flow_style=False)
                else:
                    logger.warning(f"Unknown config file type: {self.config_file}")
                    return False
            
            logger.debug(f"Saved configuration to {self.config_file}")
            return True
        except Exception as e:
            logger.error(f"Error saving config: {str(e)}")
            return False
    
    def get(self, path, default=None):
        """Get configuration value by path (dot-separated)"""
        try:
            # Split path into components
            parts = path.split('.')
            
            # Navigate through config
            current = self.config
            for part in parts:
                if part in current:
                    current = current[part]
                else:
                    return default
            
            return current
        except Exception as e:
            logger.error(f"Error getting config value {path}: {str(e)}")
            return default
    
    def set(self, path, value):
        """Set configuration value by path (dot-separated)"""
        try:
            # Split path into components
            parts = path.split('.')
            
            # Navigate through config, creating objects as needed
            current = self.config
            for i, part in enumerate(parts[:-1]):
                if part not in current:
                    current[part] = {}
                current = current[part]
            
            # Set the final value
            current[parts[-1]] = value
            
            logger.debug(f"Set config {path} = {value}")
            return True
        except Exception as e:
            logger.error(f"Error setting config value {path}: {str(e)}")
            return False
    
    def delete(self, path):
        """Delete configuration value by path (dot-separated)"""
        try:
            # Split path into components
            parts = path.split('.')
            
            # Navigate through config
            current = self.config
            parent_stack = []
            
            for i, part in enumerate(parts[:-1]):
                if part in current:
                    parent_stack.append((current, part))
                    current = current[part]
                else:
                    # Path doesn't exist
                    return False
            
            # Delete the final value
            if parts[-1] in current:
                del current[parts[-1]]
                logger.debug(f"Deleted config {path}")
                return True
            else:
                return False
        except Exception as e:
            logger.error(f"Error deleting config value {path}: {str(e)}")
            return False
    
    def merge(self, config_dict):
        """Merge configuration with another dictionary"""
        try:
            def _merge_dict(source, update):
                for key, value in update.items():
                    if key in source and isinstance(source[key], dict) and isinstance(value, dict):
                        _merge_dict(source[key], value)
                    else:
                        source[key] = value
            
            _merge_dict(self.config, config_dict)
            logger.debug(f"Merged configuration with {len(config_dict)} keys")
            return True
        except Exception as e:
            logger.error(f"Error merging config: {str(e)}")
            return False
    
    def reset(self):
        """Reset configuration to empty"""
        self.config = {}
        logger.debug("Reset configuration to empty")
        return True
    
    def get_all(self):
        """Get entire configuration"""
        return self.config

def get_config(config_name):
    """Get configuration instance by name"""
    config_file = f"{config_name}_config.json"
    return ConfigManager(config_file, config_name)