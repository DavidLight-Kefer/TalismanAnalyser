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

--- function to get a Slot-Type based on it's in-game enum (0 == WEAPON, 1 == ARMOR)
---@param number integer
function Type.type_from_number(number)
    if number == 0 then
        return Type.WEAPON
    end
    if number == 1 then
        return Type.ARMOR
    end
    error("invalid type number")
end

return {
    Slot = Slot,
    Type = Type
}

