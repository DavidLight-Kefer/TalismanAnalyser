local Util = require("talisman_analyser.util")

local Slot = {}
Slot.__index = Slot

function Slot.new(type, rank)
    local self = setmetatable({}, Slot)
    self.type = type
    self.rank = rank
    return self
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

local Type = {
    ARMOR = "ARMOR",
    WEAPON = "WEAPON"
}

--- function to get a Slot-Type based on it's in-game enum (0 == WEAPON, 1 == ARMOR)
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