local Util = {}

--- utility function to count the entries of a map
function Util.count_map_entries(map)
    local count = 0
    for _ in pairs(map) do
        count = count + 1
    end
    return count
end

--- utility function to check if object is an instance of class
function Util.is_instance(object, class)
    local metatable = getmetatable(object)
    while metatable do
        if metatable == class or metatable.__index == class then
            return true
        end
        metatable = getmetatable(metatable.__index)
    end
    return false
end

--- function to find the index of an unmatched item in other_list that is equal to item, marking it as matched
local function find_unmatched_index(other_list, matched, item)
    for index, other_item in ipairs(other_list) do
        if not matched[index] and item == other_item then
            return index
        end
    end
    return nil
end

--- utility function to check if two lists have equal items
function Util.list_has_equal_items(list, other_list)
    if #list ~= #other_list then
        return false
    end

    local matched = {}
    for _, item in ipairs(list) do
        local index = find_unmatched_index(other_list, matched, item)
        if not index then
            return false
        end
        matched[index] = true
    end
    return true
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

--- utility function to find the first index of a value in a list
function Util.index_of(list, value)
    for i, v in ipairs(list) do
        if v == value then
            return i
        end
    end
end

return Util