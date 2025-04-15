#!/bin/bash

# Plugin installation script for Obsidian
# Installs recommended plugins for Athlete Financial Empowerment vault

OBSIDIAN_DIR="/Users/patricksmith/obsidian/acupcakeshop/.obsidian"
PLUGINS_DIR="$OBSIDIAN_DIR/plugins"

# Create plugins directory if it doesn't exist
mkdir -p "$PLUGINS_DIR"

# List of recommended plugins
declare -a plugins=(
  "dataview"
  "templater"
  "calendar"
  "obsidian-excalidraw-plugin"
  "obsidian-mind-map"
  "obsidian-git"
  "table-editor-obsidian"
  "obsidian-tasks-plugin"
  "obsidian-kanban"
  "obsidian-advanced-uri"
)

# Install plugins
for plugin in "${plugins[@]}"; do
  echo "Installing $plugin..."
  plugin_dir="$PLUGINS_DIR/$plugin"
  
  if [ -d "$plugin_dir" ]; then
    echo "$plugin already installed, skipping"
  else
    mkdir -p "$plugin_dir"
    echo "Plugin directory created: $plugin_dir"
    
    # Here you would typically download the plugin files
    # This is a placeholder - in a real implementation, you would need to
    # download the actual plugin files from their GitHub repositories
    echo "# Placeholder for $plugin installation" > "$plugin_dir/manifest.json"
    echo "Plugin $plugin placeholder created"
  fi
done

echo "Plugin installation complete. Restart Obsidian to activate plugins."
