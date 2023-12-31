-- from https://github.com/asledgehammer/PipeWrench-Utils/
local ____lualib = require("lualib_bundle")
local __TS__StringReplaceAll = ____lualib.__TS__StringReplaceAll
local __TS__StringSplit = ____lualib.__TS__StringSplit

local SyncCallback = function()
    local o = {}
    o.callbacks = {}
    o.add = function(callback) table.insert(o.callbacks, callback) end
    o.tick = function()
        if #o.callbacks > 0 then
            for i = 1, #o.callbacks, 1 do o.callbacks[i]() end
            o.callbacks = {}
        end
    end
    Events.OnFETick.Add(o.tick)
    Events.OnTickEvenPaused.Add(o.tick)
    return o
end

---@param target string The target method fullpath
---@param hook function The hook function to apply to that method
local hookInto = function(target, hook)
  if type(target) ~= "string" then error("Hook 'target' param must be a string."); end
  if type(hook) ~= "function" then error("Hook 'hook' param must be a function."); end
  print(("Hooking into " .. target) .. "...")
  target = __TS__StringReplaceAll(target, ":", ".")
  local splits = __TS__StringSplit(target, ".")
  local original = _G[splits[1]]
  do
      local i = 1
      while i < #splits do
            if original and original[splits[i + 1]] then
                if i == #splits - 1 then
                    if type(original[splits[i + 1]]) ~= "function" then
                        error(("Invalid hook target '" .. target) .. "' is not a function!")
                    end
                    local originalFunc = original[splits[i + 1]]
                    original[splits[i + 1]] = function(____self, ...)
                        return hook(originalFunc, ____self, ...)
                    end
                    print("Hooked into " .. target)
                end
                original = original[splits[i + 1]]
            else
                error(("Invalid hook target '" .. target) .. "' is not found!")
            end
            i = i + 1
      end
  end
end

---@param target string The target object/method fullpath
local getGlobal = function(target)
    target = __TS__StringReplaceAll(target, ":", ".")
    local splits = __TS__StringSplit(target, ".")
    local original = _G[splits[1]]
    do
        local i = 1
        while i < #splits do
            if original and original[splits[i + 1]] then
                original = original[splits[i + 1]]
            else
                return original
            end
            i = i + 1
        end
    end
    return original
end

local Exports = {}
Exports.syncCallback = SyncCallback()
Exports.hookInto = hookInto
Exports.getGlobal = getGlobal
function Exports.isPipeWrenchLoaded() return _G.PIPEWRENCH_READY ~= nil end
return Exports
