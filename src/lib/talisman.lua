local Util = require("lib.util")
local SkillsIncompatibility = require("lib.skills_incompatibility")

---@class Talisman
---@field id integer
---@field skills Skill[]
---@field slots Slot[]
local Talisman = {}
Talisman.__index = Talisman

local _next_id = 0

---@param skills Skill[]
---@param slots Slot[]
---@return Talisman
function Talisman.new(skills, slots)
    local self = setmetatable({
        id = _next_id,
        skills = skills or {},
        slots = slots or {},
    }, Talisman)
    _next_id = _next_id + 1
    return self
end

function Talisman:__eq(other)
    if not Util.is_instance(other, Talisman) then
        return false
    end

    if not other.skills or not Util.list_has_equal_items(self.skills, other.skills) then
        return false
    end
    if not other.slots or not Util.list_has_equal_items(self.slots, other.slots) then
        return false
    end
    return true
end

function Talisman:__tostring()
    local skill_parts = {}
    for index, skill in ipairs(self.skills) do
        skill_parts[index] = tostring(skill)
    end
    local slot_parts = {}
    for index, slot in ipairs(self.slots) do
        slot_parts[index] = tostring(slot)
    end
    return "Skills = { " .. table.concat(skill_parts, ", ") .. " }, Slots = { " .. table.concat(slot_parts, ", ") .. " }"
end

function Talisman:has_skill_contradiction()
    for i, skill in ipairs(self.skills) do
        if SkillsIncompatibility[skill.name] then
            for j = i + 1, #self.skills do
                if Util.table_contains(SkillsIncompatibility[skill.name], self.skills[j].name) then
                    return true
                end
            end
        end
    end
    return false
end

return Talisman
