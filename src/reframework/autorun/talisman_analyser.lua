local Decoder = require("talisman_analyser.decoder")
local Analyser = require("talisman_analyser.analyser")
local Util = require("talisman_analyser.util")

--- function to print all talismans
local function print_all(talismans)
    print("Found " .. #talismans .. " talismans:")
    for _, talisman in ipairs(talismans) do
        print(talisman)
    end
end

--- function to print only duplicated talismans
local function print_duplicates(talismans)
    local duplicates = Analyser.find_duplicates(talismans)
    print("Found " .. Util.count_map_entries(duplicates) .. " duplicated talismans:")
    for key, count in pairs(duplicates) do
        print(tostring(key) .. " -> " .. count)
    end
end

--- function to print only obsolete talismans
local function print_obsolete(talismans)
    local obsolete_mapping = Analyser.find_obsolete_talismans(talismans)
    local amount = 0
    for _, talisman_list in pairs(obsolete_mapping) do
        amount = amount + #talisman_list
    end
    print("Found " .. amount .. " obsolete talismans:")
    for key, talisman_list in pairs(obsolete_mapping) do
        local list_string = "{"
        for index, talisman in ipairs(talisman_list) do
            if index > 1 then
                list_string = list_string .. ", "
            end
            list_string = list_string .. tostring(talisman)
        end
        list_string = list_string .. "}"
        print(tostring(key) .. " -> " .. list_string)
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