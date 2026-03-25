local Talisman = {}
Talisman.__index = Talisman

function Talisman.new(skills, slots)
    local self = setmetatable({}, Talisman)
    self.skills = skills or {}
    self.slots = slots or {}
    return self
end

function Talisman:getSkills()
    return self.skills
end

function Talisman:getSlots()
    return self.slots
end

function Talisman:__eq(other)
    if not isinstance(other, Talisman) then
        return false
    end

    -- Check if other.skills is a subset of self.skills
    local other_skills_set = {}
    for _, skill in ipairs(other.skills) do
        other_skills_set[tostring(skill)] = skill
    end

    local self_skills_set = {}
    for _, skill in ipairs(self.skills) do
        self_skills_set[tostring(skill)] = skill
    end

    for key, _ in pairs(other_skills_set) do
        if not self_skills_set[key] then
            return false
        end
    end

    -- Check if slots are equal
    if #self.slots ~= #other.slots then
        return false
    end
    for i, slot in ipairs(self.slots) do
        if slot ~= other.slots[i] then
            return false
        end
    end

    return true
end

function Talisman:__tostring()
    local skills_str = "{"
    for i, skill in ipairs(self.skills) do
        if i > 1 then
            skills_str = skills_str .. ", "
        end
        skills_str = skills_str .. tostring(skill)
    end
    skills_str = skills_str .. "}"

    local slots_str = "{"
    for i, slot in ipairs(self.slots) do
        if i > 1 then
            slots_str = slots_str .. ", "
        end
        slots_str = slots_str .. tostring(slot)
    end
    slots_str = slots_str .. "}"

    return "Talisman{skills=" .. skills_str .. ", slots=" .. slots_str .. "}"
end

function isinstance(obj, class)
    while obj do
        if obj == class then
            return true
        end
        obj = getmetatable(obj)
        obj = obj and obj.__index
    end
    return false
end

return Talisman
