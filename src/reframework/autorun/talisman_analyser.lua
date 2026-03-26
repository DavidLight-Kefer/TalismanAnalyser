local Skill = require("talisman_analyser.skill")
local Slot = require("talisman_analyser.slot")
local SlotType = require("talisman_analyser.slot_type")
local Talisman = require("talisman_analyser.talisman")
local Parser = require("talisman_analyser.parser")
local Util = require("talisman_analyser.util")

local function printAll(talismans)
    for _, talisman in ipairs(talismans) do
        print(talisman)
    end
end

local function printDuplicates(talismans)
    local duplicates = Parser.findDuplicates(talismans)
    print("Found " .. Util.table_count(duplicates) .. " duplicated talismans:")
    for key, count in pairs(duplicates) do
        print(key .. " -> " .. count)
    end
end

local function printObsolete(talismans)
    local obsoleteMapping = Parser.findObsoleteTalismans(talismans)
    local amount = 0
    for _, talismanList in pairs(obsoleteMapping) do
        amount = amount + #talismanList
    end
    print("Found " .. amount .. " obsolete talismans:")
    for key, talismanList in pairs(obsoleteMapping) do
        local list_str = "{"
        for i, t in ipairs(talismanList) do
            if i > 1 then
                list_str = list_str .. ", "
            end
            list_str = list_str .. tostring(t)
        end
        list_str = list_str .. "}"
        print(key .. " -> " .. list_str)
    end
end

-- former main
local function analyse(talismans)
    --printAll(talismans)
    print()
    printDuplicates(talismans)
    print()
    printObsolete(talismans)
end

-- Talisman Data Export (By Ninull) --

local cachedMethods = {
    getSkillName = nil,
    getMsgWithLang = nil,
    initialized = false
}

local function initMethods()
    if cachedMethods.initialized then
        return true
    end

    local msgUtil = sdk.find_type_definition("app.MessageUtil")
    local guiMsg = sdk.find_type_definition("via.gui.message")

    if msgUtil and guiMsg then
        cachedMethods.getSkillName = msgUtil:get_method("getHunterSkillName(app.HunterDef.Skill)")
        cachedMethods.getMsgWithLang = guiMsg:get_method("get(System.Guid, via.Language)")
        cachedMethods.initialized = true
        return true
    end

    return false
end

local exportState = {
    running = false,
    phase = "idle",
    index = 0,
    total = 0,
    validCount = 0
}

local function countNonZeroSkills(skills)
    local count = 0
    for _, skill in ipairs(skills) do
        if skill ~= 0 then
            count = count + 1
        end
    end
    return count
end

local function decodeSlots(slots)
    local a1 = math.floor(slots / 1000) % 10
    local a2 = math.floor(slots / 100) % 10
    local a3 = math.floor(slots / 10) % 10
    local flag = slots % 10
    local hasWeapon = (flag == 1 or flag == 3)

    if hasWeapon then
        if flag == 3 then
            a1, a2, a3 = 0, 0, 0
        else
            a1, a2, a3 = a2, a3, 0
        end
    end
    return { a1, a2, a3 }, hasWeapon and 1 or 0
end

local function get_talismans()
    if not initMethods() then
        return
    end

    local manager = sdk.get_managed_singleton("app.SaveDataManager")
    if not manager then
        return
    end

    local saveData = manager:getCurrentUserSaveData()
    if not saveData or not saveData._Equip then
        return
    end

    local box = saveData._Equip._EquipBox
    if not box then
        return
    end

    local totalCount = box:get_Count()
    local count = math.min(totalCount, 2400)
    exportState.total = count
    exportState.index = 0
    exportState.validCount = 0
    exportState.running = true
    exportState.phase = "exporting"

    local talismans = {}

    for i = 0, count - 1 do
        exportState.index = i + 1

        local work = box:get_Item(i)
        if work and work:get_Category() == 2 then
            local customValues = work.BowgunCustomizeId
            if not customValues then
                goto continue
            end

            local skillRawValues = {
                customValues:get_Item(0),
                customValues:get_Item(1),
                customValues:get_Item(2)
            }
            local slot = customValues:get_Item(3)

            if countNonZeroSkills(skillRawValues) < 2 or not slot or slot < 0 then
                goto continue
            end

            local skills = {}
            for j = 1, 3 do
                if skillRawValues[j] ~= 0 then
                    local skillName = ""
                    local level = math.floor(skillRawValues[j] / 1000)
                    local enumVal = skillRawValues[j] % 1000
                    local skillEnum = cachedMethods.getSkillName:call(nil, enumVal)
                    if skillEnum then
                        skillName = cachedMethods.getMsgWithLang:call(nil, skillEnum, 1)
                        skillName = skillName and tostring(skillName) or ""
                    end
                    if string.len(skillName) ~= 0 then
                        table.insert(skills, Skill.new(skillName, level))
                    end
                end
            end

            local slots = {}
            local armorSlots, weaponSlot = decodeSlots(slot)
            for _, armorSlot in pairs(armorSlots) do
                table.insert(slots, Slot.new(SlotType.ARMOR, armorSlot))
            end
            if weaponSlot ~= 0 then
                table.insert(slots, Slot.new(SlotType.WEAPON, weaponSlot))
            end

            table.insert(talismans, Talisman.new(skills, slots))
            exportState.validCount = exportState.validCount + 1
        end
        :: continue ::
    end

    exportState.running = false
    exportState.phase = "idle"
    return talismans
end

re.on_draw_ui(function()
    if not imgui.tree_node("Talisman Data Export") then
        return
    end

    if not exportState.running then
        if imgui.button("Export Talismans") then
            local success, result = pcall(get_talismans)
            if success then
                analyse(result)
            else
                print(result)
                exportState.running = false
                exportState.phase = "idle"
            end
        end
    else
        if exportState.phase == "exporting" then
            local progress = exportState.index / exportState.total * 100
            imgui.text(string.format("Scanning: %d / %d (%.1f%%)", exportState.index, exportState.total, progress))
            imgui.text(string.format("Talismans Found: %d", exportState.validCount))
            imgui.progress_bar(progress / 100, 250, 20)
        end
    end

    imgui.tree_pop()
end)