#!/usr/bin/env python3
# example_script1_script2.py
# Shared functions extracted from example scripts
# Created by script_consolidation.py on 2025-04-15

import json
from datetime import datetime

def load_data(file_path):
    """Load data from a JSON file"""
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading data: {str(e)}")
        return None

def save_data(file_path, data):
    """Save data to a JSON file"""
    try:
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
        return True
    except Exception as e:
        print(f"Error saving data: {str(e)}")
        return False

def get_timestamp():
    """Get current timestamp in ISO format"""
    return datetime.now().isoformat()