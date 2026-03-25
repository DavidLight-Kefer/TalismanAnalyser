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

local languageSettings = {
    currentIndex = 1,
    names = {"English", "日本語", "한국어", "繁體中文", "简体中文"},
    ids = {1, 0, 11, 12, 13},  -- 修正：英文=1, 日文=0
    languageCodes = {"en", "ja", "ko", "zh-tw", "zh-cn"}
}

local function getCurrentLanguageID()
    return languageSettings.ids[languageSettings.currentIndex]
end

local function getCurrentLanguageCode()
    return languageSettings.languageCodes[languageSettings.currentIndex] or "unknown"
end

local uiTexts = {
    [1] = {title = "Talisman Data Export", export_language = "Language:", export_button = "Export Talismans", status_exporting = "Scanning: %d / %d (%.1f%%)", talismans_found = "Talismans Found: %d", export_path = "Export Data at:"},
    [2] = {title = "お守りデータエクスポート", export_language = "言語:", export_button = "お守りをエクスポート", status_exporting = "スキャン中: %d / %d (%.1f%%)", talismans_found = "見つかったお守り: %d", export_path = "データのエクスポート先:"},
    [3] = {title = "탈리스만 데이터 내보내기", export_language = "언어:", export_button = "탈리스만 내보내기", status_exporting = "스캔 중: %d / %d (%.1f%%)", talismans_found = "찾은 탈리스만: %d", export_path = "데이터 내보내기 위치:"},
    [4] = {title = "護石資料匯出", export_language = "匯出語言:", export_button = "導出護石", status_exporting = "掃描中: %d / %d (%.1f%%)", talismans_found = "已找到護石: %d 個", export_path = "匯出資料於:"},
    [5] = {title = "护石资料导出", export_language = "导出语言:", export_button = "导出护石", status_exporting = "扫描中: %d / %d (%.1f%%)", talismans_found = "已找到护石: %d 个", export_path = "导出资料于:"}
}

local exportState = {
    running = false,
    phase = "idle",
    index = 0,
    total = 0,
    lines = {},
    startTime = 0,
    validCount = 0
}

local function getCurrentDateTimeString()
    local date = os.date("*t")
    return string.format("%04d-%02d-%02d@%02d.%02d", date.year, date.month, date.day, date.hour, date.min)
end

local function getExportPath()
    local langCode = getCurrentLanguageCode()
    local dateTime = getCurrentDateTimeString()
    return string.format("Talisman Data Export @%s=%s.txt", langCode, dateTime)
end

local function countNonZeroSkills(skills)
    local count = 0
    for _, skill in ipairs(skills) do
        if skill ~= 0 then
            count = count + 1
        end
    end
    return count
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
    exportState.lines = {}
    exportState.running = true
    exportState.phase = "exporting"
    exportState.startTime = os.clock()

    local exportString = ""

    for i = 0, count - 1 do
        exportState.index = i + 1
        
        local work = box:get_Item(i)
        if work and work:get_Category() == 2 then
            local customValues = work.BowgunCustomizeId
            if not customValues then goto continue end

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
                        local langID = getCurrentLanguageID()
                        local skillName = cachedMethods.getMsgWithLang:call(nil, skillEnum, langID)
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
        ::continue::
    end

    local exportPath = getExportPath()
    fs.write(exportPath, exportString)
    exportState.running = false
    exportState.phase = "idle"
end

function decodeSlots(slots)
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
    return {a1, a2, a3}, hasWeapon and 1 or 0
end

re.on_draw_ui(function()
    local langIdx = languageSettings.currentIndex
    local texts = uiTexts[langIdx] or uiTexts[4]

    if not imgui.tree_node(texts.title) then
        return
    end

    imgui.text(texts.export_language)
    imgui.same_line()
    local changed, newIndex = imgui.combo("##language", languageSettings.currentIndex, languageSettings.names)
    if changed then
        languageSettings.currentIndex = newIndex
    end

    imgui.spacing()
    imgui.separator()
    imgui.spacing()
    
    imgui.text("By Ninull")
    imgui.spacing()

    imgui.text(texts.export_path)
    imgui.same_line()
    imgui.text("reframework\\data\\")
    
    imgui.spacing()

    if not exportState.running then
        if imgui.button(texts.export_button) then
            local success, err = pcall(run_export)
            if not success then
                exportState.running = false
                exportState.phase = "idle"
            end
        end
    else
        if exportState.phase == "exporting" then
            local progress = exportState.index / exportState.total * 100
            imgui.text(string.format(texts.status_exporting, exportState.index, exportState.total, progress))
            imgui.text(string.format(texts.talismans_found, exportState.validCount))
            imgui.progress_bar(progress / 100, 250, 20)
        end
    end

    imgui.tree_pop()
end)