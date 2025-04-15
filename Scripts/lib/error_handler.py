#!/usr/bin/env python3
# error_handler.py
# Error handling utilities for Obsidian vault scripts

import os
import sys
import traceback
from datetime import datetime
import functools
import json

# Try to import logger, but provide fallback if not available
try:
    from logger import VaultLogger
    logger = VaultLogger("error_handler")
except ImportError:
    import logging
    logger = logging.getLogger("error_handler")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler()
    logger.addHandler(handler)

# Vault path configuration
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
ERROR_LOG_DIR = os.path.join(VAULT_PATH, "System/Logs/Errors")

# Ensure error log directory exists
os.makedirs(ERROR_LOG_DIR, exist_ok=True)

# Error codes
ERROR_CODES = {
    # General errors
    'E001': 'Unknown error',
    'E002': 'Configuration error',
    'E003': 'Dependency error',
    'E004': 'User permissions error',
    'E005': 'Command execution error',
    
    # File system errors
    'E101': 'File not found',
    'E102': 'Permission denied',
    'E103': 'File already exists',
    'E104': 'Directory not found',
    'E105': 'Unable to read file',
    'E106': 'Unable to write file',
    'E107': 'Invalid file path',
    'E108': 'File format error',
    
    # Script execution errors
    'E201': 'Script execution failed',
    'E202': 'Script timeout',
    'E203': 'Script interrupted',
    'E204': 'Script dependency missing',
    
    # Database errors
    'E301': 'Database connection error',
    'E302': 'Database query error',
    'E303': 'Database data error',
    
    # Network errors
    'E401': 'Network connection error',
    'E402': 'API request error',
    'E403': 'Network timeout',
    'E404': 'Resource not found',
    
    # Parser errors
    'E501': 'Parse error',
    'E502': 'Validation error',
    'E503': 'Schema error'
}

class ErrorHandler:
    """Handles errors for vault scripts"""
    
    def __init__(self, script_name=None):
        self.script_name = script_name or os.path.basename(sys.argv[0])
        self.errors = []
    
    def handle_error(self, error, error_code='E001', exit_on_error=False, log=True, report=True):
        """Handle an error"""
        # Build error info
        error_info = {
            'timestamp': datetime.now().isoformat(),
            'script': self.script_name,
            'error_code': error_code,
            'error_desc': ERROR_CODES.get(error_code, 'Unknown error'),
            'error_msg': str(error),
            'traceback': traceback.format_exc()
        }
        
        # Store error
        self.errors.append(error_info)
        
        # Log error
        if log:
            error_message = f"ERROR {error_code}: {error_info['error_desc']} - {error_info['error_msg']}"
            logger.error(error_message)
        
        # Report error
        if report:
            self._report_error(error_info)
        
        # Exit if required
        if exit_on_error:
            self._log_exit(error_code)
            sys.exit(1)
            
        return error_info
    
    def _report_error(self, error_info):
        """Report error to error log"""
        try:
            # Create error log filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            error_log = os.path.join(
                ERROR_LOG_DIR, 
                f"{self.script_name}_{error_info['error_code']}_{timestamp}.json"
            )
            
            # Write error log
            with open(error_log, 'w') as f:
                json.dump(error_info, f, indent=2)
                
            logger.debug(f"Error report written to {error_log}")
        except Exception as e:
            logger.error(f"Failed to write error report: {str(e)}")
    
    def _log_exit(self, error_code):
        """Log script exit due to error"""
        exit_message = f"Script {self.script_name} exiting due to error {error_code}"
        logger.critical(exit_message)
    
    def get_errors(self):
        """Get all errors encountered"""
        return self.errors
    
    def has_errors(self):
        """Check if any errors were encountered"""
        return len(self.errors) > 0
    
    def get_error_summary(self):
        """Get summary of errors encountered"""
        if not self.errors:
            return "No errors encountered"
            
        summary = []
        for error in self.errors:
            summary.append(f"{error['error_code']}: {error['error_desc']} - {error['error_msg']}")
            
        return "\n".join(summary)

def safe_execution(func):
    """Decorator for safe function execution with error handling"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        script_name = func.__name__
        error_handler = ErrorHandler(script_name)
        
        try:
            return func(*args, **kwargs)
        except Exception as e:
            # Determine error code based on exception type
            error_code = 'E001'  # Default unknown error
            if isinstance(e, FileNotFoundError):
                error_code = 'E101'
            elif isinstance(e, PermissionError):
                error_code = 'E102'
            elif isinstance(e, TimeoutError):
                error_code = 'E202'
            elif isinstance(e, KeyboardInterrupt):
                error_code = 'E203'
            elif isinstance(e, SyntaxError) or isinstance(e, ValueError):
                error_code = 'E501'
            
            error_handler.handle_error(e, error_code=error_code, exit_on_error=True)
            return 1  # Should not reach here due to exit_on_error=True
    
    return wrapper

def get_error_details(error_code):
    """Get details for a specific error code"""
    if error_code in ERROR_CODES:
        return {
            'code': error_code,
            'description': ERROR_CODES[error_code]
        }
    else:
        return {
            'code': 'E001',
            'description': 'Unknown error code'
        }