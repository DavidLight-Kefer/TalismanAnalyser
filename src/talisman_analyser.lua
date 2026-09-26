local Decoder = require("lib.decoder")
local Analyser = require("lib.analyser")
local Skill = require("lib.skill")
local slot_lib = require("lib.slot")
local Slot = slot_lib.Slot
local SlotType = slot_lib.Type
local Talisman = require("lib.talisman")
local Util = require("lib.util")

local IMGUI_TABLE_FLAG_BORDERS = 1920
local IMGUI_TABLE_FLAG_FIT_WIDTH = 8192
local ABGR_RED = 0xFF0000FF
local ABGR_YELLOW = 0xFF00FFFF
local TALISMAN_MELDING_TYPE_DEFINITION_NAME = "app.GUI090700"
local APPRAISAL_BOX_AFTER_MELDING_TYPE_DEFINITION_NAME = "app.GUI090002"
local PARTS_MATERIAL_LIST_02_TYPE_DEFINITION_NAME = "app.GUI090700PartsMaterialList02"
local SELECT_ITEM_TYPE_DEFINITION = "via.gui.SelectItem"

local talismans_data
local cached_all_output
local cached_duplicate_output
local cached_obsolete_output
local cached_contradiction_output
local cached_material_list
local force_slot_comparison = true
local is_auto_select = false
local debug = false
local cached_duplicated_auto_select_result = ""
local cached_obsolete_auto_select_result = ""
local cached_contradicting_auto_select_result = ""

local window_states = {
    all_talismans = false,
    duplicated_talismans = false,
    obsolete_talismans = false,
    contradicting_talismans = false,
}

--- auxiliary function to log only if `debug` is enabled, a global `log.set_level("debug")` could lead to log spam
local function log_if_debug(message)
    if debug then
        log.info(message)
    end
end

local function update_talisman_data()
    local success, result = pcall(Decoder.get_talismans)
    if success then
        talismans_data = result
        -- Clear the cache when data changes
        cached_all_output = nil
        cached_duplicate_output = nil
        cached_obsolete_output = nil
        cached_contradiction_output = nil
        cached_material_list = nil
        cached_duplicated_auto_select_result = ""
        cached_obsolete_auto_select_result = ""
        cached_contradicting_auto_select_result = ""
        return true
    else
        log.error(result)
        return false
    end
end

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

--- function to auto-select the given talismans at the melding pot
local function auto_select(talismans_to_meld)
    local to_meld_amount = #talismans_to_meld
    log_if_debug("Trying to auto-select " .. to_meld_amount .. " talismans")
    if not cached_material_list then
        return "Not in the Talisman Melding menu!"
    end
    local success, result = pcall(function()
        return cached_material_list._amuletDataList._items
    end)
    if not success then
        log.error(result)
        return "Could not get talisman material list, please try again!"
    end
    local talisman_list = result
    success, result = pcall(function()
        return cached_material_list:get__PageControl()
    end)
    if not success then
        log.error(result)
        return "Could not get page control of talisman material list, please try again!"
    end
    local page_control = result
    success, result = pcall(function()
        local page_index = page_control:getCurrentPage() * page_control:get_ItemNumOnPage()
        page_control:setPageFromIndex(0)
        return page_index
    end)
    if not success then
        log.error(result)
        return "Could not get page of talisman material list, please try again!"
    end
    local original_page_index = result

    local unselected_amount = 0
    local not_select_reasons = {}
    is_auto_select = true
    for index, talisman_data in pairs(talisman_list) do -- starts with 0, don't use ipairs()
        local judge_result_data = talisman_data.JudgeResultData
        local skill_object = {}
        for _, skill in pairs(judge_result_data.Skills) do -- starts with 0, don't use ipairs()
            local decoder_methods = Decoder.get_cached_methods()
            local skill_enum = decoder_methods.get_skill_name:call(nil, skill.Skill)
            local skill_name = ""
            if skill_enum then
                skill_name = decoder_methods.get_gui_message_with_language:call(nil, skill_enum, 1)
                skill_name = skill_name and tostring(skill_name) or ""
            end
            -- ignore empty names and other objects (starting with "<")
            if string.len(skill_name) > 0 and string.sub(skill_name, 1, 1) ~= "<" then
                table.insert(skill_object, Skill.new(skill_name, skill.Lv))
            end
        end
        local slot_object = {}
        for _, slot in pairs(judge_result_data.Accessories) do -- starts with 0, don't use ipairs()
            local slot_level = slot.SlotLv
            if slot_level > 0 then
                table.insert(slot_object, Slot.new(SlotType.type_from_number(slot.AccessoryType), slot_level))
            end
        end
        local talisman_object = Talisman.new(skill_object, slot_object)
        if Util.table_contains(talismans_to_meld, talisman_object) then
            local is_favorite = talisman_data:get_AmuletWork():isFavorite()
            local is_equipped = talisman_data.IsFitting
            local is_chosen = talisman_data.IsChoose
            local selected, error
            if not (is_favorite or is_equipped or is_chosen) then
                selected, error = pcall(function()
                    local select_item = sdk.find_type_definition(SELECT_ITEM_TYPE_DEFINITION):create_instance()
                    select_item:set_ListIndex(index)
                    select_item:set_CanSelect(true)
                    select_item:set_CanDecide(true)
                    cached_material_list:callbackDecide(cached_material_list._Control, select_item, index)
                end)
            else
                selected = false
                if is_favorite then
                    table.insert(not_select_reasons, tostring(talisman_object) .. " is a favorite")
                elseif is_equipped then
                    table.insert(not_select_reasons, tostring(talisman_object) .. " is currently equipped")
                elseif is_chosen then
                    table.insert(not_select_reasons, tostring(talisman_object) .. " was already selected")

                end
            end
            if not selected then
                log_if_debug("Could not select talisman (" .. tostring(talisman_object) .. "), index=" .. index ..
                        ", is_favorite=" .. tostring(is_favorite) .. ", is_equipped=" .. tostring(is_equipped) .. ", is_chosen=" ..
                        tostring(is_chosen) .. ", error=" .. tostring(error))
                unselected_amount = unselected_amount + 1
                if error then
                    table.insert(not_select_reasons, tostring(talisman_object) .. " caused an error") -- can be ignored
                end
            end
            table.remove(talismans_to_meld, Util.index_of(talismans_to_meld, talisman_object))
        end
    end

    success, result = pcall(function()
        -- if the player was on page 0 change the page once to force UI update
        local items_per_page = page_control:get_ItemNumOnPage()
        if original_page_index < items_per_page and page_control:get__MaxElementNum() > items_per_page then
            page_control:setPageFromIndex(items_per_page)
        end
        page_control:setPageFromIndex(original_page_index)
    end)
    if not success then
        log.error("Resetting the page failed: original_page_index=" .. original_page_index .. ", error=" .. result)
    end
    is_auto_select = false
    cached_material_list = nil -- to have a fresh snapshot the next time
    local status_message = string.format("Auto-selected %d talismans, %d were not selected:", to_meld_amount - unselected_amount, unselected_amount)
    for _, reason in ipairs(not_select_reasons) do
        status_message = status_message .. "\n" .. reason
    end
    return status_message
end

--- hook to get the material list and its page control from "Talisman Melding"
sdk.hook(sdk.find_type_definition(PARTS_MATERIAL_LIST_02_TYPE_DEFINITION_NAME):get_method("onVisibleUpdate"), function(args)
    if not cached_material_list then
        cached_material_list = sdk.to_managed_object(args[2])
    end
end)

--- hook to handle sorting during "Talisman Melding"
sdk.hook(sdk.find_type_definition(PARTS_MATERIAL_LIST_02_TYPE_DEFINITION_NAME):get_method("applySort"), function(args)
    cached_material_list = nil -- to have a fresh snapshot with the new indices
end)

--- hook to handle manual selecting during "Talisman Melding"
sdk.hook(sdk.find_type_definition(PARTS_MATERIAL_LIST_02_TYPE_DEFINITION_NAME):get_method("callbackDecide"), function(args)
    if not is_auto_select then
        cached_material_list = nil -- to have a fresh snapshot after a manual selecting
    end
end)

--- hook to handle favoritizing during "Talisman Melding"
sdk.hook(sdk.find_type_definition(PARTS_MATERIAL_LIST_02_TYPE_DEFINITION_NAME):get_method("switchFavorite"), function(args)
    cached_material_list = nil -- to have a fresh snapshot after favorite status change
end)

--- hook to reset the auto-selection cache after "Talisman Melding"
sdk.hook(sdk.find_type_definition(TALISMAN_MELDING_TYPE_DEFINITION_NAME):get_method("onClose"), function(args)
    cached_material_list = nil
    cached_duplicated_auto_select_result = ""
    cached_obsolete_auto_select_result = ""
    cached_contradicting_auto_select_result = ""
end)

--- hook to reset the data cache after some talismans were melded into new ones
sdk.hook(sdk.find_type_definition(APPRAISAL_BOX_AFTER_MELDING_TYPE_DEFINITION_NAME):get_method("onClose"), function(args)
    update_talisman_data()
end)

--- function to add a "Script Generated UI" for this mod
re.on_draw_ui(function()
    if not imgui.tree_node("Talisman Analyser") then
        return
    end

    local changed, value = imgui.checkbox("Debug", debug)
    if changed then
        debug = value
    end
    local analyser_button_text = talismans_data and "Re-Analyse Talismans" or "Analyse Talismans"
    if imgui.button(analyser_button_text) then
        if not update_talisman_data() then
            imgui.text_colored("Could not analyse talismans, please try again!", ABGR_RED)
        end
    end
    if not talismans_data then
        imgui.begin_disabled()
    end
    if imgui.button("Show All Talismans") then
        window_states.all_talismans = not window_states.all_talismans
    end
    if imgui.button("Show Duplicated Talismans") then
        window_states.duplicated_talismans = not window_states.duplicated_talismans
    end
    if imgui.button("Show Obsolete Talismans") then
        window_states.obsolete_talismans = not window_states.obsolete_talismans
    end
    if imgui.button("Show Contradicting Talismans") then
        window_states.contradicting_talismans = not window_states.contradicting_talismans
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
            imgui.spacing()
            if imgui.button("Select for Melding") then
                local duplicates = {}
                for talisman, count in pairs(Analyser.find_duplicates_within_hashmap(talismans_data)) do
                    -- leave 1 of each
                    for _ = 1, count - 1 do
                        table.insert(duplicates, talisman)
                    end
                end
                cached_duplicated_auto_select_result = auto_select(duplicates)
            end
            imgui.text_colored(cached_duplicated_auto_select_result, ABGR_YELLOW)
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
                imgui.set_tooltip("If enabled Slots must always be better or equal, otherwise Slots are only compared when Skills are equal")
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
            if imgui.button("Select for Melding") then
                local obsoletes = {}
                for _, talismanList in pairs(Analyser.find_obsoletes_within_hashmap(talismans_data, force_slot_comparison)) do
                    for _, talisman in ipairs(talismanList) do
                        table.insert(obsoletes, talisman)
                    end
                end
                cached_obsolete_auto_select_result = auto_select(obsoletes)
            end
            imgui.text_colored(cached_obsolete_auto_select_result, ABGR_YELLOW)
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
            if imgui.button("Select for Melding") then
                cached_contradicting_auto_select_result = auto_select(Analyser.find_contradictions_within_hashmap(talismans_data))
            end
            imgui.text_colored(cached_contradicting_auto_select_result, ABGR_YELLOW)
            imgui.end_window()
        end
    end
end)
