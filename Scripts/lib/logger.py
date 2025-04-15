#!/usr/bin/env python3
# logger.py
# Standardized logging module for Python scripts in Obsidian vault

import os
import sys
import logging
from datetime import datetime
from pathlib import Path

# Vault path configuration
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
LOG_DIR = os.path.join(VAULT_PATH, "System/Logs")

# Create logs directory if it doesn't exist
os.makedirs(LOG_DIR, exist_ok=True)

# ANSI color codes for colored terminal output
COLORS = {
    'RESET': '\033[0m',
    'RED': '\033[91m',
    'GREEN': '\033[92m',
    'YELLOW': '\033[93m',
    'BLUE': '\033[94m',
    'PURPLE': '\033[95m',
    'CYAN': '\033[96m',
    'WHITE': '\033[97m'
}

# Custom log levels
SUCCESS = 25  # Between INFO and WARNING

class ColoredFormatter(logging.Formatter):
    """Custom formatter to add colors to log output"""
    
    def __init__(self, fmt=None, datefmt=None, style='%'):
        super().__init__(fmt, datefmt, style)
        self.FORMATS = {
            logging.DEBUG: COLORS['BLUE'] + self._fmt + COLORS['RESET'],
            logging.INFO: COLORS['WHITE'] + self._fmt + COLORS['RESET'],
            SUCCESS: COLORS['GREEN'] + self._fmt + COLORS['RESET'],
            logging.WARNING: COLORS['YELLOW'] + self._fmt + COLORS['RESET'],
            logging.ERROR: COLORS['RED'] + self._fmt + COLORS['RESET'],
            logging.CRITICAL: COLORS['PURPLE'] + self._fmt + COLORS['RESET'],
        }
        self.style = style  # Store style explicitly
    
    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt, self.datefmt, self.style)
        return formatter.format(record)

class VaultLogger:
    """Standardized logger for Obsidian vault scripts"""
    
    def __init__(self, script_name=None, log_file=None, console_level=logging.INFO, file_level=logging.DEBUG):
        # Add custom log level
        logging.addLevelName(SUCCESS, 'SUCCESS')
        
        # Create logger
        self.logger = logging.getLogger(script_name)
        self.logger.setLevel(logging.DEBUG)
        self.logger.handlers = []  # Clear existing handlers
        
        # Determine log file path
        if log_file is None and script_name is not None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_file = os.path.join(LOG_DIR, f"{script_name}_{timestamp}.log")
        
        # Console handler with colored output
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(console_level)
        console_format = '%(levelname)s: %(message)s'
        console_formatter = ColoredFormatter(console_format)
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)
        
        # File handler if log_file is provided
        if log_file:
            # Create directory if it doesn't exist
            log_dir = os.path.dirname(log_file)
            if log_dir:
                os.makedirs(log_dir, exist_ok=True)
                
            file_handler = logging.FileHandler(log_file)
            file_handler.setLevel(file_level)
            file_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            file_formatter = logging.Formatter(file_format)
            file_handler.setFormatter(file_formatter)
            self.logger.addHandler(file_handler)
    
    def debug(self, msg, *args, **kwargs):
        """Log a debug message"""
        self.logger.debug(msg, *args, **kwargs)
    
    def info(self, msg, *args, **kwargs):
        """Log an info message"""
        self.logger.info(msg, *args, **kwargs)
    
    def success(self, msg, *args, **kwargs):
        """Log a success message (custom level)"""
        self.logger.log(SUCCESS, msg, *args, **kwargs)
    
    def warning(self, msg, *args, **kwargs):
        """Log a warning message"""
        self.logger.warning(msg, *args, **kwargs)
    
    def error(self, msg, *args, **kwargs):
        """Log an error message"""
        self.logger.error(msg, *args, **kwargs)
    
    def critical(self, msg, *args, **kwargs):
        """Log a critical message"""
        self.logger.critical(msg, *args, **kwargs)
    
    def exception(self, msg, *args, exc_info=True, **kwargs):
        """Log an exception with traceback"""
        self.logger.exception(msg, *args, exc_info=exc_info, **kwargs)
    
    @staticmethod
    def rotate_logs(max_logs=30, log_dir=LOG_DIR):
        """Rotate logs, keeping only the most recent ones"""
        try:
            log_files = [f for f in os.listdir(log_dir) if f.endswith('.log')]
            # Sort by modification time (newest first)
            log_files.sort(key=lambda x: os.path.getmtime(os.path.join(log_dir, x)), reverse=True)
            
            # Remove older logs
            for old_log in log_files[max_logs:]:
                os.remove(os.path.join(log_dir, old_log))
                
            return True
        except Exception as e:
            print(f"Error rotating logs: {str(e)}")
            return False
    
    @staticmethod
    def get_recent_logs(n=5, log_dir=LOG_DIR, script_name=None):
        """Get the n most recent log files for a script"""
        try:
            if script_name:
                log_files = [f for f in os.listdir(log_dir) if f.startswith(f"{script_name}_") and f.endswith('.log')]
            else:
                log_files = [f for f in os.listdir(log_dir) if f.endswith('.log')]
                
            # Sort by modification time (newest first)
            log_files.sort(key=lambda x: os.path.getmtime(os.path.join(log_dir, x)), reverse=True)
            
            return log_files[:n]
        except Exception as e:
            print(f"Error getting recent logs: {str(e)}")
            return []

# For backwards compatibility
get_logger = VaultLogger