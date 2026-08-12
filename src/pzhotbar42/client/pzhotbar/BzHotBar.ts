/**
 * @noSelfInFile
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *   
*/
import { Keyboard, getPlayer, getGameSpeed, getTextManager, UIFont, getText, MainScreen, getCore, getActivatedMods, ISBaseTimedAction, ISInventoryPane } from "@asledgehammer/pipewrench";
import * as Events from "@asledgehammer/pipewrench-events";
import { ISBzHotBarWindow, ISBzHotBarWindowClass } from "./ISUI/ISBzHotBarWindow";
// import { hookInto } from "PipeWrench-Utils";
// import { ISTimedActionQueue } from "@asledgehammer/pipewrench";
import { readINI, writeINI, tableIsEmpty} from  "./bcUtils";
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
let ConfigVersion = ""
const ConfigFileName = "pzhotbar"
const ConfigFileNameOld = "bzhotbar"
const ConfigSuffix = ".ini"

/**
 * Main table for data
 */
declare class MainHolder extends LuaTable {
    activeWindows: number
    show: boolean
    transferWeapons: boolean
    simpleDeleteButton: boolean
    showDeleteButton: boolean
    showToolTip: boolean
    slotsSize: number
    opacity: number
    hideCar: boolean
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
        windTable.rows = 2;
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
ISBzHotBar.main.slotsSize = 65;
ISBzHotBar.main.opacity = 1;
ISBzHotBar.main.hideCar = false
ISBzHotBar.main.slotsSizes = [60, 65, 70, 75, 80, 85, 90, 55, 50, 45, 40] // "60 default", "65", "70", "75", "80 1x fonts", "85", "90 2x fonts", "55", "50", "45"
// ============================
// ============================

/**
 * Saves the configuration by writing it to the INI file.
 *
 * @return {string} File config name.
 */
function getConfigFileName() {
    return ConfigFileName + ConfigVersion + ConfigSuffix
}
/**
 * Saves the configuration by writing it to the INI file.
 *
 * @return {string} File config name.
 */
function getConfigOldFileName() {
    return ConfigFileNameOld + ConfigVersion + ConfigSuffix
}

/**
 * Saves the configuration by writing it to the INI file.
 *
 * @return {void} No return value.
 */
function saveConfig() {
    writeINI(getConfigFileName(), ISBzHotBar);
}

/**
 * Loads the configuration new or old.
 *
 * @return {void} This function does not return a value.
 */
function loadConfig() {
    const ini = readINI(getConfigFileName());
    if (!tableIsEmpty(ini)) {
        updateFromTable(ini);
        return
    }
    const iniOld = readINI(getConfigOldFileName());
    if (!tableIsEmpty(iniOld)) {
        updateFromTable(iniOld);
        return
    }
}
/**
 * Loads the configuration from the specified file and initializes the necessary tables.
 *
 * @return {void} This function does not return a value.
 */
function updateFromTable(ini: LuaTable) {
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
            const opacity = ISBzHotBar.main.opacity
            const window = ISBzHotBarWindow.new(x, y, width, height, getHotBarSlotDimension(), windowNum, rows, columns, table, getDeleteText(), showDeleteButton, ISBzHotBar.main.transferWeapons, ISBzHotBar.main.showToolTip,opacity)
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
    showWindows(!ISBzHotBar.main.show)
}

function showWindows(showWin:boolean){
    windowssHolder.forEach((window) => {
        window.setVisible(showWin);
    })
    ISBzHotBar.main.show = showWin
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

function checkWindowsBounds() {
    for (const windowNum of $range(1, ISBzHotBar.main.activeWindows)) {
        const window = ISBzHotBar.windows.get(windowNum);

        if (window.x != null ) {
            if (window.x + getHotBarWidth(window.columns) > getCore().getScreenWidth()) {
                window.x = math.max(getCore().getScreenWidth() - getHotBarWidth(window.columns), 0);
                windowssHolder.get(windowNum)?.setX(window.x);
            }
        }
        if (window.y != null ) {
            if (window.y + getHotBarHeight(window.rows) > getCore().getScreenHeight()) {
                window.y = math.max(getCore().getScreenHeight() - getHotBarHeight(window.rows), 0);
                windowssHolder.get(windowNum)?.setY(window.y);
            }
        }
    }
}


/**
 * Mod options
 * https://pzwiki.net/wiki/Mod_Options
 */
/**
 * Main table for data
 */
declare class QuickSlotsConfigs extends LuaTable {
    keybind: GameModOptionsKeyBind
    activeWindows: Slider
    dropdown1x: Slider  
    dropdown1y: Slider
    dropdown2x: Slider
    dropdown2y: Slider
    dropdown3x: Slider
    dropdown3y: Slider
    dropdown4x: Slider
    dropdown4y: Slider
    dropdown5x: Slider
    dropdown5y: Slider
    moveweapons: TickBox
    simpledelete: TickBox
    showdeletebutton: TickBox
    dropdownslotsize: Slider
    showtooltip: TickBox
    configVersion: ComboBox
    opacitySettings: Slider
    hideCar: TickBox
    keybindSlot0: GameModOptionsKeyBind
    keybindSlot1: GameModOptionsKeyBind
    keybindSlot2: GameModOptionsKeyBind
    keybindSlot3: GameModOptionsKeyBind
    keybindSlot4: GameModOptionsKeyBind
    keybindSlot5: GameModOptionsKeyBind
    keybindSlot6: GameModOptionsKeyBind
    keybindSlot7: GameModOptionsKeyBind
    keybindSlot8: GameModOptionsKeyBind

}
const Configs = new QuickSlotsConfigs();

function IngameConfigSetup() {
    const options = PZAPI.ModOptions.create("pzhotbar42", " Quick slots mod")

    options.addTitle("Bz Quick slot mod")
    Configs.keybind = options.addKeyBind("pzhotbar42keybind", getText("Quick slots keybind"), Keyboard.KEY_TAB)
    Configs.activeWindows = options.addSlider("tabscount", getText("IGUI_Bz_Fast_HotBar_MaxTables_Name") + "1", 1, 5, 1, 1, "IGUI_Bz_Fast_HotBar_MaxTables_Tooltip")
    Configs.dropdown1x = options.addSlider("1x", getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "1", 1, 10, 1, 2, "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip")
    Configs.dropdown1y = options.addSlider("1y", getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "1", 1, 10, 1, 8, "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip")
    Configs.dropdown2x = options.addSlider("2x", getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "2", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip")
    Configs.dropdown2y = options.addSlider("2y", getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "2", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip")
    Configs.dropdown3x = options.addSlider("3x", getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "3", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip")
    Configs.dropdown3y = options.addSlider("3y", getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "3", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip")
    Configs.dropdown4x = options.addSlider("4x", getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "4", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip")
    Configs.dropdown4y = options.addSlider("4y", getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "4", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip")
    Configs.dropdown5x = options.addSlider("5x", getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "5", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip")
    Configs.dropdown5y = options.addSlider("5y", getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "5", 1, 10, 1, 1, "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip")

    //         optionsData.moveweapons = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Move_Weapons_Name"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Move_Weapons", true, OnApplyInGame, OnApplyMainMenu)
    Configs.moveweapons = options.addTickBox("moveweapons", getText("IGUI_Bz_Fast_HotBar_CheckBox_Move_Weapons_Name"), true)
    //         optionsData.simpledelete = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Simple_Delete"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Simple_Delete", false, OnApplyInGame, OnApplyMainMenu)
    Configs.simpledelete = options.addTickBox("simpledelete", getText("IGUI_Bz_Fast_HotBar_CheckBox_Simple_Delete"), false)
    //         optionsData.showdeletebutton = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_Delete"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Show_Delete", true, OnApplyInGame, OnApplyMainMenu)
    Configs.showdeletebutton = options.addTickBox("showdeletebutton", getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_Delete"), true)
    //         optionsData.dropdownslotsize = createModOptionData(["60 default", "65", "70", "75", "80 1x fonts", "85", "90 2x fonts", "55", "50", "45"], getText("IGUI_Bz_Fast_HotBar_SlotSize_Name"), "IGUI_Bz_Fast_HotBar_SlotSize_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    Configs.dropdownslotsize = options.addSlider("dropdownslotsize", getText("IGUI_Bz_Fast_HotBar_SlotSize_Name"), 45, 90, 5, 65, "IGUI_Bz_Fast_HotBar_SlotSize_Tooltip")
    //         optionsData.showtooltip = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_ToolTip"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Show_ToolTip", true, OnApplyInGame, OnApplyMainMenu)
    Configs.showtooltip = options.addTickBox("showtooltip", getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_ToolTip"), true)

    Configs.opacitySettings = options.addSlider("opacity", getText("IGUI_Bz_Fast_HotBar_DropdownOpacity_Name"), 0, 1, 0.1, 1, "IGUI_Bz_Fast_HotBar_DropdownOpacity_Tooltip")

    Configs.hideCar = options.addTickBox("hidecar", getText("IGUI_Bz_Fast_HotBar_HideCar_Name"), false)
    options.addSeparator()
    options.addDescription("Windows 1 keybinds")
    Configs.keybindSlot0 = options.addKeyBind("pzhotbar42keybindpos0", getText("Keybind slot 1."), Keyboard.KEY_NONE)
    Configs.keybindSlot1 = options.addKeyBind("pzhotbar42keybindpos1", getText("Keybind slot 2."), Keyboard.KEY_NONE)
    Configs.keybindSlot2 = options.addKeyBind("pzhotbar42keybindpos2", getText("Keybind slot 3."), Keyboard.KEY_NONE)
    Configs.keybindSlot3 = options.addKeyBind("pzhotbar42keybindpos3", getText("Keybind slot 4."), Keyboard.KEY_NONE)
    Configs.keybindSlot4 = options.addKeyBind("pzhotbar42keybindpos4", getText("Keybind slot 5."), Keyboard.KEY_NONE)
    Configs.keybindSlot5 = options.addKeyBind("pzhotbar42keybindpos5", getText("Keybind slot 6."), Keyboard.KEY_NONE)
    Configs.keybindSlot6 = options.addKeyBind("pzhotbar42keybindpos6", getText("Keybind slot 7."), Keyboard.KEY_NONE)
    Configs.keybindSlot7 = options.addKeyBind("pzhotbar42keybindpos7", getText("Keybind slot 8."), Keyboard.KEY_NONE)
    Configs.keybindSlot8 = options.addKeyBind("pzhotbar42keybindpos8", getText("Keybind slot 9."), Keyboard.KEY_NONE)

/*
    Configs.configVersion = options.addComboBox("configVersion", getText("IGUI_Bz_Fast_HotBar_CheckBox_Config_Version"))
    Configs.configVersion.addItem("default", true)
    Configs.configVersion.addItem("2", false)
    Configs.configVersion.addItem("3", false)
    Configs.configVersion.addItem("4", false)
    Configs.configVersion.addItem("5", false)
*/
    options.apply = function () {
        /*
        saveConfig();
        const confVer = Configs.configVersion.getValue()
        const oldConsfVer = ConfigVersion

        if (confVer == 0) {
            ConfigVersion = ""
        } else if (confVer == 2) {
            ConfigVersion = "2"
        } else if (confVer == 3) {
            ConfigVersion = "3"
        } else if (confVer == 4) {
            ConfigVersion = "4"
        } else if (confVer == 5) {
            ConfigVersion = "5"
        }
        if (oldConsfVer != ConfigVersion) {
            loadConfig();
            Configs.activeWindows.setValue(ISBzHotBar.main.activeWindows)
            Configs.dropdown1x.setValue(ISBzHotBar.windows.get(1).rows)
            Configs.dropdown1y.setValue(ISBzHotBar.windows.get(1).columns)
            Configs.dropdown2x.setValue(ISBzHotBar.windows.get(2).rows)
            Configs.dropdown2y.setValue(ISBzHotBar.windows.get(2).columns)
            Configs.dropdown3x.setValue(ISBzHotBar.windows.get(3).rows)
            Configs.dropdown3y.setValue(ISBzHotBar.windows.get(3).columns)
            Configs.dropdown4x.setValue(ISBzHotBar.windows.get(4).rows)
            Configs.dropdown4y.setValue(ISBzHotBar.windows.get(4).columns)
            Configs.dropdown5x.setValue(ISBzHotBar.windows.get(5).rows)
            Configs.dropdown5y.setValue(ISBzHotBar.windows.get(5).columns)
            Configs.moveweapons.setValue(ISBzHotBar.main.transferWeapons);
            Configs.dropdownslotsize.setValue(ISBzHotBar.main.slotsSize);
            Configs.simpledelete.setValue(ISBzHotBar.main.simpleDeleteButton);
            Configs.showdeletebutton.setValue(ISBzHotBar.main.showDeleteButton);
            Configs.showtooltip.setValue(ISBzHotBar.main.showToolTip);
        }
*/
        if (!MainScreen.instance.inGame) {
            loadConfig();
            ISBzHotBar.main.activeWindows = Configs.activeWindows.getValue()
            ISBzHotBar.windows.get(1).rows = Configs.dropdown1x.getValue()
            ISBzHotBar.windows.get(1).columns = Configs.dropdown1y.getValue()
            ISBzHotBar.windows.get(2).rows = Configs.dropdown2x.getValue()
            ISBzHotBar.windows.get(2).columns = Configs.dropdown2y.getValue()
            ISBzHotBar.windows.get(3).rows = Configs.dropdown3x.getValue()
            ISBzHotBar.windows.get(3).columns = Configs.dropdown3y.getValue()
            ISBzHotBar.windows.get(4).rows = Configs.dropdown4x.getValue()
            ISBzHotBar.windows.get(4).columns = Configs.dropdown4y.getValue()
            ISBzHotBar.windows.get(5).rows = Configs.dropdown5x.getValue()
            ISBzHotBar.windows.get(5).columns = Configs.dropdown5y.getValue()
            ISBzHotBar.main.transferWeapons = Configs.moveweapons.getValue();
            ISBzHotBar.main.slotsSize = Configs.dropdownslotsize.getValue();
            ISBzHotBar.main.simpleDeleteButton = Configs.simpledelete.getValue();
            ISBzHotBar.main.showDeleteButton = Configs.showdeletebutton.getValue();
            ISBzHotBar.main.showToolTip = Configs.showtooltip.getValue();
            ISBzHotBar.main.opacity = Configs.opacitySettings.getValue();
            ISBzHotBar.main.hideCar = Configs.hideCar.getValue();
            saveConfig();
            return
        } 

        ISBzHotBar.main.activeWindows = Configs.activeWindows.getValue()
        ISBzHotBar.windows.get(1).rows = Configs.dropdown1x.getValue()
        ISBzHotBar.windows.get(1).columns = Configs.dropdown1y.getValue()
        ISBzHotBar.windows.get(2).rows = Configs.dropdown2x.getValue()
        ISBzHotBar.windows.get(2).columns = Configs.dropdown2y.getValue()
        ISBzHotBar.windows.get(3).rows = Configs.dropdown3x.getValue()
        ISBzHotBar.windows.get(3).columns = Configs.dropdown3y.getValue()
        ISBzHotBar.windows.get(4).rows = Configs.dropdown4x.getValue()
        ISBzHotBar.windows.get(4).columns = Configs.dropdown4y.getValue()
        ISBzHotBar.windows.get(5).rows = Configs.dropdown5x.getValue()
        ISBzHotBar.windows.get(5).columns = Configs.dropdown5y.getValue()
        ISBzHotBar.main.transferWeapons = Configs.moveweapons.getValue();
        ISBzHotBar.main.slotsSize = Configs.dropdownslotsize.getValue();
        ISBzHotBar.main.simpleDeleteButton = Configs.simpledelete.getValue();
        ISBzHotBar.main.showDeleteButton = Configs.showdeletebutton.getValue();
        ISBzHotBar.main.showToolTip = Configs.showtooltip.getValue();
        ISBzHotBar.main.opacity = Configs.opacitySettings.getValue();
        ISBzHotBar.main.hideCar = Configs.hideCar.getValue();

        setWindosPos();
        saveConfig();
        reloadWindows();
    }
}
IngameConfigSetup()


/**
 * On key press toggle windows.
 */
Events.onKeyPressed.addListener((key) => {
   // if ((key == getCore().getKey("Quick slots keybind")) && getPlayer() && getGameSpeed() > 0) {
   if (getPlayer() && getGameSpeed() > 0) {
    if ( (key == Configs.keybind.getValue()) ) {
        checkWindowsBounds();
        toggleWindows();
        updateAllSlots()
        return
    } else if (key == Configs.keybindSlot0.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(0)
        }
        return
    } else if (key == Configs.keybindSlot1.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(1)
        }
        return
    } else if (key == Configs.keybindSlot2.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(2)
        }
        return
    } else if (key == Configs.keybindSlot3.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(3)
        }
        return
    } else if (key == Configs.keybindSlot4.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(4)
        }
        return
    } else if (key == Configs.keybindSlot5.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(5)
        }
        return
    } else if (key == Configs.keybindSlot6.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(6)
        }
        return
    } else if (key == Configs.keybindSlot7.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(7)
        }
        return
    } else if (key == Configs.keybindSlot8.getValue()){
        const window = windowssHolder.get(1);
        if (window != null) {
            window.activateSlot(8)
        }
        return
    }
   }  
});

Events.onResolutionChange.addListener((oldWidth: number, oldHeight: number, newWidth: number, newHeight: number) => {
     checkWindowsBounds();
     reloadWindows();
})

Events.onSave.addListener(() => {
    setWindosPos();
    saveConfig();
})

Events.onGameStart.addListener(() => {
    loadConfig();
    createWindows();
})

Events.onMainMenuEnter.addListener(() => {
    const options = PZAPI.ModOptions.getOptions("pzhotbar42")
    if (options) {
        options.apply()
    }
})

Events.onRefreshInventoryWindowContainers.addListener((iSInventoryPage: any, state: string) => {
    if (iSInventoryPage.onCharacter && state == "end") {
        // update all items
        updateAllSlots()
    }
})

Events.onEnterVehicle.addListener(() => {
    if (ISBzHotBar.main.hideCar) {
        showWindows(false)
    }
})

Events.onExitVehicle.addListener(() => {
    if (ISBzHotBar.main.hideCar) {
        showWindows(true)
    }
})


// Called when an object with a container is added/removed from the world.
// Added this to handle campfire containers.
//Events.onContainerUpdate.addListener((container: any) => {
//    updateAllSlots()
//    print("Hook update 2"); 
//})

/**
 * Hook into ISTimedActionQueue for upadting items in slots.
 */
//hookInto("ISTimedActionQueue:onCompleted", (_onCompleted: Function, self: ISTimedActionQueue, action: ISBaseTimedAction) => {
//    updateAllSlots()
//    print("Hook update 3"); 
//    return _onCompleted.call(self, action)
//})

/*
hookInto("ISInventoryPane.refreshContainer", (_refreshContainer: Function, self: ISInventoryPane) => {
    _refreshContainer.call(self)
    if (self.parent.onCharacter) {
        updateAllSlots()
        print("Hook update"); 
    }
})
*/
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
    showtooltip: ModOptionsData
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
    // if (ModOptions != null) {
    //     /** @noSelf **/
    //     function OnApplyMainMenu(value: ModOptionsValue) {
    //         ISBzHotBar.main.activeWindows = value.settings.options.activeWindows;
    //         ISBzHotBar.windows.get(1).rows = value.settings.options.dropdown1X;
    //         ISBzHotBar.windows.get(1).columns = value.settings.options.dropdown1y;
    //         ISBzHotBar.windows.get(2).rows = value.settings.options.dropdown2X;
    //         ISBzHotBar.windows.get(2).columns = value.settings.options.dropdown2y;
    //         ISBzHotBar.windows.get(3).rows = value.settings.options.dropdown3X;
    //         ISBzHotBar.windows.get(3).columns = value.settings.options.dropdown3y;
    //         ISBzHotBar.windows.get(4).rows = value.settings.options.dropdown4X;
    //         ISBzHotBar.windows.get(4).columns = value.settings.options.dropdown4y;
    //         ISBzHotBar.windows.get(5).rows = value.settings.options.dropdown5X;
    //         ISBzHotBar.windows.get(5).columns = value.settings.options.dropdown5y;
    //         ISBzHotBar.main.transferWeapons = value.settings.options.moveweapons;
    //         ISBzHotBar.main.slotsSize = ISBzHotBar.main.slotsSizes[value.settings.options.dropdownslotsize];
    //         ISBzHotBar.main.simpleDeleteButton = value.settings.options.simpledelete;
    //         ISBzHotBar.main.showDeleteButton = value.settings.options.showdeletebutton
    //         ISBzHotBar.main.showToolTip = value.settings.options.showtooltip
    //         saveConfig();
    //     }
    //     /** @noSelf **/
    //     function OnApplyInGame(value: ModOptionsValue) {
    //         setWindosPos();
    //         OnApplyMainMenu(value)
    //         reloadWindows();
    //     }

    //     /** @noSelf **/
    //     function createModOptionData(choices: string[], name: string, tooltip: string, def: number | boolean, onApplyInGame: any, onApplyMainMenu: any): ModOptionsData {
    //         const data = new ModOptionsData()
    //         for (const [k, v] of pairs(choices)) {
    //             data.set(k, v)
    //         }
    //         data.name = name
    //         data.tooltip = tooltip
    //         data.default = def
    //         data.OnApplyInGame = onApplyInGame
    //         data.OnApplyMainMenu = onApplyMainMenu
    //         return data
    //     }
    //     /** @noSelf **/
    //     function createSetttings(): ModOptionsSettings {
    //         const optionsData = new ModOptionsDataHolder()
    //         optionsData.activeWindows = createModOptionData(["1", "2", "3", "4", "5"], "IGUI_Bz_Fast_HotBar_MaxTables_Name", "IGUI_Bz_Fast_HotBar_MaxTables_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown1X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "1", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown1y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "1", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 8, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown2X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "2", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown2y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "2", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown3X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "3", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown3y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "3", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown4X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "4", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown4y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "4", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown5X = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") + "5", "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdown5y = createModOptionData(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"], getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") + "5", "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.moveweapons = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Move_Weapons_Name"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Move_Weapons", true, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.simpledelete = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Simple_Delete"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Simple_Delete", false, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.showdeletebutton = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_Delete"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Show_Delete", true, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.dropdownslotsize = createModOptionData(["60 default", "65", "70", "75", "80 1x fonts", "85", "90 2x fonts", "55", "50", "45"], getText("IGUI_Bz_Fast_HotBar_SlotSize_Name"), "IGUI_Bz_Fast_HotBar_SlotSize_Tooltip", 1, OnApplyInGame, OnApplyMainMenu)
    //         optionsData.showtooltip = createModOptionData([], getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_ToolTip"), "IGUI_Bz_Fast_HotBar_CheckBox_Tooltip_Show_ToolTip", true, OnApplyInGame, OnApplyMainMenu)

    //         const settings = new ModOptionsSettings()
    //         settings.options_data = optionsData
    //         settings.mod_id = "pzhotbar"
    //         settings.mod_shortname = "Fast Hotbar mod v2"
    //         settings.mod_fullname = "Bzouk Fast Hotbar mod v2"
    //         return settings
    //     }
    //     const SETTINGS = createSetttings()
    //     ModOptions.AddKeyBinding("[Bz_Toggle_Hotbar]", { key: Keyboard.KEY_TAB, name: "Bz_Toggle_Hotbar" });
    //     ModOptions.getInstance(SETTINGS)
    //     ModOptions.loadFile()
    //     loadConfig()
    //     ISBzHotBar.main.activeWindows = SETTINGS.options.activeWindows;
    //     ISBzHotBar.windows.get(1).rows = SETTINGS.options.dropdown1X;
    //     ISBzHotBar.windows.get(1).columns = SETTINGS.options.dropdown1y;
    //     ISBzHotBar.windows.get(2).rows = SETTINGS.options.dropdown2X;
    //     ISBzHotBar.windows.get(2).columns = SETTINGS.options.dropdown2y;
    //     ISBzHotBar.windows.get(3).rows = SETTINGS.options.dropdown3X;
    //     ISBzHotBar.windows.get(3).columns = SETTINGS.options.dropdown3y;
    //     ISBzHotBar.windows.get(4).rows = SETTINGS.options.dropdown4X;
    //     ISBzHotBar.windows.get(4).columns = SETTINGS.options.dropdown4y;
    //     ISBzHotBar.windows.get(5).rows = SETTINGS.options.dropdown5X;
    //     ISBzHotBar.windows.get(5).columns = SETTINGS.options.dropdown5y;
    //     ISBzHotBar.main.transferWeapons = SETTINGS.options.moveweapons;
    //     ISBzHotBar.main.slotsSize = ISBzHotBar.main.slotsSizes[SETTINGS.options.dropdownslotsize];
    //     ISBzHotBar.main.simpleDeleteButton = SETTINGS.options.simpledelete;
    //     ISBzHotBar.main.showDeleteButton = SETTINGS.options.showdeletebutton
    //     ISBzHotBar.main.showToolTip = SETTINGS.options.showtooltip
    //     saveConfig()
   // }
} else {
    //
}




