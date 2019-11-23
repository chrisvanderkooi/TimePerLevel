local addonName = "TimePerLevel";
local addonPrefix = "TPL: ";

local frame = CreateFrame("FRAME");

-- tracking the dinged level while waiting for async played event
local newLevel = 0;

-- waiting for asynchonrous time played event
local waitingForTimePlayed = false;

-- event registration
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LEVEL_UP");
frame:RegisterEvent("TIME_PLAYED_MSG");

-- first run for character
function InitializeTableForCharacter()
    TimePerLevel_LevelCounts = {}
    print(addonName .. ": Initialized");
end

-- record game time
function frame:RecordGameTime(level, totaltime)
    TimePerLevel_LevelCounts[level - 1] = totaltime;
end

-- event listeners
function frame:OnEvent(event, arg1)
    if (event == "ADDON_LOADED" and arg1 == addonName) then
        -- check if db created
        if TimePerLevel_LevelCounts == nil then
            InitializeTableForCharacter();
        end
    end
    if event == "PLAYER_LEVEL_UP" then
        newLevel = arg1;
        -- get the time played event
        waitingForTimePlayed = true;
        RequestTimePlayed();
    end
    if event == "TIME_PLAYED_MSG" then
        if waitingForTimePlayed then
            frame:RecordGameTime(newLevel, arg1);
            waitingForTimePlayed = false;
        end
    end
end

-- register listener func
frame:SetScript("OnEvent", frame.OnEvent);

-- triggered funcs
function printAllLevels()
    local populated = false; -- determine if level table has data and display the appropriate msg

    print(addonPrefix);

    -- capture all values in table to get mean
    local levelCountAvailable = 0; -- amount of levels tracked
    local totalLevelSeconds = 0; -- all level time seconds
    local previousLevelSeconds = 0;

    for level, time in pairsBySortedKeys(TimePerLevel_LevelCounts) do
        populated = true;

        -- track all record levels to get mean after
        totalLevelSeconds = totalLevelSeconds + (time - previousLevelSeconds);
        levelCountAvailable = levelCountAvailable+1;

        previousLevelSeconds = time;

        print("Level " .. level .. ": ", GetTimeDisplayByLevel(level));
    end

    -- determine if we should display mean
    if levelCountAvailable > 0 then
        print("Average level time: " .. ConvertSecondsToDisplayFormat(math.floor(totalLevelSeconds / levelCountAvailable)));
    end

    if populated == false then
        noDataInTable();
    end
end

function printLastLevel()
    local lastLevel = UnitLevel("player") - 1;

    print(addonPrefix);

    -- fun msg for level 1
    if lastLevel == 0 then
        print("You've only just started your journey...")
        do return end
    end

    -- if TimePerLevel_LevelCounts[lastLevel] and TimePerLevel_LevelCounts[lastLevel - 1] then
    if TimePerLevel_LevelCounts[lastLevel] then
        print("Level " .. lastLevel .. ": " .. GetTimeDisplayByLevel(lastLevel) .. " (last level)");
        do return end
    end

    -- catch if no level data
    noDataForLevel(lastLevel);
end

function printLevel(level)
    print(addonPrefix);

    if TimePerLevel_LevelCounts[level] then
        print("Level " .. level .. ": " .. GetTimeDisplayByLevel(level))
        do return end
    end

    -- catch if no level data
    noDataForLevel(level);
end

function GetTimeDisplayByLevel(level)
    local previousLevelSeconds = TimePerLevel_LevelCounts[level - 1];
    local seconds = TimePerLevel_LevelCounts[level];

    -- check if subtraction needed from past level
    if previousLevelSeconds then
        seconds = seconds - previousLevelSeconds
    end

    return ConvertSecondsToDisplayFormat(seconds);
end

function ConvertSecondsToDisplayFormat(amount)
    if (amount / 60) < 1 then
        return amount .. "s";
    end

    local minutes = math.floor(amount / 60);
    local seconds = amount % 60;

    if (minutes / 60) < 1 then
        return minutes .. "m " .. seconds .. "s"
    end

    local hours = math.floor(minutes / 60);
    minutes = minutes % 60;
    return hours .. "h " .. minutes .. "m " .. seconds .. "s"
end

function pairsBySortedKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end 

function noDataInTable()
    print("No leveling data yet! You need to level up at least once while the addon is active.");
end

function noDataForLevel(level)
    print("No data for level " .. level);
end

-- chat commands to print leveling data into chat
SLASH_TPL1 = "/timeperlevel";
SLASH_TPL2 = "/tpl";
function SlashCmdList.TPL(msg)
    -- note: msg is always true and is a string

    -- last level arg
    if msg == "last" then
        printLastLevel();
        do return end
    end

    -- specific level arg
    if msg and string.len(msg) > 0 then
        -- verify it is a number being passed as arg
        local levelRequested = tonumber(msg);

        if (type(levelRequested) == "number") then
            printLevel(levelRequested);
            do return end;
        end

        print(addonPrefix .. "You must provide a past level (eg. /tpl 20)");
        do return end
    end

    printAllLevels();
end
