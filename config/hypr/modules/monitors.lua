------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List monitors:
-- $ hyprctl monitors all
--
-- Same config runs on laptop, laptop + external and two-monitor desktop.
-- Outputs are matched generically; workspaces are laid out from whatever
-- is connected and re-laid out on hotplug.

-- Laptop panel
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = "1.25",
})

-- Any other output (DP-*, HDMI-A-*, USB-C docks...): externals go left of the laptop
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto-left",
    scale    = "1",
})


----------------------------
---- WORKSPACE LAYOUT ------
----------------------------

-- Primary monitor gets workspace 1, secondary gets 2-5.
-- Primary = leftmost external; laptop panel only when nothing else is connected.
-- Single monitor: everything on it.
local names = { [1] = "code", [2] = "web" }

local function ordered_monitors()
    local externals, internals = {}, {}
    for _, m in ipairs(hl.get_monitors()) do
        if m.enabled and not m.is_mirror then
            table.insert(m.name:match("^eDP") and internals or externals, m)
        end
    end
    table.sort(externals, function(a, b) return a.x < b.x end)
    for _, m in ipairs(internals) do table.insert(externals, m) end
    return externals
end

local rules = {}

local function apply_layout()
    local mons = ordered_monitors()
    if #mons == 0 then return end

    local primary   = mons[1].name
    local secondary = (mons[2] or mons[1]).name

    for _, r in ipairs(rules) do r:set_enabled(false) end
    rules = {}

    for ws = 1, 5 do
        local mon = ws == 1 and primary or secondary
        table.insert(rules, hl.workspace_rule({
            workspace    = tostring(ws),
            monitor      = mon,
            persistent   = true,
            default_name = names[ws],
        }))
        -- Rules only affect new workspaces; move existing ones too
        if hl.get_workspace(ws) then
            hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(ws), monitor = mon }))
        end
    end
end

apply_layout()

-- Hotplug: wait for the monitor list to settle, then re-layout
local function schedule_layout()
    hl.timer(apply_layout, { timeout = 500, type = "oneshot" })
end
hl.on("monitor.added",   schedule_layout)
hl.on("monitor.removed", schedule_layout)
