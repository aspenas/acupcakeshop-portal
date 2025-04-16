---
title: "Obsidian Sync Compatibility Guide"
date: 2025-04-15
tags: [system, obsidian, sync, troubleshooting]
---

# Obsidian Sync Compatibility Guide

## Overview

This document outlines the compatibility considerations for our script consolidation system with Obsidian's sync functionality, and provides solutions for addressing common issues.

## Potential Issues with Obsidian Sync

Certain features in scripts or their implementation can cause Obsidian to crash or fail to sync properly:

1. **Symlinks**: Symbolic links are not properly handled by Obsidian's sync system, causing sync failures or crashes
2. **Executable Permissions**: Files with executable permission bits may cause issues with Obsidian sync
3. **Absolute Paths**: Hard-coded absolute paths can cause problems when syncing between different devices
4. **Auto-executing Scripts**: Scripts that automatically execute within the Obsidian context can cause crashes

## Changes Made to Ensure Compatibility

We have implemented the following changes to ensure compatibility with Obsidian sync:

1. **Replaced Symlinks with Import Stubs**: 
   - Instead of using symbolic links, we now use import stub files that redirect to the consolidated implementation
   - This maintains the functionality while being compatible with Obsidian's sync system

2. **Normalized File Permissions**:
   - Removed executable permission bits from script files
   - This prevents Obsidian from treating these files differently during sync

3. **Implemented Relative Paths**:
   - Replaced all absolute paths with relative paths
   - Scripts now dynamically determine their location and the vault path
   - This ensures scripts work correctly regardless of where the vault is located

4. **Updated Script Database**:
   - Modified the script database to use relative paths instead of absolute paths
   - This makes the database portable between different systems

5. **Safe Script Execution**:
   - Ensured scripts only execute when explicitly run, not during Obsidian's file indexing
   - Added proper error handling to prevent crash loops

## If Obsidian Sync Issues Persist

If you encounter issues with Obsidian sync even after these changes, try the following steps:

1. **Start Obsidian in Safe Mode**:
   - This disables plugins and can help identify if a plugin is causing the issue
   - If Obsidian works in safe mode, enable plugins one by one to identify the problematic one

2. **Check File Permissions**:
   - Run `find /path/to/vault -type f -name "*.py" | xargs stat -f "%p %N"` to find files with unusual permissions
   - Fix permissions with `chmod 644 file.py`

3. **Verify No Symlinks Exist**:
   - Run `find /path/to/vault -type l` to identify any symbolic links
   - Replace symlinks with regular files or import stubs

4. **Check for Absolute Paths**:
   - Search for absolute paths with `grep -r "/Users/" /path/to/vault`
   - Replace with relative paths

5. **Check Obsidian Sync Settings**:
   - Ensure the System directory is included in sync
   - Verify sync exclusions don't interfere with script files

## Best Practices for Script Development in Obsidian

1. **Always Use Relative Paths**:
   - Never hardcode absolute paths in scripts
   - Use `os.path.dirname(__file__)` or similar to dynamically determine locations

2. **Avoid Symlinks**:
   - Use import stubs or other techniques instead of symbolic links

3. **Standardize File Permissions**:
   - Keep normal file permissions (644 for files, 755 for directories)
   - Don't rely on executable bits for script files

4. **Isolate Script Execution**:
   - Ensure scripts only run when explicitly executed
   - Don't include auto-executing code in files Obsidian will index

5. **Backup Before Changes**:
   - Always backup files before making significant changes
   - Our system automatically backs up scripts before consolidation

