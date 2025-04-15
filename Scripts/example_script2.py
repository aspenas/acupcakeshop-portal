#!/usr/bin/env python3
# example_script2.py
# Another example script for consolidation testing

import os
import sys
import json
from datetime import datetime

# Add lib directory to path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(SCRIPT_DIR, "lib")
sys.path.append(LIB_DIR)

# Import from shared library
from example_script1_script2 import load_data, save_data, get_timestamp

def validate_data(data):
    """Validate data structure"""
    required_fields = ['id', 'name', 'date']
    for field in required_fields:
        if field not in data:
            print(f"Missing required field: {field}")
            return False
    return True

def analyze_file(input_file):
    """Analyze a data file"""
    # Load data
    data = load_data(input_file)
    if data is None:
        return False
        
    # Validate data
    if not validate_data(data):
        return False
    
    # Analyze data
    analysis = {
        'id': data['id'],
        'analyzed_at': get_timestamp(),
        'fields_count': len(data.keys()),
        'status': 'analyzed'
    }
    
    # Save analysis
    analysis_file = f"{input_file}.analysis.json"
    return save_data(analysis_file, analysis)

def main():
    if len(sys.argv) < 2:
        print("Usage: example_script2.py input_file")
        return 1
        
    input_file = sys.argv[1]
    
    success = analyze_file(input_file)
    if success:
        print("File analyzed successfully.")
        return 0
    else:
        print("Error analyzing file.")
        return 1

if __name__ == "__main__":
    sys.exit(main())