local lib = require "lib"

local assert_equals = function(expected, actual)
    assert(expected == actual, "Expected " .. tostring(expected) .. " but was " .. tostring(actual))
end

return {
    get_diff__uses_cache = function()
        local getter_never_called = function()
            assert(false)
        end

        local cache = {
            a = "a"
        }

        local result = lib.get_difficulty_display("a", cache, getter_never_called)

        assert_equals("a", result)
    end,

    get_diff__adds_to_cache = function()
        local getter = function(id)
            return id
        end

        local id = "a"

        local cache = {}

        assert_equals(nil, cache[id])

        local result = lib.get_difficulty_display(id, cache, getter)

        assert_equals(id, result)
        assert_equals(id, cache[id])
    end,

    build_label_table__out_of_instance__no_changes = function()
        local dungeon = "Enter the gungeon"
        local raid = "thanks for the raid"
        local legacy = "an expensive format"

        local result = lib.build_label_table(nil, false, dungeon, raid, legacy)

        assert_equals(dungeon, result["dungeon"])
        assert_equals(raid, result["raid"])
        assert_equals(legacy, result["legacy"])
    end,

    build_label_table__in_dungeon__no_raid_info = function()
        local dungeon = "Enter the gungeon"
        local raid = "thanks for the raid"
        local legacy = "an expensive format"

        local result = lib.build_label_table("party", false, dungeon, raid, legacy)

        assert_equals(dungeon, result["dungeon"])
        assert_equals(nil, result["raid"])
        assert_equals(nil, result["legacy"])
    end,

    build_label_table__in_legacy_raid__drops_dungeon = function()
        local dungeon = "Enter the gungeon"
        local raid = "thanks for the raid"
        local legacy = "an expensive format"

        local result = lib.build_label_table("raid", true, dungeon, raid, legacy)

        assert_equals(nil, result["dungeon"])
        assert_equals(raid, result["raid"])
        assert_equals(legacy, result["legacy"])
    end,

    build_label_table__in_newer_raid__drops_dungeon_and_legacy = function()
        local dungeon = "Enter the gungeon"
        local raid = "thanks for the raid"
        local legacy = "an expensive format"

        local result = lib.build_label_table("raid", false, dungeon, raid, legacy)

        assert_equals(nil, result["dungeon"])
        assert_equals(raid, result["raid"])
        assert_equals(nil, result["legacy"])
    end,

    build_label__long_mode__all_difficulties = function()
        local dungeon = "Enter the gungeon"
        local raid = "thanks for the raid"
        local legacy = "an expensive format"
        local label_table = {dungeon = dungeon, raid = raid, legacy = legacy}

        local result = lib.build_label(false, label_table)

        assert_equals(dungeon .. " / " .. raid .. " / " .. legacy, result)
    end,

    build_label__short_mode__all_difficulties = function()
        local dungeon = "Enter the gungeon"
        local raid = "thanks for the raid"
        local legacy = "an expensive format"
        local label_table = {dungeon = dungeon, raid = raid, legacy = legacy}

        local result = lib.build_label(true, label_table)

        assert_equals("E / t / an", result)
    end,

    build_label__long_mode__some_difficulties = function()
        local dungeon = "Enter the gungeon"
        local legacy = "an expensive format"
        local label_table = {dungeon = dungeon, legacy = legacy}

        local result = lib.build_label(false, label_table)

        assert_equals(dungeon .. " / " .. legacy, result)
    end,

    build_label__short_mode__some_difficulties = function()
        local dungeon = "Enter the gungeon"
        local legacy = "an expensive format"
        local label_table = {dungeon = dungeon, legacy = legacy}

        local result = lib.build_label(true, label_table)

        assert_equals("E / an", result)
    end,
}