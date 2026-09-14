#!/usr/bin/env bash

set -e

echo "=== Fixing Git Remote and Ownership for NETFLIX ==="

# 1. Ask for your personal GitHub account username
echo "--> Enter your PERSONAL GitHub username (the account where NETFLIX repo lives):"
read -p "GitHub Username: " GH_USER

if [ -z "$GH_USER" ]; then
    echo "Error: Username cannot be empty."
    exit 1
fi

TARGET_REPO_URL="https://github.com/${GH_USER}/NETFLIX.git"

# 2. Check and update the origin remote URL
echo "--> Checking current origin remote..."
git remote get-url origin || true

echo "--> Updating 'origin' remote to point to: $TARGET_REPO_URL"
git remote set-url origin "$TARGET_REPO_URL" || git remote add origin "$TARGET_REPO_URL"

# 3. Verify remote configuration
echo "--> Updated Git Remotes:"
git remote -v

# 4. Stage and commit local changes if any are pending
if [[ -n $(git status -s) ]]; then
    echo "--> Staging untracked/modified files..."
    git add .
    git commit -m "fix: update remote tracking and preserve monorepo state"
else
    echo "--> No uncommitted changes found."
fi

# 5. Push to your main branch
echo "--> Pushing code to $TARGET_REPO_URL on branch main..."
git branch -M main
git push -u origin main

echo "=== Success! Your remote URL is updated and your monorepo remains intact. ==="