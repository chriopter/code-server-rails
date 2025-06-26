# VS Code Server Rails Development

A Docker environment for VS Code in the browser with Ruby on Rails, Node.js, and GitHub integration.

## Features

- VS Code in browser via code-server
- Ruby 3.4.4 with Rails pre-installed
- Node.js 20 with npm
- GitHub CLI integration
- PostgreSQL & Redis clients
- Persistent storage for settings and workspace

## Docker Compose Example

```yaml
services:
  code-server:
    build: .
    container_name: code-server-rails
    ports:
      - "8443:8443"  # VS Code Server
      - "3000:3000"  # Rails app
    environment:
      - PASSWORD=changeme
    volumes:
      - ./workspace:/home/coder/workspace
      - code-server-data:/home/coder/.local/share/code-server
      - code-server-config:/home/coder/.config/code-server
    restart: unless-stopped

volumes:
  code-server-data:
  code-server-config:
```

Access at https://localhost:8443 with password `changeme`.