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
    return "Slot{type=" .. self.type .. ", rank=" .. self.rank .. "}"
end

return Slot
