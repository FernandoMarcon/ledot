
---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "br,us",
        kb_variant = "",
        kb_model   = "",
        -- kb_options = "grp:alt_shift_toggle", -- Alt+Shift switches us <-> br
        kb_options = "grp:alt_space_toggle", -- Alt+Space switches us <-> br
        kb_rules   = "",

        follow_mouse = 0,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- hl.gesture({
--     fingers = 3,
--     direction = "horizontal",
--     action = "workspace"
-- })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
-- hl.device({
--     name        = "epic-mouse-v1",
--     sensitivity = -0.5,
-- })
