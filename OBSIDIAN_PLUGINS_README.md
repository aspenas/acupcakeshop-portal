# Obsidian Plugin Installer

This directory contains scripts and configuration to automatically install and configure common Obsidian plugins for your vault.

## Installed Plugins

The script installs the following popular plugins:

### Core Plugins (Already in Obsidian)
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
- [Obsidian BRAT](https://github.com/TfTHacker/obsidian42-brat) - Plugin management
- [Excalidraw](https://github.com/zsviczian/obsidian-excalidraw-plugin) - Create drawings and diagrams
- [Dataview](https://github.com/blacksmithgu/obsidian-dataview) - Query and filter notes
- [Advanced Tables](https://github.com/tgrosinger/advanced-tables-obsidian) - Improved table editing
- [Templater](https://github.com/SilentVoid13/Templater) - Advanced templating
- [Tasks](https://github.com/obsidian-tasks-group/obsidian-tasks) - Task management
- [Calendar](https://github.com/liamcain/obsidian-calendar-plugin) - Calendar view for daily notes
- [Kanban](https://github.com/mgmeyers/obsidian-kanban) - Kanban boards
- [Git](https://github.com/Vinzent03/obsidian-git) - Git integration
- [Iconize](https://github.com/FlorianWoelki/obsidian-iconize) - Add icons to folders and files
- [Outliner](https://github.com/vslinko/obsidian-outliner) - Better outlining and list management

## Usage

1. Close Obsidian if it's currently running
2. Run the script from the terminal:
   ```bash
   ./install_obsidian_plugins.sh
   ```
3. Start Obsidian
4. Go to Settings > Community plugins
5. Enable the installed plugins

## Troubleshooting

If you encounter any issues:

1. Check that all plugins were downloaded properly in `.obsidian/plugins/`
2. Ensure that the `community-plugins.json` file exists in `.obsidian/`
3. Make sure you have an active internet connection for the script to download plugins
4. Try restarting Obsidian after running the script

## Customization

To add or remove plugins, edit the `PLUGINS` array in the installation script and the list in `.obsidian/community-plugins.json`. 