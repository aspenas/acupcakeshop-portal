#!/usr/bin/env python3
# example_script3.py
# Third example script for consolidation testing

import os
import sys
import json
import csv
from datetime import datetime

# Add lib directory to path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(SCRIPT_DIR, "lib")
sys.path.append(LIB_DIR)

# Import from shared library
from example_script1_script2 import load_data, get_timestamp

def export_to_csv(file_path, data):
    """Export data to a CSV file"""
    try:
        if not data or not isinstance(data, list):
            print("Data must be a non-empty list")
            return False
            
        # Get field names from first item
        fieldnames = data[0].keys()
        
        with open(file_path, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
        return True
    except Exception as e:
        print(f"Error exporting to CSV: {str(e)}")
        return False

def get_file_stats(file_path):
    """Get file statistics"""
    try:
        stats = os.stat(file_path)
        return {
            'path': file_path,
            'size': stats.st_size,
            'modified': datetime.fromtimestamp(stats.st_mtime).isoformat(),
            'accessed': datetime.fromtimestamp(stats.st_atime).isoformat(),
            'created': datetime.fromtimestamp(stats.st_ctime).isoformat(),
        }
    except Exception as e:
        print(f"Error getting file stats: {str(e)}")
        return None

def convert_json_to_csv(input_file, output_file):
    """Convert JSON file to CSV"""
    # Load data
    data = load_data(input_file)
    if data is None:
        return False
        
    # Get file stats
    stats = get_file_stats(input_file)
    print(f"Converting file: {stats['path']}, Size: {stats['size']} bytes")
    
    # Add timestamp
    if isinstance(data, list):
        for item in data:
            item['exported_at'] = get_timestamp()
    else:
        print("Warning: Expected a list of dictionaries")
        data = [data]  # Convert to list
        data[0]['exported_at'] = get_timestamp()
    
    # Export to CSV
    return export_to_csv(output_file, data)

def main():
    if len(sys.argv) < 3:
        print("Usage: example_script3.py input_json output_csv")
        return 1
        
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success = convert_json_to_csv(input_file, output_file)
    if success:
        print("File converted successfully.")
        return 0
    else:
        print("Error converting file.")
        return 1

if __name__ == "__main__":
    sys.exit(main())