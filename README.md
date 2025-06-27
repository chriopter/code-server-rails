# VS Code Server Rails Development

A Docker environment for VS Code in the browser with Ruby on Rails, Node.js, and GitHub integration.

## Features

- VS Code in browser via code-server
- Ruby 3.4.4 with Rails pre-installed
- Node.js 20 with npm
- GitHub CLI integration
- PostgreSQL & Redis clients
- Persistent storage for settings and workspace
- Persistent bash history and aliases

## Docker Compose

See [docker-compose.yml](docker-compose.yml)

Access at https://localhost:8443 with password `changeme`.

## Persistent Bash History & Aliases

Bash history and aliases are automatically persisted across container restarts.

### Creating Aliases

In the VS Code terminal or when connected via `docker exec`:

```bash
# Add aliases to the persistent file
echo 'alias claude1="CLAUDE_CONFIG_DIR=/home/coder/.claude-profiles/1 claude"' >> ~/.bash_aliases
# Load them immediately (only needed once)
source /commandhistory/.bash_aliases
```

### Using Aliases

- **In VS Code terminal**: Aliases load automatically after container restart
- **Via docker exec**: Use `docker exec -it -u coder code-server-rails bash -l`

### Bash History

Command history is automatically saved to `/commandhistory/.bash_history` and persists across container restarts. No configuration needed.
 
