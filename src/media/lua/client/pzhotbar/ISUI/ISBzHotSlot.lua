---@class BzItemInfo
---@field itemFullName string?
---@field count number?
---@field texture Texture?
---@field isPoison boolean?
---@field isFrozen boolean?
---@field condition number?
---@field color {r: number, g: number, b: number, a: number}?

---@class ISBzHotSlot: ISPanel
---@field slotNum integer
---@field itemInfo BzItemInfo
---@field items table<integer, string>
---@field removeButton ISButton
---@field deleteButText string
---@field showDelete boolean
---@field transferWeapons boolean
---@field toolRender ISToolTipInv?
---@field showToolTip boolean
local ISBzHotSlot = ISPanel:derive("ISBzHotSlot")

-- Umbrella's ISMouseDrag does not declare the field vanilla sets while dragging items.
---@class ISMouseDrag
---@field dragging (InventoryItem | umbrella.ISInventoryPane.ItemRecord)[]?

local function predicateNotBroken(item)
    return not item:isBroken()
end

local function predicateItem(item, fullType)
    return item:getFullType() == fullType and predicateNotBroken(item)
end

local function predicateBestItem(item1, item2)
    if item1:hasComponent(ComponentType.FluidContainer) and item2:hasComponent(ComponentType.FluidContainer) then
        local items1Connt = item1:getFluidContainer()
        local items2Connt = item2:getFluidContainer()
        local scoreItem1 = 0
        local scoreItem2 = 0
        if items1Connt:canPlayerEmpty() then
            scoreItem1 = scoreItem1 + 10
        end
        if items2Connt:canPlayerEmpty() then
            scoreItem2 = scoreItem2 + 10
        end
        scoreItem1 = scoreItem1 + items1Connt:getFilledRatio()
        scoreItem2 = scoreItem2 + items2Connt:getFilledRatio()
        return scoreItem1 - scoreItem2
    end
    return item2:getCondition() - item1:getCondition()
end

local frozenItemIcon = getTexture("media/ui/icon_frozen.png")
local poisonIcon = getTexture("media/ui/SkullPoison.png")

local function getSizeOfRemoveButton(text)
    return math.max(5, getTextManager():MeasureStringY(UIFont.NewSmall, text))
end

---@param itemInfo BzItemInfo
local function hasItem(itemInfo)
    return itemInfo.itemFullName ~= nil and itemInfo.itemFullName ~= ""
end

--- Damaged body parts that are not bandaged yet.
---@return BodyPart[]
local function haveDamagePart(player)
    local result = {}
    local bodyParts = player:getBodyDamage():getBodyParts()
    for index = 0, bodyParts:size() - 1 do
        local bodyPart = bodyParts:get(index)
        if (bodyPart:HasInjury() or bodyPart:stitched()) and not bodyPart:bandaged() then
            result[#result + 1] = bodyPart
        end
    end
    return result
end

--- The bag in the player's inventory the item lies in (from ISWorldObjectContextMenu).
local function sourceContainer(player, item)
    return item:getContainer():isInCharacterInventory(player) and item:getContainer()
end

--- Moves the item back to the bag it was taken from, unless that is the main inventory.
local function returnItem(playerObject, item, playerInv, container)
    if container and container ~= playerInv then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObject, item, playerInv, container, 0))
    end
end

--- Applies the item to the first damaged body part that matches.
local function applyToFirstPart(playerObject, item, matches, makeAction)
    for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
        if matches(bodyPart) then
            ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
            ISTimedActionQueue.add(makeAction(bodyPart))
            return
        end
    end
end

---@return ISBzHotSlot
function ISBzHotSlot:new(x, y, width, height, itemTable, slot, deleteButText, showDelete, transferWeapons, showToolTip, opacity)
    local o = ISPanel:new(x, y, width, height)
    ---@cast o ISBzHotSlot
    setmetatable(o, self)
    self.__index = self
    o.anchorBottom = true
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.backgroundColor = {r = 0, g = 0, b = 0, a = opacity}
    o.borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1}
    o.slotNum = slot
    o.items = itemTable
    o.itemInfo = {itemFullName = itemTable[slot]}
    o:updateItem()
    o.deleteButText = deleteButText
    o.showDelete = showDelete
    o.transferWeapons = transferWeapons
    o.showToolTip = showToolTip
    return o
end

function ISBzHotSlot:removeItem()
    self.itemInfo = {}
    self.items[self.slotNum] = nil
    self:updateItem()
end

function ISBzHotSlot:createChildren()
    local sizeOfRemoveButton = getSizeOfRemoveButton(self.deleteButText)
    self.removeButton = ISButton:new(0, self:getHeight() - sizeOfRemoveButton, self:getWidth(), sizeOfRemoveButton, self.deleteButText, self, ISBzHotSlot.removeItem)
    self.removeButton:setVisible(self.showDelete)
    self:addChild(self.removeButton)
end

function ISBzHotSlot:onMouseUp()
    if ISMouseDrag.dragging then
        -- update with new item
        self:setItem(ISInventoryPane.getActualItems(ISMouseDrag.dragging)[1])
    else
        self:activeteSlot()
    end
end

function ISBzHotSlot:hideTooltip()
    if self.toolRender ~= nil then
        self.toolRender:removeFromUIManager()
        self.toolRender:setVisible(false)
    end
end

--- Shows the item tooltip while the mouse is over the slot.
function ISBzHotSlot:update()
    if not self.showToolTip then
        return
    end
    if ISMouseDrag.dragging or not self:isMouseOver() or not hasItem(self.itemInfo) then
        self:hideTooltip()
        return
    end
    local playerObject = getPlayer()
    local itemInInv = playerObject:getInventory():getBestEvalArgRecurse(predicateItem, predicateBestItem, self.itemInfo.itemFullName)
    -- no item do nothing
    if itemInInv == nil then
        self:hideTooltip()
        return
    end
    if self.toolRender and itemInInv == self.toolRender.item and self.toolRender:isVisible() then
        return
    end
    if self.toolRender ~= nil then
        self.toolRender:setItem(itemInInv)
        self.toolRender:setVisible(true)
        self.toolRender:addToUIManager()
        self.toolRender:bringToTop()
    else
        self.toolRender = ISToolTipInv:new(itemInInv)
        self.toolRender:initialise()
        self.toolRender:addToUIManager()
        self.toolRender:setVisible(true)
        -- 42.21 tooltips call owner:isReallyVisible() every frame, like the vanilla inventory pass the slot
        self.toolRender:setOwner(self)
        self.toolRender:setCharacter(playerObject)
        self.toolRender.anchorBottomLeft = {x = self:getAbsoluteX(), y = self:getParent():getAbsoluteY()}
    end
    self.toolRender.followMouse = true
end

function ISBzHotSlot:onRightMouseUp(x, y)
    local player = getPlayer()
    if player == nil or player:isAsleep() then
        return
    end
    local playerInventory = player:getInventory()
    if playerInventory == nil then
        return
    end
    local item = playerInventory:getBestEvalArgRecurse(predicateItem, predicateBestItem, self.itemInfo.itemFullName)
    -- getPlayerNum is marked deprecated but vanilla 42.21 still uses it everywhere
    ---@diagnostic disable-next-line: deprecated
    ISInventoryPaneContextMenu.createMenu(player:getPlayerNum(), true, {item}, self:getAbsoluteX() + x, self:getAbsoluteY() + y, self)
end

---@param invItem InventoryItem?
function ISBzHotSlot:setItem(invItem)
    if invItem ~= nil then
        local itemInfo = self.itemInfo
        itemInfo.itemFullName = invItem:getFullType()
        itemInfo.texture = invItem:getTexture()
        self.items[self.slotNum] = itemInfo.itemFullName
        self:updateItem()
    end
end

--- Recounts the item and computes the status bar (condition, fill, freshness).
function ISBzHotSlot:updateItem()
    local itemInfo = self.itemInfo
    if not hasItem(itemInfo) then
        return
    end
    local player = getPlayer()
    if player == nil then
        return
    end
    local playerInventory = player:getInventory()
    if playerInventory == nil then
        return
    end
    itemInfo.count = playerInventory:getItemCountRecurse(itemInfo.itemFullName)
    if itemInfo.texture == nil then
        local instItem = instanceItem(itemInfo.itemFullName)
        if instItem ~= nil then
            itemInfo.texture = instItem:getTexture()
        end
    end
    itemInfo.isPoison = false
    itemInfo.isFrozen = false
    itemInfo.condition = 0
    itemInfo.color = {r = 0, g = 0.502, b = 0, a = 0.4}
    local itemFromInv = playerInventory:getBestEvalArgRecurse(predicateItem, predicateBestItem, itemInfo.itemFullName)
    if instanceof(itemFromInv, "HandWeapon") then
        itemInfo.condition = itemFromInv:getCondition() / itemFromInv:getConditionMax()
    elseif instanceof(itemFromInv, "DrainableComboItem") then
        itemInfo.condition = itemFromInv:getCurrentUsesFloat()
    elseif instanceof(itemFromInv, "ComboItem") then
        if itemFromInv:hasComponent(ComponentType.FluidContainer) then
            itemInfo.condition = itemFromInv:getFluidContainer():getFilledRatio()
        end
    end
    if itemInfo.condition > 0 then
        local condition = itemInfo.condition
        if condition >= 0.8 and condition <= 1 then
            itemInfo.color = {r = 0, g = 0.502, b = 0, a = 0.4}
        elseif condition >= 0.6 and condition <= 0.8 then
            itemInfo.color = {r = 0.678, g = 1, b = 0.184, a = 0.4}
        elseif condition >= 0.2 and condition < 0.6 then
            itemInfo.color = {r = 1, g = 0.271, b = 0, a = 0.4}
        else
            itemInfo.color = {r = 1, g = 0, b = 0, a = 0.4}
        end
        return
    end
    -- smoke is also food
    if instanceof(itemFromInv, "Food") then
        ---@cast itemFromInv Food
        itemInfo.isPoison = itemFromInv:isPoison()
        itemInfo.isFrozen = itemFromInv:isFrozen()
        local hunger = itemFromInv:getHungerChange()
        local meltingTime = itemFromInv:getMeltingTime()
        if meltingTime > 0 then
            itemInfo.condition = math.abs(meltingTime / 100)
            itemInfo.color = {r = 0, g = 0, b = 0.5, a = 0.4}
        elseif hunger ~= 0 then
            itemInfo.condition = -hunger
            itemInfo.color = {r = 0.678, g = 1, b = 0.384, a = 0.4}
        end
    end
end

function ISBzHotSlot:prerender()
    if self.background then
        self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
        self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    end
    local itemInfo = self.itemInfo
    if not hasItem(itemInfo) then
        if self.removeButton ~= nil then
            self.removeButton:setVisible(false)
        end
        return
    end
    local player = getPlayer()
    if player == nil then
        return
    end
    local playerInventory = player:getInventory()
    if playerInventory == nil then
        return
    end
    if playerInventory:isDrawDirty() then
        self:updateItem()
    end
    local iconBoxSize = self.height
    if self.showDelete then
        self.removeButton:setVisible(true)
        iconBoxSize = iconBoxSize - getSizeOfRemoveButton(self.deleteButText)
    end
    local imgSize = math.min(self.width, iconBoxSize)
    local alpha = 0.3
    if itemInfo.count >= 1 then
        alpha = 0.9
    end
    if itemInfo.condition > 0 then
        local sizeOfStatusRect = iconBoxSize * itemInfo.condition
        self:drawRect(0, iconBoxSize - sizeOfStatusRect, self.width, sizeOfStatusRect, itemInfo.color.a, itemInfo.color.r, itemInfo.color.g, itemInfo.color.b)
    end
    if itemInfo.texture == nil then
        self.removeButton:setVisible(false)
        return
    end
    self:drawTextureScaled(itemInfo.texture, (self.width - imgSize) / 2, 0, imgSize, imgSize, alpha, 1, 1, 1)
    if itemInfo.isPoison then
        self:drawTexture(poisonIcon, 0, 0, 1, 1, 1, 1)
    elseif itemInfo.isFrozen then
        self:drawTexture(frozenItemIcon, 0, 0, 1, 1, 1, 1)
    end
    local text = "(" .. tostring(itemInfo.count) .. ")"
    local textHeight = getTextManager():MeasureStringY(UIFont.Small, text) + 1
    local y
    if self.showDelete then
        y = self.removeButton.y - textHeight
    else
        y = self:getHeight() - textHeight
    end
    self:drawText(text, self.width - getTextManager():MeasureStringX(UIFont.Small, text), y, 1, 1, 1, 1, UIFont.Small)
end

--- Takes a pill and puts a removed mask back on, then returns the item to its bag.
local function takePill(playerObject, item, playerInv, returnToContainer)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
    -- now remove a mask
    local mask = ISInventoryPaneContextMenu.getEatingMask(playerObject, true)
    -- take the pill
    ---@type ISBaseTimedAction
    local lastAction = ISTakePillAction:new(playerObject, item)
    ISTimedActionQueue.add(lastAction)
    if mask then
        -- same call as vanilla ISInventoryPaneContextMenu.takePill
        ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
        lastAction = ISWearClothing:new(playerObject, mask, 50)
        ISTimedActionQueue.add(lastAction)
    end
    if returnToContainer and returnToContainer ~= playerInv then
        ISTimedActionQueue.addAfter(lastAction, ISInventoryTransferAction:new(playerObject, item, playerInv, returnToContainer, nil))
    end
end

--- Disinfects every damaged body part that has no alcohol yet.
local function disinfect(playerObject, item, playerInv, returnToContainer)
    for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
        if bodyPart:getAlcoholLevel() == 0 then
            ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
            ISTimedActionQueue.add(ISDisinfect:new(playerObject, playerObject, item, bodyPart))
        end
    end
    returnItem(playerObject, item, playerInv, returnToContainer)
end

--- Equips the item in the primary hand when the right hand can hold it.
local function equipPrimary(playerObject, item, playerNumber)
    local rightHand = playerObject:getBodyDamage():getBodyPart(BodyPartType.Hand_R)
    if not playerObject:isPrimaryHandItem(item) and not rightHand:isDeepWounded() and (rightHand:getFractureTime() == 0 or rightHand:getSplintFactor() > 0) then
        if not (playerObject:getSecondaryHandItem() == item and item:getScriptItem():getReplaceWhenUnequip()) then
            ISInventoryPaneContextMenu.OnPrimaryWeapon({item}, playerNumber)
            return true
        end
    end
    return false
end

--- All the work for activating a slot: uses the slot's item the way a double click would.
function ISBzHotSlot:activeteSlot()
    if not hasItem(self.itemInfo) then
        return
    end
    local playerObject = getPlayer()
    -- not working when sleeping
    if playerObject:isAsleep() then
        return
    end
    ---@diagnostic disable-next-line: deprecated
    local playerNumber = playerObject:getPlayerNum()
    local playerInv = playerObject:getInventory()
    -- search in inventory + backpack and container in inventory
    local item = playerInv:getBestEvalArgRecurse(predicateItem, predicateBestItem, self.itemInfo.itemFullName)
    -- no item do nothing
    if item == nil then
        return
    end
    local returnToContainer = sourceContainer(playerObject, item)
    if item:getCategory() == "Food" or item:getScriptItem():isCantEat() then
        ---@cast item Food
        if not item:isPoison() and not item:isFrozen() then
            if item:getHungChange() < 0 then
                -- do not eat when full
                if playerObject:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 and playerObject:getNutrition():getCalories() >= 1000 then
                    return
                end
                ISInventoryPaneContextMenu.onEatItems({item}, 0.5, playerNumber)
                returnItem(playerObject, item, playerInv, returnToContainer)
            else
                local command = item:getCustomMenuOption() or getText("ContextMenu_Eat")
                if command ~= getText("ContextMenu_Eat") then
                    ISInventoryPaneContextMenu.onEatItems({item}, 1, playerNumber)
                end
            end
        end
    elseif instanceof(item, "DrainableComboItem") then
        ---@cast item DrainableComboItem
        if ISInventoryPaneContextMenu.startWith(item:getType(), "Pills") then
            takePill(playerObject, item, playerInv, returnToContainer)
        elseif item:getAlcoholPower() == 4 and (ISInventoryPaneContextMenu.startWith(item:getType(), "Disinfectant") or ISInventoryPaneContextMenu.startWith(item:getType(), "AlcoholWipes")) then
            disinfect(playerObject, item, playerInv, returnToContainer)
        elseif (item:getType() == "DishCloth" or item:getType() == "BathTowel") and playerObject:getStats():get(CharacterStat.WETNESS) > 0 then
            ISInventoryPaneContextMenu.onDryMyself({item}, playerNumber)
        elseif item:getType() == "Thread" and item:getCurrentUsesFloat() >= 0 then
            local itemNeedle = playerInv:getFirstTypeRecurse("Needle")
            if not itemNeedle then
                return
            end
            local needleContainer = sourceContainer(playerObject, itemNeedle)
            local itemsSutureNeedleHolder = playerInv:getFirstTypeRecurse("SutureNeedleHolder")
            for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
                if not bodyPart:stitched() and bodyPart:isDeepWounded() and not bodyPart:haveGlass() then
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemNeedle)
                    if itemsSutureNeedleHolder ~= nil then
                        ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemsSutureNeedleHolder)
                    end
                    ISTimedActionQueue.add(ISStitch:new(playerObject, playerObject, item, bodyPart, true))
                end
            end
            returnItem(playerObject, item, playerInv, returnToContainer)
            returnItem(playerObject, itemNeedle, playerInv, needleContainer)
            if itemsSutureNeedleHolder ~= nil then
                returnItem(playerObject, itemsSutureNeedleHolder, playerInv, sourceContainer(playerObject, itemsSutureNeedleHolder))
            end
        end
    elseif ISInventoryPaneContextMenu.startWith(item:getType(), "Pills") or item:hasTag(ItemTag.CONSUMABLE) then
        takePill(playerObject, item, playerInv, returnToContainer)
    elseif item:hasComponent(ComponentType.FluidContainer) then
        local fluidcontainer = item:getFluidContainer()
        local primaryFluid = fluidcontainer:getPrimaryFluid()
        -- an empty container has no primary fluid
        local fluidType = primaryFluid and primaryFluid:getFluidTypeString()
        if fluidcontainer:getProperties():getAlcohol() > 0.15 and fluidcontainer:getAmount() > 0.15 then
            disinfect(playerObject, item, playerInv, returnToContainer)
        elseif (item:isWaterSource() or fluidType == "Water" or fluidType == "CarbonatedWater") and playerObject:getStats():get(CharacterStat.THIRST) > 0.1 then
            -- like the vanilla double click: skip known tainted or sealed water, drink what the thirst needs
            local amount = fluidcontainer:getAmount()
            if fluidType == "TaintedWater" or fluidcontainer:isTaintedStatusKnown() or item:isSealed() or amount <= 0 then
                return
            end
            local units = math.min(playerObject:getStats():get(CharacterStat.THIRST) * 2, amount)
            ISInventoryPaneContextMenu.onDrinkFluid(item, units / amount, playerObject)
            returnItem(playerObject, item, playerInv, returnToContainer)
        elseif primaryFluid and primaryFluid:isCategory(FluidCategory.Beverage) then
            if not fluidcontainer:canPlayerEmpty() or item:isSealed() or fluidcontainer:isEmpty() or fluidcontainer:isTaintedStatusKnown() or playerObject:getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 and playerObject:getNutrition():getCalories() >= 1000 or fluidcontainer:getCapacity() > 3 then
                return
            end
            ISInventoryPaneContextMenu.onDrinkFluid(item, 0.25, playerObject)
            returnItem(playerObject, item, playerInv, returnToContainer)
        end
    elseif instanceof(item, "HandWeapon") and item:getCondition() > 0 then
        ---@cast item HandWeapon
        local itemsInHand = playerObject:getPrimaryHandItem()
        local gameHotbar = getPlayerHotbar(playerNumber)
        local fromHotBar = gameHotbar and gameHotbar:isItemAttached(itemsInHand)
        local equipped
        if item:isTwoHandWeapon() and not playerObject:isItemInBothHands(item) then
            ISInventoryPaneContextMenu.OnTwoHandsEquip({item}, playerNumber)
            equipped = true
        else
            equipped = equipPrimary(playerObject, item, playerNumber)
        end
        -- "Move weapons" option: put the weapon that was in hand back to the bag the new one came from
        if self.transferWeapons and equipped and itemsInHand and not fromHotBar then
            returnItem(playerObject, itemsInHand, playerInv, returnToContainer)
        end
    elseif instanceof(item, "Radio") and not instanceof(item, "HandWeapon") then
        if playerObject:isEquipped(item) then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObject, item, 50))
            return
        end
        equipPrimary(playerObject, item, playerNumber)
    elseif item:isCanBandage() then
        local bodyPartsDamaged = haveDamagePart(playerObject)
        local isDone = false
        for _, bodyPart in ipairs(bodyPartsDamaged) do
            if bodyPart:isNeedBurnWash() and item:getBandagePower() >= 2 then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
                ISTimedActionQueue.add(ISCleanBurn:new(playerObject, playerObject, item, bodyPart))
                isDone = true
            end
        end
        if isDone then
            return
        end
        local bodyPartDamaged = table.remove(bodyPartsDamaged)
        if bodyPartDamaged then
            ISInventoryPaneContextMenu.onApplyBandage({item}, bodyPartDamaged, playerNumber)
        end
    elseif item:getCategory() == "Clothing" then
        if playerObject:isEquipped(item) then
            ISInventoryPaneContextMenu.onUnEquip({item}, playerNumber)
        else
            ISInventoryPaneContextMenu.onWearItems({item}, playerNumber)
        end
    elseif item:getCategory() == "Literature" and not (item --[[@as Literature]]):canBeWrite() and not playerObject:hasTrait(CharacterTrait.ILLITERATE) then
        ISInventoryPaneContextMenu.onLiteratureItems({item}, playerNumber)
    elseif item:getType() == "SutureNeedleHolder" or item:getType() == "Tweezers" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:haveGlass() then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
                ISTimedActionQueue.add(ISRemoveGlass:new(playerObject, playerObject, bodyPart, false))
            elseif bodyPart:haveBullet() then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, item)
                ISTimedActionQueue.add(ISRemoveBullet:new(playerObject, playerObject, bodyPart))
            end
        end
        returnItem(playerObject, item, playerInv, returnToContainer)
    elseif item:getType() == "SutureNeedle" then
        applyToFirstPart(playerObject, item, function(bodyPart)
            return bodyPart:isDeepWounded() and not bodyPart:haveGlass()
        end, function(bodyPart)
            return ISStitch:new(playerObject, playerObject, item, bodyPart, true)
        end)
    elseif item:getType() == "ComfreyCataplasm" then
        applyToFirstPart(playerObject, item, function(bodyPart)
            return bodyPart:getFractureTime() > 0 and bodyPart:getComfreyFactor() == 0 and bodyPart:getGarlicFactor() == 0 and bodyPart:getPlantainFactor() == 0
        end, function(bodyPart)
            return ISComfreyCataplasm:new(playerObject, playerObject, item, bodyPart)
        end)
    elseif item:getType() == "WildGarlicCataplasm" then
        applyToFirstPart(playerObject, item, function(bodyPart)
            return bodyPart:isInfectedWound() and bodyPart:getComfreyFactor() == 0 and bodyPart:getGarlicFactor() == 0 and bodyPart:getPlantainFactor() == 0
        end, function(bodyPart)
            return ISGarlicCataplasm:new(playerObject, playerObject, item, bodyPart)
        end)
    elseif item:getType() == "PlantainCataplasm" then
        applyToFirstPart(playerObject, item, function(bodyPart)
            return (bodyPart:scratched() or bodyPart:isDeepWounded() or bodyPart:isCut()) and bodyPart:getComfreyFactor() == 0 and bodyPart:getGarlicFactor() == 0 and bodyPart:getPlantainFactor() == 0
        end, function(bodyPart)
            return ISPlantainCataplasm:new(playerObject, playerObject, item, bodyPart)
        end)
    elseif item:getType() == "Splint" then
        applyToFirstPart(playerObject, item, function(bodyPart)
            return bodyPart:getFractureTime() > 0 and bodyPart:getSplintFactor() == 0
        end, function(bodyPart)
            return ISSplint:new(playerObject, playerObject, nil, item, bodyPart, true)
        end)
    end
end

return ISBzHotSlot
