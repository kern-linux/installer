#!/bin/bash
# Kern Hybrid Setup
# Run in your terminal after installation for hybrid mode configuration

set -e

COMMAND=${1:-help}

case $COMMAND in
  help|h)
    echo "Usage: $0 [setup|launch|config]"
    echo "  setup   - Configure shell aliases and completions"
    echo "  launch  - Launch or attach to Kern Zellij session"
    echo "  config  - Edit Kern config (opens neovim)"
    exit 0
    ;;
  setup)
    print_header "Setting up hybrid environment"
    # Add aliases to shell
    SHELL_PROFILE=""
    if [[ -n $ZSH_VERSION ]]; then
      SHELL_PROFILE="$HOME/.zshrc"
    elif [[ -n $BASH_VERSION ]]; then
      SHELL_PROFILE="$HOME/.bashrc"
    fi
    if [[ -n $SHELL_PROFILE ]]; then
      cat >> "$SHELL_PROFILE" << 'EOF'

# Kern Hybrid aliases
alias kern='zellij attach -c kern-session || zellij -s kern-session'
alias kern-setup='zellij setup'
alias kern-kill='zellij kill-session -s kern-session'

# Source Kern completions if available
if [ -f ~/.config/kern/zellij-completion.zsh ]; then
  source ~/.config/kern/zellij-completion.zsh
fi
EOF
      print_success "Aliases added to $SHELL_PROFILE. Run 'source $SHELL_PROFILE' to apply."
    else
      print_warning "Could not detect shell profile"
    fi

    # Generate zellij completion
    if command -v zellij >/dev/null 2>&1; then
      zellij setup --generate-completion zsh > ~/.config/kern/zellij-completion.zsh 2>/dev/null || true
      zellij setup --generate-completion bash > ~/.config/kern/zellij-completion.bash 2>/dev/null || true
      print_success "Zellij completions generated"
    fi

    print_success "Setup complete! Run 'source ~/.zshrc' (or your shell profile) and then 'kern' to start."
    ;;
  launch)
    print_header "Launching Kern session"
    zellij attach -c kern-session || zellij -s kern-session
    ;;
  config)
    if command -v neovim >/dev/null 2>&1; then
      neovim ~/.config/zellij/config.kdl
    else
      vim ~/.config/zellij/config.kdl || nano ~/.config/zellij/config.kdl
    fi
    ;;
  *)
    echo "Unknown command: $COMMAND"
    $0 help
    ;;
esac