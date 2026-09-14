#!/usr/bin/env bash

# Exit immediately if a command fails
set -e

echo "=== Fixing Git Remote for NETFLIX ==="

# 1. Retrieve your authenticated GitHub username via SSH
echo "--> Checking GitHub authentication..."
GH_USER=$(ssh -T git@github.com 2>&1 | grep -oP 'Hi \K[^!]+' || true)

if [ -z "$GH_USER" ]; then
    echo "--> SSH Authentication failed or no key detected."
    echo "--> Falling back: Please enter your personal GitHub username manually:"
    read -p "Username: " GH_USER
else
    echo "--> Authenticated as GitHub user: $GH_USER"
fi

# 2. Check current remote configuration
echo "--> Current origin remote:"
git remote get-url origin || true

# 3. Update the origin remote URL to point to your personal account
NEW_REMOTE_URL="https://github.com/${GH_USER}/NETFLIX.git"

echo "--> Setting remote 'origin' to: $NEW_REMOTE_URL"
git remote set-url origin "$NEW_REMOTE_URL"

# 4. Verify updated remote URLs
echo "--> Updated remote configuration:"
git remote -v

# 5. Test fetching from your repository
echo "--> Testing connection by fetching from origin..."
git fetch origin main

echo "=== Successfully updated remote! You can now run 'git pull origin main' or 'git push origin main'. ==="