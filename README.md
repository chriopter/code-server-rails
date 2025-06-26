# VS Code Server with Rails

A Docker image for browser-based development with VS Code Server, Ruby 3.4.4, Node.js 20, and Rails.

## Quick Start

1. Create a `docker-compose.yml` in your project:

```yaml
services:
  vscode-server:
    image: ghcr.io/chriopter/vscode-server-rails:main
    container_name: vscode-server
    ports:
      - "3001:3001"  # VS Code HTTPS
      - "3000:3000"  # Rails app
    volumes:
      - vscode-user-data:/home/openvscode-server
      - vscode-server-data:/home/.openvscode-server
      - ./:/workspace
    environment:
      - VSCODE_CONNECTION_TOKEN=your-secure-token-here
    restart: unless-stopped

volumes:
  vscode-user-data:
  vscode-server-data:
```

2. Generate a secure token:
```bash
openssl rand -hex 32
```

3. Run:
```bash
docker compose up -d
```

4. Open https://localhost:3001/?tkn=your-secure-token-here
   (Replace `your-secure-token-here` with your actual token)

## Features

- Ruby 3.4.4
- Node.js 20
- Rails, Bundler, Foreman pre-installed
- Claude Code CLI
- PostgreSQL client
- Redis tools
- HTTPS with self-signed certificates
- Persistent extensions and settings
- Token-based authentication (required)

## Security

This image enforces token-based authentication for security. You must set the `VSCODE_CONNECTION_TOKEN` environment variable in your docker-compose.yml file.

To access VS Code Server, append your token to the URL: `https://localhost:3001/?tkn=your-token-here`. This ensures only authorized users can access your development environment.

## Customization

To add more tools, fork this repo and modify the Dockerfile.

## Acknowledgments

This project builds upon the following Docker images:
- [Ruby 3.4.4 Slim](https://hub.docker.com/_/ruby) - Official Ruby Docker image
- [Node.js 20 Slim](https://hub.docker.com/_/node) - Official Node.js Docker image  
- [Gitpod OpenVSCode Server](https://github.com/gitpod-io/openvscode-server) - Browser-based VS Code experience

Thank you to the maintainers of these projects for providing high-quality base images.