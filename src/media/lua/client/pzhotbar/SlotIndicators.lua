-- What the status bars of a slot show for an item: kind + fraction 0-1, one entry per bar.
-- With units the bar is divided, one part per real unit (a dose, a round).
local SlotIndicators = {}

---@alias BzIndicatorKind "condition"|"volume"|"fuel"|"charge"|"remaining"|"ammo"|"melting"|"frozen"|"freshness"

---@class BzIndicator
---@field kind BzIndicatorKind
---@field fraction number
---@field units integer?

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
    frozen = BLUE,
    fuel = YELLOW,
    charge = YELLOW,
    remaining = GRAY,
    ammo = GRAY,
    freshness = GREEN,
}

-- Thawing is no shortage.
local NEVER_LOW = {melting = true}

-- These change without setting the inventory's drawDirty flag.
local SILENT_KINDS = {ammo = true, charge = true, freshness = true, frozen = true, melting = true}

local MIN_UNIT_WIDTH = 4
local NEVER_ROTS = 1000000000

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
---@param units integer?
---@return BzIndicator
local function indicator(kind, fraction, units)
    return {kind = kind, fraction = math.max(0, math.min(1, fraction)), units = units}
end

--- Doses for plain drainables; for charge and fuel the use ticks are not real units.
---@param item InventoryItem
---@return BzIndicator
local function drainableIndicator(item)
    local kind = drainableKind(item)
    local maxUses = item:getMaxUses()
    if kind == "remaining" and maxUses > 0 then
        return indicator(kind, item:getCurrentUses() / maxUses, maxUses)
    end
    return indicator(kind, item:getCurrentUsesFloat())
end

---@param item InventoryItem?
---@return BzIndicator[]
function SlotIndicators.read(item)
    if item == nil then
        return {}
    end
    if instanceof(item, "Radio") then
        ---@cast item Radio
        local device = item:getDeviceData()
        if device ~= nil and device:getIsBatteryPowered() and device:getHasBattery() then
            return {indicator("charge", device:getPower())}
        end
        return {}
    end
    if instanceof(item, "HandWeapon") then
        ---@cast item HandWeapon
        local indicators = {}
        local maxAmmo = item:getMaxAmmo()
        if maxAmmo > 0 then
            local rounds = item:getCurrentAmmoCount() + (item:isRoundChambered() and 1 or 0)
            indicators[#indicators + 1] = indicator("ammo", rounds / maxAmmo, maxAmmo)
        end
        local conditionMax = item:getConditionMax()
        if conditionMax > 0 then
            indicators[#indicators + 1] = indicator("condition", item:getCondition() / conditionMax)
        end
        return indicators
    end
    if instanceof(item, "DrainableComboItem") then
        if item:hasTag(ItemTag.HIDE_REMAINING) then
            return {}
        end
        return {drainableIndicator(item)}
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
        local offAgeMax = item:getOffAgeMax()
        if offAgeMax > 0 and offAgeMax < NEVER_ROTS then
            return {indicator(item:isFrozen() and "frozen" or "freshness", 1 - item:getAge() / offAgeMax)}
        end
    end
    return {}
end

--- Whether the bars can change while the inventory stays clean, so they need polling.
---@param indicators BzIndicator[]?
---@return boolean
function SlotIndicators.changesSilently(indicators)
    for _, indicator in ipairs(indicators or {}) do
        if SILENT_KINDS[indicator.kind] then
            return true
        end
    end
    return false
end

--- Whether a bar this wide can show the indicator's units as dividers.
---@param indicator BzIndicator
---@param width number
---@return boolean
function SlotIndicators.fitsDividers(indicator, width)
    local units = indicator.units
    return units ~= nil and units > 1 and width / units >= MIN_UNIT_WIDTH
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
