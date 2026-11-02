---------------------------
---- FROSTED GLASS -------
---------------------------

-- Every window is translucent and turns the blur behind it into frosted glass.
-- The transparency is produced by a shader rather than an opacity value, so the
-- window keeps its own colours and text weight while the desktop shows through.
--
-- Provider: Hypr-DarkWindow (https://github.com/micha4w/Hypr-DarkWindow),
-- installed with hyprpm by install.sh. hyprpm records the plugin in its state
-- and Hyprland loads it at startup, so a plain `hyprctl reload` is enough here.
if hl.plugin.darkwindow == nil then
    -- Plugin not installed (or Hyprland started without it): leave windows
    -- opaque instead of failing the rest of the config.
    return
end

hl.plugin.darkwindow.load_shader("frosted", {
    path = os.getenv("HOME") .. "/.config/hypr/shaders/frosted.glsl",
    args = {
        frostOpacity = { 0.82 }, -- how much of the backdrop comes through
        frostTint    = { 0.10 }, -- milky glaze
        frostGrain   = { 0.006 }, -- fine grain, the "frosted" texture
    },
    -- Tells Hyprland to enable blur for these windows even though their alpha
    -- is opaque as far as it knows.
    introduces_transparency = true,
    fade_in_speed  = 2,
    fade_out_speed = 2,
})

-- Apply it everywhere. Fullscreen windows are left alone: a game or a stream
-- should stay opaque, and a full-screen shader pass is the one place the cost
-- would actually show.
hl.window_rule({
    name  = "frosted-glass",
    match = { class = ".*", fullscreen = false },

    ["darkwindow:shade"] = "frosted",
})
