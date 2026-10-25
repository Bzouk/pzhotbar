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

--- Moves the item back to the bag it was taken from.
local function returnItem(playerObject, item, playerInv, container)
    ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObject, item, playerInv, container, 0))
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
    o.itemInfo = {} --[[@as BzItemInfo]]
    o.items = itemTable
    o:loadItemFromTable()
    o:updateItem()
    o.deleteButText = deleteButText
    o.showDelete = showDelete
    o.transferWeapons = transferWeapons
    o.showToolTip = showToolTip
    return o
end

function ISBzHotSlot:loadItemFromTable()
    if self.items ~= nil and self.itemInfo ~= nil then
        if self.items[self.slotNum] ~= nil then
            self.itemInfo.itemFullName = self.items[self.slotNum]
        end
    end
end

function ISBzHotSlot:removeItem()
    self.itemInfo = {} --[[@as BzItemInfo]]
    self.items[self.slotNum] = nil
    self:updateItem()
end

function ISBzHotSlot:createChildren()
    local sizeOfRemoveButton = getSizeOfRemoveButton(self.deleteButText)
    self.removeButton = ISButton:new(0, self:getHeight() - sizeOfRemoveButton, self:getWidth(), sizeOfRemoveButton, self.deleteButText, nil, nil, nil, nil)
    local thisTable = self
    self.removeButton:setOnClick(function()
        thisTable:removeItem()
    end)
    self.removeButton:setVisible(self.showDelete)
    self:addChild(self.removeButton)
end

function ISBzHotSlot:onMouseUp()
    ---@diagnostic disable-next-line: undefined-field
    if ISMouseDrag.dragging then
        -- update with new item
        ---@diagnostic disable-next-line: undefined-field
        local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        for _, v in ipairs(dragging) do
            self:setItem(v)
            break
        end
    else
        self:activeteSlot()
    end
end

--- Shows the item tooltip while the mouse is over the slot.
function ISBzHotSlot:update()
    if not self.showToolTip then
        return
    end
    local itemInfo = self.itemInfo
    ---@diagnostic disable-next-line: undefined-field
    if ISMouseDrag.dragging or not self:isMouseOver() or itemInfo.itemFullName == nil or itemInfo.itemFullName == "" then
        if self.toolRender ~= nil then
            self.toolRender:removeFromUIManager()
            self.toolRender:setVisible(false)
        end
        return
    end
    local playerObject = getPlayer()
    local playerInv = playerObject:getInventory()
    local itemInInv = playerInv:getBestEvalArgRecurse(predicateItem, predicateBestItem, itemInfo.itemFullName)
    -- no item do nothing
    if itemInInv == nil then
        if self.toolRender ~= nil then
            self.toolRender:removeFromUIManager()
            self.toolRender:setVisible(false)
        end
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
        ---@diagnostic disable-next-line: param-type-mismatch
        self.toolRender:setOwner(TutorialHelperFunctions)
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
    if itemInfo.itemFullName == nil or itemInfo.itemFullName == "" then
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
        elseif condition >= 0.2 and condition <= 0.4 then
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
            itemInfo.condition = -hunger / 1
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
    if itemInfo.itemFullName == nil or itemInfo.itemFullName == "" then
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
        self:drawTexture(frozenItemIcon, 0, 0, 0, 1, 1, 1, 1)
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
    local lastAction = ISTakePillAction:new(playerObject, item, nil)
    ISTimedActionQueue.add(lastAction)
    if mask then
        lastAction = ISWearClothing:new(playerObject, mask, 50)
        ISTimedActionQueue.add(lastAction)
    end
    if returnToContainer ~= nil and returnToContainer ~= playerInv then
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
    if returnToContainer ~= nil and returnToContainer ~= playerInv then
        returnItem(playerObject, item, playerInv, returnToContainer)
    end
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
    local itemInfo = self.itemInfo
    if itemInfo.itemFullName == nil or itemInfo.itemFullName == "" then
        return
    end
    local playerObject = getPlayer()
    -- not working when sleeping
    if playerObject:isAsleep() then
        return
    end
    local playerNumber = playerObject:getPlayerNum()
    local playerInv = playerObject:getInventory()
    -- search in inventory + backpack and container in inventory
    local itemInInv = playerInv:getBestEvalArgRecurse(predicateItem, predicateBestItem, itemInfo.itemFullName)
    -- no item do nothing
    if itemInInv == nil then
        return
    end
    -- container where item is located -- from ISWorldObjectContextMenu
    local returnToContainer = itemInInv:getContainer():isInCharacterInventory(playerObject) and itemInInv:getContainer()
    if itemInInv:getCategory() == "Food" or itemInInv:getScriptItem():isCantEat() then
        local food = itemInInv
        ---@cast food Food
        if not food:isPoison() and not food:isFrozen() then
            if food:getHungChange() < 0 then
                -- do not eat when full
                if playerObject:getMoodles():getMoodleLevel(MoodleType.FoodEaten) >= 3 and playerObject:getNutrition():getCalories() >= 1000 then
                    return
                end
                ISInventoryPaneContextMenu.onEatItems({food}, 0.5, playerNumber)
                if returnToContainer ~= nil and returnToContainer ~= playerInv then
                    returnItem(playerObject, food, playerInv, returnToContainer)
                end
            else
                local command = food:getCustomMenuOption() or getText("ContextMenu_Eat")
                if command ~= getText("ContextMenu_Eat") then
                    ISInventoryPaneContextMenu.onEatItems({food}, 1, playerNumber)
                end
            end
        end
    elseif instanceof(itemInInv, "DrainableComboItem") then
        local comboItem = itemInInv
        if comboItem:isWaterSource() and playerObject:getStats():getThirst() > 0.1 and not comboItem:isTaintedWater() then
            ISInventoryPaneContextMenu.onDrinkForThirst(comboItem, playerObject)
            if returnToContainer ~= nil and returnToContainer ~= playerInv then
                returnItem(playerObject, comboItem, playerInv, returnToContainer)
            end
        elseif ISInventoryPaneContextMenu.startWith(comboItem:getType(), "Pills") then
            takePill(playerObject, comboItem, playerInv, returnToContainer)
        elseif comboItem:getAlcoholPower() == 4 and (ISInventoryPaneContextMenu.startWith(comboItem:getType(), "Disinfectant") or ISInventoryPaneContextMenu.startWith(comboItem:getType(), "AlcoholWipes")) then
            disinfect(playerObject, comboItem, playerInv, returnToContainer)
        elseif (comboItem:getType() == "DishCloth" or itemInInv:getType() == "BathTowel") and playerObject:getBodyDamage():getWetness() > 0 then
            ISInventoryPaneContextMenu.onDryMyself({comboItem}, playerNumber)
        elseif comboItem:getType() == "Thread" and comboItem:getCurrentUsesFloat() >= 0 then
            local itemNeedle = playerObject:getInventory():getFirstTypeRecurse("Needle")
            if not itemNeedle then
                return
            end
            local returnToContainerNeedle = itemNeedle:getContainer():isInCharacterInventory(playerObject) and itemNeedle:getContainer()
            local itemsSutureNeedleHolder = playerObject:getInventory():getFirstTypeRecurse("SutureNeedleHolder")
            for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
                if not bodyPart:stitched() and bodyPart:isDeepWounded() and not bodyPart:haveGlass() then
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, comboItem)
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemNeedle)
                    if itemsSutureNeedleHolder ~= nil then
                        ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemsSutureNeedleHolder)
                    end
                    ISTimedActionQueue.add(ISStitch:new(playerObject, playerObject, comboItem, bodyPart, true))
                end
            end
            if returnToContainer and returnToContainer ~= playerInv then
                returnItem(playerObject, comboItem, playerInv, returnToContainer)
            end
            if returnToContainerNeedle and returnToContainerNeedle ~= playerInv then
                returnItem(playerObject, itemNeedle, playerInv, returnToContainerNeedle)
            end
            if itemsSutureNeedleHolder ~= nil then
                local retCont = itemsSutureNeedleHolder:getContainer():isInCharacterInventory(playerObject) and itemsSutureNeedleHolder:getContainer()
                if retCont and retCont ~= playerInv then
                    returnItem(playerObject, itemsSutureNeedleHolder, playerInv, retCont)
                end
            end
        end
    elseif ISInventoryPaneContextMenu.startWith(itemInInv:getType(), "Pills") or itemInInv:hasTag("Pills") or itemInInv:hasTag("Consumable") then
        takePill(playerObject, itemInInv, playerInv, returnToContainer)
    elseif itemInInv:hasComponent(ComponentType.FluidContainer) then
        local fluidcontainer = itemInInv:getFluidContainer()
        local primaryFluid = fluidcontainer:getPrimaryFluid()
        if fluidcontainer:getProperties():getAlcohol() > 0.15 and fluidcontainer:getAmount() > 0.15 then
            disinfect(playerObject, itemInInv, playerInv, returnToContainer)
        elseif (itemInInv:isWaterSource() or (primaryFluid and primaryFluid:getFluidTypeString() == "Water" or primaryFluid:getFluidTypeString() == "CarbonatedWater")) and playerObject:getStats():getThirst() > 0.1 then
            if primaryFluid:getFluidTypeString() == "TaintedWater" then
                return
            end
            ISInventoryPaneContextMenu.onDrinkForThirst(itemInInv, playerObject)
            if returnToContainer ~= nil and returnToContainer ~= playerInv then
                returnItem(playerObject, itemInInv, playerInv, returnToContainer)
            end
        elseif primaryFluid:isCategory(FluidCategory.Beverage) then
            if not fluidcontainer:canPlayerEmpty() or playerObject:getMoodleLevel(MoodleType.FoodEaten) >= 3 and playerObject:getNutrition():getCalories() >= 1000 or fluidcontainer:getCapacity() > 3 then
                return
            end
            ISInventoryPaneContextMenu.onDrinkFluid(itemInInv, 0.25, playerObject)
            if returnToContainer ~= nil and returnToContainer ~= playerInv then
                returnItem(playerObject, itemInInv, playerInv, returnToContainer)
            end
        end
    elseif instanceof(itemInInv, "HandWeapon") and itemInInv:getCondition() > 0 then
        local handWeaponItem = itemInInv
        local itemsInHand = playerObject:getPrimaryHandItem()
        local gameHotbar = getPlayerHotbar(playerNumber)
        local fromHotBar = gameHotbar and gameHotbar:isItemAttached(itemsInHand)
        local equipped
        if handWeaponItem:isTwoHandWeapon() and not playerObject:isItemInBothHands(handWeaponItem) then
            ISInventoryPaneContextMenu.OnTwoHandsEquip({handWeaponItem}, playerNumber)
            equipped = true
        else
            equipped = equipPrimary(playerObject, handWeaponItem, playerNumber)
        end
        -- put the weapon that was in hand back to the bag the new one came from
        if equipped and itemsInHand and not fromHotBar and returnToContainer and returnToContainer ~= playerInv then
            returnItem(playerObject, itemsInHand, playerInv, returnToContainer)
        end
    elseif instanceof(itemInInv, "Radio") and (instanceof(itemInInv, "InventoryItem") and not instanceof(itemInInv, "HandWeapon")) then
        local radioItem = itemInInv
        if playerObject:isEquipped(radioItem) then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObject, radioItem, 50))
            return
        end
        equipPrimary(playerObject, radioItem, playerNumber)
    elseif itemInInv:isCanBandage() then
        local bodyPartsDamaged = haveDamagePart(playerObject)
        local isDone = false
        for _, bodyPart in ipairs(bodyPartsDamaged) do
            if bodyPart:isNeedBurnWash() and itemInInv:getBandagePower() >= 2 then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISCleanBurn:new(playerObject, playerObject, itemInInv, bodyPart))
                isDone = true
            end
        end
        if isDone then
            return
        end
        local bodyPartDamaged = table.remove(bodyPartsDamaged)
        if bodyPartDamaged then
            ISInventoryPaneContextMenu.onApplyBandage({itemInInv}, bodyPartDamaged, playerNumber)
        end
    elseif itemInInv:getCategory() == "Clothing" and not playerObject:isEquipped(itemInInv) then
        ISInventoryPaneContextMenu.onWearItems({itemInInv}, playerNumber)
    elseif itemInInv:getCategory() == "Clothing" and playerObject:isEquipped(itemInInv) then
        ISInventoryPaneContextMenu.onUnEquip({itemInInv}, playerNumber)
    elseif itemInInv:getCategory() == "Literature" and not itemInInv:canBeWrite() and not playerObject:getCharacterTraits():isIlliterate() then
        ISInventoryPaneContextMenu.onLiteratureItems({itemInInv}, playerNumber)
    elseif itemInInv:getType() == "SutureNeedleHolder" or itemInInv:getType() == "Tweezers" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:haveGlass() then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISRemoveGlass:new(playerObject, playerObject, bodyPart, nil))
            elseif bodyPart:haveBullet() then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISRemoveBullet:new(playerObject, playerObject, bodyPart))
            end
        end
        if returnToContainer and returnToContainer ~= playerInv then
            returnItem(playerObject, itemInInv, playerInv, returnToContainer)
        end
    elseif itemInInv:getType() == "SutureNeedle" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:isDeepWounded() and not bodyPart:haveGlass() then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISStitch:new(playerObject, playerObject, itemInInv, bodyPart, true))
                return
            end
        end
    elseif itemInInv:getType() == "ComfreyCataplasm" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:getFractureTime() > 0 and bodyPart:getComfreyFactor() == 0 and bodyPart:getGarlicFactor() == 0 and bodyPart:getPlantainFactor() == 0 then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISComfreyCataplasm:new(playerObject, playerObject, itemInInv, bodyPart))
                return
            end
        end
    elseif itemInInv:getType() == "WildGarlicCataplasm" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:isInfectedWound() and bodyPart:getComfreyFactor() == 0 and bodyPart:getComfreyFactor() == 0 and bodyPart:getPlantainFactor() == 0 then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISGarlicCataplasm:new(playerObject, playerObject, itemInInv, bodyPart))
                return
            end
        end
    elseif itemInInv:getType() == "PlantainCataplasm" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:scratched() or bodyPart:isDeepWounded() or bodyPart:isCut() and bodyPart:getComfreyFactor() == 0 and bodyPart:getComfreyFactor() == 0 and bodyPart:getPlantainFactor() == 0 then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISPlantainCataplasm:new(playerObject, playerObject, itemInInv, bodyPart))
                return
            end
        end
    elseif itemInInv:getType() == "Splint" then
        for _, bodyPart in ipairs(haveDamagePart(playerObject)) do
            if bodyPart:getFractureTime() > 0 and bodyPart:getSplintFactor() == 0 then
                ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                ISTimedActionQueue.add(ISSplint:new(playerObject, playerObject, nil, itemInInv, bodyPart, true))
                return
            end
        end
    end
end

return ISBzHotSlot
