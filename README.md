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
* **System**: tailnet-only SSH, autologin, lid-always-on, shutdown-as-restart policy, Bluetooth audio target (see [`system/`](system/))

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
│   ├── etc/plasmalogin.conf.d/autologin.conf
│   ├── etc/locale.conf
│   ├── etc/vconsole.conf
│   ├── etc/modprobe.d/usblp-blacklist.conf
│   ├── etc/systemd/logind.conf.d/10-lid-always-on.conf
│   ├── etc/systemd/system/sshd.service.d/10-tailscale.conf
│   ├── etc/systemd/system/systemd-poweroff.service.d/override.conf
│   ├── etc/systemd/system/systemd-halt.service.d/override.conf
│   ├── etc/systemd/system/bluetooth-audio-ready.service
│   ├── usr/local/bin/sshd-tailscale-listen.sh
│   └── usr/local/bin/bluetooth-audio-ready.sh
├── scripts/                 # Helper scripts copied to ~/.local/bin
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
4. **Links Wallpapers**: Creates a symbolic link for `wallpapers/` into `~/Pictures/Wallpapers`, and installs `wallpaper-rotate.sh` (with the other helper scripts) so the set cycles hourly.
5. **Sets Default Shell**: Detects if your active shell is not Fish, and offers to automatically change it using `chsh`.
6. **Installs System Config**: Copies `system/` into `/etc` and `/usr/local/bin`, reloads systemd, and restarts `sshd` after validating its config with `sshd -t`. It then dry-runs the real power-off helper to confirm the shutdown-as-restart policy can still be overridden.
7. **Enables Services**: `sshd`, `tailscaled` (plus Tailscale SSH via `tailscale set --ssh`), `plasmalogin` for autologin, `bluetooth` with the `bluetooth-audio-ready` unit, `battery-charge-limit` (pass-through charging, applied and reported at the end of the run), and `asusd`.
8. **Builds the Hyprland plugin**: runs `hyprpm add`/`enable`/`reload` for `Hypr-DarkWindow` at the tag matching the running Hyprland release, which is what draws the frosted-glass windows. Skipped (with the command to run) outside a Hyprland session.

---

## System Configuration (`system/`)

These files are **copied**, not symlinked — `sshd` and `systemd` read them as root and may start before `/home` is mounted. Paths under `system/` mirror the real filesystem, so `system/etc/ssh/...` lands at `/etc/ssh/...`.

**Tailnet-only SSH.** Tailscale's own SSH server (`tailscale set --ssh`) owns TCP/22 on the Tailscale IP, so OpenSSH listens on **TCP/2222** and is bound to that IP only — never the LAN or the public internet. `20-tailscale.conf` sets the port and hardens auth (public keys only, no root, `AllowUsers phil`). The `ListenAddress` is not hardcoded: the `sshd.service` drop-in runs `sshd-tailscale-listen.sh` as `ExecStartPre`, which writes `/etc/ssh/sshd_config.d/21-tailscale-listen.conf` from the current `tailscale ip -4` at every start. That generated file is deliberately untracked — it holds a node-specific address.

**Autologin.** `plasmalogin` logs `phil` straight into the `hyprland.desktop` session and relogs in if it exits, so the machine comes back to a usable desktop after a restart or a crash with nobody at the keyboard.

**Lid close never suspends.** `logind.conf.d/10-lid-always-on.conf` sets all three lid switches and `IdleAction` to `ignore`. The lid is how this laptop is parked while it keeps streaming; a suspend would take the Sunshine session and the tailnet with it. All three lid keys matter because logind checks docked first, then AC, then battery.

**Pass-through charging.** `battery-charge-limit.sh` (a systemd unit plus a udev rule) keeps the cells idle while the adapter is plugged in: the charge limit is set to the current capacity when that is above the 80% floor, or to the floor when it is below it, so the EC stops charging right there and the laptop runs off AC. Unplugging restores 100%, so it leaves the house full. Pinning the limit to the capacity — rather than a fixed 80 — is what records "stop here" at the top end: with the battery already at 100%, a limit of 80 has nothing left to stop. `battery-charge-limit.sh --status` prints capacity, status, limit and AC state, and `CHARGE_FLOOR` overrides the floor. The waybar battery readout is `custom/battery` running `scripts/battery-display.sh`, which shows `passthrough (100%)` while the limit is holding instead of the stock module's misleading `Full`, and keeps the icon/percentage readout otherwise. The old `asusctl -c 80` call in `autostart.lua` is gone: two owners of the same sysfs value fight each other at every login.

**Machine basics.** `locale.conf` pins `LANG=en_US.UTF-8`; `vconsole.conf` sets the console keymap to `mod-dh-iso-us` so the TTY matches the Colemak-DH layout used in the session; `modprobe.d/usblp-blacklist.conf` blacklists `usblp` so `ipp-usb` can drive a USB printer directly.

**Shutdown becomes restart.** `systemctl poweroff` and `systemctl halt` still run the normal shutdown sequence, but the units' `SuccessAction=reboot-force` makes the machine come back up instead of powering down. With autologin configured, the session returns on its own.

**Powering off for real.** `SUPER + SHIFT + Q` runs `poweroff-now.sh`: it writes a runtime drop-in (`/run/systemd/system/systemd-poweroff.service.d/zz-real-poweroff.conf`, `SuccessAction=poweroff-force`), reloads systemd, checks the override actually won, and only then powers off. `/run` is a tmpfs, so the override is gone at the next boot and the machine is back to reboot-instead-of-poweroff — this script stays the only way to cut power. It needs root or passwordless `sudo` (`sudo -n`), because it is triggered by a keybind with no terminal to prompt on. `poweroff-now.sh --dry-run` proves the override works without powering anything off.

**Docked laptop panel.** While an external monitor is attached the laptop panel goes dark, so workspaces and new windows are on the screen you are actually looking at. `SUPER + ALT + E` (`config/hypr/scripts/panel.sh toggle`) brings the panel back and puts it away again; the choice is remembered in `$XDG_RUNTIME_DIR/panel-forced-on` so a config reload cannot undo it.

The switch is **DPMS**, not disabling the output. A disabled output takes its workspaces and the cursor with it, which is exactly how you end up staring at a wallpaper with no pointer while applications launch somewhere invisible. Every path through `panel.sh` ends by focusing a lit output, and focusing an output warps the cursor into it. The panel is also parked beside the monitor (`eDP-1` at `3440x0`) *before* it is darkened, so bringing it back never drops it on top of the live screen, and it is put back at the origin when no monitor is attached. Monitor positions are explicit everywhere, never `auto`: auto places an output beyond the right-most monitor, and the HEADLESS streaming display sits at `9999x0`. The panel's position is computed at load from the external output's geometry (its right edge), so the two never overlap — Hyprland warns about overlapping layouts, and the pointer would land on the wrong screen at the seam.

**Idle blanks only the laptop panel.** `hypridle.conf` names `eDP-1` in its DPMS listener, so the 90-second idle timeout can darken the laptop panel and nothing else — the external monitor stays lit however long the machine sits untouched. On resume the listener runs `panel.sh sync` instead of blindly re-enabling the panel, so touching the keyboard while docked does not bring the laptop screen back to life.

**Monitor refresh.** `DP-1` is pinned to `3440x1440@180.00Hz`. Left to itself the display advertises `3440x1440@60` as its EDID-preferred mode, which is the one mode nobody wants.

**Bluetooth: a speaker, and this laptop as one.** `blueman` is the GUI — `SUPER + ALT + B` opens the device manager, and the applet sits in the waybar tray. The `bluetooth` service is enabled by the installer and `bluez-utils` is in `packages.txt`; without `bluez-utils` there is no `bluetoothctl` for the scripts to drive. The adapter advertises the A2DP **Sink** role out of the box, so a phone can pair and stream here. Two pieces make that actually work:
- `bluetooth-audio-ready.service` — BlueZ restores neither pairability nor discoverability across a reboot, so this oneshot puts the adapter back into "pairable, discoverable, no timeout" at every boot. Without it the machine is invisible to phones until you poke it.
- `scripts/bt-audio-bridge.sh` (started from `autostart.lua`) — PipeWire presents an incoming A2DP stream as an audio *source* (`bluez_input.<MAC>`), and a source is never auto-linked to an output, so the phone reports "connected" and plays into silence. The bridge loopbacks each such source to the current default sink, rebuilds the loopback if the default sink changes mid-stream (the speaker connecting, say), and drops it when the phone disconnects.

That gives the chain you want: phone —A2DP—> laptop —loopback—> whatever the default sink is, i.e. the Bluetooth speaker.

**Casting from Android.** Make the adapter findable — `bluetooth-audio-ready.service` does it at every boot (`discoverable on`, `DiscoverableTimeout=0`, so it never times out), or poke it once with `bluetoothctl discoverable on`. On the phone: Settings → Connected devices → Pair new device → **larp**, accept the code on both sides, allow media audio, then just play something. Android sends it over A2DP and it leaves through the laptop's default sink. No app and no screen mirroring: the phone appears as an audio source, not a remote display.

Audio follows the *default* sink, so if you want it out of the speaker rather than the laptop's own speakers, make the speaker the default: `pactl list short sinks` for the `bluez_output.<MAC>.1` name, then `pactl set-default-sink bluez_output.<MAC>.1`. `bt-audio-bridge.sh` follows a default-sink change mid-stream and rebuilds its loopback.

**Bluetooth audio stability.** `system/etc/modprobe.d/btusb-autosuspend.conf` and `system/etc/udev/rules.d/50-bluetooth-no-autosuspend.rules` keep the combo radio (`0489:e0f5` — Wi-Fi and Bluetooth share it) out of USB runtime autosuspend. `btusb` enables autosuspend with a 2 second delay, and a controller streaming A2DP is never idle, so the USB stack suspends and resumes it continuously: the HCI queue stalls and the whole machine hitches every couple of seconds, while the kernel log fills with `Unexpected start frame (len 676)` and `ACL packet for unknown connection handle` as the 676-byte aptX HD frames are dropped. With autosuspend pinned off, those frames get through. If a particular link is still marginal, the phone-side codec is the remaining lever — aptX or SBC-XQ are far less demanding than aptX HD.

**Pairing without a passkey.** `scripts/bt-agent.sh` keeps a `NoInputNoOutput` agent in the default slot, so BlueZ uses Just Works pairing: no code appears on either side and the phone only asks you to confirm the device. Without an agent on the session bus, a phone-initiated pairing deadlocks — the phone shows a passkey prompt and nothing on this machine ever answers it, so the pairing cannot be completed from both sides.

**Speaker keep-alive.** Speakers power themselves off after 10-20 minutes of silence, which turns every listen into a re-pair. `scripts/bt-keepalive.sh` (started from `autostart.lua`) streams a 25 Hz sine at about -66 dBFS into any connected `bluez_output.*` sink. That is far below what the speaker can reproduce and below the room's noise floor, so nothing is audible — but it is a non-silent digital stream, which is what auto-standby watches for. Digital silence would not work: all-zero samples look like "no audio" to most firmware. It never targets the laptop's own speakers, and it idles while nothing Bluetooth is attached.

**Frosted glass windows.** Every window is translucent and the blur behind it reads as frosted glass. The transparency is a shader rather than an opacity value: [Hypr-DarkWindow](https://github.com/micha4w/Hypr-DarkWindow) (built with `hyprpm`) runs `config/hypr/shaders/frosted.glsl` over each window's fragment shader, lowering its alpha and adding a faint milky glaze, so text keeps its weight while the desktop shows through. `config/hypr/modules/frosted.lua` registers that shader (`frostOpacity`, `frostTint`, `frostGrain` are the knobs) and applies it to every window except fullscreen ones, where a game or stream should stay opaque. The old per-app `opacity` rules for kitty, VSCodium and LibreWolf are gone — they would stack on top of the shader. hyprpm builds against the running Hyprland's ABI, so the plugin has to be rebuilt after a Hyprland upgrade (`hyprpm update`); until then `frosted.lua` finds no plugin and windows are simply opaque.

**Wallpapers rotate hourly.** `hyprpaper` reads its wallpaper once at startup and only ever changes it over IPC, so no config can re-time one on its own: `scripts/wallpaper-rotate.sh` (started from `autostart.lua`) walks the five wallpapers listed in it — the static one `hyprpaper.conf` starts with, then the four abstract 5K ones — and moves to the next every hour. Index 0 is that startup wallpaper, so the first change lands an hour after login rather than at login. Each output is named in the IPC call instead of using hyprpaper's "all outputs" form, which skips an output that is currently dark and would leave the DPMS-off laptop panel showing the old image. The position is remembered in `$XDG_RUNTIME_DIR/wallpaper-rotate.idx`, and a restarted watcher adopts whatever hyprpaper is already showing instead of snapping back. `WALLPAPER_INTERVAL` overrides the hour (`WALLPAPER_INTERVAL=10 wallpaper-rotate.sh` to test). The four 5120px sources are kept at 3840px in `wallpapers/`: the panel and the monitor top out at 3440 pixels wide, so the extra rows only cost memory to decode.

**Status bar.** Waybar draws nothing of its own — `window#waybar` is fully transparent, so the bar is just its modules floating over the wallpaper with no glass strip behind them — and it is 900px wide, centred. Everything is Google Sans (`ttf-google-sans-hinted`, AUR) at weight 400, the clock at 500 in white, and the volume and battery at 400 in white so the white does not pull the eye off the time. The whole bar sits at 60% opacity, and `GeistMono Nerd Font` sits behind the text for the icon glyphs Google Sans has no codepoints for. Google Sans ships only Regular/Medium/Bold, so anything in between is rounded by fontconfig.

Revert any of it:
```bash
sudo rm -r /etc/systemd/system/systemd-poweroff.service.d \
           /etc/systemd/system/systemd-halt.service.d   # shutdown works again
sudo rm /etc/systemd/logind.conf.d/10-lid-always-on.conf    # lid close suspends again
sudo rm /etc/plasmalogin.conf.d/autologin.conf              # back to a login prompt
sudo rm /etc/modprobe.d/usblp-blacklist.conf                # usblp driver claims USB printers again
sudo rm /etc/locale.conf /etc/vconsole.conf                 # localed settings gone
sudo rm /etc/ssh/sshd_config.d/20-tailscale.conf \
        /etc/ssh/sshd_config.d/21-tailscale-listen.conf \
        /usr/local/bin/sshd-tailscale-listen.sh
sudo rm -r /etc/systemd/system/sshd.service.d
sudo systemctl daemon-reload && sudo systemctl restart sshd
sudo systemctl disable --now bluetooth-audio-ready.service   # adapter not discoverable at boot
sudo rm /etc/systemd/system/bluetooth-audio-ready.service \
        /usr/local/bin/bluetooth-audio-ready.sh
sudo systemctl disable --now bluetooth                       # no Bluetooth at all
sudo systemctl disable --now battery-charge-limit.service     # charges to 100 again
sudo rm /etc/systemd/system/battery-charge-limit.service \
        /etc/udev/rules.d/60-battery-charge-limit.rules \
        /usr/local/bin/battery-charge-limit.sh
hyprpm disable Hypr-DarkWindow                               # windows opaque again
hyprpm remove https://github.com/micha4w/Hypr-DarkWindow
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
