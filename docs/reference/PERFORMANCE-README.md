---
title: "PERFORMANCE README"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation]
---

---

---

---

# Obsidian Performance Configuration

If you're experiencing performance issues with this vault, this document provides quick solutions.

## Quick Fixes

1. **Start Obsidian in Safe Mode**:
   - Hold `Ctrl` (or `Cmd` on Mac) while opening Obsidian

2. **Exclude Script Directories**:
   - Create a file called `.obsidian-ignore` in the vault root with the following content:
   ```
   Scripts/lib/
   System/Logs/
   System/Backups/
   *.bak
   *.tmp
   .DS_Store
   ```

3. **Reduce Active Plugins**:
   - Disable non-essential plugins, especially DataView if used

4. **Clear Cache**:
   - Close Obsidian
   - Delete the contents of `.obsidian/cache`

## Vault Structure

This vault contains a script optimization and consolidation system that has been carefully designed for Obsidian compatibility. However, certain aspects might affect performance:

- **Large script files**: These are stored in the Scripts directory
- **System directories**: Configuration, logs, and backups in the System directory
- **Dashboard files**: Some dashboards have been moved to System/PerformanceReports

## Working with Scripts

Scripts in this vault are designed to be run externally, not from within Obsidian. If you're working with the scripts:

1. Use a dedicated code editor like VSCode for script editing
2. Run scripts from a terminal, not from Obsidian
3. Refer to the script documentation in Documentation/System

## Full Optimization Guide

For a complete guide to optimizing Obsidian performance, see:
[Obsidian Performance Optimization Guide](Documentation/System/obsidian_performance_guide.md)
