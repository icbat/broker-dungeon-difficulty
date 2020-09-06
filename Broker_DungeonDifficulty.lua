-- TODO get Heroic/Mythic icons and display those where relevant
-- interface/encounterjournal/ui-ej-heroictexticon.blp ?
-- TODO grey out/remove click if you're in a party and not lead
-- TODO swap from green to something else if you're unable to select it

local lib = icbat_dungeon_diff_lib

------------------------------
--- Initialize Saved Variables
------------------------------
if icbat_bdd_short_mode == nil then
    -- whether or not the label should show full names or initials
    icbat_bdd_short_mode = false
end

if icbat_bdd_display_name_cache == nil then
    -- holds id -> name that we have seen before
    icbat_bdd_display_name_cache = {}
end

-------------------
--- Data structures
-------------------

local dungeon_display = {1, 2, 23}

local raid_display = {14, 15, 16}

local legacy_display = {3, 5, 4, 6}

-------------
--- View Code
-------------

local function legacy_selection_matters(raid_diff_id)
    return raid_diff_id == 14 or raid_diff_id == 15
end

local function build_diff_setter(self, difficulty_map, selected_id, setter_function)
    for _, difficulty_id in ipairs(difficulty_map) do
        local prefix = ""

        if selected_id == difficulty_id then
            prefix = ">"
        end

        local line = self:AddLine(prefix, lib.get_difficulty_display(difficulty_id, icbat_bdd_display_name_cache, GetDifficultyInfo))

        if selected_id ~= difficulty_id then
            local callback = function()
                self:Clear()
                setter_function(difficulty_id)
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
    build_diff_setter(self, dungeon_display, GetDungeonDifficultyID(), SetDungeonDifficultyID)

    self:AddLine("")

    self:AddHeader("", _G.RAID_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, raid_display, GetRaidDifficultyID(), SetRaidDifficultyID)

    self:AddLine("")

    self:AddHeader("", _G.LEGACY_RAID_DIFFICULTY)
    self:AddSeparator()
    local startLegacy = self:GetLineCount()
    build_diff_setter(self, legacy_display, GetLegacyRaidDifficultyID(), SetLegacyRaidDifficultyID)
    local endLegacy = self:GetLineCount()

    if not legacy_selection_matters(GetRaidDifficultyID()) then
        -- grey out legacy text
        for i = startLegacy, endLegacy do
            self:SetLineTextColor(i, 1, 1, 1, 0.5)
        end
    end

    self:AddLine("")
    local reset_line = self:AddLine("", _G.RESET_INSTANCES)

    if IsInInstance() then
        self:SetLineTextColor(reset_line, 1, 1, 1, 0.5)
    else
        self:SetLineScript(reset_line, "OnMouseUp", ResetInstances)
    end

    -- make the indicators green
    self:SetColumnTextColor(1, 0, 1, 0, 1)
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
    icbat_bdd_short_mode = not icbat_bdd_short_mode
end

local function set_label(self)
    local in_instance, instance_type = IsInInstance()
    -- TODO how do we figure this out? Not just legacy loot, but 10/25-matters
    local is_in_legacy_raid = false

    local dungeon = lib.get_difficulty_display(GetDungeonDifficultyID(), icbat_bdd_display_name_cache, GetDifficultyInfo)
    local raid = lib.get_difficulty_display(GetRaidDifficultyID(), icbat_bdd_display_name_cache, GetDifficultyInfo)
    local legacy = lib.get_difficulty_display(GetLegacyRaidDifficultyID(), icbat_bdd_display_name_cache, GetDifficultyInfo)

    local label_table = lib.build_label_table(instance_type, is_in_legacy_raid, dungeon, raid, legacy)

    dataobj.text = lib.build_label(icbat_bdd_short_mode, label_table)
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
