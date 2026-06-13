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
   hl.exec_cmd("awww-daemon")
   hl.exec_cmd("hypridle")
   hl.exec_cmd("asusctl -c 80")
   hl.exec_cmd("/home/larp/.config/waybar/scripts/oled_protection.sh")

 end)
