#!/bin/bash

echo "🔧 GitHub Setup for VS Code Server"
echo "=================================="
echo ""

# Check if token was provided as argument
if [ -n "$1" ]; then
    GH_TOKEN="$1"
    echo "Using provided token..."
else
    # Check if already authenticated
    if gh auth status &>/dev/null; then
        echo "✅ GitHub CLI is already authenticated!"
        echo ""
        gh auth status
        echo ""
        read -p "Do you want to reconfigure? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Keeping existing configuration."
            exit 0
        fi
    fi

    echo "📝 Step 1: Create a GitHub Personal Access Token"
    echo "------------------------------------------------"
    echo "1. Go to: https://github.com/settings/tokens/new"
    echo "2. Give it a name (e.g., 'VS Code Server')"
    echo "3. Select scopes:"
    echo "   ✓ repo (all)"
    echo "   ✓ workflow"
    echo "   ✓ read:org (optional)"
    echo "4. Click 'Generate token' and copy it"
    echo ""
    read -p "Press Enter when you have your token ready..."
    echo ""

    # Get the token
    echo -n "Paste your GitHub token (ghp_...): "
    read -s GH_TOKEN
    echo ""
fi

# Validate token format
if [[ ! "$GH_TOKEN" =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
    echo "❌ Invalid token format. GitHub tokens start with 'ghp_'"
    exit 1
fi

echo "🔐 Step 2: Configuring GitHub CLI..."
# Ensure .config directory exists with proper permissions
mkdir -p ~/.config
echo "$GH_TOKEN" | gh auth login --with-token --git-protocol https

if [ $? -eq 0 ]; then
    echo "✅ GitHub CLI configured successfully!"
else
    echo "❌ Failed to configure GitHub CLI"
    exit 1
fi

echo ""
echo "🔧 Step 3: Configuring Git..."

# Check if git config already set
GIT_USERNAME=$(git config --global user.name)
GIT_EMAIL=$(git config --global user.email)

if [ -z "$GIT_USERNAME" ]; then
    echo -n "Enter your Git username (e.g., chriopter): "
    read GIT_USERNAME
else
    echo "Using existing Git username: $GIT_USERNAME"
fi

if [ -z "$GIT_EMAIL" ]; then
    echo -n "Enter your Git email: "
    read GIT_EMAIL
else
    echo "Using existing Git email: $GIT_EMAIL"
fi

# Configure git
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper store

# Setup git to use gh
gh auth setup-git

# Store credentials for immediate use
printf "protocol=https\nhost=github.com\nusername=$GIT_USERNAME\npassword=$GH_TOKEN\n" | git credential-store store

# Set environment to bypass VS Code's askpass
echo 'export GIT_ASKPASS=' >> ~/.bashrc

echo ""
echo "✅ GitHub setup complete!"
echo ""
echo "You can now:"
echo "  • Push/pull from private repositories"
echo "  • Use VS Code's Source Control features"
echo "  • Access GitHub via 'gh' CLI commands"
echo ""
echo "Your authentication will persist across browser refreshes! 🎉"