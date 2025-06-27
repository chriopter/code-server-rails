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
    build-essential libpq-dev watchman \
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
# Set bash history environment variables globally
ENV HISTFILE=/commandhistory/.bash_history
ENV HISTSIZE=10000
ENV HISTFILESIZE=20000
ENV HISTCONTROL=ignoredups:erasedups
ENV HISTTIMEFORMAT="%F %T "
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

# Create .bashrc file for coder user with all necessary configs
RUN touch ~/.bashrc && \
    echo '# Ensure we start in a valid directory' >> ~/.bashrc && \
    echo 'if [ ! -d "$PWD" ]; then' >> ~/.bashrc && \
    echo '    cd /home/coder' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Always load aliases and history settings' >> ~/.bashrc && \
    echo 'export HISTFILE=/commandhistory/.bash_history' >> ~/.bashrc && \
    echo 'export PROMPT_COMMAND="history -a"' >> ~/.bashrc && \
    echo 'test -f /commandhistory/.bash_aliases && source /commandhistory/.bash_aliases' >> ~/.bashrc

# Create commandhistory directory with proper permissions
USER root
RUN mkdir -p /commandhistory && \
    touch /commandhistory/.bash_history && \
    touch /commandhistory/.bash_aliases && \
    chown -R coder:coder /commandhistory && \
    chmod 755 /commandhistory && \
    echo '' >> /etc/bash.bashrc && \
    echo '# Persist bash history for all users' >> /etc/bash.bashrc && \
    echo 'export PROMPT_COMMAND="history -a"' >> /etc/bash.bashrc && \
    echo 'export HISTFILE=/commandhistory/.bash_history' >> /etc/bash.bashrc && \
    echo 'export HISTSIZE=10000' >> /etc/bash.bashrc && \
    echo 'export HISTFILESIZE=20000' >> /etc/bash.bashrc && \
    echo 'export HISTCONTROL=ignoredups:erasedups' >> /etc/bash.bashrc && \
    echo 'shopt -s histappend' >> /etc/bash.bashrc && \
    echo 'if [ -f /commandhistory/.bash_aliases ]; then' >> /etc/bash.bashrc && \
    echo '    . /commandhistory/.bash_aliases' >> /etc/bash.bashrc && \
    echo 'fi' >> /etc/bash.bashrc && \
    echo '' >> /etc/bash.bashrc && \
    echo '# Force history settings even if VS Code overrides them' >> /etc/bash.bashrc && \
    echo 'export HISTFILE=/commandhistory/.bash_history' >> /etc/bash.bashrc && \
    echo 'export PROMPT_COMMAND="history -a;${PROMPT_COMMAND}"' >> /etc/bash.bashrc && \
    echo '' >> /etc/bash.bashrc && \
    echo '# Force load aliases on each prompt for VS Code terminal' >> /etc/bash.bashrc && \
    echo 'if [ -z "$ALIASES_LOADED" ]; then' >> /etc/bash.bashrc && \
    echo '    test -f /commandhistory/.bash_aliases && source /commandhistory/.bash_aliases' >> /etc/bash.bashrc && \
    echo '    export ALIASES_LOADED=1' >> /etc/bash.bashrc && \
    echo 'fi' >> /etc/bash.bashrc && \
    echo '' >> /etc/bash.bashrc && \
    echo '# VS Code terminal fix - always source our configs' >> /etc/bash.bashrc && \
    echo 'if [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_INJECTION" ]]; then' >> /etc/bash.bashrc && \
    echo '    export HISTFILE=/commandhistory/.bash_history' >> /etc/bash.bashrc && \
    echo '    test -f /commandhistory/.bash_aliases && source /commandhistory/.bash_aliases' >> /etc/bash.bashrc && \
    echo 'fi' >> /etc/bash.bashrc

# Generate self-signed certificate in user-accessible location
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /home/coder/certs/code-server.key \
    -out /home/coder/certs/code-server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" && \
    chown -R coder:coder /home/coder/certs

# Add scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY github-setup.sh /usr/local/bin/github-setup
COPY bash-wrapper.sh /usr/local/bin/bash-wrapper
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/github-setup /usr/local/bin/bash-wrapper && \
    ln -sf /usr/local/bin/bash-wrapper /usr/local/bin/bash-persistent

WORKDIR /home/coder/workspace

# Override the entrypoint from base image
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f -k https://localhost:8443/healthz || exit 1