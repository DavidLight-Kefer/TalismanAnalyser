local Util = require("lib.util")

---@class Slot
---@field type Type
---@field rank integer
local Slot = {}
Slot.__index = Slot

---@param type Type
---@param rank integer
function Slot.new(type, rank)
    return setmetatable({
        type = type,
        rank = rank,
    } --[[@as Slot]], Slot)
end

function Slot:__eq(other)
    if not Util.is_instance(other, Slot) then
        return false
    end
    return self.rank == other.rank and self.type == other.type
end

function Slot:__tostring()
    return self.type .. " " .. self.rank
end

---@enum Type
local Type = {
    ARMOR = "ARMOR",
    WEAPON = "WEAPON"
}

return {
    Slot = Slot,
    Type = Type
}

