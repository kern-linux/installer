#!/bin/bash
# Kern Migration Script
# Helps switch between full and hybrid modes

set -e

COMMAND=${1:-help}
TARGET_MODE=${2:-}

case $COMMAND in
  help|h)
    echo "Usage: $0 [to-full|to-hybrid|status]"
    echo "  to-full    - Migrate to full mode (requires Arch + reinstall fbterm)"
    echo "  to-hybrid  - Migrate to hybrid mode (remove auto-launch)"
    echo "  status     - Show current mode"
    exit 0
    ;;
  status)
    if command -v fbterm >/dev/null 2>&1; then
      echo "Full mode indicators: fbterm present"
    fi
    if grep -q "Kern auto-launch" ~/.profile 2>/dev/null || grep -q "Kern auto-launch" ~/.bash_profile 2>/dev/null || grep -q "Kern auto-launch" ~/.zprofile 2>/dev/null; then
      echo "Full mode: Auto-launch in shell profile"
    fi
    if [ -f ~/.config/zellij/config.kdl ]; then
      echo "Shared: Zellij config present"
    fi
    echo "Hybrid: Run 'kern' alias if set"
    if grep -q "alias kern=" ~/.zshrc 2>/dev/null || grep -q "alias kern=" ~/.bashrc 2>/dev/null; then
      echo "Hybrid aliases present"
    fi
    ;;
  to-hybrid)
    print_header "Migrating to hybrid mode"
    # Remove auto-launch from profiles
    for profile in ~/.profile ~/.bash_profile ~/.zprofile ~/.zshrc; do
      if [ -f "$profile" ]; then
        sed -i.bak '/# Kern auto-launch/,/^fi$/d' "$profile" 2>/dev/null || true
        print_success "Cleaned $profile"
      fi
    done
    # Run hybrid setup
    if [ -f ~/kern-hybrid.sh ]; then
      ~/kern-hybrid.sh setup
    else
      print_warning "Run kern-hybrid.sh setup manually"
    fi
    print_success "Migration to hybrid complete. Use 'kern' to launch."
    ;;
  to-full)
    print_error "Migration to full mode requires reinstall on minimal Arch."
    print_warning "1. Backup configs: cp -r ~/.config/kern ~/kern-backup"
    print_warning "2. Re-run install.sh in full mode on Arch"
    print_warning "3. Restore shared configs: cp -r ~/kern-backup/* ~/.config/"
    print_warning "4. configure_fbterm and reboot"
    exit 1
    ;;
  *)
    echo "Unknown command: $COMMAND"
    $0 help
    ;;
esac