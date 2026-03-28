local Util = require("talisman_analyser.util")

local Skill = {}
Skill.__index = Skill

function Skill.new(name, level)
    local self = setmetatable({}, Skill)
    self.name = name
    self.level = level
    return self
end

function Skill:__eq(other)
    if not Util.is_instance(other, Skill) then
        return false
    end
    return self.level == other.level and self.name == other.name
end

function Skill:__tostring()
    return "Skill{name='" .. self.name .. "', level=" .. self.level .. "}"
end

return Skill
