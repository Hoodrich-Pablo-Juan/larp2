-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    general = {
        layout = "scrolling"
    },
    dwindle = {
        preserve_split = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = false,
        column_width = 0.8,
        focus_fit_method = 1,
        follow_focus = true,
        follow_min_visible = 1,
        
        wrap_focus = false,
        wrap_swapcol = false,
        direction = "right",
    },
})
