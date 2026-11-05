-- Plain Lua check of dragging a slot onto another one outside the game: lua tests/slot_drag_test.lua
package.path = "src/media/lua/client/?.lua;" .. package.path
-- the game's Kahlua lacks these; any use fails here like in the game
---@diagnostic disable-next-line: assign-type-mismatch
next, unpack, table.unpack = nil, nil, nil

local mouse = { x = 0, y = 0, down = false }
local clock = 0

-- stand-ins for the game's UI classes, just what a slot calls
local function uiClass()
    local class = {}
    class.__index = class
    function class:derive()
        local sub = setmetatable({}, self)
        sub.__index = sub
        return sub
    end
    function class:new(x, y, width, height)
        return setmetatable({ x = x, y = y, width = width, height = height }, self)
    end
    function class:getWidth() return self.width end
    function class:getHeight() return self.height end
    function class:setVisible() end
    function class:addChild(child) child.parent = self end
    function class:getParent() return self.parent end
    return class
end

local button = uiClass()
function button:new(x, y, width, height, title, target, onclick)
    local o = uiClass().new(self, x, y, width, height)
    o.target, o.onclick = target, onclick
    return o
end
-- like vanilla: only a press on the button and a release over it clicks it
function button:onMouseUp()
    if self.pressed then
        self.onclick(self.target, self)
    end
    self.pressed = false
end

-- set by name: a plain assignment would redefine these types for the type check of the whole mod
local globals = {
    ISPanel = uiClass(),
    ISButton = button,
    ISMouseDrag = {},
    ISInventoryPane = { getActualItems = function(items) return items end },
    ItemTag = {},
    UIFont = {},
    getTexture = function() return {} end,
    getTextManager = function() return { MeasureStringY = function() return 10 end } end,
    getPlayer = function() return nil end,
    getMouseX = function() return mouse.x end,
    getMouseY = function() return mouse.y end,
    isMouseButtonDown = function() return mouse.down end,
    getTimestampMs = function() return clock end,
}
for name, value in pairs(globals) do
    _G[name] = value
end
package.preload["pzhotbar/SlotIndicators"] = function() return {} end

local ISBzHotSlot = require("pzhotbar/ISUI/ISBzHotSlot")

local used
local onTop = {}
local function newSlot(items, num)
    local slot = ISBzHotSlot:new(0, 0, 50, 50, items, num, "X", true, false, false, 1)
    slot:createChildren()
    -- the bar: a slot only brings it to the top
    ---@diagnostic disable-next-line: missing-fields
    slot.parent = { bringToTop = function(bar) onTop[bar] = true end }
    slot.activeteSlot = function(self) used = self end
    return slot
end

local function press(slot, x, y)
    mouse.x, mouse.y, mouse.down = x, y, true
    slot:onMouseDown(0, 0)
end

-- every frame the bars render, which reads the drag
local function moveTo(x, y)
    clock = clock + 16
    mouse.x, mouse.y = x, y
    ISBzHotSlot.draggedSlot()
end

-- the game sends the release to what is under the mouse, then renders
local function release(target)
    mouse.down = false
    if target then
        target:onMouseUp(0, 0)
    end
    ISBzHotSlot.draggedSlot()
end

local function dragTo(source, target)
    press(source, 10, 10)
    moveTo(70, 10)
    release(target)
end

local items, a, b
local function twoSlots(content)
    items = content
    a, b = newSlot(items, 0), newSlot(items, 1)
end

-- dragging a slot onto a full one swaps them, the bar of the dragged slot goes to the top
twoSlots({ [0] = "Base.Axe", [1] = "Base.Apple" })
press(a, 10, 10)
assert(not onTop[a.parent], "a press alone brought the bar to the top")
moveTo(70, 10)
assert(onTop[a.parent], "bar of the dragged slot not on top")
release(b)
assert(items[0] == "Base.Apple" and items[1] == "Base.Axe", "slots not swapped")
assert(a.itemInfo.itemFullName == "Base.Apple" and b.itemInfo.itemFullName == "Base.Axe")
assert(used == nil, "a drag must not use a slot")

-- a click uses the slot, also with a small jitter of the mouse
twoSlots({ [0] = "Base.Axe", [1] = "Base.Apple" })
press(a, 10, 10)
release(a)
assert(used == a, "click did not use the slot")
used = nil
press(a, 10, 10)
moveTo(14, 6)
release(a)
assert(used == a, "a move up to the threshold is a click")
assert(items[0] == "Base.Axe" and items[1] == "Base.Apple")
assert(not onTop[a.parent], "a click brought the bar to the top")

-- a release over a slot uses it only when the press was on it too
used = nil
press(a, 48, 10)
moveTo(52, 10)
release(b)
assert(used == nil, "a slot pressed next to it was used")
mouse.down = true
release(b)
assert(used == nil, "a release after a press outside the slots used a slot")

-- dragging onto an empty slot moves the item there
twoSlots({ [0] = "Base.Axe" })
dragTo(a, b)
assert(items[0] == nil and items[1] == "Base.Axe", "item not moved to the empty slot")
assert(a.itemInfo.itemFullName == nil and b.itemInfo.itemFullName == "Base.Axe")

-- slots of two bars swap, each bar keeps its own table
local bar1, bar2 = { [0] = "Base.Axe" }, { [3] = "Base.Apple" }
dragTo(newSlot(bar1, 0), newSlot(bar2, 3))
assert(bar1[0] == "Base.Apple" and bar2[3] == "Base.Axe", "slots of two bars not swapped")

-- a release outside every slot cancels the drag, a later press elsewhere does not finish it
twoSlots({ [0] = "Base.Axe", [1] = "Base.Apple" })
press(a, 10, 10)
moveTo(300, 300)
release(nil)
assert(ISBzHotSlot.draggedSlot() == nil, "drag still on after a release outside the slots")
mouse.down = true
moveTo(70, 10)
release(b)
assert(items[0] == "Base.Axe" and items[1] == "Base.Apple", "release outside the slots changed them")
assert(used == nil)

-- hidden bars end a drag: nothing renders it, a release over a shown bar later does nothing
press(a, 10, 10)
moveTo(70, 10)
clock = clock + 1000
release(b)
assert(items[0] == "Base.Axe" and items[1] == "Base.Apple", "a drag survived hidden bars")
press(a, 10, 10)
clock = clock + 1000
release(a)
assert(used == nil, "a press survived hidden bars")

-- a drag back onto its own slot does nothing
press(a, 10, 10)
moveTo(300, 300)
moveTo(10, 10)
release(a)
assert(used == nil, "a drag back onto its slot used it")
assert(items[0] == "Base.Axe" and items[1] == "Base.Apple")

-- an empty slot does not drag
twoSlots({ [1] = "Base.Apple" })
dragTo(a, b)
assert(items[0] == nil and items[1] == "Base.Apple", "an empty slot was dragged")
assert(used == nil, "dragging an empty slot used the slot it was released over")

-- the delete button passes a drop over it to its slot (#57)
twoSlots({ [0] = "Base.Axe", [1] = "Base.Apple" })
dragTo(a, b.removeButton)
assert(items[0] == "Base.Apple" and items[1] == "Base.Axe", "slot dropped over the delete button not swapped")
local bandage = { getFullType = function() return "Base.Bandage" end, getTexture = function() return {} end }
ISMouseDrag.dragging = { bandage }
b.removeButton:onMouseUp(0, 0)
ISMouseDrag.dragging = nil
assert(items[1] == "Base.Bandage", "item dropped over the delete button not set")
-- a click on the button still deletes
b.removeButton.pressed = true
b.removeButton:onMouseUp(0, 0)
assert(items[1] == nil and b.itemInfo.itemFullName == nil, "delete button no longer deletes")

print("slot_drag_test ok")
