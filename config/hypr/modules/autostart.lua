------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
local dotfiles = os.getenv("HOME") .. "/ledot"
local config   = os.getenv("HOME") .. "/.config"

hl.on("hyprland.start", function ()
    hl.exec_cmd(config .. "/waybar/scripts/launch.sh")
    -- hl.exec_cmd("quickshell")
    -- Bluetooth tray applet only on machines with an adapter
    hl.exec_cmd(dotfiles .. "/bin/get_bluetooth.sh && blueman-applet")
    -- h1.exec_cmd("swaync")
--     hl.exec_cmd(terminal)
--     hl.exec_cmd("nm-applet")
--     hl.exec_cmd("waybar & hyprpaper & firefox")
end)
