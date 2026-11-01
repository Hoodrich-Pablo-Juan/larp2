------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Physical outputs only — never a catch-all (""): an empty-name rule re-applies
-- on every reload and clobbers the HEADLESS display Sunshine streams from.
--
-- Order matters only for where "auto" lands: the laptop panel owns 0x0 and the
-- external display sits to its right, which is how the desk is arranged.
--
-- Docked behaviour (panel dark while the monitor is attached) is NOT decided
-- here. It lives in scripts/panel.sh, which is what makes a config reload
-- unable to leave the panel dark with the cursor stranded on it: every path in
-- that script ends by focusing a lit output, and focusing an output warps the
-- cursor into it. SUPER + ALT + E overrides it in both directions.

local INTERNAL = "eDP-1"
local EXTERNAL = "DP-1"

-- Positions are explicit, never "auto": auto places an output to the right of
-- whatever is currently the rightmost monitor, and HEADLESS lives at 9999x0 —
-- so "auto" lands the real monitor off at x=12731 where the cursor cannot go.

hl.monitor({
    output   = INTERNAL,
    mode     = "preferred",
    position = "0x0",
    scale    = 1.5,
})

-- 34" ultrawide at its native 180 Hz, left-most and docked at 0x0 so that when
-- the panel is switched off there is no dead strip to its left. Left to itself
-- the display advertises 3440x1440@60 as "preferred", which is the one mode
-- nobody wants.
hl.monitor({
    output   = EXTERNAL,
    mode     = "3440x1440@180.00Hz",
    position = "0x0",
    scale    = 1,
})

-- HEADLESS virtual display (tablet streaming target): the geometry
-- sunshine-start.sh uses when it creates the output, kept static so a reload
-- re-applies it instead of dropping the runtime setting and auto-placing it
-- on-screen. Inert when Sunshine isn't running.
hl.monitor({
    output   = "HEADLESS-1",
    mode     = "2732x2048@60.00",
    position = "9999x0",
    scale    = 1,
})

-- Persistent workspaces only. Deliberately NO monitor field: a workspace rule
-- that names a monitor is re-applied on every config reload and forcibly
-- relocates that workspace (and the cursor) there, even if it already lives
-- somewhere else. That is how ws 1 ends up on a DPMS-off panel mid-session.
-- Monitor placement is owned at runtime instead: sunshine-start.sh pins 1-10 to
-- the physical output, connect.sh re-pins them to HEADLESS, disconnect.sh puts
-- them back. A reload only drops those pins, it never moves anything.
for _, ws in ipairs({ "1", "2", "3", "4", "5" }) do
    hl.workspace_rule({ workspace = ws, persistent = true })
end

-- "remote" workspace served by the HEADLESS display for Sunshine clients.
hl.workspace_rule({ workspace = "11", persistent = true })

-- Apply the docked-panel policy at load and on hotplug. panel.sh is idempotent,
-- so re-running it on every monitor event costs nothing.
local function resync_panel()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/panel.sh sync")
end

hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/panel.sh sync")
hl.on("monitor.added", resync_panel)
hl.on("monitor.removed", resync_panel)
