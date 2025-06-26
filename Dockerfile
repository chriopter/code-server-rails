FROM ruby:3.4.4-slim AS ruby
FROM node:20-slim AS node
FROM gitpod/openvscode-server:latest

USER root

# Copy pre-built Ruby and Node from official images
COPY --from=ruby /usr/local /usr/local
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
    ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install system packages and Ruby runtime dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client redis-tools nginx curl git \
    libyaml-0-2 libgmp10 \
    build-essential libpq-dev \
    gnome-keyring libsecret-1-0 dbus-x11 \
    software-properties-common \
    && curl -Lo /usr/local/bin/mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 \
    && chmod +x /usr/local/bin/mkcert \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'server { \
        listen 3001 ssl http2; \
        ssl_certificate /etc/nginx/certs/localhost.pem; \
        ssl_certificate_key /etc/nginx/certs/localhost-key.pem; \
        location / { \
            proxy_pass http://127.0.0.1:3002; \
            proxy_http_version 1.1; \
            proxy_set_header Upgrade $http_upgrade; \
            proxy_set_header Connection "upgrade"; \
            proxy_set_header Host $host; \
            proxy_set_header X-Real-IP $remote_addr; \
        } \
    }' > /etc/nginx/sites-available/default

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install gems and npm packages
RUN gem install bundler rails foreman --no-document && \
    npm install -g @anthropic-ai/claude-code

# Configure user environment
USER openvscode-server
RUN mkdir -p ~/.openvscode-server/data/User && \
    mkdir -p ~/.openvscode-server/data/Machine && \
    mkdir -p ~/.openvscode-server/extensions && \
    mkdir -p ~/.config && \
    mkdir -p ~/.local/share && \
    /home/.openvscode-server/bin/openvscode-server --install-extension Shopify.ruby-extensions-pack

USER root

# Add scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY github-setup.sh /usr/local/bin/github-setup
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/github-setup

WORKDIR /workspace

# Expose ports for documentation
EXPOSE 3001 3002

# Override the entrypoint from base image
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3002/ || exit 1