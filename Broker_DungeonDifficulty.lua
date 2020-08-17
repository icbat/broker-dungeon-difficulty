local BrokerDungeonDifficulty = {}

local dungeonDiffMap = {}
dungeonDiffMap[1] = _G.PLAYER_DIFFICULTY1
dungeonDiffMap[2] = _G.PLAYER_DIFFICULTY2
dungeonDiffMap[23] = _G.PLAYER_DIFFICULTY6

local raidDiffMap = {}
raidDiffMap[14] = _G.PLAYER_DIFFICULTY1
raidDiffMap[15] = _G.PLAYER_DIFFICULTY2
raidDiffMap[16] = _G.PLAYER_DIFFICULTY6

local legacyRaidDiffMap = {}
legacyRaidDiffMap[3] = _G.RAID_DIFFICULTY_10PLAYER
legacyRaidDiffMap[4] = _G.RAID_DIFFICULTY_25PLAYER
legacyRaidDiffMap[5] = _G.RAID_DIFFICULTY_10PLAYER_HEROIC
legacyRaidDiffMap[6] = _G.RAID_DIFFICULTY_25PLAYER_HEROIC

local function difficulty(description, getter_func, diff_map)
    local id = getter_func()
    local out = diff_map[id]
    assert(out, "Could not find " .. description .. " difficulty ID " .. id ..
        " in to-string map. Have these values changed on Blizzard's side?")
    return out
end

local function build_diff_setter(self, difficulty_map, setter_function)
    for k, v in pairs(difficulty_map) do
        local line = self:AddLine("  " .. v)
        local callback = function()
            setter_function(k)
        end
        self:SetLineScript(line, "OnMouseUp", callback)
    end
end

function BrokerDungeonDifficulty.build_tooltip(self)
    self:AddHeader(_G.DUNGEON_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, dungeonDiffMap, SetDungeonDifficultyID)

    self:AddLine("")

    self:AddHeader(_G.RAID_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, raidDiffMap, SetRaidDifficultyID)

    self:AddLine("")

    self:AddHeader(_G.LEGACY_RAID_DIFFICULTY)
    self:AddSeparator()
    build_diff_setter(self, legacyRaidDiffMap, SetLegacyRaidDifficultyID)
end

-- TODO if raid is Mythic, grey out legacy settings
-- TODO if inside an instance, only show the relevant settings
-- TODO toggleable shorthand mode w/ cvars on click
-- TODO fix sorting
-- TODO hook relevant events so we don't have to update every 5s
function BrokerDungeonDifficulty.build_label()
    local display = {difficulty("Dungeon", GetDungeonDifficultyID, dungeonDiffMap),
                     difficulty("Raid", GetRaidDifficultyID, raidDiffMap),
                     difficulty("Legacy Raid", GetLegacyRaidDifficultyID, legacyRaidDiffMap)}
    return table.concat(display, " / ")
end

-------------------
-- Wiring/LDB/QTip
-------------------

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

    local tooltip = LibQTip:Acquire(ADDON, 1, "LEFT")
    self.tooltip = tooltip
    tooltip.OnRelease = OnRelease
    tooltip.OnLeave = OnLeave
    tooltip:SetAutoHideDelay(.1, self)

    BrokerDungeonDifficulty.build_tooltip(tooltip)

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
