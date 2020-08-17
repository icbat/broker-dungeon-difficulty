local BrokerDungeonDifficulty = {}

local ADDON, namespace = ...

local dungeonDiffMap = {}
dungeonDiffMap[1] = _G.PLAYER_DIFFICULTY1
dungeonDiffMap[2] = _G.PLAYER_DIFFICULTY2 
dungeonDiffMap[23] = _G.PLAYER_DIFFICULTY6

local function get_dungeon_diff()
    local dungeon_id = GetDungeonDifficultyID()
    return dungeonDiffMap[dungeon_id]
end

local raidDiffMap = {}
raidDiffMap[14] = _G.PLAYER_DIFFICULTY1
raidDiffMap[15] = _G.PLAYER_DIFFICULTY2 
raidDiffMap[16] = _G.PLAYER_DIFFICULTY6

local function get_raid_diff()
    local raid_id = GetRaidDifficultyID()
    local out = raidDiffMap[raid_id]
    assert(out, "Could not find Raid difficulty ID " .. raid_id .. " in to-string map. Have these values changed on Blizzard's side?")
    return out
end

local legacyRaidDiffMap = {}
legacyRaidDiffMap[3] = _G.RAID_DIFFICULTY_10PLAYER
legacyRaidDiffMap[4] = _G.RAID_DIFFICULTY_25PLAYER
legacyRaidDiffMap[5] = _G.RAID_DIFFICULTY_10PLAYER_HEROIC 
legacyRaidDiffMap[6] = _G.RAID_DIFFICULTY_25PLAYER_HEROIC 

local function get_legacy_diff()
    local legacy_raid_id = GetLegacyRaidDifficultyID()
    local out = legacyRaidDiffMap[legacy_raid_id]
    assert(out, "Could not find Legacy Raid difficulty ID " .. legacy_raid_id .. " in to-string map. Have these values changed on Blizzard's side?")
    return out
end

function BrokerDungeonDifficulty.build_tooltip(self)
    self:AddLine("Dungeon", tostring(GetDungeonDifficultyID()))
    self:AddLine("Dungeon", tostring(GetRaidDifficultyID()))
    self:AddLine("Legacy", tostring(GetLegacyRaidDifficultyID()))
end

-- TODO if raid is Mythic, grey out legacy settings
-- TODO if inside an instance, only show the relevant settings
-- TODO toggleable shorthand mode w/ cvars on click
function BrokerDungeonDifficulty.build_label()    
    return "" .. get_dungeon_diff() .. "/" .. get_raid_diff() .. "/" .. get_legacy_diff()
end


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

    -- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
    local tooltip = LibQTip:Acquire("FooBarTooltip", 2, "RIGHT", "LEFT")
    self.tooltip = tooltip
    tooltip.OnRelease = OnRelease
    tooltip.OnLeave = OnLeave
    tooltip:SetAutoHideDelay(.1, self)

    BrokerDungeonDifficulty.build_tooltip(tooltip)

    -- Use smart anchoring code to anchor the tooltip to our frame
    tooltip:SmartAnchorTo(self)

    -- Show it, et voilà !
    tooltip:Show()
end

-- tooltip/broker object settings
function dataobj:OnEnter()
    anchor_OnEnter(self)
end

function dataobj:OnLeave()
    -- Nothing to do. Needs to be defined for some display addons apparently
end

function dataobj:OnClick()
    ToggleLFDParentFrame()
end

function set_label(self)
    dataobj.text = BrokerDungeonDifficulty.build_label()
end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")
local UPDATEPERIOD = 5
local elapsed = 0
f:SetScript("OnUpdate", function(self, elap)
    elapsed = elapsed + elap
    if elapsed < UPDATEPERIOD then
        return
    end
    elapsed = 0
    set_label(self)
end)

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", set_label)
