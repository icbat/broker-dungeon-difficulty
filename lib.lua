-- TODO get Heroic/Mythic icons and display those where relevant
-- interface/encounterjournal/ui-ej-heroictexticon.blp ?

-- TODO grey out/remove click if you're in a party and not lead
-- TODO swap from green to something else if you're unable to select it

-- TODO test in LFR to make sure it doesn't explode


icbat_dungeon_diff_lib = {}

icbat_dungeon_diff_lib.get_difficulty_display = function(id, cache, getter)
    if cache[id] == nil then
        cache[id] = getter(id)
    end
    return cache[id]
end

--- builds a table that will have up to 3 entries, one for dungeon, raid, and legacy difficulties, depending on what instance type you are in
---@param current_instance_type one of nil, "party", or "raid"
---@param is_legacy_raid true if you are in a raid where your legacy difficulty matters
---@param dungeon_diff the pretty string for what dungeon difficulty you're set to
---@param raid_diff the pretty string for what raid difficulty you're set to
---@param legacy_diff the pretty string for what legacy raid difficulty you're set to
icbat_dungeon_diff_lib.build_label_table = function(current_instance_type, is_legacy_raid, dungeon_diff, raid_diff, legacy_diff) 
    local output = {
        dungeon = dungeon_diff,
        raid = raid_diff,
        legacy = legacy_diff,
    }

    if current_instance_type == "party" then
        output["raid"] = nil
        output["legacy"] = nil

        return output
    end
    
    if current_instance_type == "raid" then
        output["dungeon"] = nil

        if not is_legacy_raid then
            output["legacy"] = nil
        end

        return output
    end

    return output
end

icbat_dungeon_diff_lib.build_label = function (is_short_mode, label_table)
    local display = label_table

    if is_short_mode then
        if display["dungeon"] then 
            display["dungeon"] = string.sub(display["dungeon"], 1, 1)
        end
        if display["raid"] then 
            display["raid"] = string.sub(display["raid"], 1, 1)
        end
        if display["legacy"] then 
            display["legacy"] = string.sub(display["legacy"], 1, 2)
        end
    end

    local to_display = {}
    to_display[#to_display + 1] = display["dungeon"]
    to_display[#to_display + 1] = display["raid"]
    to_display[#to_display + 1] = display["legacy"]

    return table.concat(to_display, " / ")
end

return icbat_dungeon_diff_lib