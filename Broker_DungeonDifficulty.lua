-- TODO if inside an instance, only show the relevant settings
-- TODO toggleable shorthand mode w/ savedvariables on click

-------------------
--- Data structures
-------------------

local dungeon_display = {
    { id = 1, display = _G.PLAYER_DIFFICULTY1 },
    { id = 2, display = _G.PLAYER_DIFFICULTY2 },
    { id = 23, display = _G.PLAYER_DIFFICULTY6 },
}

local raid_display = {
    { id = 14, display = _G.PLAYER_DIFFICULTY1 },
    { id = 15, display = _G.PLAYER_DIFFICULTY2 },
    { id = 16, display = _G.PLAYER_DIFFICULTY6 },
}

local legacy_display = {
    { id = 3, display = _G.RAID_DIFFICULTY_10PLAYER },
    { id = 5, display = _G.RAID_DIFFICULTY_10PLAYER_HEROIC },
    { id = 4, display = _G.RAID_DIFFICULTY_25PLAYER },
    { id = 6, display = _G.RAID_DIFFICULTY_25PLAYER_HEROIC },
}

-- the map tables are auto-sorting based on the strings, this is to preserve manual ordering
local function array_to_map(array)
    local output = {}
    for _, el in ipairs(array) do
        output[el.id] = el.display
    end
    return output
end

local dungeonDiffMap = array_to_map(dungeon_display)
local raidDiffMap = array_to_map(raid_display)
local legacyRaidDiffMap = array_to_map(legacy_display)

-------------
--- View Code
-------------

local GREEN = "0000ff00"
local GREY = "00777777"

local function color(text, color) 
    return "\124c" .. color .. text .. "\124r"
end

--- Handles conditional coloring of text of Legacy Raid options when you're on Mythic, to mimic the WoW UI
local function color_with_legacy(text, difficulty_map)
    if GetRaidDifficultyID() ~= 16 then
        return text
    end

    if difficulty_map ~= legacyRaidDiffMap and difficulty_map ~= legacy_display then
        return text
    end
    
    return color(text, GREY)
end

local function difficulty(description, getter_func, diff_map)
    local id = getter_func()
    local out = diff_map[id]
    assert(out, "Could not find " .. description .. " difficulty ID " .. id ..
        " in to-string map. Have these values changed on Blizzard's side?")
    return color_with_legacy(out, diff_map)
end

local function build_diff_setter(self, difficulty_map, getter_function, setter_function)
    for _, el in ipairs(difficulty_map) do
        local selected_id = getter_function()
        local prefix = ""

        if selected_id == el.id then
            prefix = color(">", GREEN)
        end

        local line = self:AddLine(prefix, color_with_legacy(el.display, difficulty_map))

        if selected_id ~= el.id then
            local callback = function()
                self:Clear()
                setter_function(el.id)
            end
            self:SetLineScript(line, "OnMouseUp", callback)
        end
    end
end

local function build_tooltip(self)
    -- col 1 is for highlighting what you're currently queued for
    -- col 2 is general text
    self:AddHeader("", _G.DUNGEON_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, dungeon_display, GetDungeonDifficultyID, SetDungeonDifficultyID)

    self:AddLine("")

    self:AddHeader("", _G.RAID_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, raid_display, GetRaidDifficultyID, SetRaidDifficultyID)

    self:AddLine("")

    self:AddHeader("", _G.LEGACY_RAID_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, legacy_display, GetLegacyRaidDifficultyID, SetLegacyRaidDifficultyID)
end

local function build_label()
    local display = {difficulty("Dungeon", GetDungeonDifficultyID, dungeonDiffMap),
                     difficulty("Raid", GetRaidDifficultyID, raidDiffMap),
                     difficulty("Legacy Raid", GetLegacyRaidDifficultyID, legacyRaidDiffMap)}
    return table.concat(display, " / ")
end

--------------------
--- Wiring/LDB/QTip
--------------------

local ADDON, namespace = ...
local LibQTip = LibStub('LibQTip-1.0')
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject(ADDON, {
    type = "data source",
    text = "-"
})

local function OnRelease(self)
    LibQTip:Release(self.tooltip)
    self.tooltip = nil
end

local function anchor_OnEnter(self)
    if self.tooltip then
        LibQTip:Release(self.tooltip)
        self.tooltip = nil
    end

    local tooltip = LibQTip:Acquire(ADDON, 2, "LEFT", "LEFT")
    self.tooltip = tooltip
    tooltip.OnRelease = OnRelease
    tooltip.OnLeave = OnLeave
    tooltip:SetAutoHideDelay(.1, self)

    build_tooltip(tooltip)

    tooltip:SmartAnchorTo(self)

    tooltip:Show()
end

function dataobj:OnEnter()
    anchor_OnEnter(self)
end

--- Nothing to do. Needs to be defined for some display addons apparently
function dataobj:OnLeave()
end

function dataobj:OnClick()
    ToggleLFDParentFrame()
end

local function set_label(self)
    dataobj.text = build_label()
end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")
local UPDATEPERIOD = 0.5
local elapsed = 0
f:SetScript("OnUpdate", function(self, elap)
    elapsed = elapsed + elap
    if elapsed < UPDATEPERIOD then
        return
    end
    elapsed = 0
    set_label(self)
end)

-- https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentation#PLAYER_DIFFICULTY_CHANGED
-- "This is claimed to exist." 
f:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
-- on login
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", set_label)

