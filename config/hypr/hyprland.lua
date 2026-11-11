-- Per-machine overrides: after each module, modules/<name>.<hostname>.lua is
-- loaded too if it exists (e.g. modules/monitors.fremen.lua only runs on fremen).
-- Keep machine-specific bits there so they don't leak to other machines via git.
local dir  = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or (os.getenv("HOME") .. "/.config/hypr/")
local host = (function()
    local f = io.open("/etc/hostname")
    local h = f and f:read("*l")
    if f then f:close() end
    return (h and h:match("^%s*(.-)%s*$")) or os.getenv("HOSTNAME") or ""
end)()

local function load(name)
    require("modules." .. name)
    local override = dir .. "modules/" .. name .. "." .. host .. ".lua"
    local f = host ~= "" and io.open(override)
    if f then f:close(); dofile(override) end
end

load("autostart")
load("env")
load("input")
load("keybinds")
load("look_and_feel")
load("misc")
load("monitors")
load("permissions")
load("windows_workspaces")
load("layout")
