---------------------
---- MY PROGRAMS ----
---------------------

local home        = os.getenv( "HOME" )
local dotfiles    = home .. "/ledot"
local config      = home .. "/.config"

-- Set programs that you use
local terminal    = "kitty"
local terminal    = "alacritty"
-- local fileManager = "dolphin"
local fileManager = "kitty -e ranger" -- TUI; kitty for image previews
-- local menu        = "hyprlauncher"
-- local menu        = "rofi -show drun"
local menu        = config .. "/rofi/type-2/launcher.sh"
local browser     = "firefox"

local waybar_launcher = config .. "/waybar/scripts/launch.sh"



---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
-- [ Launch Programs ] ---------------------------------------------------------------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(waybar_launcher))

local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- Color picker: click copies hex to clipboard
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(dotfiles .. "/bin/color_picker.sh"))


-- [ Layout ] ------------------------------------------------------------------------------------------
hl.bind(mainMod .. " + ALT + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + O", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle"  }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Resize windows
hl.bind("ALT + R", hl.dsp.submap("resize"))

-- Start a submap called "resize".
hl.define_submap("resize", function()

    -- Set repeating binds for resizing the active window
    hl.bind("l", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true})
    hl.bind("h", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true})
    hl.bind("j", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true})
    hl.bind("k", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true})
    
    hl.bind("right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true})
    hl.bind("left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true})
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true})
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true})

    hl.bind("SHIFT + l", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true})
    hl.bind("SHIFT + h", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true})
    hl.bind("SHIFT + j", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true})
    hl.bind("SHIFT + k", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true})


    hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true})
    hl.bind("SHIFT + left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true})
    hl.bind("SHIFT + down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true})
    hl.bind("SHIFT + up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true})

    -- Use 'reset' to go back to the global submap
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- [ Session ] ---------------------------------------------------------------------------------
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + ALT + X", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- [ Navigation ] ---------------------------------------------------------------------------------
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- ?

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + H",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",  hl.dsp.focus({ direction = "down" }))

-- [ Workspace ] ---------------------------------------------------------------------------------
-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))


-- [ Multimidia ] ---------------------------------------------------------------------------------
-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

--- [ TOOLS ] -------------------------------------------
--- Paths
local translate = dotfiles .. "/config/quickshell/Translate.qml"

--- Translate
local launch_translate = "qs -p " .. translate
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd(launch_translate))
