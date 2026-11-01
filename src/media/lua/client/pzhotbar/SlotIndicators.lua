-- What the status bars of a slot show for an item: kind + fraction 0-1, one entry per bar.
local SlotIndicators = {}

---@alias BzIndicatorKind "condition"|"volume"|"fuel"|"charge"|"remaining"|"melting"|"hunger"

---@class BzIndicator
---@field kind BzIndicatorKind
---@field fraction number

local LOW_FRACTION = 0.2
local LOW_COLOR = {r = 0.95, g = 0.25, b = 0.18}

-- The hue says what the bar measures, never how much is left.
local GREEN = {r = 0.35, g = 0.85, b = 0.4}
local BLUE = {r = 0.35, g = 0.68, b = 0.95}
local YELLOW = {r = 0.95, g = 0.84, b = 0.25}
local GRAY = {r = 0.75, g = 0.77, b = 0.8}
local KIND_COLORS = {
    condition = GREEN,
    volume = BLUE,
    melting = BLUE,
    fuel = YELLOW,
    charge = YELLOW,
    remaining = GRAY,
    hunger = {r = 0.678, g = 1, b = 0.384},
}

-- Not a level that runs out: a typical food sits below LOW_FRACTION when it is whole.
local NEVER_LOW = {hunger = true}

-- Loose batteries and older tools have no tag to go by.
local CHARGE_TYPES = {Battery = true, Lighter_Battery = true}
local FUEL_TYPES = {BlowTorch = true, PropaneTank = true, LighterFluid = true}

---@param item InventoryItem
local function isCharge(item)
    return item:hasTag(ItemTag.CAR_BATTERY) or item:hasTag(ItemTag.FLASHLIGHT) or CHARGE_TYPES[item:getType()] == true
end

---@param item InventoryItem
local function isFuel(item)
    return item:hasTag(ItemTag.LIGHTER) or item:hasTag(ItemTag.BLOW_TORCH) or item:hasTag(ItemTag.LIGHTER_FLUID)
        or item:hasTag(ItemTag.IS_FIRE_FUEL) or FUEL_TYPES[item:getType()] == true
end

---@param item InventoryItem
---@return BzIndicatorKind
local function drainableKind(item)
    if isCharge(item) then
        return "charge"
    elseif isFuel(item) then
        return "fuel"
    end
    return "remaining"
end

---@param fluid FluidContainer
---@return BzIndicatorKind
local function fluidKind(fluid)
    -- an empty container has no primary fluid
    local primary = fluid:getPrimaryFluid()
    if primary ~= nil and primary:isCategory(FluidCategory.Fuel) then
        return "fuel"
    end
    return "volume"
end

---@param item InventoryItem?
---@return BzIndicator[]
function SlotIndicators.read(item)
    if item == nil then
        return {}
    end
    if instanceof(item, "HandWeapon") then
        ---@cast item HandWeapon
        return {{kind = "condition", fraction = item:getCondition() / item:getConditionMax()}}
    end
    if instanceof(item, "DrainableComboItem") then
        if item:hasTag(ItemTag.HIDE_REMAINING) then
            return {}
        end
        return {{kind = drainableKind(item), fraction = item:getCurrentUsesFloat()}}
    end
    if instanceof(item, "ComboItem") then
        if item:hasComponent(ComponentType.FluidContainer) and not item:hasTag(ItemTag.HIDE_REMAINING) then
            local fluid = item:getFluidContainer()
            return {{kind = fluidKind(fluid), fraction = fluid:getFilledRatio()}}
        end
        return {}
    end
    -- smoke is also food
    if instanceof(item, "Food") then
        ---@cast item Food
        local meltingTime = item:getMeltingTime()
        if meltingTime > 0 then
            return {{kind = "melting", fraction = math.min(1, meltingTime / 100)}}
        end
        local hunger = item:getHungerChange()
        if hunger ~= 0 then
            return {{kind = "hunger", fraction = math.min(1, math.abs(hunger))}}
        end
    end
    return {}
end

---@param indicator BzIndicator
---@return number r, number g, number b
function SlotIndicators.color(indicator)
    local color = KIND_COLORS[indicator.kind]
    if indicator.fraction < LOW_FRACTION and not NEVER_LOW[indicator.kind] then
        color = LOW_COLOR
    end
    return color.r, color.g, color.b
end

return SlotIndicators
