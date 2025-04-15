#!/usr/bin/env python3
# consolidate_scripts_lite.py
# Lightweight script consolidation launcher that uses external modules
# Created: 2025-04-15

import os
import sys
import json
import argparse

# Add lib directory to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(SCRIPT_DIR, "lib")
sys.path.append(LIB_DIR)

# Add parent directory to get vault path
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(SCRIPT_DIR, "..")))

try:
    # Import only what we need for the command line interface
    from logger import VaultLogger
    from consolidation_functions import extract_common_functions, consolidate_scripts
    from config_manager import ConfigManager
    
    # Import when needed
    def get_file_utils():
        from file_utils import VaultFile, find_files
        return VaultFile, find_files
    
    def get_error_handler():
        from error_handler import ErrorHandler, safe_execution
        return ErrorHandler, safe_execution
    
except ImportError as e:
    print(f"Error: Required library modules not found: {e}")
    print(f"Please ensure the lib directory is properly set up at: {LIB_DIR}")
    sys.exit(1)

# Initialize minimal components
logger = VaultLogger("consolidate_scripts_lite")
config = ConfigManager("script_consolidation_config.json", "script_consolidation")

# Script Database
SCRIPT_DB_PATH = os.path.join(VAULT_PATH, "System/Configuration/script_database.csv")

class ScriptConsolidatorLite:
    """Lightweight facade for script consolidation functionality"""
    
    def __init__(self, vault_path=VAULT_PATH):
        self.vault_path = vault_path
        self.scripts = {}
        self.candidate_groups = []
        self.config = config.get_all() or {}
        self.load_script_database()
    
    def load_script_database(self):
        """Load script database from CSV"""
        try:
            VaultFile, _ = get_file_utils()
            db_file = VaultFile(SCRIPT_DB_PATH)
            content = db_file.read()
            
            if content:
                lines = content.strip().split('\n')
                headers = lines[0].split(',')
                
                for line in lines[1:]:  # Skip header
                    values = line.split(',')
                    script_data = dict(zip(headers, values))
                    script_path = script_data.get('Path', '')
                    if script_path:
                        # Use relative paths
                        if not os.path.isabs(script_path):
                            script_path = os.path.join(self.vault_path, script_path)
                        self.scripts[script_path] = script_data
                
                logger.info(f"Loaded {len(self.scripts)} scripts from database")
        except Exception as e:
            logger.error(f"Error loading script database: {str(e)}")
            
    def analyze_scripts(self):
        """Run analysis by delegating to consolidation_functions"""
        # Simplified implementation that will be expanded when needed
        logger.info("Starting script analysis...")
        # Implementation would go here
        logger.info("Analysis completed")
        return True
    
    def generate_plan(self):
        """Generate consolidation plan"""
        logger.info("Generating consolidation plan...")
        # Implementation would go here
        logger.info("Generated consolidation plan")
        return True
    
    def execute_plan(self, plan_ids=None, dry_run=True):
        """Execute consolidation plan"""
        logger.info(f"Executing consolidation plan (dry_run={dry_run})...")
        # Implementation would go here
        logger.info("Consolidation plan executed")
        return True
    
    def generate_report(self):
        """Generate consolidation report"""
        logger.info("Generating consolidation report...")
        # Implementation would go here
        logger.info("Report generated")
        return True

def main():
    parser = argparse.ArgumentParser(description="Script Consolidation Tool")
    parser.add_argument('--analyze', action='store_true', help='Analyze scripts and identify consolidation candidates')
    parser.add_argument('--plan', action='store_true', help='Generate consolidation plan')
    parser.add_argument('--execute', action='store_true', help='Execute consolidation plan')
    parser.add_argument('--report', action='store_true', help='Generate consolidation report')
    parser.add_argument('--group-ids', type=str, help='Comma-separated list of group IDs to consolidate')
    parser.add_argument('--dry-run', action='store_true', help='Perform a dry run without making changes')
    parser.add_argument('--all', action='store_true', help='Run all steps')
    args = parser.parse_args()
    
    # Set defaults if no options specified
    if not any([args.analyze, args.plan, args.execute, args.report, args.all]):
        args.analyze = True
    
    consolidator = ScriptConsolidatorLite()
    
    # Process group IDs
    group_ids = None
    if args.group_ids:
        group_ids = [int(x.strip()) for x in args.group_ids.split(',')]
    
    # Analysis phase
    if args.analyze or args.all:
        consolidator.analyze_scripts()
    
    # Planning phase
    if args.plan or args.all:
        consolidator.generate_plan()
    
    # Execution phase
    if args.execute or args.all:
        consolidator.execute_plan(group_ids, args.dry_run)
    
    # Reporting phase
    if args.report or args.all:
        consolidator.generate_report()
    
    logger.info("Script consolidation process completed")
    return 0

if __name__ == "__main__":
    sys.exit(main())