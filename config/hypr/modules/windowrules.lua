




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

hl.window_rule({
    name = "kitty-transparency",
    match = { class = "kitty" },
    opacity = 0.8,
})

hl.window_rule({
    name = "vscode-transparency",
    match = { class = "VSCodium" },
    opacity = "0.95 0.90",
})

hl.window_rule({
    name = "librewolf-transparency",
    match = { class = "librewolf" },
    opacity = "0.90 0.85",
})

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