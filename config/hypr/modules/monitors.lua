------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List monitors:
-- $ hyprctl monitors all

hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = "1.25",
})

hl.monitor({
    output   = "DP-1",
    mode     = "preferred",
    position = "auto-left",
    scale    = "1",
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "preferred",
    -- position = "auto-center-right",
    -- position = "auto-right",
    position = "auto",
    scale    = "1",
})

-- Workspaces 1-5
hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", persistent = true })
