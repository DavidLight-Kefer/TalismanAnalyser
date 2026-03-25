local Skill = {}
Skill.__index = Skill

function Skill.new(name, level)
    local self = setmetatable({}, Skill)
    self.name = name
    self.level = level
    return self
end

function Skill:getName()
    return self.name
end

function Skill:getLevel()
    return self.level
end

function Skill:__eq(other)
    if not isinstance(other, Skill) then
        return false
    end
    return self.level == other.level and self.name == other.name
end

function Skill:__tostring()
    return "Skill{name='" .. self.name .. "', level=" .. self.level .. "}"
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

return Skill
