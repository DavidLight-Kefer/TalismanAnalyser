local Util = require("talisman_analyser.util")

local Talisman = {}
Talisman.__index = Talisman

function Talisman.new(skills, slots)
    local self = setmetatable({}, Talisman)
    self.skills = skills or {}
    self.slots = slots or {}
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
    local skills_string = "{"
    for index, skill in ipairs(self.skills) do
        if index > 1 then
            skills_string = skills_string .. ", "
        end
        skills_string = skills_string .. tostring(skill)
    end
    skills_string = skills_string .. "}"

    local slots_string = "{"
    for index, slot in ipairs(self.slots) do
        if index > 1 then
            slots_string = slots_string .. ", "
        end
        slots_string = slots_string .. tostring(slot)
    end
    slots_string = slots_string .. "}"

    return "Talisman{skills=" .. skills_string .. ", slots=" .. slots_string .. "}"
end

return Talisman
