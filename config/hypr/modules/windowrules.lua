




--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Per-app opacity rules used to live here. Translucency is now global and
-- comes from the frosted-glass shader (modules/frosted.lua), so a per-app
-- opacity would stack on top of it and make those windows stand out.

hl.layer_rule({
    name = "rofi_popup",
    match = { namespace = "rofi" },
    animation = "slide bottom",
    dim_around = true
    

})

hl.layer_rule ({
    name = "notification-animations",
    match = { namespace = "swaync-control-center"},
    animation = "slide top"
})

hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = true,
})

hl.layer_rule({
    name = "swaync-blur",
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = true,
})

hl.layer_rule({
    name = "swaync-notification-blur",
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = true,
})

hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = true,
})