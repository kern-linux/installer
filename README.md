# Kern Installer

Bootstrap script for [Kern](https://getkern.sh) - a framebuffer-first Linux environment.

## What This Does

Transforms a minimal Arch Linux installation into a complete Kern environment:

- Installs and configures `fbterm` (framebuffer terminal)
- Sets up `zellij` as your session manager
- Configures automatic session launching on login
- Customizes your TTY login screen
- Installs core TUI applications (optional)

## Requirements

- Fresh minimal Arch Linux installation
- Root or sudo access
- Internet connection

## Installation

```bash
curl -fsSL https://getkern.sh/install.sh | bash
```

## What Gets Installed

**Core (always installed):**
- `fbterm` - Framebuffer terminal emulator
- `zellij` - Terminal multiplexer and session manager

**Optional (user choice during install):**
- File manager: `ranger` or `nnn`
- Editor: `neovim` or `helix`
- System monitor: `btop`
- Fuzzy finder: `fzf`
- Additional TUI tools

## Manual Installation

If you prefer to review the script before running:

```bash
curl -fsSL https://getkern.sh/install.sh -o install-kern.sh
less install-kern.sh
bash install-kern.sh
```

## Development Status

Early development. Currently supports Arch Linux only. See [roadmap](https://github.com/kern-linux/installer/issues) for planned features.

## Documentation

See the [Kern vision document](https://kern-linux.github.io) for philosophy and architecture details.

## License

MIT - See [LICENSE](LICENSE) for details.

## Contact

Michael Borck <michael@getkern.sh>
