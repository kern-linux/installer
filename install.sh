#!/bin/bash

# Kern Installer v0.1
# Transforms a minimal Arch Linux installation into a Kern environment
# https://getkern.sh

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if running on Arch Linux
check_arch() {
  if [ ! -f /etc/arch-release ]; then
    print_error "This installer currently only supports Arch Linux"
    exit 1
  fi
  print_success "Arch Linux detected"
}

# Check if running as root
check_root() {
  if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this installer as root"
    print_warning "Run as your regular user (sudo will be used when needed)"
    exit 1
  fi
}

# Check sudo access
check_sudo() {
  if ! sudo -v; then
    print_error "This installer requires sudo access"
    exit 1
  fi
  print_success "Sudo access confirmed"
}

# Install base packages
install_base_packages() {
  print_header "Installing base packages"

  sudo pacman -Sy --noconfirm

  # Core packages
  local packages=(
    "fbterm"
    "git"
    "base-devel"
  )

  for pkg in "${packages[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
      print_success "$pkg already installed"
    else
      sudo pacman -S --noconfirm "$pkg"
      print_success "Installed $pkg"
    fi
  done
}

# Install yay (AUR helper)
install_yay() {
  if command -v yay &>/dev/null; then
    print_success "yay already installed"
    return
  fi

  print_header "Installing yay (AUR helper)"

  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~

  print_success "yay installed"
}

# Install zellij
install_zellij() {
  print_header "Installing zellij"

  if command -v zellij &>/dev/null; then
    print_success "zellij already installed"
    return
  fi

  yay -S --noconfirm zellij
  print_success "zellij installed"
}

# Configure fbterm permissions
configure_fbterm() {
  print_header "Configuring fbterm"

  # Add user to video group for framebuffer access
  sudo gpasswd -a "$USER" video

  # Set fbterm setuid (required for framebuffer access)
  sudo chmod u+s /usr/bin/fbterm

  print_success "fbterm configured"
  print_warning "You may need to log out and back in for group changes to take effect"
}

# Create Kern config directory
create_config_dir() {
  print_header "Creating configuration directory"

  mkdir -p ~/.config/kern
  print_success "Created ~/.config/kern"
}

# Configure shell profile for auto-launch
configure_shell_profile() {
  print_header "Configuring shell profile"

  # Detect shell
  local shell_profile=""
  if [ -n "$BASH_VERSION" ]; then
    shell_profile="$HOME/.bash_profile"
  elif [ -n "$ZSH_VERSION" ]; then
    shell_profile="$HOME/.zprofile"
  else
    shell_profile="$HOME/.profile"
  fi

  # Add auto-launch script
  local launch_script='
# Kern auto-launch
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec fbterm -- zellij attach --create kern-session
fi
'

  # Check if already configured
  if grep -q "Kern auto-launch" "$shell_profile" 2>/dev/null; then
    print_success "Shell profile already configured"
  else
    echo "$launch_script" >>"$shell_profile"
    print_success "Configured $shell_profile"
  fi
}

# Create custom /etc/issue
create_custom_issue() {
  print_header "Creating custom login screen"

  local issue_content='
\e[H\e[2J

                ██╗  ██╗███████╗██████╗ ███╗   ██╗
                ██║ ██╔╝██╔════╝██╔══██╗████╗  ██║
                █████╔╝ █████╗  ██████╔╝██╔██╗ ██║
                ██╔═██╗ ██╔══╝  ██╔══██╗██║╚██╗██║
                ██║  ██╗███████╗██║  ██║██║ ╚████║
                ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝

              Fast, Focused, Foundational.

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        Hostname: \n
        Kernel:   \s \r
        Date:     \d

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

'

  echo "$issue_content" | sudo tee /etc/issue >/dev/null
  print_success "Custom login screen created"
}

# Create basic zellij config
create_zellij_config() {
  print_header "Creating zellij configuration"

  local zellij_config_dir="$HOME/.config/zellij"
  mkdir -p "$zellij_config_dir"

  cat >"$zellij_config_dir/config.kdl" <<'EOF'
// Kern default zellij configuration

keybinds {
    normal {
        // Application launcher (will be implemented in future version)
        bind "Ctrl p" { 
            // Placeholder for fzf launcher
        }
    }
}

theme "default"

default_shell "bash"

pane_frames false
simplified_ui true
EOF

  print_success "Created zellij configuration"
}

# Print completion message
print_completion() {
  echo ""
  print_header "Kern Installation Complete!"
  echo ""
  echo -e "${GREEN}Next steps:${NC}"
  echo "1. Log out and log back in (or reboot)"
  echo "2. Log in to TTY1 (Ctrl+Alt+F1)"
  echo "3. You'll automatically be launched into your Kern environment"
  echo ""
  echo -e "${BLUE}Useful commands:${NC}"
  echo "  zellij - Manual launch if needed"
  echo "  zellij attach kern-session - Attach to your main session"
  echo "  zellij --help - View zellij help"
  echo ""
  echo -e "${YELLOW}Documentation:${NC} https://github.com/kern-linux"
  echo -e "${YELLOW}Issues:${NC} https://github.com/kern-linux/installer/issues"
  echo ""
}

# Main installation flow
main() {
  echo ""
  print_header "Kern Installer"
  echo "This will transform your Arch Linux system into a Kern environment"
  echo ""

  read -p "Continue with installation? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation cancelled"
    exit 0
  fi

  echo ""

  check_arch
  check_root
  check_sudo

  install_base_packages
  install_yay
  install_zellij
  configure_fbterm
  create_config_dir
  configure_shell_profile
  create_custom_issue
  create_zellij_config

  print_completion
}

# Run main function
main
