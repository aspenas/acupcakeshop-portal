#!/usr/bin/env python3
# file_utils.py
# File utility functions for Obsidian vault scripts

import os
import sys
import re
import glob
import shutil
import yaml
from pathlib import Path
from datetime import datetime
import tempfile
import hashlib

# Vault path configuration
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

# Try to import logger, but provide fallback if not available
try:
    from logger import VaultLogger
    logger = VaultLogger("file_utils")
except ImportError:
    import logging
    logger = logging.getLogger("file_utils")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler()
    logger.addHandler(handler)

class VaultFile:
    """Class for handling Obsidian vault files"""
    
    def __init__(self, file_path):
        """Initialize with absolute or relative path"""
        # Convert relative to absolute path
        if not os.path.isabs(file_path):
            file_path = os.path.join(VAULT_PATH, file_path)
        
        self.file_path = file_path
        self.exists = os.path.exists(file_path)
        self.is_file = os.path.isfile(file_path) if self.exists else False
        self.is_dir = os.path.isdir(file_path) if self.exists else False
        self.frontmatter = None
        self.content = None
    
    def read(self):
        """Read file contents"""
        if not self.exists or not self.is_file:
            logger.warning(f"Cannot read non-existent file: {self.file_path}")
            return None
        
        try:
            with open(self.file_path, 'r', encoding='utf-8') as f:
                self.content = f.read()
            return self.content
        except Exception as e:
            logger.error(f"Error reading file {self.file_path}: {str(e)}")
            return None
    
    def write(self, content, backup=True):
        """Write content to file with optional backup"""
        # Ensure directory exists
        directory = os.path.dirname(self.file_path)
        if directory and not os.path.exists(directory):
            try:
                os.makedirs(directory, exist_ok=True)
                logger.debug(f"Created directory: {directory}")
            except Exception as e:
                logger.error(f"Error creating directory {directory}: {str(e)}")
                return False
        
        # Backup if file exists and backup requested
        if backup and self.exists:
            backup_result = self.backup()
            if not backup_result:
                logger.warning("Backup failed, proceeding with write operation")
        
        # Write content
        try:
            with open(self.file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            self.content = content
            self.exists = True
            self.is_file = True
            logger.debug(f"Successfully wrote to {self.file_path}")
            return True
        except Exception as e:
            logger.error(f"Error writing to file {self.file_path}: {str(e)}")
            return False
    
    def backup(self, backup_dir=None):
        """Create backup of the file"""
        if not self.exists or not self.is_file:
            logger.warning(f"Cannot backup non-existent file: {self.file_path}")
            return False
        
        try:
            # Determine backup path
            if backup_dir is None:
                backup_dir = os.path.join(VAULT_PATH, "System/Backups")
            
            os.makedirs(backup_dir, exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = os.path.basename(self.file_path)
            backup_path = os.path.join(backup_dir, f"{filename}.{timestamp}.bak")
            
            # Create backup
            shutil.copy2(self.file_path, backup_path)
            logger.debug(f"Created backup at {backup_path}")
            return True
        except Exception as e:
            logger.error(f"Error creating backup for {self.file_path}: {str(e)}")
            return False
    
    def restore_from_backup(self, backup_path=None):
        """Restore file from backup"""
        if backup_path is None:
            # Find most recent backup
            backup_dir = os.path.join(VAULT_PATH, "System/Backups")
            if not os.path.exists(backup_dir):
                logger.error(f"Backup directory does not exist: {backup_dir}")
                return False
            
            filename = os.path.basename(self.file_path)
            backups = [f for f in os.listdir(backup_dir) if f.startswith(filename + ".")]
            
            if not backups:
                logger.error(f"No backups found for {self.file_path}")
                return False
            
            # Sort by timestamp (newest first)
            backups.sort(reverse=True)
            backup_path = os.path.join(backup_dir, backups[0])
        
        try:
            # Restore from backup
            shutil.copy2(backup_path, self.file_path)
            logger.info(f"Restored {self.file_path} from backup {backup_path}")
            return True
        except Exception as e:
            logger.error(f"Error restoring from backup: {str(e)}")
            return False
    
    def parse_frontmatter(self):
        """Parse YAML frontmatter from markdown file"""
        if self.content is None:
            self.read()
            
        if self.content is None:
            return None
        
        # Look for YAML frontmatter
        frontmatter_match = re.match(r'^---\s*\n(.+?)\n---\s*\n', self.content, re.DOTALL)
        
        if frontmatter_match:
            frontmatter_text = frontmatter_match.group(1)
            try:
                self.frontmatter = yaml.safe_load(frontmatter_text)
                return self.frontmatter
            except Exception as e:
                logger.error(f"Error parsing frontmatter: {str(e)}")
                return None
        else:
            return None
    
    def update_frontmatter(self, new_frontmatter, create_if_missing=False):
        """Update the file's YAML frontmatter"""
        if self.content is None:
            self.read()
            
        if self.content is None:
            return False
        
        # Parse current frontmatter if we haven't already
        if self.frontmatter is None:
            self.parse_frontmatter()
        
        # If no frontmatter and not creating, return
        if self.frontmatter is None and not create_if_missing:
            logger.warning("No frontmatter found and create_if_missing is False")
            return False
        
        # If we're creating new frontmatter
        if self.frontmatter is None and create_if_missing:
            new_content = f"---\n{yaml.dump(new_frontmatter)}---\n\n{self.content}"
            return self.write(new_content)
        
        # Update existing frontmatter
        try:
            # Merge frontmatter
            updated_frontmatter = {**self.frontmatter, **new_frontmatter}
            self.frontmatter = updated_frontmatter
            
            # Replace in content
            frontmatter_yaml = yaml.dump(updated_frontmatter)
            new_content = re.sub(
                r'^---\s*\n.+?\n---\s*\n', 
                f"---\n{frontmatter_yaml}---\n\n", 
                self.content, 
                flags=re.DOTALL
            )
            
            return self.write(new_content)
        except Exception as e:
            logger.error(f"Error updating frontmatter: {str(e)}")
            return False
    
    def calculate_hash(self, algorithm='sha256'):
        """Calculate hash of file contents"""
        if not self.exists or not self.is_file:
            logger.warning(f"Cannot hash non-existent file: {self.file_path}")
            return None
        
        try:
            hash_obj = hashlib.new(algorithm)
            with open(self.file_path, 'rb') as f:
                # Read in chunks to handle large files
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_obj.update(chunk)
            return hash_obj.hexdigest()
        except Exception as e:
            logger.error(f"Error calculating hash: {str(e)}")
            return None
    
    def get_metadata(self):
        """Get file metadata"""
        if not self.exists:
            return {
                'exists': False,
                'path': self.file_path
            }
        
        try:
            stat_info = os.stat(self.file_path)
            metadata = {
                'exists': True,
                'path': self.file_path,
                'size': stat_info.st_size,
                'created': datetime.fromtimestamp(stat_info.st_ctime),
                'modified': datetime.fromtimestamp(stat_info.st_mtime),
                'accessed': datetime.fromtimestamp(stat_info.st_atime),
                'is_file': self.is_file,
                'is_dir': self.is_dir,
                'extension': os.path.splitext(self.file_path)[1]
            }
            
            # Add frontmatter if markdown file
            if self.is_file and self.file_path.lower().endswith('.md'):
                if self.frontmatter is None:
                    self.parse_frontmatter()
                metadata['has_frontmatter'] = self.frontmatter is not None
                metadata['frontmatter'] = self.frontmatter
            
            return metadata
        except Exception as e:
            logger.error(f"Error getting metadata: {str(e)}")
            return {'exists': self.exists, 'path': self.file_path, 'error': str(e)}

def find_files(path=VAULT_PATH, pattern="*", exclude_patterns=None, relative=True):
    """Find files matching pattern"""
    if exclude_patterns is None:
        exclude_patterns = []
    
    # Ensure path is absolute
    if not os.path.isabs(path):
        path = os.path.join(VAULT_PATH, path)
    
    # Find files matching pattern
    try:
        files = glob.glob(os.path.join(path, pattern), recursive=True)
        
        # Apply exclusions
        for exclude in exclude_patterns:
            exclude_files = glob.glob(os.path.join(path, exclude), recursive=True)
            files = [f for f in files if f not in exclude_files]
        
        # Convert to relative paths if requested
        if relative:
            files = [os.path.relpath(f, VAULT_PATH) for f in files]
        
        return files
    except Exception as e:
        logger.error(f"Error finding files: {str(e)}")
        return []

def is_link_valid(link, vault_path=VAULT_PATH):
    """Check if an Obsidian link is valid"""
    # Remove Obsidian link formatting
    link_match = re.search(r'\[\[([^\]|#]*)(?:\|[^\]]*)?(?:#[^\]]*)?\]\]', link)
    if link_match:
        link_target = link_match.group(1)
    else:
        link_target = link
    
    # Handle file extensions
    if not link_target.endswith('.md'):
        link_target += '.md'
    
    # Check if file exists
    target_path = os.path.join(vault_path, link_target)
    return os.path.exists(target_path)

def extract_links(content):
    """Extract Obsidian links from content"""
    # Match standard Obsidian links: [[Page]] or [[Page|Alias]]  or [[Page#Heading]]
    links = re.findall(r'\[\[([^\]]+)\]\]', content)
    
    # Process links to normalize
    processed_links = []
    for link in links:
        # Strip aliases
        if '|' in link:
            link = link.split('|')[0]
        
        # Strip headings
        if '#' in link:
            link = link.split('#')[0]
        
        processed_links.append(link)
    
    return processed_links

def create_backup_archive(files, archive_name=None, backup_dir=None):
    """Create backup archive of specified files"""
    if archive_name is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        archive_name = f"vault_backup_{timestamp}.zip"
    
    if backup_dir is None:
        backup_dir = os.path.join(VAULT_PATH, "System/Backups")
    
    # Ensure backup directory exists
    os.makedirs(backup_dir, exist_ok=True)
    
    archive_path = os.path.join(backup_dir, archive_name)
    
    try:
        # Create archive
        shutil.make_archive(
            os.path.splitext(archive_path)[0],  # Base name (without extension)
            'zip',
            root_dir=VAULT_PATH,
            base_dir='.',
            verbose=True
        )
        
        logger.info(f"Created backup archive at {archive_path}")
        return archive_path
    except Exception as e:
        logger.error(f"Error creating backup archive: {str(e)}")
        return None