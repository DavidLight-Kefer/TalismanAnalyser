-- Talisman Data Export (By Ninull)
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

local function run_export()
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

    local exportString = ""

    for i = 0, count - 1 do
        exportState.index = i + 1

        local work = box:get_Item(i)
        if work and work:get_Category() == 2 then
            local customValues = work.BowgunCustomizeId
            if not customValues then
                goto continue
            end

            local skills = {
                customValues:get_Item(0),
                customValues:get_Item(1),
                customValues:get_Item(2)
            }
            local slot = customValues:get_Item(3)

            if countNonZeroSkills(skills) < 2 or not slot or slot < 0 then
                goto continue
            end

            local skillNames, skillPts = {}, {}
            for j = 1, 3 do
                if skills[j] == 0 then
                    skillNames[j], skillPts[j] = "", 0
                else
                    local level = math.floor(skills[j] / 1000)
                    local enumVal = skills[j] % 1000
                    local skillEnum = cachedMethods.getSkillName:call(nil, enumVal)
                    if skillEnum then
                        local skillName = cachedMethods.getMsgWithLang:call(nil, skillEnum, 1)
                        skillNames[j] = skillName and tostring(skillName) or "Unknown"
                    else
                        skillNames[j] = "Invalid"
                    end
                    skillPts[j] = level
                end
            end

            local armorSlots, weaponSlot = decodeSlots(slot)
            local a1 = armorSlots[1] or 0
            local a2 = armorSlots[2] or 0
            local a3 = armorSlots[3] or 0

            local line = string.format(
                    "%s,%d,%s,%d,%s,%d,%d,%d,%d,%d,0,0",
                    skillNames[1], skillPts[1],
                    skillNames[2], skillPts[2],
                    skillNames[3], skillPts[3],
                    a1, a2, a3, weaponSlot
            )

            exportString = exportString .. line .. "\n"
            exportState.validCount = exportState.validCount + 1
        end
        :: continue ::
    end

    local exportPath = string.format("Talisman Data Export.txt")
    fs.write(exportPath, exportString)
    exportState.running = false
    exportState.phase = "idle"
end

re.on_draw_ui(function()
    if not imgui.tree_node("Talisman Data Export") then
        return
    end

    if not exportState.running then
        if imgui.button("Export Talismans") then
            local success, _ = pcall(run_export)
            if not success then
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