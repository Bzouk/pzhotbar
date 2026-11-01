-- Plain Lua check of pzhotbar/SlotIndicators outside the game: lua tests/slot_indicators_test.lua
package.path = "src/media/lua/client/?.lua;" .. package.path
-- the game's Kahlua lacks these; any use fails here like in the game
---@diagnostic disable-next-line: assign-type-mismatch
next, unpack, table.unpack = nil, nil, nil

-- stand-ins for the game's enums and item classes
local KNOWN_TAGS = { CAR_BATTERY = 1, FLASHLIGHT = 1, LIGHTER = 1, BLOW_TORCH = 1, LIGHTER_FLUID = 1, HIDE_REMAINING = 1 }
-- set by name: a plain assignment would redefine these types for the type check of the whole mod
local enums = {
    -- only tags that exist in 42.21: anything else is a typo and fails like nil would in the game
    ItemTag = setmetatable({}, { __index = function(_, name)
        return KNOWN_TAGS[name] and name or error("unknown ItemTag " .. name)
    end }),
    ComponentType = { FluidContainer = "FluidContainer" },
    FluidCategory = { Fuel = "Fuel" },
}
for name, enum in pairs(enums) do
    _G[name] = enum
end
function instanceof(item, class)
    return item.classes ~= nil and item.classes[class] == true
end

local NEVER_ROTS = 1000000000

local function fakeItem(classes, fields)
    local item = {
        classes = {},
        tags = fields.tags or {},
        hasTag = function(self, tag) return self.tags[tag] == true end,
        getType = function() return fields.type or "Thing" end,
        hasComponent = function() return fields.fluid ~= nil end,
        getFluidContainer = function() return fields.fluid end,
        getCurrentUsesFloat = function() return fields.uses end,
        getCurrentUses = function() return fields.currentUses or 0 end,
        getMaxUses = function() return fields.maxUses or 0 end,
        getCondition = function() return fields.condition end,
        getConditionMax = function() return fields.conditionMax end,
        getMeltingTime = function() return fields.meltingTime or 0 end,
        getAge = function() return fields.age or 0 end,
        getOffAgeMax = function() return fields.offAgeMax or NEVER_ROTS end,
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

-- pills and other plain drainables count whole doses, one unit per dose
local pills = single(fakeItem({ "DrainableComboItem" }, { currentUses = 7, maxUses = 10, type = "PillsBeta" }))
assert(pills.kind == "remaining" and pills.fraction == 0.7 and pills.units == 10)
-- nothing to divide without a scale
local noScale = single(fakeItem({ "DrainableComboItem" }, { uses = 0.4 }))
assert(noScale.kind == "remaining" and noScale.fraction == 0.4 and noScale.units == nil)

-- charge: by tag, and the loose batteries that have no tag
local flashlight = single(fakeItem({ "DrainableComboItem" }, { uses = 1, maxUses = 50, tags = { FLASHLIGHT = true } }))
assert(flashlight.kind == "charge" and flashlight.units == nil)
assert(single(fakeItem({ "DrainableComboItem" }, { uses = 1, type = "Battery" })).kind == "charge")

-- fuel: by tag, and the older drainables that have no tag
local lighter = single(fakeItem({ "DrainableComboItem" }, { uses = 1, maxUses = 50, tags = { LIGHTER = true } }))
assert(lighter.kind == "fuel" and lighter.units == nil)
-- burnable is not fuel in the item: IS_FIRE_FUEL must stay out of the check (ItemTag stand-in rejects it)
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

-- food: melting wins over freshness
local melting = single(fakeItem({ "Food" }, { meltingTime = 40, age = 1, offAgeMax = 4 }))
assert(melting.kind == "melting" and melting.fraction == 0.4)
local freshness = single(fakeItem({ "Food" }, { age = 1, offAgeMax = 4 }))
assert(freshness.kind == "freshness" and freshness.fraction == 0.75)
-- rotten stays at an empty bar
assert(single(fakeItem({ "Food" }, { age = 9, offAgeMax = 4 })).fraction == 0)
-- food that does not rot has no bar
assert(#SlotIndicators.read(fakeItem({ "Food" }, {})) == 0)
assert(#SlotIndicators.read(fakeItem({ "Food" }, { offAgeMax = 0 })) == 0)

-- a weapon without a condition scale has no bar
assert(#SlotIndicators.read(fakeItem({ "HandWeapon" }, { condition = 0, conditionMax = 0 })) == 0)

-- color: the hue names the kind, below 20% everything turns the same red
assert(colorOf("condition", 1) ~= colorOf("volume", 1))
assert(colorOf("volume", 1) == colorOf("melting", 1))
assert(colorOf("fuel", 1) == colorOf("charge", 1))
assert(colorOf("remaining", 1) ~= colorOf("fuel", 1))
assert(colorOf("condition", 0.2) == colorOf("condition", 1))
assert(colorOf("condition", 0.19) == colorOf("volume", 0.19))
assert(colorOf("condition", 0.19) ~= colorOf("condition", 1))
-- thawing is not a level to run out of
assert(colorOf("melting", 0.1) == colorOf("melting", 1))
assert(colorOf("freshness", 1) == colorOf("condition", 1))

-- dividers: only when one unit is at least 4 px wide
assert(SlotIndicators.fitsDividers({ kind = "remaining", fraction = 1, units = 10 }, 43))
assert(not SlotIndicators.fitsDividers({ kind = "remaining", fraction = 1, units = 12 }, 43))
assert(not SlotIndicators.fitsDividers({ kind = "remaining", fraction = 1, units = 1 }, 43))
assert(not SlotIndicators.fitsDividers({ kind = "remaining", fraction = 1 }, 43))

print("slot_indicators_test ok")
