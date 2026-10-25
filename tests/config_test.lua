-- Plain Lua check of pzhotbar/ConfigFile outside the game: lua tests/config_test.lua
package.path = "src/media/lua/client/?.lua;" .. package.path

-- in-memory stand-ins for the game's file API
local files = {}
function getFileReader(name)
    local text = files[name]
    if not text then return nil end
    local nextLine = text:gmatch("([^\n]*)\n")
    return { readLine = function() return nextLine() end, close = function() end }
end
function getFileWriter(name)
    local parts = {}
    return {
        write = function(_, s) parts[#parts + 1] = s end,
        close = function() files[name] = table.concat(parts) end,
    }
end

local ConfigFile = require("pzhotbar/ConfigFile")

-- round trip: everything comes back as strings
ConfigFile.write("new.txt", {
    main = { activeWindows = 2, show = true, opacity = 0.5 },
    items = { { [1] = "Base.Bandage", [10] = "Base.Disinfectant" } },
    windows = { { rows = 2, x = 640 } },
})
assert(files["new.txt"]:find("items.1.10=Base.Disinfectant\n", 1, true), files["new.txt"])
local back = ConfigFile.read("new.txt")
assert(back.main.activeWindows == "2")
assert(back.main.show == "true")
assert(back.main.opacity == "0.5")
assert(back.items["1"]["1"] == "Base.Bandage")
assert(back.items["1"]["10"] == "Base.Disinfectant")
assert(back.windows["1"].x == "640")

-- old INI written by bcUtils
files["old.ini"] = "[main]\nactiveWindows=1\n[items]\n[items/1]\n3=Base.Pills\n[windows/1]\nrows=2\n"
local old = ConfigFile.read("old.ini")
assert(old.main.activeWindows == "1")
assert(old.items["1"]["3"] == "Base.Pills")
assert(old.windows["1"].rows == "2")

-- missing file
assert(next(ConfigFile.read("missing.txt")) == nil)

print("config_test ok")
