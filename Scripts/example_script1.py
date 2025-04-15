#!/usr/bin/env python3
# example_script1.py
# Example script for consolidation testing

import os
import sys
import json
import sys
from datetime import datetime

# Add lib directory to path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(SCRIPT_DIR, "lib")
sys.path.append(LIB_DIR)

# Import from shared library
from example_script1_script2 import load_data, save_data, get_timestamp

def process_file(input_file, output_file):
    """Process a data file"""
    # Load data
    data = load_data(input_file)
    if data is None:
        return False
        
    # Process data
    data['processed_at'] = get_timestamp()
    data['status'] = 'processed'
    
    # Save processed data
    return save_data(output_file, data)

def main():
    if len(sys.argv) < 3:
        print("Usage: example_script1.py input_file output_file")
        return 1
        
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success = process_file(input_file, output_file)
    if success:
        print("File processed successfully.")
        return 0
    else:
        print("Error processing file.")
        return 1

if __name__ == "__main__":
    sys.exit(main())