------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Scoped to physical outputs ON PURPOSE: a catch-all ("") re-applies on every
-- config reload and clobbers the HEADLESS virtual display used for Sunshine
-- streaming.
--
-- Physical panel: preferred mode, top-left, 1.5x.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1.5,
})

-- HEADLESS virtual display (iPad Air 13" AirPlay-class target): the exact
-- geometry sunshine-start.sh sets when creating it, kept as a static rule so
-- a config reload re-applies it instead of dropping the runtime keyword and
-- auto-placing the display on-screen. Update both places if one changes.
hl.monitor({
    output   = "HEADLESS-1",
    mode     = "2732x2048@60.00",
    position = "9999x0",
    scale    = 1,
})

-- Persistent workspaces only — deliberately NO monitor field here.
-- A workspace rule that names a monitor is re-applied on every config reload
-- and forcibly relocates that workspace (and the cursor) to that output, even
-- if it already lives somewhere else. During a Sunshine session that yanks
-- ws 1 and all its windows onto the DPMS-off physical panel: the stream then
-- shows nothing but waybar and the wallpaper, with no cursor.
-- Monitor placement is owned at runtime instead: sunshine-start.sh pins 1-10
-- to the physical output, connect.sh re-pins them to HEADLESS, disconnect.sh
-- puts them back. A reload only drops those pins, it never moves anything.
hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "3", persistent = true })
hl.workspace_rule({ workspace = "4", persistent = true })
hl.workspace_rule({ workspace = "5", persistent = true })

-- "remote" workspace served by the HEADLESS display for Sunshine clients.
-- Same rule as above: persistent, but pinned to an output only by the
-- Sunshine scripts, never by the config.
hl.workspace_rule({ workspace = "11", persistent = true })
