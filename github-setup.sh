#!/bin/bash

echo "GitHub CLI Setup Helper"
echo "======================="
echo

# Check if already authenticated
if gh auth status &>/dev/null; then
    echo "✅ Already authenticated with GitHub"
    gh auth status
else
    echo "📋 To authenticate with GitHub, run:"
    echo "   gh auth login"
    echo
    echo "Choose these options:"
    echo "  - GitHub.com"
    echo "  - HTTPS"
    echo "  - Login with a web browser (or paste token)"
    echo
fi

echo
echo "📌 Useful GitHub CLI commands:"
echo "  gh repo list                    - List your repositories"
echo "  gh repo clone <owner>/<repo>    - Clone a repository"
echo "  gh pr list                      - List pull requests"
echo "  gh issue list                   - List issues"
echo
echo "For more info: https://cli.github.com/manual/"