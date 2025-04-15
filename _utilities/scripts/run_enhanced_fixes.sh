#!/usr/bin/env bash
# run_enhanced_fixes.sh - Run all enhanced fix scripts in sequence
#
# This script runs the enhanced fix scripts in the correct order to ensure
# all migration issues are resolved properly.
#
# Dependencies: bash, chmod

# Set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/run_enhanced_fixes_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Enhanced Fixes Master Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to make a script executable and run it
run_script() {
    local script="$1"
    local script_path="${SCRIPT_DIR}/${script}"
    
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Running script: ${script}" | tee -a "$LOG_FILE"
    echo "Started at: $(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    
    # Make script executable if it's not already
    if [[ ! -x "$script_path" ]]; then
        echo "Making script executable: $script_path" | tee -a "$LOG_FILE"
        chmod +x "$script_path"
    fi
    
    # Run the script
    "$script_path" 2>&1 | tee -a "$LOG_FILE"
    
    # Check return status
    local status=$?
    if [[ $status -eq 0 ]]; then
        echo "Script completed successfully: $script" | tee -a "$LOG_FILE"
    else
        echo "Script failed with status $status: $script" | tee -a "$LOG_FILE"
    fi
    
    echo "Completed at: $(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    return $status
}

# Begin process
echo "Starting enhanced fixes process..." | tee -a "$LOG_FILE"

# Step 1: Run enhanced direct migration
echo "Step 1: Running enhanced direct migration..." | tee -a "$LOG_FILE"
run_script "enhanced_direct_migrate.sh"

# Step 2: Run enhanced frontmatter standardization
echo "Step 2: Running enhanced frontmatter standardization..." | tee -a "$LOG_FILE"
run_script "enhanced_standardize_frontmatter.sh"

# Step 3: Run enhanced link fixing
echo "Step 3: Running enhanced link fixing..." | tee -a "$LOG_FILE"
run_script "enhanced_fix_links.sh"

# Step 4: Run verification
echo "Step 4: Running verification..." | tee -a "$LOG_FILE"
run_script "verify_migration.sh"

# Completion message
echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "All enhanced fixes completed: $(date)" | tee -a "$LOG_FILE"
echo "See individual logs for details." | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Enhanced fixes process completed. See log at: $LOG_FILE"