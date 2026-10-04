local Util = require("lib.util")

---@class Skill
---@field name string
---@field level integer
local Skill = {}
Skill.__index = Skill

---@param name string
---@param level integer
---@return Skill
function Skill.new(name, level)
    return setmetatable({
        name = name,
        level = level,
    } --[[@as Skill]], Skill)
end

function Skill:__eq(other)
    if not Util.is_instance(other, Skill) then
        return false
    end
    return self.level == other.level and self.name == other.name
end

function Skill:__tostring()
    return self.name .. " Lv" .. self.level
end

return Skill
