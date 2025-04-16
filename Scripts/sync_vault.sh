#!/bin/bash

# Simple script to commit and push Obsidian vault changes to GitHub.
# Assumes:
# 1. This script is run from the root of the Git repository.
# 2. Git is configured (user name, email).
# 3. Authentication to GitHub is handled (e.g., via gh CLI, SSH key, or PAT helper).

# Navigate to the script's directory to be safe, although we expect execution from repo root
cd "$(dirname "$0")/.." || exit 1

# Fetch latest changes from the remote
git fetch origin

# Check if the local main branch is behind the remote main branch
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Local branch is not up-to-date with origin/main. Attempting fast-forward merge..."
    # Try a fast-forward merge only to avoid complex merge conflicts automatically
    git merge --ff-only origin/main
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not fast-forward merge. Please resolve conflicts manually."
        exit 1
    fi
    echo "Merged origin/main."
else
    echo "Local branch is up-to-date with origin/main."
fi

# Add all changes (including new files, deletions, modifications)
git add .

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
    echo "No changes to commit."
    exit 0
fi

# Commit changes with a timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
COMMIT_MSG="Automated vault sync: $TIMESTAMP"
echo "Committing changes with message: '$COMMIT_MSG'"
git commit -m "$COMMIT_MSG"

# Push changes to the main branch
echo "Pushing changes to origin main..."
git push origin main

if [ $? -eq 0 ]; then
    echo "Successfully pushed changes to GitHub."
else
    echo "ERROR: Failed to push changes to GitHub."
    exit 1
fi

exit 0 