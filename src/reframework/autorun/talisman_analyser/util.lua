local Util = {}

--- utility function to count the entries of a map
function Util.count_map_entries(map)
    local count = 0
    for _ in pairs(map) do
        count = count + 1
    end
    return count
end

--- utility function to check if a table contains a specific value
function Util.table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--- utility function to check if object is an instance of class
function Util.is_instance(object, class)
    while object do
        if object == class then
            return true
        end
        object = getmetatable(object)
        object = object and object.__index
    end
    return false
end

--- utility function to check if two lists have equal items
function Util.list_has_equal_items(list, other_list)
    if #list ~= #other_list then
        return false
    end

    for _, item in ipairs(list) do
        if not Util.table_contains(other_list, item) then
            return false
        end
    end
    for _, item in ipairs(other_list) do
        if not Util.table_contains(list, item) then
            return false
        end
    end
    return true
end

return Util