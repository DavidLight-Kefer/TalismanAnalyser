local Skill = require("talisman_analyser.skill")
local Slot = require("talisman_analyser.slot")
local SlotType = require("talisman_analyser.slot_type")
local Talisman = require("talisman_analyser.talisman")
local Util = require("talisman_analyser.util")

local Parser = {}

function Parser.parseFile(filePath)
    local talismans = {}
    local file, _ = io.open(filePath, "r")
    if not file then
        error("File not found: " .. filePath)
    end

    for line in file:lines() do
        table.insert(talismans, Parser.parseLine(line))
    end
    file:close()

    return talismans
end

function Parser.parseLine(line)
    local values = {}
    for value in line:gmatch("[^,]*") do
        table.insert(values, value)
    end

    if #values ~= 12 then
        error("Invalid number of fields: " .. #values)
    end

    local skills = {}
    local slots = {}

    -- Parse skills (first 6 values)
    for i = 1, 6, 2 do
        if values[i] ~= "" then
            table.insert(skills, Skill.new(values[i], tonumber(values[i + 1])))
        end
    end

    -- Parse slots (last 6 values)
    for i = 7, 12 do
        local rank = tonumber(values[i])
        if rank ~= 0 then
            if i < 10 then
                table.insert(slots, Slot.new(SlotType.ARMOR, rank))
            else
                table.insert(slots, Slot.new(SlotType.WEAPON, rank))
            end
        end
    end

    return Talisman.new(skills, slots)
end

function Parser.findDuplicates(talismans)
    if not talismans or #talismans == 0 then
        return {}
    end

    local counts = {}
    local duplicates = {}

    for _, t in ipairs(talismans) do
        local key = tostring(t)
        counts[key] = (counts[key] or 0) + 1
    end

    for key, count in pairs(counts) do
        if count > 1 then
            duplicates[key] = count
        end
    end

    return duplicates
end

function Parser.findObsoleteTalismans(talismans)
    if not talismans or #talismans == 0 then
        return {}
    end

    local obsoleteMapping = {}

    for i = 1, #talismans do
        local candidate = talismans[i]
        for j = 1, #talismans do
            if i ~= j then
                local maybeObsolete = talismans[j]
                if Parser.makesObsolete(candidate, maybeObsolete) then
                    local key = tostring(candidate)
                    if not obsoleteMapping[key] then
                        obsoleteMapping[key] = {}
                    end
                    table.insert(obsoleteMapping[key], maybeObsolete)
                end
            end
        end
    end

    return obsoleteMapping
end

function Parser.makesObsolete(candidate, maybeObsolete)
    local candidateSkills = Parser.toSkillLevelMap(candidate:getSkills())
    local obsoleteSkills = Parser.toSkillLevelMap(maybeObsolete:getSkills())

    local hasSkillImprovement = false
    for skillName, level in pairs(obsoleteSkills) do
        local candidateLevel = candidateSkills[skillName]
        if not candidateLevel or candidateLevel < level then
            return false
        end
        if candidateLevel > level then
            hasSkillImprovement = true
        end
    end

    local hasExtraSkills = Util.table_count(candidateSkills) > Util.table_count(obsoleteSkills)

    if hasSkillImprovement or hasExtraSkills then
        return true
    end

    -- Skills are exactly equal — break the tie with slots
    return Parser.slotsDominate(candidate, maybeObsolete)
end

function Parser.toSkillLevelMap(skills)
    local skillLevels = {}
    for _, skill in ipairs(skills) do
        local name = skill:getName()
        if not skillLevels[name] then
            skillLevels[name] = skill:getLevel()
        else
            skillLevels[name] = math.max(skillLevels[name], skill:getLevel())
        end
    end
    return skillLevels
end

function Parser.slotsDominate(candidate, maybeObsolete)
    local weaponCmp = Parser.compareSlotRanks(candidate, maybeObsolete, SlotType.WEAPON)
    local armorCmp = Parser.compareSlotRanks(candidate, maybeObsolete, SlotType.ARMOR)

    if weaponCmp < 0 or armorCmp < 0 then
        return false
    end
    return weaponCmp > 0 or armorCmp > 0
end

function Parser.compareSlotRanks(candidate, maybeObsolete, slot_type)
    local candidateRanks = Parser.getSortedRanks(candidate, slot_type)
    local obsoleteRanks = Parser.getSortedRanks(maybeObsolete, slot_type)

    if #candidateRanks < #obsoleteRanks then
        return -1
    end

    local hasImprovement = #candidateRanks > #obsoleteRanks

    for i = 1, #obsoleteRanks do
        if candidateRanks[i] < obsoleteRanks[i] then
            return -1
        end
        if candidateRanks[i] > obsoleteRanks[i] then
            hasImprovement = true
        end
    end

    return hasImprovement and 1 or 0
end

function Parser.getSortedRanks(talisman, slot_type)
    local ranks = {}
    for _, slot in ipairs(talisman:getSlots()) do
        if slot:getType() == slot_type then
            table.insert(ranks, slot:getRank())
        end
    end

    -- Sort in descending order
    table.sort(ranks, function(a, b)
        return a > b
    end)
    return ranks
end

return Parser
