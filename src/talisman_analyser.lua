local Decoder = require("lib.decoder")
local Analyser = require("lib.analyser")
local Util = require("lib.util")

local talismans_data
local cached_all_output
local cached_duplicate_output
local cached_obsolete_output
local force_slot_comparison = true
local cached_contradiction_output

local window_states = {
    all_talismans = false,
    duplicated_talismans = false,
    obsolete_talismans = false
}

local IMGUI_TABLE_FLAG_BORDERS = 1920
local IMGUI_TABLE_FLAG_FIT_WIDTH = 8192

--- function to generate output for all talismans
local function generate_all_output(talismans)
    local result = {}
    local count = 0
    local seen = {}
    for _, talisman_list in pairs(talismans) do
        for _, talisman in ipairs(talisman_list) do
            -- deduplication skips some indexes!
            if not seen[talisman] then
                seen[talisman] = true
                count = count + 1
                table.insert(result, tostring(talisman))
            end
        end
    end
    table.insert(result, 1, "Found " .. count .. " talismans:")
    return result
end

--- function to generate output for duplicated talismans
local function generate_duplicate_output(talismans)
    local result = {}
    local duplicates = Analyser.find_duplicates_within_hashmap(talismans)
    table.insert(result, "These " .. Util.count_map_entries(duplicates) .. " talismans are duplicated:")
    for key, count in pairs(duplicates) do
        table.insert(result, { tostring(key), count })
    end
    return result
end

--- function to generate output for obsolete talismans
local function generate_obsolete_output(talismans)
    local obsolete_mapping = Analyser.find_obsoletes_within_hashmap(talismans, force_slot_comparison)
    local amount = 0
    local result = {}
    for _, talisman_list in pairs(obsolete_mapping) do
        amount = amount + #talisman_list
    end
    table.insert(result, "These talismans obsolete " .. amount .. " other (expand to view obsoletes): ")
    for key, talisman_list in pairs(obsolete_mapping) do
        local list_parts = {}
        for index, talisman in ipairs(talisman_list) do
            list_parts[index] = tostring(talisman)
        end
        table.insert(result, { tostring(key), list_parts })
    end
    return result
end

--- function to generate output for contradicting talismans
local function generate_contradiction_output(talismans)
    local result = {}
    local contradictions = Analyser.find_contradictions_within_hashmap(talismans)
    table.insert(result, "These " .. #contradictions .. " talismans are contradicting:")
    for _, talisman in ipairs(contradictions) do
        table.insert(result, tostring(talisman))
    end
    return result
end

--- function to add a "Script Generated UI" for this mod
re.on_draw_ui(function()
    if not imgui.tree_node("Talisman Analyser") then
        return
    end

    local analyser_button_text = talismans_data and "Re-Analyse Talismans" or "Analyse Talismans"
    if imgui.button(analyser_button_text) then
        local success, result = pcall(Decoder.get_talismans)
        if success then
            talismans_data = result
            -- Clear the cache when data changes
            cached_all_output = nil
            cached_duplicate_output = nil
            cached_obsolete_output = nil
            cached_contradiction_output = nil
        else
            imgui.text_colored(result, 0xFF0000FF) -- error message in RGBA red
        end
    end
    if not talismans_data then
        imgui.begin_disabled()
    end
    if imgui.button("Show All Talismans") then
        window_states.all_talismans = true
    end
    if imgui.button("Show Duplicated Talismans") then
        window_states.duplicated_talismans = true
    end
    if imgui.button("Show Obsolete Talismans") then
        window_states.obsolete_talismans = true
    end
    if imgui.button("Show Contradicting Talismans") then
        window_states.contradicting_talismans = true
    end
    if not talismans_data then
        imgui.end_disabled()
    end

    imgui.tree_pop()
end)

re.on_frame(function()
    if talismans_data then
        -- All Talismans Window
        if window_states.all_talismans then
            window_states.all_talismans = imgui.begin_window("All Talismans", true, nil)
            if not cached_all_output then
                cached_all_output = generate_all_output(talismans_data)
            end
            imgui.text(cached_all_output[1])
            imgui.spacing()
            for i = 2, #cached_all_output do
                imgui.text(cached_all_output[i])
            end
            imgui.end_window()
        end
        -- Duplicated Talismans Window
        if window_states.duplicated_talismans then
            window_states.duplicated_talismans = imgui.begin_window("Duplicated Talismans", true, nil)
            if not cached_duplicate_output then
                cached_duplicate_output = generate_duplicate_output(talismans_data)
            end
            imgui.text(cached_duplicate_output[1])
            imgui.spacing()
            imgui.begin_table("##duplicatedTalismansTable", 2, IMGUI_TABLE_FLAG_BORDERS | IMGUI_TABLE_FLAG_FIT_WIDTH)
            imgui.table_setup_column("Talisman")
            imgui.table_setup_column("Owned")
            imgui.table_headers_row()
            for i = 2, #cached_duplicate_output do
                imgui.table_next_column()
                imgui.text(cached_duplicate_output[i][1])
                imgui.table_next_column()
                imgui.text(cached_duplicate_output[i][2])
                imgui.table_next_row()
            end
            imgui.end_table()
            imgui.end_window()
        end
        -- Obsolete Talismans Window
        if window_states.obsolete_talismans then
            window_states.obsolete_talismans = imgui.begin_window("Obsolete Talismans", true, nil)
            if not cached_obsolete_output then
                cached_obsolete_output = generate_obsolete_output(talismans_data)
            end
            local changed, value = imgui.checkbox("Always compare Slots", force_slot_comparison)
            if changed then
                force_slot_comparison = value
                cached_obsolete_output = generate_obsolete_output(talismans_data)
            end
            imgui.same_line()
            imgui.text("(?)")
            if imgui.is_item_hovered() then
                imgui.set_tooltip(
                    "If enabled Slots must always be better or equal, otherwise Slots are only compared when Skills are equal")
            end
            imgui.spacing()
            imgui.text(cached_obsolete_output[1])
            imgui.spacing()
            for i = 2, #cached_obsolete_output do
                if imgui.tree_node(cached_obsolete_output[i][1]) then
                    for _, obsolete in ipairs(cached_obsolete_output[i][2]) do
                        imgui.text(obsolete)
                    end
                    imgui.tree_pop()
                end
                imgui.spacing()
            end
            imgui.end_window()
        end
        -- Contradicting Talismans Window
        if window_states.contradicting_talismans then
            window_states.contradicting_talismans = imgui.begin_window("Contradicting Talismans", true, nil)
            if not cached_contradiction_output then
                cached_contradiction_output = generate_contradiction_output(talismans_data)
            end
            imgui.text(cached_contradiction_output[1])
            imgui.spacing()
            for i = 2, #cached_contradiction_output do
                imgui.text(cached_contradiction_output[i])
            end
            imgui.end_window()
        end
    end
end)
