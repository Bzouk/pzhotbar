local ISBzHotBarWindow = require("pzhotbar/ISUI/ISBzHotBarWindow")
local ConfigFile = require("pzhotbar/ConfigFile")

local FONT_UI_SMALL = getTextManager():getFontHeight(UIFont.Small)
local CONFIG_FILE = "pzhotbar42.txt"
--- Read in this order; the files of older versions only while CONFIG_FILE does not exist yet.
local CONFIG_FILES = {CONFIG_FILE, "pzhotbar.ini", "bzhotbar.ini"}

---@class BzWindowData
---@field rows integer
---@field columns integer
---@field x number?
---@field y number?

---@class BzMainData
---@field activeWindows integer
---@field show boolean
---@field transferWeapons boolean
---@field simpleDeleteButton boolean
---@field showDeleteButton boolean
---@field showToolTip boolean
---@field slotsSize number
---@field opacity number
---@field hideCar boolean

--- Data saved to the config file: item full names per window and slot, window layout, settings.
---@class BzHotBarData
---@field items table<integer, table<integer, string>>
---@field windows table<integer, BzWindowData>
---@field main BzMainData
local ISBzHotBar = {
    items = {{}, {}, {}, {}, {}},
    windows = {
        {rows = 2, columns = 8},
        {rows = 1, columns = 1},
        {rows = 1, columns = 1},
        {rows = 1, columns = 1},
        {rows = 1, columns = 1},
    },
    main = {
        activeWindows = 1,
        show = true,
        transferWeapons = true,
        simpleDeleteButton = true,
        showDeleteButton = true,
        showToolTip = true,
        slotsSize = 65,
        opacity = 1,
        hideCar = false,
    },
}

--- Open windows by window number.
---@type table<integer, ISBzHotBarWindow>
local windowsHolder = {}

-- ============================
-- Helpers

local function str_to_bool(tex)
    if tex == nil then
        return false
    end
    return string.lower(tex) == "true"
end

--- No main screen yet while the game is starting.
local function isInGame()
    return MainScreen.instance ~= nil and MainScreen.instance.inGame
end

local function getDeleteText()
    if ISBzHotBar.main.showDeleteButton == false then
        return ""
    end
    if ISBzHotBar.main.simpleDeleteButton then
        return "X"
    end
    return getText("UI_Bz_Fast_HotBar_Slot_Remove")
end

local function getHotBarSlotDimension()
    return math.max(ISBzHotBar.main.slotsSize, getTextManager():MeasureStringX(UIFont.Small, getDeleteText()) + 10)
end

local function getHotBarWidth(columns)
    return getHotBarSlotDimension() * columns + 3
end

local function getHotBarHeight(rows)
    local titleBarHeight = math.max(16, FONT_UI_SMALL + 1)
    return titleBarHeight + 3 + getHotBarSlotDimension() * rows
end

-- ============================
-- Config file

local function saveConfig()
    ConfigFile.write(CONFIG_FILE, ISBzHotBar)
end

--- Copies settings, slot items and window layout read from a config file into ISBzHotBar.
local function updateFromTable(data)
    local dataMain = data.main or {}
    local main = ISBzHotBar.main
    -- a missing or broken value keeps the current one
    main.activeWindows = tonumber(dataMain.activeWindows) or main.activeWindows
    main.transferWeapons = str_to_bool(dataMain.transferWeapons)
    main.slotsSize = tonumber(dataMain.slotsSize) or main.slotsSize
    main.simpleDeleteButton = str_to_bool(dataMain.simpleDeleteButton)
    main.showToolTip = str_to_bool(dataMain.showToolTip)
    -- bars hidden with the toggle key stay hidden; files without the key show them
    main.show = dataMain.show == nil or str_to_bool(dataMain.show)
    local dataItems = data.items or {}
    local dataWindows = data.windows or {}
    for i = 1, main.activeWindows do
        local iStr = tostring(i)
        for key, value in pairs(dataItems[iStr] or {}) do
            local kk = tonumber(key)
            if kk then
                ISBzHotBar.items[i][kk] = value
            end
        end
        local dataWindow = dataWindows[iStr] or {}
        local window = ISBzHotBar.windows[i]
        window.rows = tonumber(dataWindow.rows) or window.rows
        window.columns = tonumber(dataWindow.columns) or window.columns
        if dataWindow.x and dataWindow.y then
            window.x = tonumber(dataWindow.x)
            window.y = tonumber(dataWindow.y)
        end
    end
end

--- Loads the first config file found, the current one first.
local function loadConfig()
    for _, file in ipairs(CONFIG_FILES) do
        local data = ConfigFile.read(file)
        -- Kahlua has no next(); an empty table skips the loop
        for _ in pairs(data) do
            updateFromTable(data)
            return
        end
    end
end

-- ============================
-- Windows

--- Stores the current window positions into ISBzHotBar.
local function setWindosPos()
    for windowNum = 1, ISBzHotBar.main.activeWindows do
        local window = windowsHolder[windowNum]
        if window ~= nil then
            local windowTable = ISBzHotBar.windows[windowNum]
            windowTable.x = window:getX()
            windowTable.y = window:getY()
        end
    end
end

local function createWindows()
    if not isInGame() then
        return
    end
    -- hidden bars are created too, or the toggle key has nothing to show after a reload
    for windowNum = 1, ISBzHotBar.main.activeWindows do
        local windowData = ISBzHotBar.windows[windowNum]
        local x = windowData.x or getCore():getScreenWidth() / 2 - 240
        local y = windowData.y or getCore():getScreenHeight() - getHotBarHeight(windowData.rows) - 240
        local columns = windowData.columns
        local rows = windowData.rows
        local window = ISBzHotBarWindow:new(x, y, getHotBarWidth(columns), getHotBarHeight(rows), getHotBarSlotDimension(), windowNum, rows, columns, ISBzHotBar.items[windowNum], getDeleteText(), ISBzHotBar.main.showDeleteButton, ISBzHotBar.main.transferWeapons, ISBzHotBar.main.showToolTip, ISBzHotBar.main.opacity)
        window:setVisible(ISBzHotBar.main.show)
        if ISBzHotBar.main.show then
            window:addToUIManager()
        end
        windowsHolder[windowNum] = window
    end
end

local function reloadWindows()
    for _, window in pairs(windowsHolder) do
        window:setVisible(false)
        window:removeFromUIManager()
    end
    windowsHolder = {}
    createWindows()
end

--- Hidden bars leave the UI manager, or the game keeps calling update() on every slot.
local function showWindows(showWin)
    for _, window in pairs(windowsHolder) do
        if window:getIsVisible() ~= showWin then
            window:setVisible(showWin)
            if showWin then
                window:addToUIManager()
            else
                window:removeFromUIManager()
            end
        end
    end
    ISBzHotBar.main.show = showWin
end

local function updateAllSlots()
    for _, window in pairs(windowsHolder) do
        if window:getIsVisible() then
            window:updateItems()
        end
    end
end

--- Moves windows that ended up off screen, past any edge, back inside it.
local function checkWindowsBounds()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    for windowNum = 1, ISBzHotBar.main.activeWindows do
        local window = ISBzHotBar.windows[windowNum]
        local openWindow = windowsHolder[windowNum]
        if window.x ~= nil then
            local x = math.max(math.min(window.x --[[@as number]], screenWidth - getHotBarWidth(window.columns)), 0)
            if x ~= window.x then
                window.x = x
                if openWindow ~= nil then
                    openWindow:setX(x)
                end
            end
        end
        if window.y ~= nil then
            local y = math.max(math.min(window.y --[[@as number]], screenHeight - getHotBarHeight(window.rows)), 0)
            if y ~= window.y then
                window.y = y
                if openWindow ~= nil then
                    openWindow:setY(y)
                end
            end
        end
    end
end

-- ============================
-- Mod options (B42 PZAPI.ModOptions)

local Configs = {rows = {}, columns = {}, keybindSlots = {}}

--- Copies the values from mod options into ISBzHotBar.
local function readConfigs()
    ISBzHotBar.main.activeWindows = Configs.activeWindows:getValue()
    for windowNum = 1, 5 do
        ISBzHotBar.windows[windowNum].rows = Configs.rows[windowNum]:getValue()
        ISBzHotBar.windows[windowNum].columns = Configs.columns[windowNum]:getValue()
    end
    ISBzHotBar.main.transferWeapons = Configs.moveweapons:getValue()
    ISBzHotBar.main.slotsSize = Configs.dropdownslotsize:getValue()
    ISBzHotBar.main.simpleDeleteButton = Configs.simpledelete:getValue()
    ISBzHotBar.main.showDeleteButton = Configs.showdeletebutton:getValue()
    ISBzHotBar.main.showToolTip = Configs.showtooltip:getValue()
    ISBzHotBar.main.opacity = Configs.opacitySettings:getValue()
    ISBzHotBar.main.hideCar = Configs.hideCar:getValue()
end

local function IngameConfigSetup()
    local options = PZAPI.ModOptions:create("pzhotbar42", " Quick slots mod")
    options:addTitle("Bz Quick slot mod")
    Configs.keybind = options:addKeyBind("pzhotbar42keybind", getText("Quick slots keybind"), Keyboard.KEY_TAB)
    Configs.activeWindows = options:addSlider("tabscount", getText("IGUI_Bz_Fast_HotBar_MaxTables_Name") .. "1", 1, 5, 1, 1, "IGUI_Bz_Fast_HotBar_MaxTables_Tooltip")
    -- defaults: window 1 is 2 x 8, the others 1 x 1
    for windowNum = 1, 5 do
        local defaultRows, defaultColumns = 1, 1
        if windowNum == 1 then
            defaultRows, defaultColumns = 2, 8
        end
        Configs.rows[windowNum] = options:addSlider(windowNum .. "x", getText("IGUI_Bz_Fast_HotBar_DropdownX_Name") .. windowNum, 1, 10, 1, defaultRows, "IGUI_Bz_Fast_HotBar_DropdownX_Tooltip")
        Configs.columns[windowNum] = options:addSlider(windowNum .. "y", getText("IGUI_Bz_Fast_HotBar_DropdownY_Name") .. windowNum, 1, 10, 1, defaultColumns, "IGUI_Bz_Fast_HotBar_DropdownY_Tooltip")
    end
    Configs.moveweapons = options:addTickBox("moveweapons", getText("IGUI_Bz_Fast_HotBar_CheckBox_Move_Weapons_Name"), true)
    Configs.simpledelete = options:addTickBox("simpledelete", getText("IGUI_Bz_Fast_HotBar_CheckBox_Simple_Delete"), false)
    Configs.showdeletebutton = options:addTickBox("showdeletebutton", getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_Delete"), true)
    Configs.dropdownslotsize = options:addSlider("dropdownslotsize", getText("IGUI_Bz_Fast_HotBar_SlotSize_Name"), 45, 90, 5, 65, "IGUI_Bz_Fast_HotBar_SlotSize_Tooltip")
    Configs.showtooltip = options:addTickBox("showtooltip", getText("IGUI_Bz_Fast_HotBar_CheckBox_Show_ToolTip"), true)
    Configs.opacitySettings = options:addSlider("opacity", getText("IGUI_Bz_Fast_HotBar_DropdownOpacity_Name"), 0, 1, 0.1, 1, "IGUI_Bz_Fast_HotBar_DropdownOpacity_Tooltip")
    Configs.hideCar = options:addTickBox("hidecar", getText("IGUI_Bz_Fast_HotBar_HideCar_Name"), false)
    options:addSeparator()
    options:addDescription("Windows 1 keybinds")
    for slot = 0, 8 do
        Configs.keybindSlots[slot] = options:addKeyBind("pzhotbar42keybindpos" .. slot, getText("Keybind slot " .. (slot + 1) .. "."), Keyboard.KEY_NONE)
    end
    options.apply = function()
        if not isInGame() then
            loadConfig()
            readConfigs()
            saveConfig()
            return
        end
        readConfigs()
        setWindosPos()
        saveConfig()
        reloadWindows()
    end
end
IngameConfigSetup()

-- ============================
-- Events

Events.OnKeyPressed.Add(function(key)
    if not (getPlayer() and getGameSpeed() > 0) then
        return
    end
    if key == Configs.keybind:getValue() then
        checkWindowsBounds()
        showWindows(not ISBzHotBar.main.show)
        updateAllSlots()
        return
    end
    for slot = 0, 8 do
        if key == Configs.keybindSlots[slot]:getValue() then
            local window = windowsHolder[1]
            if window ~= nil then
                window:activateSlot(slot)
            end
            return
        end
    end
end)

Events.OnResolutionChange.Add(function()
    checkWindowsBounds()
    reloadWindows()
end)

Events.OnSave.Add(function()
    setWindosPos()
    saveConfig()
end)

Events.OnGameStart.Add(function()
    loadConfig()
    checkWindowsBounds()
    createWindows()
end)

Events.OnMainMenuEnter.Add(function()
    local options = PZAPI.ModOptions:getOptions("pzhotbar42")
    if options then
        options:apply()
    end
end)

Events.OnRefreshInventoryWindowContainers.Add(function(iSInventoryPage, state)
    if iSInventoryPage.onCharacter and state == "end" then
        updateAllSlots()
    end
end)

Events.OnEnterVehicle.Add(function()
    if ISBzHotBar.main.hideCar then
        showWindows(false)
    end
end)

Events.OnExitVehicle.Add(function()
    if ISBzHotBar.main.hideCar then
        showWindows(true)
    end
end)
