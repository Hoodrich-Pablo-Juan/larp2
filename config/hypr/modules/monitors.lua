------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Physical outputs only — never a catch-all (""): an empty-name rule re-applies
-- on every reload and clobbers the HEADLESS display Sunshine streams from.

local INTERNAL = "eDP-1"
local EXTERNALS = {
    "DP-1", "DP-2", "DP-3", "DP-4", "DP-5", "DP-6", "DP-7", "HDMI-A-1",
}

-- The external output that is currently plugged in, if any.
local function external()
    for _, name in ipairs(EXTERNALS) do
        local m = hl.get_monitor(name)
        if m then
            return m
        end
    end
    return nil
end

-- Where the laptop panel goes: at the origin when it is alone, otherwise to the
-- right of the external output.
--
-- Computed here instead of being left at 0x0, because a panel sitting on top of
-- a monitor is an overlapping layout — Hyprland warns about it and the pointer
-- hits the wrong screen at the seam. The panel is dark while docked (see
-- scripts/panel.sh), but it still occupies a place in the layout, so that place
-- has to be somewhere valid.
local function panel_position()
    local ext = external()
    if not ext then
        return "0x0"
    end
    -- Guarded: if the monitor object lacks any of these fields, fall back to the
    -- undocked position rather than breaking the whole config.
    local ok, pos = pcall(function()
        return tostring(math.floor(ext.x + ext.width / ext.scale)) .. "x0"
    end)
    if ok and pos then
        return pos
    end
    return "0x0"
end

hl.monitor({
    output   = INTERNAL,
    mode     = "preferred",
    position = panel_position(),
    scale    = 1.5,
})

-- 34" ultrawide at its native 180 Hz, left-most and docked at 0x0 so that when
-- the panel is switched off there is no dead strip to its left. Left to itself
-- the display advertises 3440x1440@60 as "preferred", which is the one mode
-- nobody wants.
hl.monitor({
    output   = "DP-1",
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
