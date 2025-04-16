#!/bin/bash

# Script to copy Node.js application files from source to destination
# as specified in the requirements

SOURCE_DIR="/Users/patricksmith/acupcakeshop"
DEST_DIR="/Users/patricksmith/obsidian/acupcakeshop"

echo "Starting migration of Node.js app from $SOURCE_DIR to $DEST_DIR"

# Create directories if they don't exist
mkdir -p "$DEST_DIR"

# 1. Copy package.json and package-lock.json
echo "Copying package files..."
cp "$SOURCE_DIR/package.json" "$DEST_DIR/"
cp "$SOURCE_DIR/package-lock.json" "$DEST_DIR/" 2>/dev/null || echo "No package-lock.json found"

# 2. Copy configuration files
echo "Copying configuration files..."
cp "$SOURCE_DIR/observablehq.config.js" "$DEST_DIR/" 2>/dev/null || echo "No observablehq.config.js found"
cp "$SOURCE_DIR/README.md" "$DEST_DIR/APP_README.md" 2>/dev/null || echo "No README.md found"
cp "$SOURCE_DIR/.gitignore" "$DEST_DIR/app.gitignore" 2>/dev/null || echo "No .gitignore found"

# 3. Copy source code directories
echo "Copying source code directories..."
# src directory
if [ -d "$SOURCE_DIR/src" ]; then
  mkdir -p "$DEST_DIR/src"
  cp -R "$SOURCE_DIR/src/"* "$DEST_DIR/src/"
  echo "Copied src directory"
fi

# 4. Exclude node_modules, dist, and .git directories
echo "Excluded node_modules, dist, and .git directories as specified"

echo "Migration complete! The Node.js application has been copied to $DEST_DIR"
echo "Please run 'npm install' in the destination directory to install dependencies" 