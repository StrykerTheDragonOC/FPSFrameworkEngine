-- XPLevelingSystem.lua
-- Advanced XP and leveling system for KFCS FUNNY RANDOMIZER
-- Uses specified formulas: XP = 1000 × ((rank² + rank) ÷ 2) and credit rewards

local XPLevelingSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Data stores (you may want to use a different key in production)
local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

-- XP Sources and amounts
local XP_SOURCES = {
    -- Basic combat
    KILL = 100,
    ASSIST = 50,
    HEADSHOT = 25, -- Bonus on top of kill
    LONG_DISTANCE_SHOT = 20, -- 100+ studs
    BACKSTAB = 30,
    WALLBANG = 15,
    QUICKSCOPE = 20,
    NO_SCOPE = 30,
    
    -- Multi-kills (bonus XP)
    DOUBLE_KILL = 50,
    TRIPLE_KILL = 100,
    QUAD_KILL = 200,
    
    -- Objective-based
    OBJECTIVE_CAPTURE = 150,
    OBJECTIVE_HOLD = 5, -- Per 10 seconds
    FLAG_CAPTURE = 200,
    FLAG_RETURN = 100,
    
    -- Support actions
    SPOT_ASSIST = 10, -- When spotted enemy is killed
    SUPPRESSION = 5, -- Per suppression action
    
    -- Weapon mastery
    WEAPON_MASTERY = 500, -- Per mastery level
    ATTACHMENT_UNLOCK = 50 -- Per attachment unlocked
}

-- Credit reward formulas
-- Rank 1-20: Credit = ((rank-1) * 5) + 200
-- Rank 21+: Credit = (rank * 5) + 200

-- Initialize XP system
function XPLevelingSystem:init()
    print("[XPLevelingSystem] Initializing XP and leveling system...")
    
    -- Create remote events for XP updates
    self:createRemoteEvents()
    
    -- Player data tracking
    self.playerData = {}
    
    -- Setup player connections
    self:setupPlayerConnections()
    
    print("[XPLevelingSystem] XP and leveling system initialized")
end

-- Create remote events
function XPLevelingSystem:createRemoteEvents()
    local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem")
    local remoteEvents = fpsSystem:WaitForChild("RemoteEvents")
    
    -- Create XP update event if it doesn't exist
    if not remoteEvents:FindFirstChild("XPUpdate") then
        local xpUpdateEvent = Instance.new("RemoteEvent")
        xpUpdateEvent.Name = "XPUpdate"
        xpUpdateEvent.Parent = remoteEvents
    end
    
    -- Create level up event
    if not remoteEvents:FindFirstChild("LevelUp") then
        local levelUpEvent = Instance.new("RemoteEvent")
        levelUpEvent.Name = "LevelUp"
        levelUpEvent.Parent = remoteEvents
    end
end

-- Setup player connection events
function XPLevelingSystem:setupPlayerConnections()
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:loadPlayerData(player)
    end)
    
    -- Handle leaving players
    Players.PlayerRemoving:Connect(function(player)
        self:savePlayerData(player)
    end)
    
    -- Load existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:loadPlayerData(player)
    end
end

-- Load player data from DataStore
function XPLevelingSystem:loadPlayerData(player)
    print("[XPLevelingSystem] Loading data for player:", player.Name)
    
    local success, data = pcall(function()
        return playerDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        self.playerData[player.UserId] = data
    else
        -- Create new player data
        self.playerData[player.UserId] = {
            level = 0,
            totalXP = 0,
            currentLevelXP = 0,
            credits = 200, -- Starting credits
            totalKills = 0,
            totalDeaths = 0,
            totalKDR = 0,
            matchKills = 0,
            matchDeaths = 0,
            matchKDR = 0,
            weaponMastery = {},
            unlockedWeapons = {},
            unlockedAttachments = {}
        }
    end
    
    -- Update player attributes
    self:updatePlayerAttributes(player)
    
    print("[XPLevelingSystem] Player data loaded for:", player.Name)
end

-- Save player data to DataStore
function XPLevelingSystem:savePlayerData(player)
    if not self.playerData[player.UserId] then return end
    
    print("[XPLevelingSystem] Saving data for player:", player.Name)
    
    local success, error = pcall(function()
        playerDataStore:SetAsync(player.UserId, self.playerData[player.UserId])
    end)
    
    if not success then
        warn("[XPLevelingSystem] Failed to save data for", player.Name, ":", error)
    end
end

-- Update player attributes (for UI access)
function XPLevelingSystem:updatePlayerAttributes(player)
    local data = self.playerData[player.UserId]
    if not data then return end
    
    player:SetAttribute("Level", data.level)
    player:SetAttribute("TotalXP", data.totalXP)
    player:SetAttribute("CurrentLevelXP", data.currentLevelXP)
    player:SetAttribute("Credits", data.credits)
    player:SetAttribute("TotalKills", data.totalKills)
    player:SetAttribute("TotalDeaths", data.totalDeaths)
    player:SetAttribute("TotalKDR", data.totalKDR)
    player:SetAttribute("MatchKills", data.matchKills)
    player:SetAttribute("MatchDeaths", data.matchDeaths)
    player:SetAttribute("MatchKDR", data.matchKDR)
end

-- Calculate XP required for specific level using formula: XP = 1000 × ((rank² + rank) ÷ 2)
function XPLevelingSystem:calculateXPRequired(level)
    if level <= 0 then return 0 end
    return 1000 * ((level * level + level) / 2)
end

-- Calculate XP required for next level
function XPLevelingSystem:getXPForNextLevel(currentLevel)
    return self:calculateXPRequired(currentLevel + 1) - self:calculateXPRequired(currentLevel)
end

-- Calculate credit reward for level up
function XPLevelingSystem:calculateCreditReward(level)
    if level <= 0 then return 200 end -- Starting credits
    
    if level <= 20 then
        -- Rank 1-20: Credit = ((rank-1) * 5) + 200
        return ((level - 1) * 5) + 200
    else
        -- Rank 21+: Credit = (rank * 5) + 200
        return (level * 5) + 200
    end
end

-- Award XP to player
function XPLevelingSystem:awardXP(player, xpAmount, source)
    local data = self.playerData[player.UserId]
    if not data then
        warn("[XPLevelingSystem] No data found for player:", player.Name)
        return
    end
    
    print(string.format("[XPLevelingSystem] Awarding %d XP to %s for %s", xpAmount, player.Name, source or "Unknown"))
    
    -- Add XP
    data.totalXP = data.totalXP + xpAmount
    data.currentLevelXP = data.currentLevelXP + xpAmount
    
    -- Check for level up
    local xpRequiredForNextLevel = self:getXPForNextLevel(data.level)
    
    while data.currentLevelXP >= xpRequiredForNextLevel do
        -- Level up!
        data.currentLevelXP = data.currentLevelXP - xpRequiredForNextLevel
        data.level = data.level + 1
        
        local creditReward = self:calculateCreditReward(data.level)
        data.credits = data.credits + creditReward
        
        print(string.format("[XPLevelingSystem] %s leveled up to %d! +%d Credits", player.Name, data.level, creditReward))
        
        -- Trigger level up event
        self:triggerLevelUp(player, data.level, creditReward)
        
        -- Calculate next level requirement
        xpRequiredForNextLevel = self:getXPForNextLevel(data.level)
    end
    
    -- Update player attributes
    self:updatePlayerAttributes(player)
    
    -- Send XP update to client
    self:sendXPUpdate(player, xpAmount, source)
end

-- Trigger level up event and effects
function XPLevelingSystem:triggerLevelUp(player, newLevel, creditReward)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    local levelUpEvent = remoteEvents:FindFirstChild("LevelUp")
    if levelUpEvent then
        levelUpEvent:FireClient(player, {
            newLevel = newLevel,
            creditReward = creditReward,
            message = string.format("Level Up! Rank %d +%d Credits", newLevel, creditReward)
        })
    end
end

-- Send XP update to client
function XPLevelingSystem:sendXPUpdate(player, xpAmount, source)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end
    
    local xpUpdateEvent = remoteEvents:FindFirstChild("XPUpdate")
    if xpUpdateEvent then
        local data = self.playerData[player.UserId]
        xpUpdateEvent:FireClient(player, {
            xpGained = xpAmount,
            source = source,
            totalXP = data.totalXP,
            currentLevel = data.level,
            currentLevelXP = data.currentLevelXP,
            xpToNextLevel = self:getXPForNextLevel(data.level),
            credits = data.credits
        })
    end
end

-- Record kill and award XP
function XPLevelingSystem:recordKill(killer, victim, weaponUsed, isHeadshot, distance, isBackstab, isWallbang, isQuickscope, isNoScope)
    if not killer or killer == victim then return end
    
    local killerData = self.playerData[killer.UserId]
    local victimData = self.playerData[victim.UserId]
    
    if not killerData or not victimData then return end
    
    -- Update kill/death stats
    killerData.totalKills = killerData.totalKills + 1
    killerData.matchKills = killerData.matchKills + 1
    
    victimData.totalDeaths = victimData.totalDeaths + 1
    victimData.matchDeaths = victimData.matchDeaths + 1
    
    -- Update KDR
    killerData.totalKDR = killerData.totalKills / math.max(1, killerData.totalDeaths)
    killerData.matchKDR = killerData.matchKills / math.max(1, killerData.matchDeaths)
    
    victimData.totalKDR = victimData.totalKills / math.max(1, victimData.totalDeaths)
    victimData.matchKDR = victimData.matchKills / math.max(1, victimData.matchDeaths)
    
    -- Award base kill XP
    local totalXP = XP_SOURCES.KILL
    local xpBreakdown = {"Kill: " .. XP_SOURCES.KILL}
    
    -- Bonus XP for special conditions
    if isHeadshot then
        totalXP = totalXP + XP_SOURCES.HEADSHOT
        table.insert(xpBreakdown, "Headshot: " .. XP_SOURCES.HEADSHOT)
    end
    
    if distance and distance >= 100 then
        totalXP = totalXP + XP_SOURCES.LONG_DISTANCE_SHOT
        table.insert(xpBreakdown, "Long Range: " .. XP_SOURCES.LONG_DISTANCE_SHOT)
    end
    
    if isBackstab then
        totalXP = totalXP + XP_SOURCES.BACKSTAB
        table.insert(xpBreakdown, "Backstab: " .. XP_SOURCES.BACKSTAB)
    end
    
    if isWallbang then
        totalXP = totalXP + XP_SOURCES.WALLBANG
        table.insert(xpBreakdown, "Wallbang: " .. XP_SOURCES.WALLBANG)
    end
    
    if isQuickscope then
        totalXP = totalXP + XP_SOURCES.QUICKSCOPE
        table.insert(xpBreakdown, "Quickscope: " .. XP_SOURCES.QUICKSCOPE)
    end
    
    if isNoScope then
        totalXP = totalXP + XP_SOURCES.NO_SCOPE
        table.insert(xpBreakdown, "No Scope: " .. XP_SOURCES.NO_SCOPE)
    end
    
    -- Award XP
    self:awardXP(killer, totalXP, table.concat(xpBreakdown, ", "))
    
    -- Update weapon mastery
    if weaponUsed then
        self:updateWeaponMastery(killer, weaponUsed)
    end
    
    -- Update player attributes
    self:updatePlayerAttributes(killer)
    self:updatePlayerAttributes(victim)
    
    print(string.format("[XPLevelingSystem] %s killed %s (+%d XP)", killer.Name, victim.Name, totalXP))
end

-- Record assist and award XP
function XPLevelingSystem:recordAssist(assister, killer, victim)
    if not assister or assister == killer or assister == victim then return end
    
    local assisterData = self.playerData[assister.UserId]
    if not assisterData then return end
    
    -- Award assist XP
    self:awardXP(assister, XP_SOURCES.ASSIST, "Assist")
    
    print(string.format("[XPLevelingSystem] %s assisted kill on %s (+%d XP)", assister.Name, victim.Name, XP_SOURCES.ASSIST))
end

-- Update weapon mastery
function XPLevelingSystem:updateWeaponMastery(player, weaponName)
    local data = self.playerData[player.UserId]
    if not data then return end
    
    if not data.weaponMastery[weaponName] then
        data.weaponMastery[weaponName] = {
            kills = 0,
            level = 0,
            totalXP = 0
        }
    end
    
    local weaponData = data.weaponMastery[weaponName]
    weaponData.kills = weaponData.kills + 1
    weaponData.totalXP = weaponData.totalXP + 10 -- Base weapon XP per kill
    
    -- Check for weapon mastery level up (every 100 kills)
    local newLevel = math.floor(weaponData.kills / 100)
    if newLevel > weaponData.level then
        weaponData.level = newLevel
        
        -- Award mastery XP
        self:awardXP(player, XP_SOURCES.WEAPON_MASTERY, weaponName .. " Mastery Level " .. newLevel)
        
        print(string.format("[XPLevelingSystem] %s achieved %s mastery level %d", player.Name, weaponName, newLevel))
    end
end

-- Award objective XP
function XPLevelingSystem:awardObjectiveXP(player, objectiveType)
    local xpAmount = XP_SOURCES[objectiveType]
    if not xpAmount then
        warn("[XPLevelingSystem] Unknown objective type:", objectiveType)
        return
    end
    
    self:awardXP(player, xpAmount, objectiveType:gsub("_", " "):lower())
end

-- Check multi-kill and award bonus XP
function XPLevelingSystem:checkMultiKill(player, killCount, timeWindow)
    if killCount < 2 then return end
    
    local bonusXP = 0
    local multiKillType = ""
    
    if killCount == 2 then
        bonusXP = XP_SOURCES.DOUBLE_KILL
        multiKillType = "Double Kill"
    elseif killCount == 3 then
        bonusXP = XP_SOURCES.TRIPLE_KILL
        multiKillType = "Triple Kill"
    elseif killCount >= 4 then
        bonusXP = XP_SOURCES.QUAD_KILL
        multiKillType = "Quad Kill"
    end
    
    if bonusXP > 0 then
        self:awardXP(player, bonusXP, multiKillType)
        print(string.format("[XPLevelingSystem] %s achieved %s (+%d XP)", player.Name, multiKillType, bonusXP))
    end
end

-- Get player level and XP info
function XPLevelingSystem:getPlayerStats(player)
    local data = self.playerData[player.UserId]
    if not data then return nil end
    
    return {
        level = data.level,
        totalXP = data.totalXP,
        currentLevelXP = data.currentLevelXP,
        xpToNextLevel = self:getXPForNextLevel(data.level),
        credits = data.credits,
        totalKills = data.totalKills,
        totalDeaths = data.totalDeaths,
        totalKDR = data.totalKDR,
        matchKills = data.matchKills,
        matchDeaths = data.matchDeaths,
        matchKDR = data.matchKDR
    }
end

-- Reset match stats (called at end of match)
function XPLevelingSystem:resetMatchStats(player)
    local data = self.playerData[player.UserId]
    if not data then return end
    
    data.matchKills = 0
    data.matchDeaths = 0
    data.matchKDR = 0
    
    self:updatePlayerAttributes(player)
end

-- Spend credits
function XPLevelingSystem:spendCredits(player, amount)
    local data = self.playerData[player.UserId]
    if not data then return false end
    
    if data.credits >= amount then
        data.credits = data.credits - amount
        self:updatePlayerAttributes(player)
        return true
    end
    
    return false
end

-- Add credits (for purchases, refunds, etc.)
function XPLevelingSystem:addCredits(player, amount, reason)
    local data = self.playerData[player.UserId]
    if not data then return end
    
    data.credits = data.credits + amount
    self:updatePlayerAttributes(player)
    
    print(string.format("[XPLevelingSystem] Added %d credits to %s (%s)", amount, player.Name, reason or "Unknown"))
end

-- Check if player has unlocked weapon based on level
function XPLevelingSystem:hasUnlockedWeapon(player, weaponName, requiredLevel)
    local data = self.playerData[player.UserId]
    if not data then return false end
    
    -- Check level requirement
    if data.level >= requiredLevel then
        return true
    end
    
    -- Check if pre-bought
    return data.unlockedWeapons[weaponName] == true
end

-- Unlock weapon (by purchase or level)
function XPLevelingSystem:unlockWeapon(player, weaponName)
    local data = self.playerData[player.UserId]
    if not data then return end
    
    data.unlockedWeapons[weaponName] = true
end

-- Auto-save system
function XPLevelingSystem:startAutoSave()
    spawn(function()
        while true do
            wait(300) -- Save every 5 minutes
            for _, player in ipairs(Players:GetPlayers()) do
                self:savePlayerData(player)
            end
        end
    end)
end

-- Cleanup
function XPLevelingSystem:cleanup()
    print("[XPLevelingSystem] Cleaning up XP system...")
    
    -- Save all player data
    for _, player in ipairs(Players:GetPlayers()) do
        self:savePlayerData(player)
    end
    
    print("[XPLevelingSystem] XP system cleanup complete")
end

return XPLevelingSystem