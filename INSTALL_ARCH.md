# Installing Arch Linux for Kern

Kern requires a minimal Arch Linux installation with no GUI. The easiest way to achieve this is using the `archinstall` script included in the official Arch Linux live ISO.

## Installation Steps

1. Boot the Arch Linux live ISO (USB drive or VM)

2. Run `archinstall` at the root prompt

3. Configure the following options:
   - **Profile**: Select "Minimal" or "Server" (do NOT select Desktop/Xorg/Wayland)
   - **Disk partitioning**: Use "best-effort default partition layout"
   - **Filesystem**: ext4 (recommended) or btrfs
   - **Bootloader**: systemd-boot or GRUB
   - **Root password**: Set a secure password
   - **User account**: Create your primary user account
   - **Timezone/Locale**: Configure for your region
   - **Network**: Enable NetworkManager for connectivity

4. Leave "Additional packages" empty for now (Kern installer will add what's needed)

5. Select "Install" and confirm

6. After installation completes, reboot

7. You should boot to a console login prompt with no graphical environment

## Next Steps

Once logged in to your minimal Arch installation, run the Kern installer:
```bash
curl -fsSL https://getkern.sh/install.sh | bash
