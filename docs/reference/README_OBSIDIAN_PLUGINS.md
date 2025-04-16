---
title: "README_OBSIDIAN_PLUGINS"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation, migration]
---

---

---

# Obsidian Plugin Installer

This package provides automated tools to install and configure popular Obsidian plugins for your vault. Choose the installation method that works best for your system.

## Installation Options

### Option 1: Shell Script (macOS/Linux)

If you're on macOS or Linux, you can use the shell script:

```bash
./install_obsidian_plugins.sh
```

### Option 2: Python Script (Cross-platform)

For a cross-platform solution that works on Windows, macOS, and Linux:

```bash
# If Python is in your PATH
python3 install_plugins.py

# On Windows
python install_plugins.py
```

## What Gets Installed

### Core Plugins (Already in Obsidian)

The scripts will enable the following core plugins:

- File Explorer
- Search
- Quick Switcher
- Graph View
- Backlinks
- Canvas
- Outgoing Links
- Tag Pane
- Properties
- Page Preview
- Daily Notes
- Templates
- Note Composer
- Command Palette
- Slash Commands
- Editor Status
- Bookmarks
- Random Note
- Outline
- Word Count
- Workspaces
- File Recovery
- Sync

### Community Plugins

The following community plugins will be installed:

- **BRAT** - Beta Reviewer's Auto-update Tool for plugin management
- **Excalidraw** - Create drawings and diagrams
- **Dataview** - Query and filter notes using a simple query language
- **Advanced Tables** - Improved table editing and formatting
- **Templater** - Advanced templating with JavaScript support
- **Tasks** - Task management across your vault
- **Calendar** - Calendar view for daily notes
- **Kanban** - Create kanban boards in your vault
- **Git** - Git integration for version control
- **Iconize** - Add icons to folders and files
- **Outliner** - Better outlining and list management

## Usage Instructions

1. **Close Obsidian** if it's currently running
2. Run the installation script of your choice
3. Wait for the script to complete (it may take a few minutes to download all plugins)
4. Start Obsidian
5. Go to Settings → Community plugins
6. Enable the installed plugins

## Customization

### Adding or Removing Plugins

To customize which plugins get installed:

#### Shell Script
- Edit the `PLUGINS` array in `install_obsidian_plugins.sh`
- Update the `.obsidian/community-plugins.json` file

#### Python Script
- Edit the `PLUGINS` list in `install_plugins.py`
- Edit the `PLUGIN_IDS` dictionary if needed

## Troubleshooting

If you encounter any issues:

1. **Check Permissions**: Make sure the scripts have execution permissions (`chmod +x script_name`)
2. **Internet Connection**: Ensure you have an active internet connection
3. **Manual Installation**: If automatic installation fails, you can always install plugins manually through Obsidian's interface
4. **Review Logs**: Check the script output for any error messages
5. **Plugin Directory**: Verify the plugins were installed correctly in `.obsidian/plugins/`

## Manual Installation (Alternative)

If the automated scripts don't work, you can:

1. Open Obsidian
2. Go to Settings → Community plugins → Browse
3. Search for each plugin by name and install them individually

## Syncing Plugins Across Devices

Once you've set up your plugins on one device, you can:

1. Copy the entire `.obsidian/plugins` folder to your other devices
2. Copy the `.obsidian/community-plugins.json` file to enable the same plugins 
