local Decoder = require("talisman_analyser.decoder")
local Analyser = require("talisman_analyser.analyser")
local Util = require("talisman_analyser.util")

--- function to print all talismans
local function print_all(talismans)
    local count = 0
    local seen = {}
    for key, talisman_list in pairs(talismans) do
        for index, talisman in ipairs(talisman_list) do
            -- deduplicate
            if not seen[talisman] then
                seen[talisman] = true
                count = count + 1
                print(key .. "[" .. index .. "] -> " .. tostring(talisman))
            end
        end
    end
    print("Found " .. count .. " talismans")
end

--- function to print only duplicated talismans
local function print_duplicates(talismans)
    local duplicates = Analyser.find_duplicates_within_hashmap(talismans)
    print("Found " .. Util.count_map_entries(duplicates) .. " duplicated talismans:")
    for key, count in pairs(duplicates) do
        print(tostring(key) .. " -> " .. count)
    end
end

--- function to print only obsolete talismans
local function print_obsolete(talismans)
    local obsolete_mapping = Analyser.find_obsoletes_within_hashmap(talismans)
    local amount = 0
    for _, talisman_list in pairs(obsolete_mapping) do
        amount = amount + #talisman_list
    end
    print("Found " .. amount .. " obsolete talismans:")
    for key, talisman_list in pairs(obsolete_mapping) do
        local list_parts = {}
        for index, talisman in ipairs(talisman_list) do
            list_parts[index] = tostring(talisman)
        end
        print(tostring(key) .. " -> {" .. table.concat(list_parts, ", ") .. "}")
    end
end

--- function to add a "Script Generated UI" for this mod
re.on_draw_ui(function()
    if not imgui.tree_node("Talisman Analyser") then
        return
    end

    if imgui.button("Analyse Talismans") then
        local success, result = pcall(Decoder.get_talismans)
        if success then
            print_all(result)
            print()
            print_duplicates(result)
            print()
            print_obsolete(result)
        else
            print(result)
        end
    end

    imgui.tree_pop()
end)