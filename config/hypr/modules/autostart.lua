-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
   hl.on("hyprland.start", function () 
   hl.exec_cmd("waybar")
   hl.exec_cmd("swaync")
   hl.exec_cmd("hyprpaper")
   hl.exec_cmd("hypridle")
   hl.exec_cmd("systemctl start power-profiles-daemon.service")
   hl.exec_cmd("powerprofilesctl set power-saver")
   hl.exec_cmd("asusctl -c 80")
   hl.exec_cmd(os.getenv("HOME") .. "/.config/waybar/scripts/oled_protection.sh")
   hl.exec_cmd("~/.local/bin/sunshine-start.sh")
   -- Bluetooth: tray icon (pair/connect devices, incl. the speaker) and the
   -- bridge that plays audio a phone streams to this machine out of the
   -- current default sink.
   hl.exec_cmd("blueman-applet")
   -- Code-free pairing: keeps a NoInputNoOutput agent in the default slot, so a
   -- phone pairing does not stall waiting for a confirmation this side never
   -- shows. Runs after blueman-applet, which registers an agent of its own.
   hl.exec_cmd("~/.local/bin/bt-agent.sh")
   hl.exec_cmd("~/.local/bin/bt-audio-bridge.sh")
   -- Keeps a connected Bluetooth speaker from powering itself off during
   -- silence (inaudible 25 Hz tone, Bluetooth outputs only).
   hl.exec_cmd("~/.local/bin/bt-keepalive.sh")

 end)
