-- Settings file: one "dotted.key=value" per line, e.g. items.1.3=Base.Bandage.
-- Reads the INI files of older versions too ([items/1] sections, then key=value).
-- Values always come back as strings.
local ConfigFile = {}

local function setPath(t, path, value)
    local keys = {}
    for key in path:gmatch("[^.]+") do
        keys[#keys + 1] = key
    end
    for i = 1, #keys - 1 do
        if type(t[keys[i]]) ~= "table" then
            t[keys[i]] = {}
        end
        t = t[keys[i]]
    end
    if #keys > 0 then
        t[keys[#keys]] = value
    end
end

--- Reads a settings file into a nested table; {} when the file is missing.
---@param filename string
---@return table
function ConfigFile.read(filename)
    local result = {}
    local reader = getFileReader(filename, false)
    if not reader then
        return result
    end
    local prefix = ""
    local line = reader:readLine()
    while line do
        local section = line:match("^%[(.*)%]")
        if section then
            prefix = section:gsub("/", ".") .. "."
        else
            local key, value = line:match("^([^=]+)=(.*)$")
            if key then
                setPath(result, prefix .. key, value)
            end
        end
        line = reader:readLine()
    end
    reader:close()
    return result
end

-- numbers first, in numeric order, then strings
local function keyOrder(a, b)
    if type(a) == type(b) then
        return a < b
    end
    return type(a) == "number"
end

local function writeTable(writer, t, prefix)
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    table.sort(keys, keyOrder)
    for _, key in ipairs(keys) do
        local value = t[key]
        if type(value) == "table" then
            writeTable(writer, value, prefix .. tostring(key) .. ".")
        else
            writer:write(prefix .. tostring(key) .. "=" .. tostring(value) .. "\n")
        end
    end
end

--- Overwrites the settings file with the nested table t.
---@param filename string
---@param t table
function ConfigFile.write(filename, t)
    local writer = getFileWriter(filename, true, false)
    if not writer then
        return
    end
    writeTable(writer, t, "")
    writer:close()
end

return ConfigFile
