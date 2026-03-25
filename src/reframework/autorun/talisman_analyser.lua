local Parser = require("talisman_analyser.parser")
local Util = require("talisman_analyser.util")
local io = require("io")

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

local function main()
    local talismans
    repeat
        io.write("path to export file = ")
        local filePath = io.read()

        if filePath:find('"') then
            filePath = filePath:gsub('"', "")
        end

        local status, result = pcall(function()
            return Parser.parseFile(filePath)
        end)

        if status then
            talismans = result
        else
            io.stderr:write(result .. "\n")
        end
    until talismans ~= nil

    printAll(talismans)
    print()
    printDuplicates(talismans)
    print()
    printObsolete(talismans)
end

main()
