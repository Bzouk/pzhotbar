/**
 * @noSelfInFile
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *   
*/
import { Keyboard, getPlayer, getGameSpeed, getTextManager, UIFont, getText, MainScreen, getCore, getActivatedMods, ISBaseTimedAction } from "@asledgehammer/pipewrench";
import * as Events from "@asledgehammer/pipewrench-events";
import { ISBzHotBarWindow, ISBzHotBarWindowClass } from "./ISUI/ISBzHotBarWindow";
import { hookInto } from "PipeWrench-Utils";
import { ISTimedActionQueue } from "@asledgehammer/pipewrench";
// ============================
/** 
 * Helpers
*/
const isEmpty = (val: any) => val == null || !(Object.keys(val) || val).length;

function str_to_bool(tex: string): boolean {
    if (tex == null) {
        return false
    }
    return string.lower(tex) == 'true'
}

function getDeleteText(): string {
    if (ISBzHotBar.main.showDeleteButton == false) {
        return ""
    }
    if (ISBzHotBar.main.simpleDeleteButton) {
        return "X"
    }
    return getText("UI_Bz_Fast_HotBar_Slot_Remove")
}

function getHotBarSlotDimension(): number {
    return math.max(ISBzHotBar.main.slotsSize, getTextManager().MeasureStringX(UIFont.Small, getDeleteText()) + 10)
}

function getHotBarWidth(columns: number): number {
    return getHotBarSlotDimension() * columns + 3
}

function getHotBarWindowTitleBarHeight(): number {
    return math.max(16, FONT_UI_SMALL + 1)
}

function getHotBarHeight(rows: number): number {
    return getHotBarWindowTitleBarHeight() + 3 + getHotBarSlotDimension() * rows
}

// ============================
/** 
 * consts
*/
abstract class Constants {
    static readonly TABLE_BZHOTBAR = "bzHotBar";
    static readonly TABLE_CONFIG = "config";
    static readonly TABLE_ITEMS = "items";
    static readonly TABLE_WINDOWS = "windows";
    static readonly TABLE_MAIN = "main";
    static readonly TABLE_ARRAY_ITEMS = "items";
    static readonly TABLE_ARRAY_WINDOWS = "windows";
    static readonly TABLE_SLOT_ROWS = "rows";
    static readonly TABLE_SLOT_COLUMNS = "columns";
    static readonly TABLE_SLOT_ACTIVEWINDOWS = "activeWindows";
    static readonly TABLE_SLOT_SHOW = "show";
    static readonly TABLE_SLOT_TRANSFERWEAPONS = "transferWeapons";
    static readonly TABLE_SLOT_SIMPLEDELETEBUTTON = "simpleDeleteButton";
    static readonly TABLE_SLOT_SHOWDELETEBUTTON = "showDeleteButton";
    static readonly TABLE_SLOT_SHOWTOLLTIP = "showToolTip";
    static readonly TABLE_SLOT_SLOTSIZE = "slotsSize";
    static readonly TABLE_SLOT_SLOTSIZES = "slotsSizes";
}
const FONT_UI_SMALL = getTextManager().getFontHeight(UIFont.Small);
const ConfigFileName = "pzhotbar.ini"
const ConfigFileNameOld = "bzhotbar.ini"


/**
 * Main table for data
 */
declare class MainHolder extends LuaTable {
    activeWindows: number
    show: boolean
    transferWeapons: boolean
    simpleDeleteButton: boolean
    showDeleteButton: boolean
    showToolTip:boolean
    slotsSize: number
    slotsSizes: number[]
}

/**
 * Info about windows
 */
declare class WindowsHolder extends LuaTable {
    rows: number
    columns: number
    x: number
    y: number
}

/***
 * This class definition extends the LuaTable class and defines three properties: items, windows, and main.
items is a table that stores numbers as keys and tables of numbers and strings as values.
windows is a table that stores numbers as keys and WindowsHolder instances as values.
main is an instance of the MainHolder class.
 */
declare class DataHolder extends LuaTable {
    items: LuaTable<number, LuaTable<number, string>>
    windows: LuaTable<number, WindowsHolder>  //LuaTable<number,WindowsHolder> 
    main: MainHolder
}
/**
 * Map with actual windows.
 */
const windowssHolder = new Map<number, ISBzHotBarWindowClass>();

/**
 * Table with data
 */
const ISBzHotBar = new DataHolder();

ISBzHotBar.items = new LuaTable<number, LuaTable<number, string>>();
ISBzHotBar.windows = new LuaTable<number, WindowsHolder>();

for (let index = 1; index < 6; index++) {
    ISBzHotBar.items.set(index, new LuaTable<number, string>())
    if (index == 1) {
        const windTable = new WindowsHolder();
        windTable.rows = 1;
        windTable.columns = 8;
        ISBzHotBar.windows.set(index, windTable)
    } else {
        const windTable = new WindowsHolder();
        windTable.rows = 1;
        windTable.columns = 1;
        ISBzHotBar.windows.set(index, windTable)
    }
}
ISBzHotBar.main = new MainHolder();
ISBzHotBar.main.activeWindows = 1
ISBzHotBar.main.show = true;
ISBzHotBar.main.transferWeapons = true;
ISBzHotBar.main.simpleDeleteButton = true;
ISBzHotBar.main.showDeleteButton = true;
ISBzHotBar.main.showToolTip = true;
ISBzHotBar.main.slotsSize = 60;
ISBzHotBar.main.slotsSizes = [60, 65, 70, 75, 80, 85, 90, 55, 50, 45, 40] // "60 default", "65", "70", "75", "80 1x fonts", "85", "90 2x fonts", "55", "50", "45"
// ============================
// ============================

/**
 * Saves the configuration by writing it to the INI file.
 *
 * @return {void} No return value.
 */
function saveConfig() {
    bcUtils.writeINI(ConfigFileName, ISBzHotBar);
}

/**
 * Loads the configuration new or old.
 *
 * @return {void} This function does not return a value.
 */
function loadConfig() {
    const ini = bcUtils.readINI(ConfigFileName);
    if (!bcUtils.tableIsEmpty(ini)) {
        updateFromTable(ini);
        return
    } 
    const iniOld = bcUtils.readINI(ConfigFileNameOld);
    if (!bcUtils.tableIsEmpty(iniOld)) {
        updateFromTable(iniOld);
        return
    } 
}
/**
 * Loads the configuration from the specified file and initializes the necessary tables.
 *
 * @return {void} This function does not return a value.
 */
function updateFromTable(ini:LuaTable) {
    if (!ini.has(Constants.TABLE_MAIN)) {
        ini.set(Constants.TABLE_MAIN, new LuaTable());
    }
    const iniMainTable = (ini.get(Constants.TABLE_MAIN) as LuaTable);

    ISBzHotBar.main.set(Constants.TABLE_SLOT_ACTIVEWINDOWS, tonumber(iniMainTable.get(Constants.TABLE_SLOT_ACTIVEWINDOWS)));
    ISBzHotBar.main.set(Constants.TABLE_SLOT_TRANSFERWEAPONS, str_to_bool(iniMainTable.get(Constants.TABLE_SLOT_TRANSFERWEAPONS)));
    ISBzHotBar.main.set(Constants.TABLE_SLOT_SLOTSIZE, tonumber(iniMainTable.get(Constants.TABLE_SLOT_SLOTSIZE)));
    ISBzHotBar.main.set(Constants.TABLE_SLOT_SIMPLEDELETEBUTTON, str_to_bool(iniMainTable.get(Constants.TABLE_SLOT_SIMPLEDELETEBUTTON)));
    ISBzHotBar.main.set(Constants.TABLE_SLOT_SHOWTOLLTIP, str_to_bool(iniMainTable.get(Constants.TABLE_SLOT_SHOWTOLLTIP)));
    
    
    if (!ini.has(Constants.TABLE_ARRAY_ITEMS)) {
        ini.set(Constants.TABLE_ARRAY_ITEMS, []);
    }
    if (!ini.has(Constants.TABLE_ARRAY_WINDOWS)) {
        ini.set(Constants.TABLE_ARRAY_WINDOWS, {});
    }
    const iniItems = ini.get(Constants.TABLE_ARRAY_ITEMS) as LuaTable;
    const iniwindowsTable = (ini.get(Constants.TABLE_ARRAY_WINDOWS) as LuaTable);
    for (const i of $range(1, ISBzHotBar.main.get(Constants.TABLE_SLOT_ACTIVEWINDOWS))) {
        const iStr = tostring(i)

        if (!(iniItems.get(iStr))) {
            iniItems.set(iStr, new LuaTable());
        }

        for (const [key, value] of (iniItems.get(iStr) as LuaTable)) {
            const kk = tonumber(key);
            if (kk) {
                ISBzHotBar.items.get(i).set(kk, value);
            }
        }

        if (!(iniwindowsTable.get(iStr))) {
            iniwindowsTable.set(iStr, new LuaTable());
        }
        (ISBzHotBar.windows.get(i) as LuaTable).set(Constants.TABLE_SLOT_ROWS, tonumber((iniwindowsTable.get(iStr) as LuaTable).get(Constants.TABLE_SLOT_ROWS)));
        (ISBzHotBar.windows.get(i) as LuaTable).set(Constants.TABLE_SLOT_COLUMNS, tonumber((iniwindowsTable.get(iStr) as LuaTable).get(Constants.TABLE_SLOT_COLUMNS)));

        if ((iniwindowsTable.get(iStr) as LuaTable).get("x") && (iniwindowsTable.get(iStr) as LuaTable).get("y")) {
            (ISBzHotBar.windows.get(i) as LuaTable).set("x", tonumber((iniwindowsTable.get(iStr) as LuaTable).get("x")));
            (ISBzHotBar.windows.get(i) as LuaTable).set("y", tonumber((iniwindowsTable.get(iStr) as LuaTable).get("y")));
        }
    }
}
/**
 * Set windows position for data table
 */
function setWindosPos() {
    for (const windowNum of $range(1, ISBzHotBar.main.activeWindows)) {
        if (windowssHolder.has(windowNum)) {
            const window = windowssHolder.get(windowNum);
            if (window != null) {
                const windowTable = ISBzHotBar.windows.get(windowNum)
                windowTable.set("x", window.getX());
                windowTable.set("y", window.getY());
            }
        }
    }
}

function createWindows() {
    // if not in game do no show
    if (!MainScreen.instance.inGame) {
        return
    }
    if (ISBzHotBar.main.show) {
        for (const windowNum of $range(1, ISBzHotBar.main.activeWindows)) {
            const x = ISBzHotBar.windows.get(windowNum).x || (getCore().getScreenWidth() / 2 - 240);
            const y = ISBzHotBar.windows.get(windowNum).y || (getCore().getScreenHeight() - getHotBarHeight(ISBzHotBar.windows.get(windowNum).columns) - 240);
            const columns = ISBzHotBar.windows.get(windowNum).columns
            const rows = ISBzHotBar.windows.get(windowNum).rows
            const width = getHotBarWidth(columns)
            const height = getHotBarHeight(rows)
            const table = ISBzHotBar.items.get(windowNum)
            const showDeleteButton = ISBzHotBar.main.showDeleteButton
            const showToolTip  = ISBzHotBar.main.showToolTip
            const window = ISBzHotBarWindow.new(x, y, width, height, getHotBarSlotDimension(), windowNum, rows, columns, table, getDeleteText(), showDeleteButton,ISBzHotBar.main.transferWeapons,ISBzHotBar.main.showToolTip)
            window.setVisible(ISBzHotBar.main.show);
            window.addToUIManager();
            // window.backMost(); // TODO differrent aproch
            windowssHolder.set(windowNum, window);
        }
    }
}

/**
 * Reloads all windows.
 */
function reloadWindows() {
    windowssHolder.forEach((window) => {
        window.setVisible(false);
        window.removeFromUIManager();
    })
    windowssHolder.clear();
    createWindows();
}
/**
 * Hid or show windows.
 */
function toggleWindows() {
    const showWindows = !ISBzHotBar.main.show
    windowssHolder.forEach((window) => {
        window.setVisible(showWindows);
    })
    ISBzHotBar.main.show = showWindows
}

/**
 * Updates all slots by iterating through the windowsHolder array and calling the updateItems method on all visible windows.
 */
function updateAllSlots() {
    // update all items
    windowssHolder.forEach((window) => {
        if (window.getIsVisible) {
            window.updateItems()
        }
    })
}

/**
 * On key press toggle windows.
 */
Events.onKeyPressed.addListener((key) => {
    if (( key == getCore().getKey("Bz_Toggle_Hotbar")) && getPlayer() && getGameSpeed() > 0) {
        toggleWindows();
        updateAllSlots()
    }
});

Events.onResolutionChange.addListener(() => {
    if (MainScreen.instance.inGame) {
        return
    }
    for (const windowNum of $range(1, ISBzHotBar.main.activeWindows)) {
        ISBzHotBar.windows.get(windowNum).x = 0
        ISBzHotBar.windows.get(windowNum).x = 0
    }
    reloadWindows()
})

Events.onSave.addListener(() => {
    setWindosPos();
    saveConfig();
})

Events.onGameStart.addListener(() => {
    loadConfig();
    createWindows();
})

Events.onRefreshInventoryWindowContainers.addListener((iSInventoryPage: any, state: string) => {
    if (iSInventoryPage.onCharacter && state == "end") {
        // update all items
        updateAllSlots()
    }
})
// Called when an object with a container is added/removed from the world.
// Added this to handle campfire containers.
Events.onContainerUpdate.addListener((container: any) => {
    updateAllSlots()
})

/**
 * Hook into ISTimedActionQueue for upadting items in slots.
 */
hookInto("ISTimedActionQueue:onCompleted", (_onCompleted: Function, self: ISTimedActionQueue, action: ISBaseTimedAction) => {
    updateAllSlots()
    return _onCompleted.call(self, action)
})

//=======================================================//=======================================================//=======================================================
//=======================================================//=======================================================//=======================================================
//=======================================================//=======================================================//=======================================================
/**
 * Only with ModOptions mod
 */
declare class ModOptionsData extends LuaTable {
    name: string
    tooltip: string
    default: number | boolean
    OnApplyInGame: any
    OnApplyMainMenu: any
}

declare class ModOptionsDataHolder extends LuaTable {
    activeWindows: ModOptionsData
    dropdown1X: ModOptionsData
    dropdown1y: ModOptionsData
    dropdown2X: ModOptionsData
    dropdown2y: ModOptionsData
    dropdown3X: ModOptionsData
    dropdown3y: ModOptionsData
    dropdown4X: ModOptionsData
    dropdown4y: ModOptionsData
    dropdown5X: ModOptionsData
    dropdown5y: ModOptionsData
    moveweapons: ModOptionsData
    simpledelete: ModOptionsData
    dropdownslotsize: ModOptionsData
    showdeletebutton: ModOptionsData
    showtooltip:ModOptionsData
}
declare class Options extends LuaTable {
    activeWindows: number
    dropdown1X: number
    dropdown1y: number
    dropdown2X: number
    dropdown2y: number
    dropdown3X: number
    dropdown3y: number
    dropdown4X: number
    dropdown4y: number
    dropdown5X: number
    dropdown5y: number
    moveweapons: boolean
    simpledelete: boolean
    dropdownslotsize: number
    showdeletebutton: boolean
    showtooltip: boolean
}
declare class ModOptionsValue extends LuaTable {
    settings: ModOptionsSettings
}

/**
 * Global lua table 
 */
declare var keyBinding: []
declare class ModOptionsSettings extends LuaTable {
    options_data: ModOptionsDataHolder
    options: Options
    mod_id: string
    mod_shortname: string
    mod_fullname: string
}


if (getActivatedMods().contains("modoptions")) {
    if (ModOptions != null) {
        /** @noSelf **/
        function OnApplyMainMenu(value: ModOptionsValue) {
            ISBzHotBar.main.activeWindows = value.settings.options.activeWindows;
            ISBzHotBar.windows.get(1).rows = value.settings.options.dropdown1X;
            ISBzHotBar.windows.get(1).columns = value.settings.options.dropdown1y;
            ISBzHotBar.windows.get(2).rows = value.settings.options.dropdown2X;
            ISBzHotBar.windows.get(2).columns = value.settings.options.dropdown2y;
            ISBzHotBar.windows.get(3).rows = value.settings.options.dropdown3X;
            ISBzHotBar.windows.get(3).columns = value.settings.options.dropdown3y;
            ISBzHotBar.windows.get(4).rows = value.settings.options.dropdown4X;
            ISBzHotBar.windows.get(4).columns = value.settings.options.dropdown4y;
            ISBzHotBar.windows.get(5).rows = value.settings.options.dropdown5X;
            ISBzHotBar.windows.get(5).columns = value.settings.options.dropdown5y;
            ISBzHotBar.main.transferWeapons = value.settings.options.moveweapons;
            ISBzHotBar.main.slotsSize = ISBzHotBar.main.slotsSizes[value.settings.options.dropdownslotsize];
            ISBzHotBar.main.simpleDeleteButton = value.settings.options.simpledelete;
            ISBzHotBar.main.showDeleteButton = value.settings.options.showdeletebutton
            ISBzHotBar.main.showToolTip = value.settings.options.showtooltip
            saveConfig();
        }
        /** @noSelf **/
        function OnApplyInGame(value: ModOptionsValue) {
            setWindosPos();
            OnApplyMainMenu(value)
            reloadWindows();
        }

        /** @noSelf **/
        function createModOptionData(choices: string[], name: string, tooltip: string, def: number | boolean, onApplyInGame: any, onApplyMainMenu: any): ModOptionsData {
            const data = new ModOptionsData()
            for (const [k, v] of pairs(choices)) {
                data.set(k, v)
            }
            data.name = name
            data.tooltip = tooltip
            data.default = def
            data.OnApplyInGame = onApplyInGame
            data.OnApplyMainMenu = onApplyMainMenu
            return data
        }
        /** @noSelf **/
        function createSetttings(): ModOptionsSettings {
            const optionsData = new ModOptionsDataHolder()
            optionsData.activeWindows = createModOptionData(["1", "2", "3", "4", "5"], "IGUI_Bz_Fast_HotBar_MaxTables_Name", "IGUI_Bz_Fast_HotBar_MaxTables_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown1X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "1", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown1y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "1", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 8, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown2X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "2", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown2y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "2", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown3X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "3", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown3y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "3", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown4X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "4", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown4y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "4", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown5X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "5", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdown5y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "5", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.moveweapons = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Move_Weapons_Name"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Move_Weapons", true, OnApplyInGame, OnApplyMainMenu)
            optionsData.simpledelete = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Simple_Delete"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Simple_Delete", false, OnApplyInGame, OnApplyMainMenu)
            optionsData.showdeletebutton = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_Delete"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Show_Delete", true, OnApplyInGame, OnApplyMainMenu)
            optionsData.dropdownslotsize = createModOptionData(["60 default", "65", "70", "75", "80 1x fonts", "85", "90 2x fonts", "55", "50", "45"], getText("IGUI_Bz_Fast_HotBar_SlotSize_Name"), "IGUI_Bz_Fast_HotBar_SlotSize_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
            optionsData.showtooltip = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_ToolTip"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Show_ToolTip", true, OnApplyInGame, OnApplyMainMenu)

            const settings = new ModOptionsSettings()
            settings.options_data = optionsData
            settings.mod_id = "pzhotbar"
            settings.mod_shortname = "Fast Hotbar mod v2"
            settings.mod_fullname = "Bzouk Fast Hotbar mod v2"
            return settings
        }
        const SETTINGS = createSetttings()
        ModOptions.AddKeyBinding("[Bz_Toggle_Hotbar]", { key: Keyboard.KEY_TAB, name: "Bz_Toggle_Hotbar" });
        ModOptions.getInstance(SETTINGS)
        ModOptions.loadFile()
        loadConfig()
        ISBzHotBar.main.activeWindows = SETTINGS.options.activeWindows;
        ISBzHotBar.windows.get(1).rows = SETTINGS.options.dropdown1X;
        ISBzHotBar.windows.get(1).columns = SETTINGS.options.dropdown1y;
        ISBzHotBar.windows.get(2).rows = SETTINGS.options.dropdown2X;
        ISBzHotBar.windows.get(2).columns = SETTINGS.options.dropdown2y;
        ISBzHotBar.windows.get(3).rows = SETTINGS.options.dropdown3X;
        ISBzHotBar.windows.get(3).columns = SETTINGS.options.dropdown3y;
        ISBzHotBar.windows.get(4).rows = SETTINGS.options.dropdown4X;
        ISBzHotBar.windows.get(4).columns = SETTINGS.options.dropdown4y;
        ISBzHotBar.windows.get(5).rows = SETTINGS.options.dropdown5X;
        ISBzHotBar.windows.get(5).columns = SETTINGS.options.dropdown5y;
        ISBzHotBar.main.transferWeapons = SETTINGS.options.moveweapons;
        ISBzHotBar.main.slotsSize = ISBzHotBar.main.slotsSizes[SETTINGS.options.dropdownslotsize];
        ISBzHotBar.main.simpleDeleteButton = SETTINGS.options.simpledelete;
        ISBzHotBar.main.showDeleteButton = SETTINGS.options.showdeletebutton
        ISBzHotBar.main.showToolTip = SETTINGS.options.showtooltip
        saveConfig()
    }
} else {
    table.insert(keyBinding, { key: Keyboard.KEY_TAB, value: "Bz_Toggle_Hotbar" })
}