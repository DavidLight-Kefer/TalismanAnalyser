local SlotType = require("lib.slot").Type
local Util = require("lib.util")

local Analyser = {}
local skill_map_cache = {}

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

--- function to determine if talisman has better slots than other_talisman; -1 -> worse, 0 -> equal, 1 -> better
local function compare_slots(talisman, other_talisman)
    local weapon_comparison = compare_slot_ranks(get_ranks_sorted(talisman, SlotType.WEAPON),
        get_ranks_sorted(other_talisman, SlotType.WEAPON))
    local armor_comparison = compare_slot_ranks(get_ranks_sorted(talisman, SlotType.ARMOR),
        get_ranks_sorted(other_talisman, SlotType.ARMOR))
    if weapon_comparison == -1 or armor_comparison == -1 then
        return -1
    elseif weapon_comparison == 1 or armor_comparison == 1 then
        return 1
    else
        return 0
    end
end

--- function to lazily compute and cache a skill map
local function get_skill_map(talisman)
    local cached = skill_map_cache[talisman.id]
    if cached then
        return cached
    end

    local skill_map = {}
    for _, skill in ipairs(talisman.skills) do
        local name = skill.name
        skill_map[name] = (skill_map[name] or 0) + skill.level
    end
    skill_map_cache[talisman.id] = skill_map
    return skill_map
end

--- function to determine if talisman makes other_talisman obsolete
local function makes_obsolete(talisman, other_talisman, cache, force_slot_comparison)
    if cache[other_talisman] then
        return false
    end

    local skills = get_skill_map(talisman)
    local other_skills = get_skill_map(other_talisman)
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

    if force_slot_comparison then
        local slot_comparison = compare_slots(talisman, other_talisman)
        if slot_comparison == 1 or (slot_comparison == 0 and (has_skill_improvement or Util.count_map_entries(skills) > Util.count_map_entries(other_skills))) then
            cache[other_talisman] = true
            return true
        end
    else
        if has_skill_improvement or Util.count_map_entries(skills) > Util.count_map_entries(other_skills) or compare_slots(talisman, other_talisman) == 1 then
            cache[other_talisman] = true
            return true
        end
    end
    return false
end

--- function to identify obsolete talismans, returning a map of talisman to a list of talismans it obsoletes
function Analyser.find_obsoletes(talismans, cache, compared, force_slot_comparison)
    if not talismans or #talismans < 2 then
        return {}
    end

    cache = cache or {}
    compared = compared or {}
    local obsolete_mapping = {}
    for i = 1, #talismans - 1 do
        local talisman1 = talismans[i]
        local talisman_comparison = compared[talisman1.id]
        for j = i + 1, #talismans do
            local talisman2 = talismans[j]
            if not (talisman_comparison and talisman_comparison[talisman2.id]) then
                if not compared[talisman1.id] then
                    compared[talisman1.id] = {}
                end
                compared[talisman1.id][talisman2.id] = true
                if makes_obsolete(talisman1, talisman2, cache, force_slot_comparison) then
                    obsolete_mapping[talisman1] = obsolete_mapping[talisman1] or {}
                    table.insert(obsolete_mapping[talisman1], talisman2)
                elseif makes_obsolete(talisman2, talisman1, cache, force_slot_comparison) then
                    obsolete_mapping[talisman2] = obsolete_mapping[talisman2] or {}
                    table.insert(obsolete_mapping[talisman2], talisman1)
                end
            end
        end
    end
    return obsolete_mapping
end

--- function to identify and return obsolete talismans within a hashmap
function Analyser.find_obsoletes_within_hashmap(talisman_map, force_slot_comparison)
    local cache = {}
    local compared = {}
    local all_obsoletes = {}
    local seen_worse = {}
    for _, talisman_list in pairs(talisman_map) do
        local group_obsoletes = Analyser.find_obsoletes(talisman_list, cache, compared, force_slot_comparison)
        for talisman, obsoletes_list in pairs(group_obsoletes) do
            all_obsoletes[talisman] = all_obsoletes[talisman] or {}
            for _, obsolete in ipairs(obsoletes_list) do
                if not seen_worse[obsolete] then
                    seen_worse[obsolete] = true
                    table.insert(all_obsoletes[talisman], obsolete)
                end
            end
        end
    end
    return all_obsoletes
end

--- function to identify and return duplicate talismans
function Analyser.find_duplicates(talismans)
    if not talismans or #talismans < 2 then
        return {}
    end

    local duplicates = {}
    local already_counted = {}
    for i, talisman in ipairs(talismans) do
        if not already_counted[i] then
            local count = 1
            for j = i + 1, #talismans do
                if talisman == talismans[j] then
                    count = count + 1
                    already_counted[j] = true
                end
            end
            if count > 1 then
                duplicates[talisman] = count
            end
        end
    end
    return duplicates
end

--- function to identify and return duplicate talismans within a hashmap
function Analyser.find_duplicates_within_hashmap(talisman_map)
    local all_duplicates = {}
    local seen = {}
    for _, talismans in pairs(talisman_map) do
        local duplicates = Analyser.find_duplicates(talismans)
        for talisman, count in pairs(duplicates) do
            if not seen[talisman] then
                seen[talisman] = true
                all_duplicates[talisman] = count
            end
        end
    end
    return all_duplicates
end

--- function to identify and return contradicting talismans
function Analyser.find_contradictions(talismans)
    local contradictions = {}
    for _, talisman in ipairs(talismans) do
        if talisman:has_skill_contradiction() then
            table.insert(contradictions, talisman)
        end
    end
    return contradictions
end

--- function to identify and return talismans with contradictions within a hashmap
function Analyser.find_contradictions_within_hashmap(talisman_map)
    local all_contradictions = {}
    local seen = {}
    for _, talismans in pairs(talisman_map) do
        local contradictions = Analyser.find_contradictions(talismans)
        for _, talisman in ipairs(contradictions) do
            if not seen[talisman] then
                seen[talisman] = true
                table.insert(all_contradictions, talisman)
            end
        end
    end
    return all_contradictions
end

return Analyser

