import { ISCollapsableWindow } from "@asledgehammer/pipewrench";
// PipeWrench Events API.
import * as ISBzHotBarWindowDer from "./ISBzHotBarWindowDer"
import { ISBzHotSlot, ISBzHotSlotClass } from "./ISBzHotSlot"

/** @customConstructor ISBzHotBarWindow:new */
export declare class ISBzHotBarWindowClass extends ISCollapsableWindow {
    constructor(x: number, y: number, width: number, height: number, slotSize: number, windowNum: number, rows: number, columns: number, itemTable: LuaTable<number, string>, deleteButText: string, showDelete: boolean, transferWeapons: boolean, showToolTip:boolean);
    new: (x: number, y: number, width: number, height: number, slotSize: number, windowNum: number, rows: number, columns: number, itemTable: LuaTable<number, string>, deleteButText: string, showDelete: boolean, transferWeapons: boolean, showToolTip:boolean) => ISBzHotBarWindowClass
    slots: LuaTable<number, ISBzHotSlotClass>
    windowNum: number
    rows: number
    columns: number
    itemTable: LuaTable<number, string>
    deleteButString: string
    showDelete: boolean
    transferWeapons: boolean
    showToolTip:boolean

    updateItems: () => any

}
export const ISBzHotBarWindow = ISBzHotBarWindowDer.ISBzHotBarWindow as ISBzHotBarWindowClass
ISBzHotBarWindow.new = function (x: number, y: number, width: number, height: number, slotSize: number, windowNum: number, rows: number, columns: number, itemTable: LuaTable<number, string>, deleteButText: string, showDelete: boolean, transferWeapons: boolean, showToolTip:boolean) :ISBzHotBarWindowClass {
    const o = (new ISCollapsableWindow(x, y, width, height) as ISBzHotBarWindowClass)
    setmetatable(o, this)
    this.__index = this
    o.backgroundColor = { r: 0, g: 0, b: 0, a: 1 };
    o.borderColor = { r: 0, g: 0, b: 0, a: 0.5 };
    o.setResizable(false);
    o.slotSize = slotSize;
    o.slots = new LuaTable<number, ISBzHotSlotClass>();
    o.itemTable = itemTable
    o.slotPad = 2
    o.margins = 1
    o.windowNum = windowNum
    o.rows = rows
    o.columns = columns
    o.deleteButString = deleteButText
    o.showDelete = showDelete
    o.setTitle(tostring(windowNum))
    o.transferWeapons = transferWeapons
    o.showToolTip = showToolTip

    return o
}

type WordAroundContext = (this:void, self:any) => void;
const oldCreateChildrenFnc = ISBzHotBarWindow.createChildren as WordAroundContext 

ISBzHotBarWindow.createChildren = function () {
    oldCreateChildrenFnc(this) 
    const tbw = this.titleBarHeight()
    const offx = this.slotSize
    let i = 0
    for (const y of $range(0, this.rows - 1)) {
        for (const x of $range(0, this.columns - 1)) {
            const slot = ISBzHotSlot.new(offx * x + this.slotPad, tbw + y * this.slotSize, offx - this.margins, this.slotSize - this.margins, this.itemTable, i, this.deleteButString, this.showDelete, this.transferWeapons,this.showToolTip);
            this.addChild(slot);
            this.slots.set(i, slot);
            i++;
        }
    }
}
ISBzHotBarWindow.updateItems = function () {
    for (const i of $range(0, (this.rows * this.columns) - 1)) {
        const slot = this.slots.get(i);
        if (slot != null) {
            slot.updateItem();
        }
    }
}
