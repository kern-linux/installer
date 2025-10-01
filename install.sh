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

# Detect OS and mode
detect_os_and_mode() {
  OS=$(uname -s)
  DISTRO=""
  PKGMGR=""

  if [[ $OS == "Linux" ]]; then
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      DISTRO=${ID:-unknown}
    fi
  fi

  if [[ $OS == "Darwin" ]]; then
    MODE="hybrid"
    PKGMGR="brew"
    print_header "macOS detected"
    print_success "Using hybrid mode"
    return 0
  elif [[ $OS == "Linux" ]]; then
    print_header "System Detection"
    print_success "$DISTRO Linux detected"

    if [[ $DISTRO == "arch" ]]; then
      read -p "Installation mode for Arch: full (f/framebuffer) or hybrid (h)? [f] " -n 1 -r choice
      echo
      case $choice in
        h|H)
          MODE="hybrid"
          PKGMGR="pacman"
          ;;
        *)
          MODE="full"
          PKGMGR="pacman"
          ;;
      esac
    elif [[ $DISTRO == "ubuntu" ]] || [[ $DISTRO == "debian" ]] || [[ $DISTRO == "fedora" ]]; then
      # For now, hybrid only for non-Arch Linux
      MODE="hybrid"
      if [[ $DISTRO == "ubuntu" ]] || [[ $DISTRO == "debian" ]]; then
        PKGMGR="apt"
      elif [[ $DISTRO == "fedora" ]]; then
        PKGMGR="dnf"
      fi
      print_warning "Non-Arch Linux: hybrid mode only (full mode Arch-exclusive for now)"
    else
      print_error "Unsupported Linux distro: $DISTRO"
      exit 1
    fi
    print_success "Selected mode: $MODE (pkgmgr: $PKGMGR)"
    return 0
  else
    print_error "Unsupported OS: $OS. Only macOS and Linux supported."
    exit 1
  fi
}

# OS checks handled in detect_os_and_mode

# Check if running as root
check_root() {
  if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this installer as root"
    print_warning "Run as your regular user (sudo/brew will be used when needed)"
    exit 1
  fi
}

# Check access based on package manager
check_access() {
  case $PKGMGR in
    brew)
      if ! command -v brew >/dev/null 2>&1; then
        print_error "Homebrew not found. Install it with: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
      fi
      print_success "Homebrew access confirmed"
      ;;
    pacman)
      if ! sudo pacman -Sy >/dev/null 2>&1; then
        print_error "Pacman access failed. Ensure you have sudo privileges."
        exit 1
      fi
      print_success "Pacman access confirmed"
      ;;
    apt)
      if ! sudo apt update >/dev/null 2>&1; then
        print_error "Apt access failed. Ensure you have sudo privileges."
        exit 1
      fi
      print_success "Apt access confirmed"
      ;;
    dnf)
      if ! sudo dnf check-update >/dev/null 2>&1; then
        print_error "Dnf access failed. Ensure you have sudo privileges."
        exit 1
      fi
      print_success "Dnf access confirmed"
      ;;
    *)
      print_error "Unknown package manager: $PKGMGR"
      exit 1
      ;;
  esac
}

# Install base packages
install_base_packages() {
  print_header "Installing base packages"

  local common_packages=("git")

  if [[ $MODE == "full" ]]; then
    common_packages+=("fbterm")
    if [[ $PKGMGR == "pacman" ]]; then
      common_packages+=("base-devel")
    fi
  fi

  # Update repos
  case $PKGMGR in
    brew)
      brew update
      ;;
    pacman)
      sudo pacman -Sy --noconfirm
      ;;
    apt)
      sudo apt update -qq
      ;;
    dnf)
      sudo dnf check-update
      ;;
  esac

  # Install common packages
  for pkg in "${common_packages[@]}"; do
    case $PKGMGR in
      brew)
        if brew list "$pkg" >/dev/null 2>&1; then
          print_success "$pkg already installed"
        else
          brew install "$pkg"
          print_success "Installed $pkg"
        fi
        ;;
      pacman)
        if pacman -Q "$pkg" >/dev/null 2>&1; then
          print_success "$pkg already installed"
        else
          sudo pacman -S --noconfirm "$pkg"
          print_success "Installed $pkg"
        fi
        ;;
      apt)
        if dpkg -l | grep -q "^ii  $pkg "; then
          print_success "$pkg already installed"
        else
          sudo apt install -y "$pkg"
          print_success "Installed $pkg"
        fi
        ;;
      dnf)
        if rpm -q "$pkg" >/dev/null 2>&1; then
          print_success "$pkg already installed"
        else
          sudo dnf install -y "$pkg"
          print_success "Installed $pkg"
        fi
        ;;
    esac
  done
}

# Install yay (only for Arch if needed for AUR packages)
# Currently not needed as core packages are in main repos
install_yay() {
  # Placeholder for future AUR needs
  true
}

# Install zellij
install_zellij() {
  print_header "Installing zellij"

  if command -v zellij >/dev/null 2>&1; then
    print_success "zellij already installed"
    return
  fi

  case $PKGMGR in
    brew)
      brew install zellij
      ;;
    pacman)
      sudo pacman -S --noconfirm zellij
      ;;
    apt)
      sudo apt install -y zellij
      ;;
    dnf)
      sudo dnf install -y zellij
      ;;
  esac
  print_success "zellij installed"
}

# Install core TUI apps
install_core_tuis() {
  print_header "Installing core TUI applications"

  local tuis=("fzf" "neovim" "ranger" "zoxide" "lazygit")

  for pkg in "${tuis[@]}"; do
    if command -v "$pkg" >/dev/null 2>&1; then
      print_success "$pkg already installed"
      continue
    fi

    local pkg_name="$pkg"
    # Adjust package names if needed (e.g., lazygit may be lazygit-bin on some)
    case $pkg/$PKGMGR in
      lazygit/pacman)
        # For Arch, use AUR if not in main
        if pacman -Q lazygit >/dev/null 2>&1; then
          pkg_name="lazygit"
        else
          # Install yay first if not
          install_yay
          yay -S --noconfirm lazygit
          continue
        fi
        ;;
      *|*)
        pkg_name="$pkg"
        ;;
    esac

    case $PKGMGR in
      brew)
        brew install "$pkg_name"
        ;;
      pacman)
        sudo pacman -S --noconfirm "$pkg_name"
        ;;
      apt)
        sudo apt install -y "$pkg_name"
        ;;
      dnf)
        sudo dnf install -y "$pkg_name"
        ;;
    esac
    print_success "$pkg installed"
  done
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

  detect_os_and_mode
  check_root
  check_access

  install_base_packages
  install_yay
  install_zellij
  install_core_tuis

  if [[ $MODE == "full" ]]; then
    configure_fbterm
    configure_shell_profile
    create_custom_issue
  else
    print_success "Hybrid mode: No framebuffer or boot config needed"
    # Copy kern-hybrid.sh to user home (hybrid only)
    HYBRID_SCRIPT="$HOME/kern-hybrid.sh"
    if [ ! -f "$HYBRID_SCRIPT" ]; then
      cp "$(dirname "$0")/kern-hybrid.sh" "$HYBRID_SCRIPT"
      chmod +x "$HYBRID_SCRIPT"
      print_success "Copied kern-hybrid.sh to $HYBRID_SCRIPT"
      print_success "Run '$HYBRID_SCRIPT setup' to configure aliases and launch with 'kern'"
    else
      print_success "kern-hybrid.sh already exists at $HYBRID_SCRIPT"
    fi
  fi

  create_config_dir
  create_zellij_config

  # Copy kern-migrate.sh always for mode switching
  MIGRATE_SCRIPT="$HOME/kern-migrate.sh"
  if [ ! -f "$MIGRATE_SCRIPT" ]; then
    if [ -f "$(dirname "$0")/kern-migrate.sh" ]; then
      cp "$(dirname "$0")/kern-migrate.sh" "$MIGRATE_SCRIPT"
      chmod +x "$MIGRATE_SCRIPT"
      print_success "Copied kern-migrate.sh to $MIGRATE_SCRIPT"
      print_success "Use '$MIGRATE_SCRIPT status' or 'to-hybrid/to-full' to switch modes"
    fi
  else
    print_success "kern-migrate.sh already exists"
  fi

  print_completion
}

# Run main function
main
