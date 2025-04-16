---
title: "Obsidian Performance Optimization Guide"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation, obsidian, performance, system, troubleshooting]
---

---

---

# Obsidian Performance Optimization Guide

This guide addresses performance issues with Obsidian and provides a systematic approach to diagnosing and fixing problems that cause slowdowns, crashes, or sync issues.

## Common Causes of Performance Issues

1. **Large Files**: Files over 100KB can cause slowdowns
2. **Complex Folders**: Too many nested folders or files
3. **Plugin Conflicts**: Plugins that modify the same functionality
4. **Excessive Metadata**: Too many tags or properties
5. **Large Sync Queue**: Too many files waiting to sync
6. **Code/Script Files**: Large script files with complex syntax
7. **Hidden Files**: .DS_Store and other system files
8. **Symlinks and Special Files**: Non-standard file types

## Immediate Actions for Performance Issues

If Obsidian is running slowly or crashing:

1. **Start in Safe Mode**: 
   - Hold `Ctrl` (or `Cmd` on Mac) while opening Obsidian
   - This disables all community plugins

2. **Check Recent Changes**:
   - Review recently added files or plugins
   - Temporarily move new files outside the vault

3. **Clear Cache**:
   - Close Obsidian
   - Navigate to `.obsidian/cache`
   - Delete the contents of this folder

4. **Update Obsidian**:
   - Ensure you're running the latest version
   - Some performance issues are fixed in newer releases

## Performance Optimization Techniques

### 1. File Structure Optimization

- **Limit Folder Depth**: Keep folder nesting to 3-4 levels max
- **Split Large Files**: Break files larger than 100KB into smaller ones
- **Use Index Files**: Create index files that link to content instead of massive files
- **Separate Media**: Keep images and other media in a dedicated folder

### 2. Script and Code Management

- **Separate Scripts from Notes**: Keep scripts in a dedicated folder structure
- **Use Relative Paths**: Never use absolute paths in scripts
- **Avoid Executable Bits**: Don't mark files as executable within Obsidian vaults
- **No Symlinks**: Don't use symbolic links in vaults that are synced
- **Import Stubs**: Use lightweight import redirects instead of duplicating code
- **Lazy Loading**: Use lazy loading patterns in scripts

### 3. Sync Optimization

- **Selective Sync**: Don't sync large files or directories
- **Create .obsidian-ignore**: Create this file to tell Obsidian which folders to ignore
- **Sync Frequency**: Reduce automatic sync frequency
- **Smaller Vaults**: Consider splitting into multiple smaller vaults

### 4. Plugin Management

- **Minimize Plugins**: Only use essential plugins
- **Identify Heavy Plugins**: DataView, Graph view, and full-text search can be resource-intensive
- **Update or Replace**: Update problematic plugins or find lighter alternatives

## Performance Diagnosis Tools

### Script for Finding Large Files

```bash
find /path/to/vault -type f -size +100k | sort -nk 5 | tail -n 20
```

### Check for Executable Files

```bash
find /path/to/vault -type f -perm +111
```

### Find Symbolic Links

```bash
find /path/to/vault -type l
```

### Count Files and Directories

```bash
find /path/to/vault -type f | wc -l
find /path/to/vault -type d | wc -l
```

## Optimizations We've Implemented

We've made the following optimizations to improve Obsidian performance:

1. **Created .obsidian-ignore**: Added a file to tell Obsidian which folders to skip
2. **Removed Executable Bits**: Changed file permissions to standard (644)
3. **Eliminated Symlinks**: Replaced with import stubs
4. **Moved Large Files**: Relocated large dashboard files to PerformanceReports
5. **Created Lightweight Scripts**: Developed modular, lazy-loading scripts
6. **Replaced Absolute Paths**: Switched to relative, context-aware paths
7. **Standardized File Structure**: Organized files consistently

## Creating an .obsidian-ignore File

```
# Obsidian ignore file
Scripts/lib/
System/Logs/
System/Backups/
*.bak
*.tmp
.DS_Store
```

## When to Contact Support

If performance issues persist despite these optimizations:

1. **Validate Issues**: Ensure the issue occurs in Safe Mode
2. **Try New Vault**: Create a new empty vault to test if issues persist
3. **Export Diagnostics**: Export diagnostics from Help → Debug Info
4. **Contact Obsidian Support**: Share diagnostics and detailed description

## Best Practices Going Forward

1. **Regular Maintenance**: Periodically clean up and optimize the vault
2. **Performance Testing**: Test performance impact of new plugins or large files
3. **Documentation**: Document all performance optimizations
4. **Backup**: Always maintain backups before making changes
5. **Script Isolation**: Keep scripts isolated from content

By following these guidelines, we can maintain a high-performance Obsidian vault even with extensive scripts and automation.
