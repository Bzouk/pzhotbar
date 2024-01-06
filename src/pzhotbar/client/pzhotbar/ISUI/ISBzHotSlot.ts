/**
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *       rendered Lua code.
 */
import { ISPanel, ISButton, getTexture, getTextManager, UIFont, ISInventoryPane, getPlayer, InventoryItem, InventoryItemFactory, zombie, _instanceof_, DrainableComboItem, Food, MoodleType, ISInventoryPaneContextMenu, ISTimedActionQueue, ISInventoryTransferAction, getText, ISDisinfect, ISStitch, HandWeapon, ISHotbar, BodyPartType, Radio, ISUnequipAction, ISCleanBurn, Literature, ISRemoveGlass, ISRemoveBullet, ISComfreyCataplasm, ISGarlicCataplasm, ISPlantainCataplasm, ISSplint, ISToolTipInv, TutorialHelperFunctions, getSpecificPlayer } from "@asledgehammer/pipewrench";
// PipeWrench Events API.
import * as ISBzHotSlotDer from "./ISBzHotSlotDer"

const frozenItemIcon = getTexture("media/ui/icon_frozen.png")
const poisonIcon = getTexture("media/ui/SkullPoison.png");

declare class ItemInfo extends LuaTable {
    itemFullName: string
    count: number
    texture: zombie.core.textures.Texture
    isPoison: boolean
    isFrozen: boolean
    condition: number
    color: { r: number, g: number, b: number, a: number }
}
/** @customConstructor ____exports.ISBzHotSlot:new */
export declare class ISBzHotSlotClass extends ISPanel {
    constructor(x: number, y: number, width: number, height: number, itemTable: LuaTable<number, string>, slot: number, deleteButText: string, showDelete: boolean, transferWeapons: boolean, showToolTip:boolean);
    new: (x: number, y: number, width: number, height: number, itemTable: LuaTable<number, string>, slot: number, deleteButText: string, showDelete: boolean, transferWeapons: boolean, showToolTip:boolean) => ISBzHotSlotClass
    slotNum: number
    windowNum: number
    itemInfo: ItemInfo
    items: LuaTable<number, string>
    removeButton: ISButton
    deleteButText: string
    showDelete: boolean
    transferWeapons: boolean
    toolRender: ISToolTipInv
    showToolTip:boolean

    setItem: (invItem: InventoryItem) => any
    updateItem: () => any
    loadItemFromTable: () => any
    activeteSlot: () => any
    onRightMouseUp: (x: any, y: any) => any
}


/** @noSelf **/
function getSizeOfRemoveButton(text: string): number {
    return math.max(10, getTextManager().MeasureStringY(UIFont.Small, text)) //  ISBzHotBar.getHotBarDeleteText()
}

export const ISBzHotSlot = ISBzHotSlotDer.ISBzHotSlot as ISBzHotSlotClass
ISBzHotSlot.new = function (x: number, y: number, width: number, height: number, itemTable: LuaTable<number, string>, slot: number, deleteButText: string, showDelete: boolean, transferWeapons: boolean, showToolTip:boolean) {
    const o = (new ISPanel(x, y, width, height) as ISBzHotSlotClass)
    setmetatable(o, this)
    this.__index = this
    o.anchorBottom = true;
    o.anchorLeft = true;
    o.anchorRight = true;
    o.anchorTop = true;
    o.backgroundColor = { r: 0, g: 0, b: 0, a: 0.8 };
    o.borderColor = { r: 0.4, g: 0.4, b: 0.4, a: 1 };
    o.slotNum = slot;
    o.itemInfo = new ItemInfo()
    o.items = itemTable
    o.loadItemFromTable() // update item to show in slot 
    o.updateItem()
    o.deleteButText = deleteButText
    o.showDelete = showDelete
    o.transferWeapons = transferWeapons
    o.showToolTip = showToolTip

    return o
}
ISBzHotSlot.loadItemFromTable = function () {
    if (this.items != null && this.itemInfo != null) {
        if (this.items.has(this.slotNum)) {
            this.itemInfo.itemFullName = this.items.get(this.slotNum)
        }
    }
}

ISBzHotSlot.removeItem = function () {
    this.itemInfo = new ItemInfo()
    this.items.delete(this.slotNum)
    this.updateItem()
}

ISBzHotSlot.createChildren = function () {
    const sizeOfRemoveButton = getSizeOfRemoveButton(this.deleteButText);
    this.removeButton = new ISButton(0, this.getHeight() - sizeOfRemoveButton, this.getWidth(), sizeOfRemoveButton, this.deleteButText, null, null, null, null);
    const thisTable = this
    this.removeButton.setOnClick(function () {
        thisTable.removeItem();
    })
    this.removeButton.setVisible(this.showDelete);
    this.addChild(this.removeButton);
}

/** @noSelf **/
declare function getPlayerHotbar(playerNumber: number): ISHotbar

/**
 * Needs to be like this, becouse it cant be called from pipewrench. It changes overtime.
 */
declare class ISMouseDrag {
    /**
     * @noSelf
     */
    static dragging: any;
}

ISBzHotSlot.onMouseUp = function () {
    if (ISMouseDrag.dragging) {
        const dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
        for (const [_, v] of ipairs(dragging)) {
            // update with new item
            this.setItem((v as InventoryItem))
            break
        }
    } else {
        this.activeteSlot();
    }
}

/**
The function updates the UI display of a tool tip inventory item when certain conditions are met. It checks if the mouse is dragging, if the mouse is over the item, and if the item has a name.
 * @returns 
 */
ISBzHotSlot.update = function () {
    if (!this.showToolTip) {
        return
    }
    const itemInfo = this.itemInfo
    // If any of these conditions are not met, the function removes the tool tip from the UI.
    if (ISMouseDrag.dragging || !this.isMouseOver() || itemInfo.itemFullName == null || itemInfo.itemFullName == "") {
        if (this.toolRender != null) {
            this.toolRender.removeFromUIManager()
            this.toolRender.setVisible(false)
        }
        return
    }
    // If the conditions are met, the function retrieves the player's inventory and searches for the item in the inventory. If the item is not found, the function removes the tool tip from the UI.
    const playerObject = getPlayer()
    const playerInv = playerObject.getInventory()
    const itemInInv = playerInv.getFirstTypeEvalRecurse(itemInfo.itemFullName, predicateNotBroken)
    // no item do nothing
    if (itemInInv == null) {
        if (this.toolRender != null) {
            this.toolRender.removeFromUIManager()
            this.toolRender.setVisible(false)
        }
        return
    }
    // If the item is found and the tool tip is not already displaying the same item, the function updates the tool tip with the new item, makes it visible, and adds it to the UI.
    if (this.toolRender && (itemInInv == this.toolRender.item) && this.toolRender.isVisible()) {
        return
    }

    if (this.toolRender != null) {
        this.toolRender.setItem(itemInInv)
        this.toolRender.setVisible(true)
        this.toolRender.addToUIManager()
        this.toolRender.bringToTop()
    } else {
        // If the tool tip doesn't exist, the function creates a new tool tip, initializes it, and adds it to the UI. The tool tip is then anchored to the bottom left of the parent UI element. Finally, the tool tip is set to follow the mouse cursor.
        this.toolRender = new ISToolTipInv(itemInInv)
        this.toolRender.initialise()
        this.toolRender.addToUIManager()
        this.toolRender.setVisible(true)
        this.toolRender.setOwner(TutorialHelperFunctions)
        this.toolRender.setCharacter(playerObject)
        this.toolRender.anchorBottomLeft = { x: this.getAbsoluteX(), y: this.getParent().getAbsoluteY() }
    }
    this.toolRender.followMouse = true
}

/** @noSelf **/
function predicateNotBroken(item: InventoryItem): boolean {
    return !item.isBroken()
}

ISBzHotSlot.onRightMouseUp = function (x: any, y: any) {
    const player = getPlayer()
    if (player == null) {
        return
    }
    if (player.isAsleep()) {
        return
    }
    const playerInventory = player.getInventory()
    if (playerInventory == null) {
        return
    }
    const itemInfo = this.itemInfo
    ISInventoryPaneContextMenu.createMenu(player.getPlayerNum(), true, [playerInventory.getFirstTypeEvalRecurse(itemInfo.itemFullName, predicateNotBroken)], this.getAbsoluteX() + x, this.getAbsoluteY() + y, this)
}

/**
 * Sets the item in the ISBzHotSlot.
 *
 * @param {InventoryItem} invItem - The inventory item to set.
 */
ISBzHotSlot.setItem = function (invItem: InventoryItem) {
    if (invItem != null) {
        const itemInfo = this.itemInfo
        itemInfo.itemFullName = invItem.getFullType()
        itemInfo.texture = invItem.getTexture()
        this.items.set(this.slotNum, itemInfo.itemFullName)
        this.updateItem()
    }
}


ISBzHotSlot.updateItem = function () {
    const itemInfo = this.itemInfo
    if (itemInfo.itemFullName == null || itemInfo.itemFullName == "") {
        return
    }

    const player = getPlayer()
    if (player == null) {
        return
    }
    const playerInventory = player.getInventory()
    if (playerInventory == null) {
        return
    }
    itemInfo.count = playerInventory.getItemCountRecurse(itemInfo.itemFullName)

    if (itemInfo.texture == null) {
        const instItem = InventoryItemFactory.CreateItem(itemInfo.itemFullName);
        if (instItem != null) {
            itemInfo.texture = instItem.getTexture()
        }
    }

    itemInfo.isPoison = false
    itemInfo.isFrozen = false
    itemInfo.condition = 0
    itemInfo.color = { r: 0.000, g: 0.502, b: 0, a: 0.4 }
    const itemFromInv = playerInventory.getFirstTypeEvalRecurse(itemInfo.itemFullName, predicateNotBroken)

    if (_instanceof_(itemFromInv, "HandWeapon")) {
        itemInfo.condition = itemFromInv.getCondition() / itemFromInv.getConditionMax()
    } else if (_instanceof_(itemFromInv, "DrainableComboItem")) {
        itemInfo.condition = (itemFromInv as DrainableComboItem).getUsedDelta()
    }
    if (itemInfo.condition > 0) {
        const condition = itemInfo.condition
        if (condition >= 0.8 && condition <= 1) {
            itemInfo.color = { r: 0.000, g: 0.502, b: 0, a: 0.4 } // Green
        } else if (condition >= 0.6 && condition <= 0.8) {
            itemInfo.color = { r: 0.678, g: 1, b: 0.184, a: 0.4 } // GreenYellow
        } else if (condition >= 0.2 && condition <= 0.4) {
            itemInfo.color = { r: 1.000, g: 0.271, b: 0, a: 0.4 } // OrangeRed
        } else {
            itemInfo.color = { r: 1, g: 0, b: 0, a: 0.4 } // red
        }
        return
    }

    if (_instanceof_(itemFromInv, "Food")) {
        // smoke is also food
        itemInfo.isPoison = (itemFromInv as Food).isPoison()
        itemInfo.isFrozen = (itemFromInv as Food).isFrozen()
        const hunger = (itemFromInv as Food).getHungerChange()
        const meltingTime = (itemFromInv as Food).getMeltingTime()
        if (meltingTime > 0) {
            itemInfo.condition = math.abs(meltingTime / 100)
            itemInfo.color = { r: 0.0, g: 0, b: 0.5, a: 0.4 }
        } else if (hunger != 0) {
            itemInfo.condition = (-hunger) / 1.0
            itemInfo.color = { r: 0.678, g: 1, b: 0.384, a: 0.4 }
        }
    }
}

ISBzHotSlot.prerender = function () {
    if (this.background) {
        this.drawRectStatic(0, 0, this.width, this.height, this.backgroundColor.a, this.backgroundColor.r, this.backgroundColor.g, this.backgroundColor.b);
        this.drawRectBorderStatic(0, 0, this.width, this.height, this.borderColor.a, this.borderColor.r, this.borderColor.g, this.borderColor.b);
    }
    //this.drawTexture(this.poisonIcon, 0, 0, 1, 1, 1, 1)
    const itemInfo = this.itemInfo
    if (itemInfo.itemFullName == null || (itemInfo.itemFullName == "")) {
        if (this.removeButton != null) {
            this.removeButton.setVisible(false)
        }
        return
    }
    const player = getPlayer()
    if (player == null) {
        return
    }
    const playerInventory = player.getInventory()
    if (playerInventory == null) {
        return
    }
    if (playerInventory.isDrawDirty()) {
        this.updateItem()
    }
    let iconBoxSize = this.height;
    if (this.showDelete) {
        this.removeButton.setVisible(true)
        iconBoxSize = iconBoxSize - getSizeOfRemoveButton(this.deleteButString);
    }

    const imgSize = math.min(this.width, iconBoxSize);
    let alpha = 0.3;

    if (itemInfo.count >= 1) {
        alpha = 0.9;
    }

    if (itemInfo.condition > 0) {
        const sizeOfStatusRect = iconBoxSize * itemInfo.condition
        this.drawRect(0, iconBoxSize - sizeOfStatusRect, this.width, sizeOfStatusRect, itemInfo.color.a, itemInfo.color.r, itemInfo.color.g, itemInfo.color.b) //-- self.height - self.sizeOfRemoveButton-(imgSize*condition)
    }

    if (itemInfo.texture != null) {
        this.drawTextureScaled(itemInfo.texture, (this.width - imgSize) / 2, 0, imgSize, imgSize, alpha, 1, 1, 1);
        if (itemInfo.isPoison) {
            this.drawTexture(poisonIcon, 0, 0, 1, 1, 1, 1);
        } else if (itemInfo.isFrozen) {
            this.drawTexture(frozenItemIcon, 0, 0, 0, 1, 1, 1, 1);
        }
    } else {
        this.removeButton.setVisible(false);
        return
    }

    const text = "(" + itemInfo.count + ")";
    const y = this.showDelete && this.removeButton.y - (getTextManager().MeasureStringY(UIFont.Small, text) + 1) || this.getHeight() - (getTextManager().MeasureStringY(UIFont.Small, text) + 1)
    this.drawText(text, this.width - getTextManager().MeasureStringX(UIFont.Small, text), y, 1, 1, 1, 1, UIFont.Small);
}
/** @noSelf **/
function haveDamagePart(player: zombie.characters.IsoPlayer): zombie.characters.BodyDamage.BodyPart[] {
    // const result = new Array<zombie.characters.BodyDamage.BodyPart>();
    const result: zombie.characters.BodyDamage.BodyPart[] = [];
    const bodyParts = player.getBodyDamage().getBodyParts()
    for (let index = 0; index < bodyParts.size(); index++) {
        const bodyPart = (bodyParts.get(index) as zombie.characters.BodyDamage.BodyPart);
        // -- if it's damaged
        if ((bodyPart.HasInjury() || bodyPart.stitched()) && !bodyPart.bandaged()) {
            result.push(bodyPart)
        }
    }
    return result
}

/** @noSelf **/
declare function getPlayerHotbar(playerNumber: number): ISHotbar

/**
 * allthe work for activateing slot
 */
ISBzHotSlot.activeteSlot = function () {
    const itemInfo = this.itemInfo
    // if not item then nothing
    if (itemInfo.itemFullName == null || itemInfo.itemFullName == "") {
        return
    }

    const playerObject = getPlayer()
    // not working when sleeping
    if (playerObject.isAsleep()) {
        return
    }

    const playerNumber = playerObject.getPlayerNum()
    // search in inventory + backpack and container in inventory
    // local item = playerObj:getInventory():getFirstTypeRecurse(self.object.item);
    const playerInv = playerObject.getInventory()
    const itemInInv = playerInv.getFirstTypeEvalRecurse(itemInfo.itemFullName, predicateNotBroken)
    // no item do nothing
    if (itemInInv == null) {
        return
    }

    // container where item is located -- from ISWorldObjectContextMenu
    const returnToContainer = itemInInv.getContainer().isInCharacterInventory(playerObject) && itemInInv.getContainer()

    // https://projectzomboid.com/modding/zombie/inventory/InventoryItem.html
    // same like ISInventoryPane:doContextualDblClick(item)
    if (_instanceof_(itemInInv, "Food")) {
        const food = itemInInv as Food
        if (!food.isPoison() && !food.isFrozen()) {   // if not posion, and not frozen
            if (food.getHungChange() < 0) {
                // dp not eat  when full
                if (playerObject.getMoodles().getMoodleLevel(MoodleType.FoodEaten) >= 3 && playerObject.getNutrition().getCalories() >= 1000) {
                    return
                }
                ISInventoryPaneContextMenu.onEatItems([food], 0.5, playerNumber)
                if (returnToContainer != null && (returnToContainer != playerInv)) {
                    // return item to original container
                    ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, food, playerInv, returnToContainer, 0)) // time 0 = not specified
                }
            } else { // eat it whole
                const command = food.getCustomMenuOption() || getText("ContextMenu_Eat")
                if (command != getText("ContextMenu_Eat")) {
                    ISInventoryPaneContextMenu.onEatItems([food], 1, playerNumber)
                }
            }
        }
    } else if (_instanceof_(itemInInv, "DrainableComboItem")) {
        const comboItem = itemInInv as DrainableComboItem
        if (comboItem.isWaterSource() && (playerObject.getStats().getThirst() > 0.1) && !comboItem.isTaintedWater()) { //  water ISInventoryPaneContextMenu
            ISInventoryPaneContextMenu.onDrinkForThirst(comboItem, playerObject)
            if (returnToContainer != null && (returnToContainer != playerInv)) {
                // return item to original container
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, comboItem, playerInv, returnToContainer, 0)) // time 0 = not specified
            }
        } else if (ISInventoryPaneContextMenu.startWith(comboItem.getType(), "Pills")) { // -- pills like betablockers -- ISInventoryPaneContextMenu
            ISInventoryPaneContextMenu.onPutItems([comboItem], playerNumber)
            if (returnToContainer != null && (returnToContainer != playerInv)) {
                // return item to original container
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, comboItem, playerInv, returnToContainer, 0)) // time 0 = not specified
            }
        } else if (comboItem.getAlcoholPower() > 0 && (ISInventoryPaneContextMenu.startWith(comboItem.getType(), "Disinfectant") || ISInventoryPaneContextMenu.startWith(comboItem.getType(), "AlcoholWipes"))) {
            // if alcohol comboItem  we get all the damaged body part
            const bodyPartDamaged = haveDamagePart(playerObject)
            bodyPartDamaged.forEach((bodyPart) => {
                if (bodyPart.getAlcoholLevel() == 0) {
                    // if Disinfectant isn't in main inventory, put it there first.
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, comboItem)
                    // apply Disinfect
                    ISTimedActionQueue.add(new ISDisinfect(playerObject, playerObject, comboItem, bodyPart))
                }
            })
            if (returnToContainer != null && (returnToContainer != playerInv)) {
                // return item to original container
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, comboItem, playerInv, returnToContainer, 0)) // time 0 = not specified
            }
        } else if ((comboItem.getType() == "DishCloth" || itemInInv.getType() == "BathTowel") && playerObject.getBodyDamage().getWetness() > 0) {
            ISInventoryPaneContextMenu.onDryMyself([comboItem], playerNumber)
        } else if (comboItem.getType() == "Thread" && comboItem.getUsedDelta() > 0) {
            const itemNeedle = playerObject.getInventory().getFirstTypeRecurse("Needle")
            // no itemNeedle do nothing
            if (!itemNeedle) {
                return
            }
            const returnToContainerNeedle = itemNeedle.getContainer().isInCharacterInventory(playerObject) && itemNeedle.getContainer()
            const itemsSutureNeedleHolder = playerObject.getInventory().getFirstTypeRecurse("SutureNeedleHolder") // for pain reduction 
            // we get all the damaged body part
            const bodyPartDamaged = haveDamagePart(playerObject)
            bodyPartDamaged.forEach((bodyPart) => {
                if (!bodyPart.stitched() && bodyPart.isDeepWounded() && !bodyPart.haveGlass()) {
                    // if needle isn't in main inventory, put it there first.
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, comboItem);
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemNeedle);
                    if (itemsSutureNeedleHolder != null) {
                        ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemsSutureNeedleHolder);
                    }
                    ISTimedActionQueue.add(new ISStitch(playerObject, playerObject, comboItem, bodyPart, true))
                }
            })
            if (returnToContainer && (returnToContainer != playerInv)) {
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, comboItem, playerInv, returnToContainer, 0))
            }
            if (returnToContainerNeedle && (returnToContainerNeedle != playerInv)) {
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, itemNeedle, playerInv, returnToContainerNeedle, 0))
            }
            if (itemsSutureNeedleHolder != null) { //  return sature needle holder to original container
                const retCont = itemsSutureNeedleHolder.getContainer().isInCharacterInventory(playerObject) && itemsSutureNeedleHolder.getContainer()
                if (retCont && (retCont != playerInv)) {
                    ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, itemsSutureNeedleHolder, playerInv, retCont, 0))
                }
            }
        }
    } else if (_instanceof_(itemInInv, "HandWeapon") && itemInInv.getCondition() > 0) {
        const handWeaponItem = itemInInv as HandWeapon
        const itemsInHand = playerObject.getPrimaryHandItem()
        const gameHotbar = getPlayerHotbar(playerNumber);
        const fromHotBar = gameHotbar && gameHotbar.isItemAttached(itemsInHand)

        if (handWeaponItem.isTwoHandWeapon() && !playerObject.isItemInBothHands(handWeaponItem)) {
            ISInventoryPaneContextMenu.OnTwoHandsEquip([handWeaponItem], playerNumber)
            // TODO ADD config
            if (itemsInHand && !fromHotBar && returnToContainer && (returnToContainer != playerInv)) {
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, itemsInHand, playerInv, returnToContainer, 0))
            }
        } else {
            const rightHand = playerObject.getBodyDamage().getBodyPart(BodyPartType.Hand_R)
            if (!playerObject.isPrimaryHandItem(handWeaponItem) && !rightHand.isDeepWounded() && (rightHand.getFractureTime() == 0 || rightHand.getSplintFactor() > 0)) {
                // forbid reequipping skinned items to avoid multiple problems for now
                if (!(playerObject.getSecondaryHandItem() == handWeaponItem && handWeaponItem.getScriptItem().getReplaceWhenUnequip())) {
                    ISInventoryPaneContextMenu.OnPrimaryWeapon([handWeaponItem], playerNumber)
                    if (itemsInHand && !fromHotBar && returnToContainer && (returnToContainer != playerInv)) {
                        ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, itemsInHand, playerInv, returnToContainer, 0))
                    }
                }
            }
        }
    } else if (_instanceof_(itemInInv, "Radio") && (_instanceof_(itemInInv, "InventoryItem") && !_instanceof_(itemInInv, "HandWeapon"))) {
        const radioItem = itemInInv as Radio
        if (playerObject.isEquipped(radioItem)) {
            ISTimedActionQueue.add(new ISUnequipAction(playerObject, radioItem, 50))
            return
        }
        const rightHand = playerObject.getBodyDamage().getBodyPart(BodyPartType.Hand_R)
        if (!playerObject.isPrimaryHandItem(radioItem) && !rightHand.isDeepWounded() && (rightHand.getFractureTime() == 0 || rightHand.getSplintFactor() > 0)) {
            // forbid reequipping skinned items to avoid multiple problems for now
            if (!(playerObject.getSecondaryHandItem() == radioItem && radioItem.getScriptItem().getReplaceWhenUnequip())) {
                ISInventoryPaneContextMenu.OnPrimaryWeapon([radioItem], playerNumber)
            }
        }
    } else {
        if (itemInInv.isCanBandage()) {
            // we get all the damaged body part + not bandaged
            const bodyPartsDamaged = haveDamagePart(playerObject)
            let isDone = false
            bodyPartsDamaged.forEach(bodyPart => {
                if (bodyPart.isNeedBurnWash() && itemInInv.getBandagePower() >= 2) {
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                    ISTimedActionQueue.add(new ISCleanBurn(playerObject, playerObject, itemInInv, bodyPart))
                    isDone = true
                }
            });
            if (isDone) {
                return
            }

            const bodyPartDamaged = bodyPartsDamaged.pop() // appli bandage on firtst body part
            if (bodyPartDamaged) {
                ISInventoryPaneContextMenu.onApplyBandage([itemInInv], bodyPartDamaged, playerNumber)
            }
        } else if (itemInInv.getCategory() == "Clothing" && !playerObject.isEquipped(itemInInv)) {
            ISInventoryPaneContextMenu.onWearItems([itemInInv], playerNumber)
        } else if (itemInInv.getCategory() == "Literature" && !(itemInInv as Literature).canBeWrite() && !playerObject.getCharacterTraits().isIlliterate()) {
            ISInventoryPaneContextMenu.onLiteratureItems([itemInInv], playerNumber)
        } else if (itemInInv.getType() == "SutureNeedleHolder" || itemInInv.getType() == "Tweezers") {
            const bodyPartsDamaged = haveDamagePart(playerObject)
            bodyPartsDamaged.forEach(bodyPart => {
                if (bodyPart.haveGlass()) {
                    // if Tweezers or SutureNeedleHolder isn't in main inventory, put it there first.
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                    ISTimedActionQueue.add(new ISRemoveGlass(playerObject, playerObject, bodyPart, null)) // no hands
                } else if (bodyPart.haveBullet()) {
                    // if Tweezers or SutureNeedleHolder isn't in main inventory, put it there first.
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv)
                    ISTimedActionQueue.add(new ISRemoveBullet(playerObject, playerObject, bodyPart))
                }
            });
            if (returnToContainer && (returnToContainer != playerInv)) {
                ISTimedActionQueue.add(new ISInventoryTransferAction(playerObject, itemInInv, playerInv, returnToContainer, 0))
            }
        } else if (itemInInv.getType() == "SutureNeedle") {
            const bodyPartsDamaged = haveDamagePart(playerObject)
            for (let index = 0; index < bodyPartsDamaged.length; index++) {
                const bodyPart = bodyPartsDamaged[index];
                if (bodyPart.isDeepWounded() && !bodyPart.haveGlass()) {
                    // if SutureNeedle isn't in main inventory, put it there first.
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv);
                    ISTimedActionQueue.add(new ISStitch(playerObject, playerObject, itemInInv, bodyPart, true))
                    return
                }
            }
        } else if (itemInInv.getType() == "ComfreyCataplasm") {
            const bodyPartsDamaged = haveDamagePart(playerObject)
            for (let index = 0; index < bodyPartsDamaged.length; index++) {
                const bodyPart = bodyPartsDamaged[index];
                if (bodyPart.getFractureTime() > 0 && bodyPart.getComfreyFactor() == 0 && bodyPart.getGarlicFactor() == 0 && bodyPart.getPlantainFactor() == 0) {
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv);
                    ISTimedActionQueue.add(new ISComfreyCataplasm(playerObject, playerObject, itemInInv, bodyPart))
                    return
                }
            }
        } else if (itemInInv.getType() == "WildGarlicCataplasm") {
            const bodyPartsDamaged = haveDamagePart(playerObject)
            for (let index = 0; index < bodyPartsDamaged.length; index++) {
                const bodyPart = bodyPartsDamaged[index];
                if (bodyPart.isInfectedWound() && bodyPart.getComfreyFactor() == 0 && bodyPart.getComfreyFactor() == 0 && bodyPart.getPlantainFactor() == 0) {
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv);
                    ISTimedActionQueue.add(new ISGarlicCataplasm(playerObject, playerObject, itemInInv, bodyPart))
                    return
                }
            }
        } else if (itemInInv.getType() == "PlantainCataplasm") {
            const bodyPartsDamaged = haveDamagePart(playerObject)
            for (let index = 0; index < bodyPartsDamaged.length; index++) {
                const bodyPart = bodyPartsDamaged[index];
                if (bodyPart.scratched() || bodyPart.isDeepWounded() || bodyPart.isCut() && bodyPart.getComfreyFactor() == 0 && bodyPart.getComfreyFactor() == 0 && bodyPart.getPlantainFactor() == 0) {
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv);
                    ISTimedActionQueue.add(new ISPlantainCataplasm(playerObject, playerObject, itemInInv, bodyPart))
                    return
                }
            }
        } else if (itemInInv.getType() == "Splint") {
            const bodyPartsDamaged = haveDamagePart(playerObject)
            for (let index = 0; index < bodyPartsDamaged.length; index++) {
                const bodyPart = bodyPartsDamaged[index];
                if (bodyPart.getFractureTime() > 0 && bodyPart.getSplintFactor() == 0) {
                    ISInventoryPaneContextMenu.transferIfNeeded(playerObject, itemInInv);
                    ISTimedActionQueue.add(new ISSplint(playerObject, playerObject, null, itemInInv, bodyPart, true))
                    return
                }
            }
        }
    }
}