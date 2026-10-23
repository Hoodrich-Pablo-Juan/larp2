# larp2 - My Dotfiles

This repository contains my personal system configuration files extracted directly from my machine. The configurations are managed using symlinks, meaning any changes made to configuration files on the system are instantly tracked here and ready to be committed.

## Configurations Included
* **Window Manager**: [Hyprland](config/hypr/) (configured via lua modules)
* **Shell**: [Fish](config/fish/) with [Starship Prompt](config/starship.toml)
* **Terminal Emulator**: [Kitty](config/kitty/)
* **Status Bar**: [Waybar](config/waybar/)
* **Notification Daemon**: [SwayNC](config/swaync/) (Sway Notification Center)
* **Application Launcher**: [Rofi](config/rofi/)
* **Music Visualizer**: [Cava](config/cava/)
* **Text Editor/IDE**: [VSCodium](config/VSCodium/) (user settings)
* **Themes**: GTK 3.0 and GTK 4.0 configurations
* **System**: tailnet-only SSH and shutdown-as-restart policy (see [`system/`](system/))

---

## Directory Structure

```text
larp2/
├── config/                  # Symlinked into ~/.config/
│   ├── cava/
│   ├── fish/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── hypr/
│   ├── kitty/
│   ├── rofi/
│   ├── starship.toml
│   ├── swaync/
│   ├── waybar/
│   └── VSCodium/
│       └── User/
│           └── settings.json
├── wallpapers/              # Wallpapers symlinked to ~/Pictures/Wallpapers
├── system/                  # Copied to /etc and /usr/local/bin (root-owned)
│   ├── etc/ssh/sshd_config.d/20-tailscale.conf
│   ├── etc/systemd/system/sshd.service.d/10-tailscale.conf
│   ├── etc/systemd/system/systemd-poweroff.service.d/override.conf
│   ├── etc/systemd/system/systemd-halt.service.d/override.conf
│   └── usr/local/bin/sshd-tailscale-listen.sh
├── install.sh               # Install and symlink script
├── packages.txt             # Native Arch packages installed on this system
├── packages.aur.txt         # AUR packages installed on this system
└── README.md                # This documentation
```

---

## Installation

To apply these configuration files onto a new system or restore them on your current system:

1. Clone or navigate to the repository directory:
   ```bash
   cd ~/larp2
   ```

2. Run the installer script:
   ```bash
   ./install.sh
   ```

### What the Install Script Does:
1. **Verifies Dependencies**: On Arch Linux, it checks if any native or AUR packages from `packages.txt` and `packages.aur.txt` are missing, and offers to install them automatically using `pacman` and your AUR helper (`yay`/`paru`).
2. **Safe Backups**: If you have existing files/directories at the target locations (e.g. `~/.config/kitty`), the script will automatically move them to a timestamped backup folder (`~/.config-backup-YYYYMMDDHHMMSS`) before linking. Your data will never be silently overwritten.
3. **Symlinks Configs**: Creates symbolic links from the repository's `config/` directory into `~/.config/`.
4. **Links Wallpapers**: Creates a symbolic link for `wallpapers/` into `~/Pictures/Wallpapers`.
5. **Sets Default Shell**: Detects if your active shell is not Fish, and offers to automatically change it using `chsh`.
6. **Installs System Config**: Copies `system/` into `/etc` and `/usr/local/bin`, reloads systemd, and restarts `sshd` after validating its config with `sshd -t`.

---

## System Configuration (`system/`)

These files are **copied**, not symlinked — `sshd` and `systemd` read them as root and may start before `/home` is mounted. Paths under `system/` mirror the real filesystem, so `system/etc/ssh/...` lands at `/etc/ssh/...`.

**Tailnet-only SSH.** Tailscale's own SSH server (`tailscale set --ssh`) owns TCP/22 on the Tailscale IP, so OpenSSH listens on **TCP/2222** and is bound to that IP only — never the LAN or the public internet. `20-tailscale.conf` sets the port and hardens auth (public keys only, no root, `AllowUsers phil`). The `ListenAddress` is not hardcoded: the `sshd.service` drop-in runs `sshd-tailscale-listen.sh` as `ExecStartPre`, which writes `/etc/ssh/sshd_config.d/21-tailscale-listen.conf` from the current `tailscale ip -4` at every start. That generated file is deliberately untracked — it holds a node-specific address.

**Shutdown becomes restart.** `systemctl poweroff` and `systemctl halt` still run the normal shutdown sequence, but the units' `SuccessAction=reboot-force` makes the machine come back up instead of powering down. With autologin configured, the session returns on its own.

Revert either piece:
```bash
sudo rm -r /etc/systemd/system/systemd-poweroff.service.d \
           /etc/systemd/system/systemd-halt.service.d   # shutdown works again
sudo rm /etc/ssh/sshd_config.d/20-tailscale.conf \
        /etc/ssh/sshd_config.d/21-tailscale-listen.conf \
        /usr/local/bin/sshd-tailscale-listen.sh
sudo rm -r /etc/systemd/system/sshd.service.d
sudo systemctl daemon-reload && sudo systemctl restart sshd
```

---

## Managing Your Dotfiles

Because the configurations are symlinked, editing any file under `~/.config/` (for example, tweaking your `kitty.conf` or `hyprland.lua`) will immediately update the files in this repository.

To save and push changes:
```bash
cd ~/larp2
git status
git add .
git commit -m "Update configuration"
git push
```
