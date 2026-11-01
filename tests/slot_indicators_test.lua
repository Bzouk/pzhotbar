-- Plain Lua check of pzhotbar/SlotIndicators outside the game: lua tests/slot_indicators_test.lua
package.path = "src/media/lua/client/?.lua;" .. package.path
-- the game's Kahlua lacks these; any use fails here like in the game
---@diagnostic disable-next-line: assign-type-mismatch
next, unpack, table.unpack = nil, nil, nil

-- stand-ins for the game's enums and item classes
-- set by name: a plain assignment would redefine these types for the type check of the whole mod
local enums = {
    ItemTag = setmetatable({}, { __index = function(_, name) return name end }),
    ComponentType = { FluidContainer = "FluidContainer" },
    FluidCategory = { Fuel = "Fuel" },
}
for name, enum in pairs(enums) do
    _G[name] = enum
end
function instanceof(item, class)
    return item.classes ~= nil and item.classes[class] == true
end

local function fakeItem(classes, fields)
    local item = {
        classes = {},
        tags = fields.tags or {},
        hasTag = function(self, tag) return self.tags[tag] == true end,
        getType = function() return fields.type or "Thing" end,
        hasComponent = function() return fields.fluid ~= nil end,
        getFluidContainer = function() return fields.fluid end,
        getCurrentUsesFloat = function() return fields.uses end,
        getCondition = function() return fields.condition end,
        getConditionMax = function() return fields.conditionMax end,
        getMeltingTime = function() return fields.meltingTime or 0 end,
        getHungerChange = function() return fields.hunger or 0 end,
    }
    for _, class in ipairs(classes) do
        item.classes[class] = true
    end
    return item
end

local function fakeFluid(ratio, category)
    local primary = category and { isCategory = function(_, c) return c == category end } or nil
    return {
        getFilledRatio = function() return ratio end,
        getPrimaryFluid = function() return primary end,
    }
end

local SlotIndicators = require("pzhotbar/SlotIndicators")

local function single(item)
    local indicators = SlotIndicators.read(item)
    assert(#indicators == 1, "expected one indicator, got " .. #indicators)
    return indicators[1]
end

local function colorOf(kind, fraction)
    local r, g, b = SlotIndicators.color({ kind = kind, fraction = fraction })
    return r .. "," .. g .. "," .. b
end

-- no item, or an item with nothing to show
assert(#SlotIndicators.read(nil) == 0)
assert(#SlotIndicators.read(fakeItem({ "ComboItem" }, {})) == 0)

-- weapon condition
local weapon = single(fakeItem({ "HandWeapon" }, { condition = 3, conditionMax = 10 }))
assert(weapon.kind == "condition" and weapon.fraction == 0.3)

-- pills and other plain drainables are a quantity
local pills = single(fakeItem({ "DrainableComboItem" }, { uses = 0.7, type = "PillsBeta" }))
assert(pills.kind == "remaining" and pills.fraction == 0.7)

-- charge: by tag, and the loose batteries that have no tag
assert(single(fakeItem({ "DrainableComboItem" }, { uses = 1, tags = { FLASHLIGHT = true } })).kind == "charge")
assert(single(fakeItem({ "DrainableComboItem" }, { uses = 1, type = "Battery" })).kind == "charge")

-- fuel: by tag, and the older drainables that have no tag
assert(single(fakeItem({ "DrainableComboItem" }, { uses = 1, tags = { LIGHTER = true } })).kind == "fuel")
assert(single(fakeItem({ "DrainableComboItem" }, { uses = 1, type = "PropaneTank" })).kind == "fuel")

-- fluids go by what is inside, not by the bottle
local water = single(fakeItem({ "ComboItem" }, { fluid = fakeFluid(0.5, "Water") }))
assert(water.kind == "volume" and water.fraction == 0.5)
assert(single(fakeItem({ "ComboItem" }, { fluid = fakeFluid(0.5, "Fuel") })).kind == "fuel")
-- an empty bottle has no primary fluid and still shows its empty bar
local empty = single(fakeItem({ "ComboItem" }, { fluid = fakeFluid(0) }))
assert(empty.kind == "volume" and empty.fraction == 0)

-- the HIDE_REMAINING tag hides the quantity of drainables and fluids
local hidden = { HIDE_REMAINING = true }
assert(#SlotIndicators.read(fakeItem({ "DrainableComboItem" }, { uses = 1, tags = hidden })) == 0)
assert(#SlotIndicators.read(fakeItem({ "ComboItem" }, { fluid = fakeFluid(1), tags = hidden })) == 0)

-- food: melting wins over hunger, hunger is capped at a full bar
local melting = single(fakeItem({ "Food" }, { meltingTime = 40, hunger = -0.5 }))
assert(melting.kind == "melting" and melting.fraction == 0.4)
local hunger = single(fakeItem({ "Food" }, { hunger = -0.25 }))
assert(hunger.kind == "hunger" and hunger.fraction == 0.25)
assert(single(fakeItem({ "Food" }, { hunger = -1.5 })).fraction == 1)
assert(#SlotIndicators.read(fakeItem({ "Food" }, {})) == 0)

-- color: the hue names the kind, below 20% everything turns the same red
assert(colorOf("condition", 1) ~= colorOf("volume", 1))
assert(colorOf("volume", 1) == colorOf("melting", 1))
assert(colorOf("fuel", 1) == colorOf("charge", 1))
assert(colorOf("remaining", 1) ~= colorOf("fuel", 1))
assert(colorOf("condition", 0.2) == colorOf("condition", 1))
assert(colorOf("condition", 0.19) == colorOf("volume", 0.19))
assert(colorOf("condition", 0.19) ~= colorOf("condition", 1))
-- hunger is not a level to run out of
assert(colorOf("hunger", 0.1) == colorOf("hunger", 1))

print("slot_indicators_test ok")
