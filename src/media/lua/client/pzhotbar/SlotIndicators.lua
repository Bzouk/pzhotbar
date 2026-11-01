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

-- Not levels that run out: a whole food often sits below LOW_FRACTION, thawing is no shortage.
local NEVER_LOW = {hunger = true, melting = true}

-- First match wins.
local KIND_BY_TAG = {
    {tag = ItemTag.CAR_BATTERY, kind = "charge"},
    {tag = ItemTag.FLASHLIGHT, kind = "charge"},
    {tag = ItemTag.LIGHTER, kind = "fuel"},
    {tag = ItemTag.BLOW_TORCH, kind = "fuel"},
    {tag = ItemTag.LIGHTER_FLUID, kind = "fuel"},
}
-- Loose batteries and older tools have no tag to go by.
local KIND_BY_TYPE = {
    Battery = "charge",
    Lighter_Battery = "charge",
    BlowTorch = "fuel",
    PropaneTank = "fuel",
    LighterFluid = "fuel",
}

---@param item InventoryItem
---@return BzIndicatorKind
local function drainableKind(item)
    for _, entry in ipairs(KIND_BY_TAG) do
        if item:hasTag(entry.tag) then
            return entry.kind
        end
    end
    return KIND_BY_TYPE[item:getType()] or "remaining"
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

---@param kind BzIndicatorKind
---@param fraction number
---@return BzIndicator
local function indicator(kind, fraction)
    return {kind = kind, fraction = math.max(0, math.min(1, fraction))}
end

---@param item InventoryItem?
---@return BzIndicator[]
function SlotIndicators.read(item)
    if item == nil then
        return {}
    end
    if instanceof(item, "HandWeapon") then
        ---@cast item HandWeapon
        local conditionMax = item:getConditionMax()
        if conditionMax <= 0 then
            return {}
        end
        return {indicator("condition", item:getCondition() / conditionMax)}
    end
    if instanceof(item, "DrainableComboItem") then
        if item:hasTag(ItemTag.HIDE_REMAINING) then
            return {}
        end
        return {indicator(drainableKind(item), item:getCurrentUsesFloat())}
    end
    if instanceof(item, "ComboItem") then
        if item:hasComponent(ComponentType.FluidContainer) and not item:hasTag(ItemTag.HIDE_REMAINING) then
            local fluid = item:getFluidContainer()
            return {indicator(fluidKind(fluid), fluid:getFilledRatio())}
        end
        return {}
    end
    -- smoke is also food
    if instanceof(item, "Food") then
        ---@cast item Food
        local meltingTime = item:getMeltingTime()
        if meltingTime > 0 then
            return {indicator("melting", meltingTime / 100)}
        end
        local hunger = item:getHungerChange()
        if hunger < 0 then
            return {indicator("hunger", -hunger)}
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
