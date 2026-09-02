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

 end)
