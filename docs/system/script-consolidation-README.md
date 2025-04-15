---
title: "script consolidation README"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: []
---

# Script Consolidation System

## Overview

The Script Consolidation System is a tool designed to identify and merge duplicate functionality across scripts in the Obsidian vault. It analyzes script content, identifies functions that are duplicated across multiple files, and provides a consolidation plan to extract these shared functions into centralized libraries.

## Key Features

- **Function Analysis**: Identifies functions defined in Python, JavaScript, and Shell scripts
- **Similarity Detection**: Calculates similarity scores between scripts based on shared functions
- **Content Analysis**: Performs detailed content analysis to identify similar code patterns
- **Consolidation Planning**: Generates a plan for consolidating similar scripts
- **Library Extraction**: Extracts common functions into shared libraries
- **Reference Updating**: Updates script references to use the consolidated libraries
- **Comprehensive Reporting**: Generates detailed reports of the consolidation process

## Usage

### Analysis Mode

To analyze scripts and identify consolidation candidates:

```bash
python /Users/patricksmith/obsidian/acupcakeshop/Scripts/consolidate_scripts.py --analyze
```

### Plan Generation

To generate a consolidation plan based on the analysis:

```bash
python /Users/patricksmith/obsidian/acupcakeshop/Scripts/consolidate_scripts.py --plan
```

### Dry Run

To perform a dry run of the consolidation process without making changes:

```bash
python /Users/patricksmith/obsidian/acupcakeshop/Scripts/consolidate_scripts.py --execute --dry-run
```

### Execution

To execute the consolidation plan:

```bash
python /Users/patricksmith/obsidian/acupcakeshop/Scripts/consolidate_scripts.py --execute
```

### Reporting

To generate a report of the consolidation process:

```bash
python /Users/patricksmith/obsidian/acupcakeshop/Scripts/consolidate_scripts.py --report
```

### All Steps

To run all steps (analyze, plan, execute, and report):

```bash
python /Users/patricksmith/obsidian/acupcakeshop/Scripts/consolidate_scripts.py --all
```

## Configuration

The script consolidation system is configured using the file at `/Users/patricksmith/obsidian/acupcakeshop/System/Configuration/script_consolidation_config.json`. This file contains settings for:

- Analysis thresholds
- Execution options
- Reporting preferences
- Exclusion patterns
- Script type specific configurations

## Dependencies

The script consolidation system depends on the following libraries:

- `logger.py`: Standardized logging
- `config_manager.py`: Configuration management
- `file_utils.py`: File operations
- `error_handler.py`: Error handling

## Output

### Consolidation Plan

The consolidation plan is saved to `/Users/patricksmith/obsidian/acupcakeshop/System/Configuration/script_consolidation_plan.json` and contains details about:

- Groups of scripts with similar functionality
- Shared functions between scripts
- Similarity scores
- Suggested consolidated script names
- Proposed action (consolidate or extract_common)

### Consolidation Results

The results of the consolidation process are saved to `/Users/patricksmith/obsidian/acupcakeshop/System/Configuration/script_consolidation_results.json` and contain:

- Success/failure status of each consolidation
- Error messages for failed consolidations
- Paths to consolidated scripts
- Lists of modified scripts

### Consolidation Report

A comprehensive markdown report is generated at `/Users/patricksmith/obsidian/acupcakeshop/Dashboards/System/script_consolidation_report.md` that summarizes the consolidation process.

## Best Practices

1. Always run with `--analyze` and `--plan` first to review the consolidation plan
2. Use `--dry-run` to verify changes before applying them
3. Back up important scripts before running the consolidation process
4. Review the generated report to understand the changes made
5. Update documentation after consolidation to reflect the new structure
