-- Every language has the same translation keys as EN: lua tests/translations_test.lua
local DIR = "src/media/lua/shared/Translate/"
local LANGUAGES = {"CN", "CS", "ES", "FR", "RU"}
local FILES = {"IG_UI.json", "UI.json"}

local function keys(path)
    local f = assert(io.open(path, "r"), path)
    local result = {}
    for key in f:read("*a"):gmatch('"([%w_]+)"%s*:') do
        result[key] = true
    end
    f:close()
    return result
end

local problems = {}
for _, file in ipairs(FILES) do
    local en = keys(DIR .. "EN/" .. file)
    for _, lang in ipairs(LANGUAGES) do
        local other = keys(DIR .. lang .. "/" .. file)
        for key in pairs(en) do
            if not other[key] then problems[#problems + 1] = lang .. "/" .. file .. " missing " .. key end
        end
        for key in pairs(other) do
            if not en[key] then problems[#problems + 1] = lang .. "/" .. file .. " extra " .. key end
        end
    end
end
table.sort(problems)
assert(#problems == 0, "\n" .. table.concat(problems, "\n"))
print("translations_test ok")
