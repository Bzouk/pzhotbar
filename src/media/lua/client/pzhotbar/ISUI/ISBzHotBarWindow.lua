local ISBzHotSlot = require("pzhotbar/ISUI/ISBzHotSlot")

---@class ISBzHotBarWindow: ISCollapsableWindow
---@field slotSize number
---@field slots table<integer, ISBzHotSlot>
---@field itemTable table<integer, string>
---@field slotPad number
---@field margins number
---@field windowNum integer
---@field rows integer
---@field columns integer
---@field deleteButString string
---@field showDelete boolean
---@field transferWeapons boolean
---@field showToolTip boolean
local ISBzHotBarWindow = ISCollapsableWindow:derive("ISBzHotBarWindow")

---@return ISBzHotBarWindow
function ISBzHotBarWindow:new(x, y, width, height, slotSize, windowNum, rows, columns, itemTable, deleteButText, showDelete, transferWeapons, showToolTip, opacity)
    local o = ISCollapsableWindow:new(x, y, width, height)
    ---@cast o ISBzHotBarWindow
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r = 0, g = 0, b = 0, a = opacity}
    o.borderColor = {r = 0, g = 0, b = 0, a = 0.5}
    o:setResizable(false)
    o.slotSize = slotSize
    o.slots = {}
    o.itemTable = itemTable
    o.slotPad = 2
    o.margins = 1
    o.windowNum = windowNum
    o.rows = rows
    o.columns = columns
    o.deleteButString = deleteButText
    o.showDelete = showDelete
    o:setTitle(tostring(windowNum))
    o.transferWeapons = transferWeapons
    o.showToolTip = showToolTip
    return o
end

function ISBzHotBarWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local tbw = self:titleBarHeight()
    local offx = self.slotSize
    local i = 0
    for y = 0, self.rows - 1 do
        for x = 0, self.columns - 1 do
            local slot = ISBzHotSlot:new(offx * x + self.slotPad, tbw + y * self.slotSize, offx - self.margins, self.slotSize - self.margins, self.itemTable, i, self.deleteButString, self.showDelete, self.transferWeapons, self.showToolTip, self.backgroundColor.a)
            self:addChild(slot)
            self.slots[i] = slot
            i = i + 1
        end
    end
end

function ISBzHotBarWindow:updateItems()
    for i = 0, self.rows * self.columns - 1 do
        local slot = self.slots[i]
        if slot ~= nil then
            slot:updateItem()
        end
    end
end

function ISBzHotBarWindow:activateSlot(pos)
    local slot = self.slots[pos]
    if slot ~= nil and pos < self.rows * self.columns then
        slot:activeteSlot()
    end
end

return ISBzHotBarWindow
