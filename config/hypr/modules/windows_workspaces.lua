
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

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

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
-- hl.window_rule({
--     name  = "move-hyprland-run",
--     match = { class = "hyprland-run" },

--     move  = "20 monitor_h-120",
--     float = true,
-- })

-- Translate popup (config/quickshell/Translate.qml): float in the top-left corner
hl.window_rule({
    name  = "translate-popup",
    match = { class = "^org\\.quickshell$", title = "^Translate$" },

    float = true,
    size  = "620 120",
    -- move  = "20 20",
    move  = "20 monitor_h*0.85",
})

-- Drop-down terminal (SUPER + '): spawn on first toggle, float across top of screen
hl.workspace_rule({
    workspace        = "special:dropterm",
    on_created_empty = "alacritty --class dropterm",
    gaps_out         = 0,
})

hl.window_rule({
    name  = "dropterm",
    match = { class = "^dropterm$" },

    float = true,
    size  = "monitor_w*0.6 monitor_h*0.45",
    move  = "monitor_w*0.2 10",
})

hl.layer_rule({
    name = "rofi-popup",
    match = { namespace = "rofi" },
    animation = "slide bottom",
    dim_around = true
})
