#!/bin/bash

# Script to automatically install popular Obsidian plugins
# Author: Patrick Smith

echo "⚙️ Installing Obsidian plugins..."

# VARIABLES
VAULT_DIR="$(pwd)"
PLUGINS_DIR="$VAULT_DIR/.obsidian/plugins"
TEMP_DIR="$VAULT_DIR/.temp_plugins"

# Function to download and install a plugin from GitHub
install_plugin() {
    local repo=$1
    local plugin_name=$(echo $repo | cut -d'/' -f2)
    
    echo "📥 Installing $plugin_name..."
    
    mkdir -p "$TEMP_DIR"
    curl -L "https://github.com/$repo/archive/master.zip" -o "$TEMP_DIR/$plugin_name.zip"
    
    # Extract the plugin
    unzip -q -o "$TEMP_DIR/$plugin_name.zip" -d "$TEMP_DIR"
    
    # Create plugin directory
    mkdir -p "$PLUGINS_DIR/$plugin_name"
    
    # Copy required files
    if [ -f "$TEMP_DIR/$plugin_name-master/main.js" ]; then
        cp "$TEMP_DIR/$plugin_name-master/main.js" "$PLUGINS_DIR/$plugin_name/"
    fi
    
    if [ -f "$TEMP_DIR/$plugin_name-master/manifest.json" ]; then
        cp "$TEMP_DIR/$plugin_name-master/manifest.json" "$PLUGINS_DIR/$plugin_name/"
    fi
    
    if [ -f "$TEMP_DIR/$plugin_name-master/styles.css" ]; then
        cp "$TEMP_DIR/$plugin_name-master/styles.css" "$PLUGINS_DIR/$plugin_name/"
    fi
    
    echo "✅ Installed $plugin_name"
}

# First, install BRAT (Beta Reviewer's Auto-update Tool)
echo "🔧 Installing BRAT plugin..."
install_plugin "TfTHacker/obsidian42-brat"

# Create the community-plugins.json file if it doesn't exist
if [ ! -f "$VAULT_DIR/.obsidian/community-plugins.json" ]; then
    echo "📝 Creating community-plugins.json..."
    echo '["obsidian42-brat"]' > "$VAULT_DIR/.obsidian/community-plugins.json"
else
    # Add BRAT to the enabled plugins if not already there
    if ! grep -q "obsidian42-brat" "$VAULT_DIR/.obsidian/community-plugins.json"; then
        sed -i '' 's/\[/\["obsidian42-brat",/' "$VAULT_DIR/.obsidian/community-plugins.json"
    fi
fi

# List of popular plugins to install
PLUGINS=(
    "zsviczian/obsidian-excalidraw-plugin"
    "blacksmithgu/obsidian-dataview"
    "tgrosinger/advanced-tables-obsidian"
    "SilentVoid13/Templater"
    "obsidian-tasks-group/obsidian-tasks"
    "liamcain/obsidian-calendar-plugin"
    "mgmeyers/obsidian-kanban"
    "Vinzent03/obsidian-git"
    "FlorianWoelki/obsidian-iconize"
    "vslinko/obsidian-outliner"
)

# Install all plugins
for plugin in "${PLUGINS[@]}"; do
    install_plugin "$plugin"
done

# Clean up temporary files
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo "🎉 All plugins installed! Please restart Obsidian to activate them."
echo "ℹ️ After restarting, you may need to enable the plugins in Settings > Community plugins." 