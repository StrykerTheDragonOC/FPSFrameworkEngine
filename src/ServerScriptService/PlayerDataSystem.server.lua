-- Fixed Player Data Manager with proper DataStore serialization
-- Place in ServerScriptService
local PlayerDataManager = {}

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Data stores
local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

-- Cache for player data
local playerDataCache = {}
local dataAutoSaveInterval = 60 -- Auto-save every 60 seconds

-- Default player data structure
local DEFAULT_PLAYER_DATA = {
    -- Stats
    level = 1,
    xp = 0,
    totalXp = 0,
    credits = 1000,

    -- Combat stats
    kills = 0,
    deaths = 0,
    assists = 0,
    headshots = 0,
    kdr = 0,

    -- Loadout (store as strings, not tables)
    primaryWeapon = "G36",
    secondaryWeapon = "M9",
    meleeWeapon = "Knife",
    grenade = "M67 FRAG",

    -- Unlocked items (store as JSON string)
    unlockedWeapons = '["G36", "M9", "Knife", "M67 FRAG"]',
    unlockedAttachments = '[]',
    unlockedSkins = '[]',

    -- Settings
    sensitivity = 1,
    fov = 70,

    -- Timestamps
    firstJoined = 0,
    lastSaved = 0,
    playtime = 0
}

-- Convert complex data to storable format
local function serializeData(data)
    local serialized = {}

    for key, value in pairs(data) do
        if type(value) == "table" then
            -- Convert tables to JSON strings
            serialized[key] = HttpService:JSONEncode(value)
        elseif type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
            -- These types are safe for DataStore
            serialized[key] = value
        else
            -- Skip unsupported types
            warn("Skipping unsupported data type for key:", key, type(value))
        end
    end

    return serialized
end

-- Convert stored data back to usable format
local function deserializeData(data)
    local deserialized = {}

    for key, value in pairs(data) do
        if type(value) == "string" then
            -- Try to parse JSON strings back to tables
            local success, result = pcall(function()
                return HttpService:JSONDecode(value)
            end)

            if success and type(result) == "table" then
                deserialized[key] = result
            else
                deserialized[key] = value
            end
        else
            deserialized[key] = value
        end
    end

    return deserialized
end

-- Load player data from DataStore
function PlayerDataManager:loadPlayerData(player)
    local userId = tostring(player.UserId)
    local success, data = pcall(function()
        return playerDataStore:GetAsync(userId)
    end)

    if success then
        if data then
            -- Deserialize and merge with defaults
            local deserializedData = deserializeData(data)
            local playerData = {}

            -- Merge with defaults to ensure all fields exist
            for key, defaultValue in pairs(DEFAULT_PLAYER_DATA) do
                playerData[key] = deserializedData[key] or defaultValue
            end

            -- Parse JSON fields
            if type(playerData.unlockedWeapons) == "string" then
                local success, weapons = pcall(function()
                    return HttpService:JSONDecode(playerData.unlockedWeapons)
                end)
                playerData.unlockedWeapons = success and weapons or {"G36", "M9", "Knife", "M67 FRAG"}
            end

            if type(playerData.unlockedAttachments) == "string" then
                local success, attachments = pcall(function()
                    return HttpService:JSONDecode(playerData.unlockedAttachments)
                end)
                playerData.unlockedAttachments = success and attachments or {}
            end

            if type(playerData.unlockedSkins) == "string" then
                local success, skins = pcall(function()
                    return HttpService:JSONDecode(playerData.unlockedSkins)
                end)
                playerData.unlockedSkins = success and skins or {}
            end

            playerDataCache[userId] = playerData
            print("[PlayerData] Loaded data for", player.Name)
            return playerData
        else
            -- New player
            print("[PlayerData] Creating new data for", player.Name)
            return self:createNewPlayerData(player)
        end
    else
        warn("[PlayerData] Failed to load data for", player.Name, ":", data)
        -- Use default data as fallback
        return self:createNewPlayerData(player)
    end
end

-- Create new player data
function PlayerDataManager:createNewPlayerData(player)
    local userId = tostring(player.UserId)
    local newData = {}

    -- Copy defaults
    for key, value in pairs(DEFAULT_PLAYER_DATA) do
        newData[key] = value
    end

    -- Set timestamps
    newData.firstJoined = os.time()
    newData.lastSaved = os.time()

    -- Parse default arrays
    newData.unlockedWeapons = {"G36", "M9", "Knife", "M67 FRAG"}
    newData.unlockedAttachments = {}
    newData.unlockedSkins = {}

    playerDataCache[userId] = newData

    -- Attempt to save immediately
    self:savePlayerData(player)

    return newData
end

-- Save player data to DataStore
function PlayerDataManager:savePlayerData(player)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if not data then
        warn("[PlayerData] No data to save for", player.Name)
        return false
    end

    -- Prepare data for storage
    local dataToSave = {}

    -- Convert all data to storable format
    for key, value in pairs(data) do
        if key == "unlockedWeapons" or key == "unlockedAttachments" or key == "unlockedSkins" then
            -- Convert arrays to JSON strings
            dataToSave[key] = HttpService:JSONEncode(value)
        elseif type(value) ~= "function" and type(value) ~= "userdata" and type(value) ~= "thread" then
            if type(value) == "table" then
                -- Convert other tables to JSON
                dataToSave[key] = HttpService:JSONEncode(value)
            else
                dataToSave[key] = value
            end
        end
    end

    -- Update last saved timestamp
    dataToSave.lastSaved = os.time()

    -- Attempt to save
    local success, errorMsg = pcall(function()
        playerDataStore:SetAsync(userId, dataToSave)
    end)

    if success then
        print("[PlayerData] Successfully saved data for", player.Name)
        return true
    else
        warn("[PlayerData] Failed to save data for", player.Name, ":", errorMsg)
        return false
    end
end

-- Get player data
function PlayerDataManager:getPlayerData(player)
    local userId = tostring(player.UserId)
    return playerDataCache[userId]
end

-- Update specific player data field
function PlayerDataManager:updatePlayerData(player, key, value)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if data then
        data[key] = value

        -- Update KDR if kills or deaths changed
        if key == "kills" or key == "deaths" then
            data.kdr = data.deaths > 0 and (data.kills / data.deaths) or data.kills
        end

        return true
    end

    return false
end

-- Increment a numeric field
function PlayerDataManager:incrementValue(player, key, amount)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if data and type(data[key]) == "number" then
        data[key] = data[key] + (amount or 1)

        -- Update KDR if kills or deaths changed
        if key == "kills" or key == "deaths" then
            data.kdr = data.deaths > 0 and (data.kills / data.deaths) or data.kills
        end

        return true
    end

    return false
end

-- Add unlocked item
function PlayerDataManager:unlockItem(player, itemType, itemName)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if not data then return false end

    local unlockList
    if itemType == "weapon" then
        unlockList = data.unlockedWeapons
    elseif itemType == "attachment" then
        unlockList = data.unlockedAttachments
    elseif itemType == "skin" then
        unlockList = data.unlockedSkins
    else
        return false
    end

    -- Check if already unlocked
    if table.find(unlockList, itemName) then
        return false
    end

    -- Add to unlocked list
    table.insert(unlockList, itemName)
    print("[PlayerData] Unlocked", itemType, itemName, "for", player.Name)

    return true
end

-- Update loadout
function PlayerDataManager:updateLoadout(player, slot, item)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if not data then return false end

    local validSlots = {
        primary = "primaryWeapon",
        secondary = "secondaryWeapon",
        melee = "meleeWeapon",
        grenade = "grenade"
    }

    local dataKey = validSlots[slot:lower()]
    if dataKey then
        data[dataKey] = item
        print("[PlayerData] Updated", slot, "to", item, "for", player.Name)
        return true
    end

    return false
end

-- Get player loadout
function PlayerDataManager:getLoadout(player)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if not data then
        return {
            primary = "G36",
            secondary = "M9",
            melee = "Knife",
            grenade = "M67 FRAG"
        }
    end

    return {
        primary = data.primaryWeapon,
        secondary = data.secondaryWeapon,
        melee = data.meleeWeapon,
        grenade = data.grenade
    }
end

-- Auto-save function
local function autoSaveAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        PlayerDataManager:savePlayerData(player)
    end
end

-- Setup auto-save loop
local function setupAutoSave()
    while true do
        wait(dataAutoSaveInterval)
        autoSaveAllPlayers()
        print("[PlayerData] Auto-saved all player data")
    end
end

-- Player join handler
local function onPlayerAdded(player)
    -- Load player data
    PlayerDataManager:loadPlayerData(player)

    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local data = PlayerDataManager:getPlayerData(player)
    if data then
        -- Level
        local level = Instance.new("IntValue")
        level.Name = "Level"
        level.Value = data.level
        level.Parent = leaderstats

        -- Kills
        local kills = Instance.new("IntValue")
        kills.Name = "Kills"
        kills.Value = data.kills
        kills.Parent = leaderstats

        -- Deaths
        local deaths = Instance.new("IntValue")
        deaths.Name = "Deaths"
        deaths.Value = data.deaths
        deaths.Parent = leaderstats

        -- Credits
        local credits = Instance.new("IntValue")
        credits.Name = "Credits"
        credits.Value = data.credits
        credits.Parent = leaderstats
    end

    print("[PlayerData] Initialized player:", player.Name)
end

-- Player leave handler
local function onPlayerRemoving(player)
    -- Update playtime
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if data then
        -- You could track actual playtime here
        data.playtime = data.playtime + 60 -- Example: add 60 seconds
    end

    -- Save player data
    PlayerDataManager:savePlayerData(player)

    -- Clear from cache
    playerDataCache[userId] = nil

    print("[PlayerData] Player left, data saved:", player.Name)
end

-- Initialize the system
local function initialize()
    -- Connect events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    -- Start auto-save loop
    spawn(setupAutoSave)

    -- Save all data on server shutdown
    game:BindToClose(function()
        print("[PlayerData] Server shutting down, saving all data...")
        for _, player in pairs(Players:GetPlayers()) do
            PlayerDataManager:savePlayerData(player)
        end
        wait(2) -- Give time for saves to complete
    end)

    print("[PlayerData] System initialized")
end

-- Initialize
initialize()

-- Export for other scripts
_G.PlayerDataManager = PlayerDataManager

return PlayerDataManager