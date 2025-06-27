#!/bin/bash
# Wrapper script to ensure aliases and history work in all contexts

# Source system bashrc if it exists
test -f /etc/bash.bashrc && source /etc/bash.bashrc

# Set up history
export HISTFILE=/commandhistory/.bash_history
export HISTSIZE=10000
export HISTFILESIZE=20000
export PROMPT_COMMAND="history -a"

# Load aliases
test -f /commandhistory/.bash_aliases && source /commandhistory/.bash_aliases

# Execute bash with all arguments passed through
exec /bin/bash "$@"