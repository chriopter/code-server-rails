FROM ruby:3.4.4-slim AS ruby
FROM node:20-slim AS node
FROM codercom/code-server:latest

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
    postgresql-client redis-tools curl git sudo \
    libyaml-0-2 libgmp10 libyaml-dev \
    build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/git /usr/local/bin/git

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install gems and npm packages
RUN gem install bundler rails foreman ruby-lsp --no-document && \
    npm install -g @anthropic-ai/claude-code

# Configure bundler globally for all users
RUN bundle config set --global path /home/coder/.bundle && \
    bundle config set --global bin /home/coder/.local/bin && \
    bundle config set --global cache_path /home/coder/.bundle/cache && \
    bundle config set --global cache_all true && \
    bundle config set --global disable_shared_gems true

# Setup code-server user (coder) with sudo access
RUN usermod -aG sudo coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure user environment
USER coder

# Set environment variables for bundler
ENV GEM_HOME=/home/coder/.bundle
ENV BUNDLE_PATH=/home/coder/.bundle
ENV PATH="/home/coder/.local/bin:${PATH}"
RUN mkdir -p ~/.config/code-server && \
    mkdir -p ~/.config/gh && \
    mkdir -p ~/.local/share && \
    mkdir -p /home/coder/workspace && \
    mkdir -p /home/coder/certs && \
    code-server --install-extension shopify.ruby-extensions-pack

# Configure bundler to use user-writable paths
RUN bundle config set --global path /home/coder/.bundle && \
    bundle config set --global bin /home/coder/.local/bin && \
    bundle config set --global cache_path /home/coder/.bundle/cache && \
    bundle config set --global cache_all true && \
    bundle config set --global disable_shared_gems true && \
    mkdir -p /home/coder/.bundle /home/coder/.local/bin && \
    touch ~/.bashrc && \
    echo 'export PATH="/home/coder/.local/bin:$PATH"' >> ~/.bashrc && \
    echo 'export GEM_HOME="/home/coder/.bundle"' >> ~/.bashrc && \
    echo 'export BUNDLE_PATH="/home/coder/.bundle"' >> ~/.bashrc && \
    echo 'export PATH="/home/coder/.local/bin:$PATH"' >> ~/.profile && \
    echo 'export GEM_HOME="/home/coder/.bundle"' >> ~/.profile && \
    echo 'export BUNDLE_PATH="/home/coder/.bundle"' >> ~/.profile

# Set terminal default directory and handle missing directories
RUN echo '# Ensure we start in a valid directory' >> ~/.bashrc && \
    echo 'if [ ! -d "$PWD" ]; then' >> ~/.bashrc && \
    echo '    cd /home/coder' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Persist bash history' >> ~/.bashrc && \
    echo 'export PROMPT_COMMAND="history -a"' >> ~/.bashrc && \
    echo 'export HISTFILE=/commandhistory/.bash_history' >> ~/.bashrc && \
    echo 'export HISTSIZE=10000' >> ~/.bashrc && \
    echo 'export HISTFILESIZE=20000' >> ~/.bashrc && \
    echo 'export HISTCONTROL=ignoredups:erasedups' >> ~/.bashrc && \
    echo 'shopt -s histappend' >> ~/.bashrc && \
    echo 'export HISTTIMEFORMAT="%F %T "' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Source bash aliases if exists' >> ~/.bashrc && \
    echo 'if [ -f /commandhistory/.bash_aliases ]; then' >> ~/.bashrc && \
    echo '    . /commandhistory/.bash_aliases' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc

# Create commandhistory directory with proper permissions
USER root
RUN mkdir -p /commandhistory && \
    touch /commandhistory/.bash_history && \
    touch /commandhistory/.bash_aliases && \
    chown -R coder:coder /commandhistory && \
    chmod 755 /commandhistory

# Generate self-signed certificate in user-accessible location
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /home/coder/certs/code-server.key \
    -out /home/coder/certs/code-server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" && \
    chown -R coder:coder /home/coder/certs

# Add scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY github-setup.sh /usr/local/bin/github-setup
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/github-setup

WORKDIR /home/coder/workspace

# Override the entrypoint from base image
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f -k https://localhost:8443/healthz || exit 1