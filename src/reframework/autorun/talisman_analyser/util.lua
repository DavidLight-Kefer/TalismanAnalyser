local Util = {}

function Util.table_count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return Util