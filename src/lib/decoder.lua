local Skill = require("lib.skill")
local slot_lib = require("lib.slot")
local Slot = slot_lib.Slot
local SlotType = slot_lib.Type
local Talisman = require("lib.talisman")

-- Talisman Data Export by Ninull (adjusted) --
local Decoder = {}

local cached_methods = {
    get_skill_name = nil,
    get_gui_message_with_language = nil,
    initialized = false
}

local function init_methods()
    if cached_methods.initialized then
        return true
    end

    local message_util = sdk.find_type_definition("app.MessageUtil")
    local gui_message = sdk.find_type_definition("via.gui.message")
    if message_util and gui_message then
        cached_methods.get_skill_name = message_util:get_method("getHunterSkillName(app.HunterDef.Skill)")
        cached_methods.get_gui_message_with_language = gui_message:get_method("get(System.Guid, via.Language)")
        cached_methods.initialized = true
        return true
    end
    return false
end

local function count_non_zero_skills(skills)
    local count = 0
    for _, skill in ipairs(skills) do
        if skill ~= 0 then
            count = count + 1
        end
    end
    return count
end

local function decode_slots(slots)
    local a1 = math.floor(slots / 1000) % 10
    local a2 = math.floor(slots / 100) % 10
    local a3 = math.floor(slots / 10) % 10
    local flag = slots % 10
    local has_weapon = (flag == 1 or flag == 3)
    if has_weapon then
        if flag == 3 then
            a1, a2, a3 = 0, 0, 0
        else
            a1, a2, a3 = a2, a3, 0
        end
    end
    return { a1, a2, a3 }, has_weapon and 1 or 0
end

function Decoder.get_talismans()
    if not init_methods() then
        return {}
    end
    local manager = sdk.get_managed_singleton("app.SaveDataManager")
    if not manager then
        return {}
    end
    local save_data = manager:getCurrentUserSaveData()
    if not save_data or not save_data._Equip then
        return {}
    end
    local box = save_data._Equip._EquipBox
    if not box then
        return {}
    end

    local total_count = box:get_Count()
    local count = math.min(total_count, 2400)
    local talisman_map = {}
    for i = 0, count - 1 do
        local work = box:get_Item(i)
        if work and work:get_Category() == 2 then
            local custom_values = work.BowgunCustomizeId
            if not custom_values then
                goto continue
            end
            local skill_raw_values = {
                custom_values:get_Item(0),
                custom_values:get_Item(1),
                custom_values:get_Item(2)
            }
            local slot = custom_values:get_Item(3)

            if count_non_zero_skills(skill_raw_values) < 2 or not slot or slot < 0 then
                goto continue
            end

            local skills = {}
            for j = 1, 3 do
                if skill_raw_values[j] ~= 0 then
                    local skill_name = ""
                    local level = math.floor(skill_raw_values[j] / 1000)
                    local enum_val = skill_raw_values[j] % 1000
                    local skill_enum = cached_methods.get_skill_name:call(nil, enum_val)
                    if skill_enum then
                        skill_name = cached_methods.get_gui_message_with_language:call(nil, skill_enum, 1)
                        skill_name = skill_name and tostring(skill_name) or ""
                    end
                    if string.len(skill_name) ~= 0 then
                        table.insert(skills, Skill.new(skill_name, level))
                    end
                end
            end

            local slots = {}
            local armor_slots, weapon_slot = decode_slots(slot)
            for _, armor_slot in pairs(armor_slots) do
                if armor_slot ~= 0 then
                    table.insert(slots, Slot.new(SlotType.ARMOR, armor_slot))
                end
            end
            if weapon_slot ~= 0 then
                table.insert(slots, Slot.new(SlotType.WEAPON, weapon_slot))
            end

            local talisman = Talisman.new(skills, slots)
            -- talisman_map is a skill-based grouping of all talismans to allow quick lookup of talismans by their skills
            for _, skill in ipairs(skills) do
                if not talisman_map[skill.name] then
                    talisman_map[skill.name] = {}
                end
                table.insert(talisman_map[skill.name], talisman)
            end

            :: continue ::
        end
    end

    return talisman_map
end

function Decoder.get_cached_methods()
    return cached_methods
end

return Decoder
