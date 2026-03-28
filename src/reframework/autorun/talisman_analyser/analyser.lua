local SlotType = require("talisman_analyser.slot_type")
local Util = require("talisman_analyser.util")

local Analyser = {}

--- function to get the ranks of a talisman's slots of a specific type sorted
local function get_ranks_sorted(talisman, slot_type)
    local ranks = {}
    for _, slot in ipairs(talisman.slots) do
        if slot.type == slot_type then
            table.insert(ranks, slot.rank)
        end
    end
    table.sort(ranks, function(a, b)
        return a > b
    end)
    return ranks
end

--- function to compare the rank of each slot; -1 -> worse, 0 -> equal, 1 -> better
local function compare_slot_ranks(talisman_ranks, other_talisman_ranks)
    if #talisman_ranks < #other_talisman_ranks then
        return -1
    end
    local has_improvement = #talisman_ranks > #other_talisman_ranks
    for i = 1, #other_talisman_ranks do
        if talisman_ranks[i] < other_talisman_ranks[i] then
            return -1
        end
        if talisman_ranks[i] > other_talisman_ranks[i] then
            has_improvement = true
        end
    end
    return has_improvement and 1 or 0
end

--- function to determine if talisman has better slots than other_talisman
local function has_better_slots(talisman, other_talisman)
    local weapon_comparison = compare_slot_ranks(get_ranks_sorted(talisman, SlotType.WEAPON), get_ranks_sorted(other_talisman, SlotType.WEAPON))
    local armor_comparison = compare_slot_ranks(get_ranks_sorted(talisman, SlotType.ARMOR), get_ranks_sorted(other_talisman, SlotType.ARMOR))

    if weapon_comparison >= 0 and armor_comparison >= 0 then
        return weapon_comparison > 0 or armor_comparison > 0
    end
    return false
end

--- function to convert a skill list into a mapping of name to level
local function to_skill_map(skills)
    local skill_map = {}
    for _, skill in ipairs(skills) do
        local name = skill.name
        if not skill_map[name] then
            skill_map[name] = skill.level
        else
            skill_map[name] = skill_map[name] + skill.level
        end
    end
    return skill_map
end

--- function to determine if talisman makes other_talisman obsolete
local function makes_obsolete(talisman, other_talisman)
    local skills = to_skill_map(talisman.skills)
    local other_skills = to_skill_map(other_talisman.skills)
    local has_skill_improvement = false
    for name, other_level in pairs(other_skills) do
        local level = skills[name]
        if not level or level < other_level then
            return false
        end
        if level > other_level then
            has_skill_improvement = true
        end
    end
    if has_skill_improvement or Util.count_map_entries(skills) > Util.count_map_entries(other_skills) then
        return true
    end
    -- Skills are exactly equal, break the tie with Slots
    return has_better_slots(talisman, other_talisman)
end

--- function to identify obsolete talismans, returning a map of talisman to a list of talismans it obsoletes
function Analyser.find_obsolete_talismans(talismans)
    if not talismans or #talismans == 0 then
        return {}
    end

    local obsolete_mapping = {}
    for i = 1, #talismans do
        local talisman = talismans[i]
        for j = 1, #talismans do
            if i ~= j then
                local other_talisman = talismans[j]
                if makes_obsolete(talisman, other_talisman) then
                    if not obsolete_mapping[talisman] then
                        obsolete_mapping[talisman] = {}
                    end
                    table.insert(obsolete_mapping[talisman], other_talisman)
                end
            end
        end
    end
    return obsolete_mapping
end

--- function to identify and return duplicate talismans
function Analyser.find_duplicates(talismans)
    if not talismans or #talismans == 0 then
        return {}
    end

    local duplicates = {}
    local already_counted = {}
    for i, talisman in ipairs(talismans) do
        if not Util.table_contains(already_counted, i) then
            local count = 1
            for j = i + 1, #talismans do
                if talisman == talismans[j] then
                    count = count + 1
                    table.insert(already_counted, j)
                end
            end
            if count > 1 then
                duplicates[talisman] = count
            end
        end
    end
    return duplicates
end

return Analyser
