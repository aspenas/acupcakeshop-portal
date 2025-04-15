#!/usr/bin/env python3
"""
Obsidian Plugin Installer
A cross-platform script to install popular Obsidian plugins
"""

import os
import json
import shutil
import tempfile
import zipfile
from urllib.request import urlretrieve

# Plugin repositories to install
PLUGINS = [
    "TfTHacker/obsidian42-brat",
    "zsviczian/obsidian-excalidraw-plugin",
    "blacksmithgu/obsidian-dataview",
    "tgrosinger/advanced-tables-obsidian",
    "SilentVoid13/Templater",
    "obsidian-tasks-group/obsidian-tasks",
    "liamcain/obsidian-calendar-plugin",
    "mgmeyers/obsidian-kanban",
    "Vinzent03/obsidian-git",
    "FlorianWoelki/obsidian-iconize",
    "vslinko/obsidian-outliner"
]

# ID mappings for plugins (repo name -> plugin ID)
PLUGIN_IDS = {
    "obsidian42-brat": "obsidian42-brat",
    "obsidian-excalidraw-plugin": "obsidian-excalidraw-plugin",
    "obsidian-dataview": "dataview",
    "advanced-tables-obsidian": "table-editor-obsidian",
    "Templater": "templater-obsidian",
    "obsidian-tasks": "obsidian-tasks-plugin",
    "obsidian-calendar-plugin": "calendar",
    "obsidian-kanban": "obsidian-kanban",
    "obsidian-git": "obsidian-git",
    "obsidian-iconize": "obsidian-icon-folder",
    "obsidian-outliner": "obsidian-outliner"
}


def get_vault_dir():
    """Get the Obsidian vault directory (current working directory)"""
    return os.getcwd()


def get_plugins_dir(vault_dir):
    """Get the plugins directory path"""
    return os.path.join(vault_dir, '.obsidian', 'plugins')


def ensure_dir_exists(directory):
    """Create directory if it doesn't exist"""
    if not os.path.exists(directory):
        os.makedirs(directory)
        print(f"Created directory: {directory}")


def install_plugin(repo, plugins_dir):
    """Install a plugin from GitHub"""
    user, repo_name = repo.split('/')
    plugin_id = PLUGIN_IDS.get(repo_name, repo_name)
    
    print(f"Installing {repo_name}...")
    
    # Create a temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        zip_path = os.path.join(temp_dir, f"{repo_name}.zip")
        
        # Download the zip file
        download_url = f"https://github.com/{repo}/archive/master.zip"
        try:
            urlretrieve(download_url, zip_path)
        except Exception as e:
            print(f"Failed to download {repo_name}: {e}")
            return None
        
        # Extract the zip file
        plugin_temp_dir = os.path.join(temp_dir, "extracted")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(plugin_temp_dir)
        
        # Create plugin directory
        plugin_dir = os.path.join(plugins_dir, plugin_id)
        ensure_dir_exists(plugin_dir)
        
        # Copy required files
        extracted_dir = os.path.join(plugin_temp_dir, f"{repo_name}-master")
        
        for file_name in ["main.js", "manifest.json", "styles.css"]:
            src_file = os.path.join(extracted_dir, file_name)
            dest_file = os.path.join(plugin_dir, file_name)
            
            if os.path.exists(src_file):
                shutil.copy2(src_file, dest_file)
                print(f"  Copied {file_name}")
    
    return plugin_id


def update_community_plugins_json(vault_dir, plugin_ids):
    """Update the community-plugins.json file"""
    community_plugins_path = os.path.join(
        vault_dir, '.obsidian', 'community-plugins.json'
    )
    
    if os.path.exists(community_plugins_path):
        with open(community_plugins_path, 'r') as f:
            try:
                enabled_plugins = json.load(f)
            except json.JSONDecodeError:
                enabled_plugins = []
    else:
        enabled_plugins = []
    
    # Add any new plugins
    for plugin_id in plugin_ids:
        if plugin_id and plugin_id not in enabled_plugins:
            enabled_plugins.append(plugin_id)
    
    # Write back to file
    with open(community_plugins_path, 'w') as f:
        json.dump(enabled_plugins, f, indent=2)
    
    print(f"Updated {community_plugins_path}")


def update_core_plugins_json(vault_dir):
    """Update the core-plugins.json file to enable essential plugins"""
    core_plugins_path = os.path.join(
        vault_dir, '.obsidian', 'core-plugins.json'
    )
    
    if os.path.exists(core_plugins_path):
        with open(core_plugins_path, 'r') as f:
            core_plugins = json.load(f)
    else:
        core_plugins = {}
    
    # Enable essential core plugins
    essential_plugins = [
        "file-explorer", "global-search", "switcher", "graph", 
        "backlink", "canvas", "outgoing-link", "tag-pane", 
        "properties", "page-preview", "daily-notes", "templates", 
        "note-composer", "command-palette", "slash-command", 
        "editor-status", "bookmarks", "random-note", "outline", 
        "word-count", "workspaces", "file-recovery", "sync"
    ]
    
    for plugin in essential_plugins:
        core_plugins[plugin] = True
    
    # Write back to file
    with open(core_plugins_path, 'w') as f:
        json.dump(core_plugins, f, indent=2)
    
    print(f"Updated {core_plugins_path}")


def main():
    """Main function"""
    print("==== Obsidian Plugin Installer ====")
    
    vault_dir = get_vault_dir()
    plugins_dir = get_plugins_dir(vault_dir)
    
    ensure_dir_exists(os.path.join(vault_dir, '.obsidian'))
    ensure_dir_exists(plugins_dir)
    
    # Install plugins
    installed_plugin_ids = []
    for repo in PLUGINS:
        plugin_id = install_plugin(repo, plugins_dir)
        if plugin_id:
            installed_plugin_ids.append(plugin_id)
            print(f"✅ Installed {plugin_id}")
    
    # Update configuration files
    update_community_plugins_json(vault_dir, installed_plugin_ids)
    update_core_plugins_json(vault_dir)
    
    print("\n🎉 All plugins installed! Please restart Obsidian to activate them.")
    print("ℹ️ After restarting, you may need to enable the plugins.")


if __name__ == "__main__":
    main() 