local Slot = {}
Slot.__index = Slot

function Slot.new(slot_type, rank)
    local self = setmetatable({}, Slot)
    self.slot_type = slot_type
    self.rank = rank
    return self
end

function Slot:getType()
    return self.slot_type
end

function Slot:getRank()
    return self.rank
end

function Slot:__eq(other)
    if not isinstance(other, Slot) then
        return false
    end
    return self.rank == other.rank and self.slot_type == other.slot_type
end

function Slot:__tostring()
    return "Slot{type=" .. self.slot_type .. ", rank=" .. self.rank .. "}"
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

return Slot
