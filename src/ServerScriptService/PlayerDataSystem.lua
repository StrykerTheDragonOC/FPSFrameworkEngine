-- PlayerDataSystem.lua
-- Comprehensive player data management and leveling system
-- Place in ServerScriptService

local PlayerDataSystem = {}
PlayerDataSystem.__index = PlayerDataSystem

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataStore configuration
local DATA_STORE_NAME = "PlayerData_v1"
local LOADOUT_STORE_NAME = "PlayerLoadouts_v1"

-- Leveling configuration
local LEVEL_CONFIG = {
    MAX_LEVEL = 150,
    BASE_XP_REQUIRED = 1000,
    XP_MULTIPLIER = 1.15, -- Each level requires 15% more XP than previous

    -- XP rewards
    KILL_XP = 100,
    ASSIST_XP = 50,
    HEADSHOT_BONUS = 25,
    BACKSTAB_BONUS = 30,
    WIN_BONUS = 200,
    LOSS_BONUS = 75,
    OBJECTIVE_CAPTURE_XP = 150,
    OBJECTIVE_DEFEND_XP = 100,

    -- Unlock levels for weapons/attachments
    WEAPON_UNLOCKS = {
        -- Primary weapons
        ["AK74"] = 5,
        ["SCAR-H"] = 15,
        ["AWP"] = 25,

        -- Secondary weapons
        ["Glock17"] = 8,
        ["DesertEagle"] = 20,

        -- Melee weapons
        ["Machete"] = 10,
        ["Katana"] = 30,

        -- Attachments
        ["RedDotSight"] = 3,
        ["ACOG"] = 12,
        ["Suppressor"] = 18,
        ["ForwardGrip"] = 7
    }
}

-- Default player data structure
local DEFAULT_PLAYER_DATA = {
    -- Basic info
    level = 1,
    experience = 0,
    totalExperience = 0,

    -- Combat stats
    kills = 0,
    deaths = 0,
    headshots = 0,
    assists = 0,
    backstabs = 0,

    -- Weapon stats
    shotsHit = 0,
    shotsFired = 0,
    accuracy = 0,
    favoriteWeapon = "G36",
    weaponKills = {}, -- [weaponName] = killCount

    -- Match stats
    matches = {
        total = 0,
        wins = 0,
        losses = 0,
        draws = 0
    },

    -- Objective stats
    objectiveCaptures = 0,
    objectiveDefends = 0,
    flagCaptures = 0,

    -- Progression
    unlockedWeapons = {"G36", "M9", "PocketKnife", "M67"}, -- Default unlocks
    unlockedAttachments = {},
    credits = 0, -- In-game currency

    -- Playtime
    playtime = 0, -- In seconds
    lastPlayed = 0,

    -- Settings/preferences
    preferences = {
        sensitivity = 1.0,
        fov = 70,
        crosshairColor = Color3.fromRGB(255, 255, 255)
    }
}

-- Default loadout structure
local DEFAULT_LOADOUT = {
    PRIMARY = "G36",
    SECONDARY = "M9",
    MELEE = "PocketKnife",
    GRENADE = "M67",
    attachments = {
        PRIMARY = {},
        SECONDARY = {},
        MELEE = {},
        GRENADE = {}
    }
}

function PlayerDataSystem.new()
    local self = setmetatable({}, PlayerDataSystem)

    -- Data stores
    self.playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
    self.loadoutDataStore = DataStoreService:GetDataStore(LOADOUT_STORE_NAME)

    -- Player data cache
    self.playerData = {}
    self.playerLoadouts = {}

    -- Session tracking
    self.sessionStartTimes = {}

    -- Connections
    self.connections = {}

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the player data system
function PlayerDataSystem:initialize()
    print("[PlayerData] Initializing Player Data System...")

    -- Setup player connections
    self:setupPlayerConnections()

    -- Setup remote events for client communication
    self:setupRemoteEvents()

    -- Setup periodic auto-save
    self:setupAutoSave()

    print("[PlayerData] Player Data System initialized")
end

-- Setup player join/leave connections
function PlayerDataSystem:setupPlayerConnections()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)

    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeft(player)
    end)

    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:onPlayerJoined(player)
    end
end

-- Handle player joining - load their data
function PlayerDataSystem:onPlayerJoined(player)
    print("[PlayerData] Loading data for player:", player.Name)

    -- Track session start time
    self.sessionStartTimes[player] = tick()

    -- Load player data
    self:loadPlayerData(player)

    -- Load player loadout
    self:loadPlayerLoadout(player)
end

-- Handle player leaving - save their data
function PlayerDataSystem:onPlayerLeft(player)
    print("[PlayerData] Saving data for leaving player:", player.Name)

    -- Update playtime
    self:updatePlaytime(player)

    -- Save player data
    self:savePlayerData(player)

    -- Save player loadout
    self:savePlayerLoadout(player)

    -- Clean up
    self.playerData[player] = nil
    self.playerLoadouts[player] = nil
    self.sessionStartTimes[player] = nil
end

-- Load player data from DataStore
function PlayerDataSystem:loadPlayerData(player)
    local success, data = pcall(function()
        return self.playerDataStore:GetAsync(player.UserId)
    end)

    if success and data then
        -- Merge with default data to ensure all fields exist
        self.playerData[player] = self:mergeWithDefaults(data, DEFAULT_PLAYER_DATA)
        print("[PlayerData] Loaded existing data for", player.Name, "- Level:", self.playerData[player].level)
    else
        -- New player or load failed - use defaults
        self.playerData[player] = self:deepCopy(DEFAULT_PLAYER_DATA)
        print("[PlayerData] Created new player data for", player.Name)
    end

    -- Update last played time
    self.playerData[player].lastPlayed = tick()

    -- Send data to client
    self:sendPlayerDataToClient(player)
end

-- Load player loadout from DataStore
function PlayerDataSystem:loadPlayerLoadout(player)
    local success, loadout = pcall(function()
        return self.loadoutDataStore:GetAsync(player.UserId)
    end)

    if success and loadout then
        self.playerLoadouts[player] = loadout
        print("[PlayerData] Loaded existing loadout for", player.Name)
    else
        -- New player or load failed - use defaults
        self.playerLoadouts[player] = self:deepCopy(DEFAULT_LOADOUT)
        print("[PlayerData] Created default loadout for", player.Name)
    end

    -- Send loadout to client
    self:sendLoadoutToClient(player)
end

-- Save player data to DataStore
function PlayerDataSystem:savePlayerData(player)
    local data = self.playerData[player]
    if not data then return end

    local success, error = pcall(function()
        self.playerDataStore:SetAsync(player.UserId, data)
    end)

    if success then
        print("[PlayerData] Saved data for", player.Name)
    else
        warn("[PlayerData] Failed to save data for", player.Name, ":", error)
    end
end

-- Save player loadout to DataStore
function PlayerDataSystem:savePlayerLoadout(player)
    local loadout = self.playerLoadouts[player]
    if not loadout then return end

    local success, error = pcall(function()
        self.loadoutDataStore:SetAsync(player.UserId, loadout)
    end)

    if success then
        print("[PlayerData] Saved loadout for", player.Name)
    else
        warn("[PlayerData] Failed to save loadout for", player.Name, ":", error)
    end
end

-- Award experience to a player
function PlayerDataSystem:awardExperience(player, amount, reason)
    local data = self.playerData[player]
    if not data then return end

    local oldLevel = data.level
    data.experience = data.experience + amount
    data.totalExperience = data.totalExperience + amount

    -- Check for level up
    local newLevel = self:calculateLevel(data.totalExperience)
    if newLevel > oldLevel then
        data.level = newLevel
        self:onPlayerLevelUp(player, oldLevel, newLevel)
    end

    print("[PlayerData]", player.Name, "gained", amount, "XP for", reason)

    -- Send updated data to client
    self:sendPlayerDataToClient(player)
end

-- Calculate level based on total experience
function PlayerDataSystem:calculateLevel(totalExp)
    local level = 1
    local expRequired = LEVEL_CONFIG.BASE_XP_REQUIRED
    local totalExpRequired = 0

    while level < LEVEL_CONFIG.MAX_LEVEL do
        totalExpRequired = totalExpRequired + expRequired

        if totalExp < totalExpRequired then
            break
        end

        level = level + 1
        expRequired = math.floor(expRequired * LEVEL_CONFIG.XP_MULTIPLIER)
    end

    return level
end

-- Handle player level up
function PlayerDataSystem:onPlayerLevelUp(player, oldLevel, newLevel)
    print("[PlayerData]", player.Name, "leveled up from", oldLevel, "to", newLevel)

    -- Award credits for leveling up
    local creditsAwarded = newLevel * 50
    self:awardCredits(player, creditsAwarded, "Level up bonus")

    -- Check for new unlocks
    self:checkUnlocks(player, newLevel)

    -- Notify client of level up
    local levelUpEvent = ReplicatedStorage:FindFirstChild("PlayerLevelUp")
    if levelUpEvent then
        levelUpEvent:FireClient(player, oldLevel, newLevel, creditsAwarded)
    end
end

-- Check for new weapon/attachment unlocks
function PlayerDataSystem:checkUnlocks(player, level)
    local data = self.playerData[player]
    if not data then return end

    local newUnlocks = {}

    for itemName, unlockLevel in pairs(LEVEL_CONFIG.WEAPON_UNLOCKS) do
        if level >= unlockLevel then
            -- Check if it's a weapon or attachment
            if itemName:find("Sight") or itemName:find("Suppressor") or itemName:find("Grip") then
                -- It's an attachment
                if not table.find(data.unlockedAttachments, itemName) then
                    table.insert(data.unlockedAttachments, itemName)
                    table.insert(newUnlocks, {type = "attachment", name = itemName})
                end
            else
                -- It's a weapon
                if not table.find(data.unlockedWeapons, itemName) then
                    table.insert(data.unlockedWeapons, itemName)
                    table.insert(newUnlocks, {type = "weapon", name = itemName})
                end
            end
        end
    end

    -- Notify player of new unlocks
    if #newUnlocks > 0 then
        local unlockEvent = ReplicatedStorage:FindFirstChild("NewUnlocks")
        if unlockEvent then
            unlockEvent:FireClient(player, newUnlocks)
        end

        print("[PlayerData]", player.Name, "unlocked", #newUnlocks, "new items")
    end
end

-- Award credits to a player
function PlayerDataSystem:awardCredits(player, amount, reason)
    local data = self.playerData[player]
    if not data then return end

    data.credits = data.credits + amount
    print("[PlayerData]", player.Name, "earned", amount, "credits for", reason)

    -- Send updated data to client
    self:sendPlayerDataToClient(player)
end

-- Record a kill for a player
function PlayerDataSystem:recordKill(killer, victim, weaponName, isHeadshot, isBackstab)
    local killerData = self.playerData[killer]
    local victimData = self.playerData[victim]

    if killerData then
        killerData.kills = killerData.kills + 1

        -- Track weapon kills
        if not killerData.weaponKills[weaponName] then
            killerData.weaponKills[weaponName] = 0
        end
        killerData.weaponKills[weaponName] = killerData.weaponKills[weaponName] + 1

        -- Update favorite weapon
        local maxKills = 0
        for weapon, kills in pairs(killerData.weaponKills) do
            if kills > maxKills then
                maxKills = kills
                killerData.favoriteWeapon = weapon
            end
        end

        -- Award XP for kill
        local xpAmount = LEVEL_CONFIG.KILL_XP

        -- Bonus XP for special kills
        if isHeadshot then
            killerData.headshots = killerData.headshots + 1
            xpAmount = xpAmount + LEVEL_CONFIG.HEADSHOT_BONUS
        end

        if isBackstab then
            killerData.backstabs = killerData.backstabs + 1
            xpAmount = xpAmount + LEVEL_CONFIG.BACKSTAB_BONUS
        end

        self:awardExperience(killer, xpAmount, "Kill")
    end

    if victimData then
        victimData.deaths = victimData.deaths + 1
    end

    -- Update both players' data on client
    if killerData then
        self:sendPlayerDataToClient(killer)
    end
    if victimData then
        self:sendPlayerDataToClient(victim)
    end
end

-- Record match result for a player
function PlayerDataSystem:recordMatchResult(player, result, duration)
    local data = self.playerData[player]
    if not data then return end

    data.matches.total = data.matches.total + 1

    local xpAmount = 0
    if result == "win" then
        data.matches.wins = data.matches.wins + 1
        xpAmount = LEVEL_CONFIG.WIN_BONUS
    elseif result == "loss" then
        data.matches.losses = data.matches.losses + 1
        xpAmount = LEVEL_CONFIG.LOSS_BONUS
    else -- draw
        data.matches.draws = data.matches.draws + 1
        xpAmount = math.floor((LEVEL_CONFIG.WIN_BONUS + LEVEL_CONFIG.LOSS_BONUS) / 2)
    end

    -- Bonus XP for match duration (longer matches = more XP)
    local durationBonus = math.floor(duration / 60) * 10 -- 10 XP per minute
    xpAmount = xpAmount + durationBonus

    self:awardExperience(player, xpAmount, "Match completion (" .. result .. ")")

    -- Send updated data to client
    self:sendPlayerDataToClient(player)
end

-- Record objective capture
function PlayerDataSystem:recordObjectiveCapture(player, objectiveType)
    local data = self.playerData[player]
    if not data then return end

    data.objectiveCaptures = data.objectiveCaptures + 1

    if objectiveType == "flag" then
        data.flagCaptures = data.flagCaptures + 1
    end

    self:awardExperience(player, LEVEL_CONFIG.OBJECTIVE_CAPTURE_XP, "Objective capture")

    -- Send updated data to client
    self:sendPlayerDataToClient(player)
end

-- Update weapon accuracy stats
function PlayerDataSystem:updateAccuracy(player, hits, shots)
    local data = self.playerData[player]
    if not data then return end

    data.shotsHit = data.shotsHit + hits
    data.shotsFired = data.shotsFired + shots

    -- Calculate overall accuracy
    if data.shotsFired > 0 then
        data.accuracy = math.floor((data.shotsHit / data.shotsFired) * 100)
    end

    -- Send updated data to client
    self:sendPlayerDataToClient(player)
end

-- Update playtime for a player
function PlayerDataSystem:updatePlaytime(player)
    local data = self.playerData[player]
    local startTime = self.sessionStartTimes[player]

    if data and startTime then
        local sessionDuration = tick() - startTime
        data.playtime = data.playtime + sessionDuration
        self.sessionStartTimes[player] = tick() -- Reset for next update
    end
end

-- Setup remote events for client communication
function PlayerDataSystem:setupRemoteEvents()
    -- Create remote events
    local function createRemoteEvent(name)
        local existing = ReplicatedStorage:FindFirstChild(name)
        if existing then existing:Destroy() end

        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = ReplicatedStorage
        return event
    end

    createRemoteEvent("PlayerDataRequest")
    createRemoteEvent("PlayerDataUpdate")
    createRemoteEvent("LoadoutUpdate")
    createRemoteEvent("PlayerLevelUp")
    createRemoteEvent("NewUnlocks")

    -- Handle client requests
    local dataRequest = ReplicatedStorage:FindFirstChild("PlayerDataRequest")
    if dataRequest then
        dataRequest.OnServerEvent:Connect(function(player)
            self:sendPlayerDataToClient(player)
            self:sendLoadoutToClient(player)
        end)
    end

    -- Handle loadout updates from client
    local loadoutUpdate = ReplicatedStorage:FindFirstChild("LoadoutUpdate")
    if loadoutUpdate then
        loadoutUpdate.OnServerEvent:Connect(function(player, newLoadout)
            self:updatePlayerLoadout(player, newLoadout)
        end)
    end
end

-- Send player data to client
function PlayerDataSystem:sendPlayerDataToClient(player)
    local data = self.playerData[player]
    if not data then return end

    local updateEvent = ReplicatedStorage:FindFirstChild("PlayerDataUpdate")
    if updateEvent then
        updateEvent:FireClient(player, data)
    end
end

-- Send loadout to client
function PlayerDataSystem:sendLoadoutToClient(player)
    local loadout = self.playerLoadouts[player]
    if not loadout then return end

    local loadoutEvent = ReplicatedStorage:FindFirstChild("LoadoutUpdate")
    if loadoutEvent then
        loadoutEvent:FireClient(player, loadout)
    end
end

-- Update player loadout
function PlayerDataSystem:updatePlayerLoadout(player, newLoadout)
    self.playerLoadouts[player] = newLoadout
    print("[PlayerData] Updated loadout for", player.Name)

    -- Save immediately
    self:savePlayerLoadout(player)
end

-- Setup automatic saving every 5 minutes
function PlayerDataSystem:setupAutoSave()
    spawn(function()
        while true do
            wait(300) -- 5 minutes

            print("[PlayerData] Auto-saving all player data...")

            for player, _ in pairs(self.playerData) do
                if player.Parent then -- Player still in game
                    self:updatePlaytime(player)
                    self:savePlayerData(player)
                    self:savePlayerLoadout(player)
                end
            end

            print("[PlayerData] Auto-save complete")
        end
    end)
end

-- Get player data (for other systems to use)
function PlayerDataSystem:getPlayerData(player)
    return self.playerData[player]
end

-- Get player loadout (for other systems to use)
function PlayerDataSystem:getPlayerLoadout(player)
    return self.playerLoadouts[player]
end

-- Utility functions
function PlayerDataSystem:deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = self:deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function PlayerDataSystem:mergeWithDefaults(data, defaults)
    local merged = self:deepCopy(defaults)

    for key, value in pairs(data) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = self:mergeWithDefaults(value, merged[key])
        else
            merged[key] = value
        end
    end

    return merged
end

-- Cleanup
function PlayerDataSystem:cleanup()
    print("[PlayerData] Cleaning up Player Data System...")

    -- Save all player data
    for player, _ in pairs(self.playerData) do
        self:updatePlaytime(player)
        self:savePlayerData(player)
        self:savePlayerLoadout(player)
    end

    -- Disconnect connections
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    print("[PlayerData] Player Data System cleanup complete")
end

-- Initialize the system
local playerDataSystem = PlayerDataSystem.new()
_G.PlayerDataSystem = playerDataSystem

-- Admin commands for testing
_G.AwardXP = function(playerName, amount)
    local player = Players:FindFirstChild(playerName)
    if player then
        playerDataSystem:awardExperience(player, amount, "Admin award")
        return true
    end
    return false
end

_G.SetLevel = function(playerName, level)
    local player = Players:FindFirstChild(playerName)
    if player then
        local data = playerDataSystem:getPlayerData(player)
        if data then
            data.level = level
            data.totalExperience = level * LEVEL_CONFIG.BASE_XP_REQUIRED
            playerDataSystem:sendPlayerDataToClient(player)
            return true
        end
    end
    return false
end

_G.GetPlayerStats = function(playerName)
    local player = Players:FindFirstChild(playerName)
    if player then
        return playerDataSystem:getPlayerData(player)
    end
    return nil
end

return playerDataSystem