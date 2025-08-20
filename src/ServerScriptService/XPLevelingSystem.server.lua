-- XPLevelingSystem.server.lua
-- Manages XP, leveling, and credit rewards with progression tracking
-- Place in ServerScriptService

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")

-- Data store (in production, use proper DataStore)
local playerDataStore = DataStoreService:GetDataStore("FPSPlayerData")

-- XP Sources and values
local XP_VALUES = {
    -- Combat
    Kill = 100,
    Assist = 50,
    Headshot = 25,
    LongDistanceShot = 30, -- 100+ studs
    Wallbang = 40,
    Quickscope = 35,
    NoScope = 50,
    Backstab = 60,
    
    -- Multi-kills
    DoubleKill = 50,
    TripleKill = 100,
    QuadKill = 200,
    
    -- Objectives
    Capture = 150,
    Defend = 75,
    HoldObjective = 5, -- Per 10 seconds
    
    -- Spotting
    SpottedKill = 25,
    SpottedAssist = 15,
    
    -- Suppression
    Suppression = 10,
    
    -- Weapon mastery
    WeaponUnlock = 200,
    AttachmentUnlock = 100
}

-- Credit formulas
local CREDIT_FORMULAS = {
    -- Rank 1-20: ((rank-1) * 5) + 200
    -- Rank 21+: (rank * 5) + 200
    getRankReward = function(rank)
        if rank <= 20 then
            return ((rank - 1) * 5) + 200
        else
            return (rank * 5) + 200
        end
    end,
    
    -- XP = 1000 × ((rank² + rank) ÷ 2)
    getXPForRank = function(rank)
        return 1000 * ((rank * rank + rank) / 2)
    end,
    
    -- Solve for rank from XP
    getRankFromXP = function(xp)
        local rank = math.floor((-1 + math.sqrt(1 + 8 * xp / 1000)) / 2)
        return math.max(0, rank)
    end
}

-- XP and Leveling System
local XPLevelingSystem = {}
XPLevelingSystem.playerData = {}
XPLevelingSystem.sessionStats = {}

-- Remote events for client communication
local remoteEvents = {}

function XPLevelingSystem:initialize()
    print("[XPLevelingSystem] Initializing XP and leveling system...")
    
    -- Create remote events
    self:createRemoteEvents()
    
    -- Setup player connections
    self:setupPlayerConnections()
    
    -- Setup data saving
    self:setupDataSaving()
    
    print("[XPLevelingSystem] XP and leveling system initialized")
end

function XPLevelingSystem:createRemoteEvents()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        fpsSystem = Instance.new("Folder")
        fpsSystem.Name = "FPSSystem"
        fpsSystem.Parent = ReplicatedStorage
    end
    
    local remoteEventsFolder = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = fpsSystem
    end
    
    -- XP Update event
    local xpUpdateEvent = Instance.new("RemoteEvent")
    xpUpdateEvent.Name = "XPUpdate"
    xpUpdateEvent.Parent = remoteEventsFolder
    remoteEvents.XPUpdate = xpUpdateEvent
    
    -- Rank Up event
    local rankUpEvent = Instance.new("RemoteEvent")
    rankUpEvent.Name = "RankUp"
    rankUpEvent.Parent = remoteEventsFolder
    remoteEvents.RankUp = rankUpEvent
    
    -- Stats Request event
    local statsRequestEvent = Instance.new("RemoteEvent")
    statsRequestEvent.Name = "StatsRequest"
    statsRequestEvent.Parent = remoteEventsFolder
    remoteEvents.StatsRequest = statsRequestEvent
    
    -- Handle client requests
    statsRequestEvent.OnServerEvent:Connect(function(player)
        self:sendPlayerStats(player)
    end)
    
    print("[XPLevelingSystem] Remote events created")
end

function XPLevelingSystem:setupPlayerConnections()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerAdded(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:onPlayerAdded(player)
    end
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeaving(player)
    end)
end

function XPLevelingSystem:setupDataSaving()
    -- Auto-save every 5 minutes
    game:BindToClose(function()
        self:saveAllPlayerData()
    end)
    
    -- Periodic auto-save
    task.spawn(function()
        while true do
            task.wait(300) -- 5 minutes
            self:saveAllPlayerData()
        end
    end)
end

function XPLevelingSystem:onPlayerAdded(player)
    print("[XPLevelingSystem] Loading data for player:", player.Name)
    
    -- Load player data
    self:loadPlayerData(player)
    
    -- Create leaderstats
    self:createLeaderstats(player)
    
    -- Initialize session stats
    self.sessionStats[player.UserId] = {
        sessionXP = 0,
        sessionKills = 0,
        sessionDeaths = 0,
        sessionScore = 0,
        currentStreak = 0,
        bestStreak = 0,
        lastKillTime = 0
    }
    
    -- Send initial stats to client
    task.wait(1) -- Wait for client to load
    self:sendPlayerStats(player)
end

function XPLevelingSystem:onPlayerLeaving(player)
    print("[XPLevelingSystem] Saving data for player:", player.Name)
    
    -- Save player data
    self:savePlayerData(player)
    
    -- Clean up session data
    self.sessionStats[player.UserId] = nil
end

function XPLevelingSystem:loadPlayerData(player)
    local userId = player.UserId
    
    -- Try to load from DataStore
    local success, data = pcall(function()
        return playerDataStore:GetAsync(tostring(userId))
    end)
    
    if success and data then
        self.playerData[userId] = data
        print(string.format("[XPLevelingSystem] Loaded data for %s: Level %d, %d XP, %d credits", 
            player.Name, data.level, data.xp, data.credits))
    else
        -- Create new player data
        self.playerData[userId] = {
            level = 0,
            xp = 0,
            credits = 200, -- Starting credits
            totalKills = 0,
            totalDeaths = 0,
            totalScore = 0,
            playtime = 0,
            joinedTimestamp = os.time(),
            weaponStats = {}, -- Per-weapon kill tracking
            achievements = {},
            settings = {
                sensitivity = 1.0,
                ragdollFactor = 1.0,
                fov = 90
            }
        }
        print(string.format("[XPLevelingSystem] Created new data for %s", player.Name))
    end
end

function XPLevelingSystem:createLeaderstats(player)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    
    if not playerData then
        warn("[XPLevelingSystem] No player data found for leaderstats creation:", player.Name)
        return
    end
    
    -- Create leaderstats folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- Level/Rank
    local rankValue = Instance.new("IntValue")
    rankValue.Name = "Rank"
    rankValue.Value = playerData.level
    rankValue.Parent = leaderstats
    
    -- Kills
    local killsValue = Instance.new("IntValue")
    killsValue.Name = "Kills"
    killsValue.Value = playerData.totalKills
    killsValue.Parent = leaderstats
    
    -- Deaths
    local deathsValue = Instance.new("IntValue")
    deathsValue.Name = "Deaths"
    deathsValue.Value = playerData.totalDeaths
    deathsValue.Parent = leaderstats
    
    -- Credits
    local creditsValue = Instance.new("IntValue")
    creditsValue.Name = "Credits"
    creditsValue.Value = playerData.credits
    creditsValue.Parent = leaderstats
    
    -- XP
    local xpValue = Instance.new("IntValue")
    xpValue.Name = "XP"
    xpValue.Value = playerData.xp
    xpValue.Parent = leaderstats
    
    print(string.format("[XPLevelingSystem] Created leaderstats for %s - Level: %d, Credits: %d", 
        player.Name, playerData.level, playerData.credits))
end

function XPLevelingSystem:updateLeaderstats(player)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    local leaderstats = player:FindFirstChild("leaderstats")
    
    if not playerData or not leaderstats then return end
    
    -- Update all leaderstats values
    if leaderstats:FindFirstChild("Rank") then
        leaderstats.Rank.Value = playerData.level
    end
    
    if leaderstats:FindFirstChild("Kills") then
        leaderstats.Kills.Value = playerData.totalKills
    end
    
    if leaderstats:FindFirstChild("Deaths") then
        leaderstats.Deaths.Value = playerData.totalDeaths
    end
    
    if leaderstats:FindFirstChild("Credits") then
        leaderstats.Credits.Value = playerData.credits
    end
    
    if leaderstats:FindFirstChild("XP") then
        leaderstats.XP.Value = playerData.xp
    end
end

function XPLevelingSystem:savePlayerData(player)
    local userId = player.UserId
    local data = self.playerData[userId]
    
    if not data then return end
    
    local success, error = pcall(function()
        playerDataStore:SetAsync(tostring(userId), data)
    end)
    
    if success then
        print(string.format("[XPLevelingSystem] Saved data for %s", player.Name))
    else
        warn(string.format("[XPLevelingSystem] Failed to save data for %s: %s", player.Name, error))
    end
end

function XPLevelingSystem:saveAllPlayerData()
    print("[XPLevelingSystem] Auto-saving all player data...")
    
    for _, player in pairs(Players:GetPlayers()) do
        self:savePlayerData(player)
    end
    
    print("[XPLevelingSystem] Auto-save complete")
end

function XPLevelingSystem:addXP(player, amount, reason, details)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    local sessionData = self.sessionStats[userId]
    
    if not playerData or not sessionData then return end
    
    -- Add XP
    playerData.xp = playerData.xp + amount
    sessionData.sessionXP = sessionData.sessionXP + amount
    
    -- Check for level up
    local newLevel = CREDIT_FORMULAS.getRankFromXP(playerData.xp)
    local oldLevel = playerData.level
    
    if newLevel > oldLevel then
        self:levelUp(player, newLevel, oldLevel)
    end
    
    -- Update leaderstats
    self:updateLeaderstats(player)
    
    -- Send XP update to client
    remoteEvents.XPUpdate:FireClient(player, {
        xpGained = amount,
        reason = reason,
        details = details,
        totalXP = playerData.xp,
        level = playerData.level,
        credits = playerData.credits
    })
    
    print(string.format("[XPLevelingSystem] %s gained %d XP (%s) - Total: %d", 
        player.Name, amount, reason or "Unknown", playerData.xp))
end

function XPLevelingSystem:levelUp(player, newLevel, oldLevel)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    
    playerData.level = newLevel
    
    -- Calculate credit reward
    local creditReward = CREDIT_FORMULAS.getRankReward(newLevel)
    playerData.credits = playerData.credits + creditReward
    
    -- Update leaderstats
    self:updateLeaderstats(player)
    
    -- Send rank up notification to client
    remoteEvents.RankUp:FireClient(player, {
        oldLevel = oldLevel,
        newLevel = newLevel,
        creditReward = creditReward,
        totalCredits = playerData.credits
    })
    
    print(string.format("[XPLevelingSystem] %s ranked up! %d -> %d (+%d credits)", 
        player.Name, oldLevel, newLevel, creditReward))
end

function XPLevelingSystem:awardKill(player, victim, weapon, distance, headshot, wallbang, quickscope, noscope)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    local sessionData = self.sessionStats[userId]
    
    if not playerData or not sessionData then return end
    
    -- Update kill stats
    playerData.totalKills = playerData.totalKills + 1
    sessionData.sessionKills = sessionData.sessionKills + 1
    sessionData.currentStreak = sessionData.currentStreak + 1
    
    if sessionData.currentStreak > sessionData.bestStreak then
        sessionData.bestStreak = sessionData.currentStreak
    end
    
    -- Track weapon kills
    if weapon then
        if not playerData.weaponStats[weapon] then
            playerData.weaponStats[weapon] = {kills = 0, headshots = 0}
        end
        playerData.weaponStats[weapon].kills = playerData.weaponStats[weapon].kills + 1
        
        if headshot then
            playerData.weaponStats[weapon].headshots = playerData.weaponStats[weapon].headshots + 1
        end
    end
    
    -- Calculate XP rewards
    local totalXP = XP_VALUES.Kill
    local bonuses = {"Kill"}
    
    if headshot then
        totalXP = totalXP + XP_VALUES.Headshot
        table.insert(bonuses, "Headshot")
    end
    
    if distance and distance >= 100 then
        totalXP = totalXP + XP_VALUES.LongDistanceShot
        table.insert(bonuses, "Long Distance")
    end
    
    if wallbang then
        totalXP = totalXP + XP_VALUES.Wallbang
        table.insert(bonuses, "Wallbang")
    end
    
    if quickscope then
        totalXP = totalXP + XP_VALUES.Quickscope
        table.insert(bonuses, "Quickscope")
    end
    
    if noscope then
        totalXP = totalXP + XP_VALUES.NoScope
        table.insert(bonuses, "No Scope")
    end
    
    -- Multi-kill bonuses
    local timeSinceLastKill = tick() - sessionData.lastKillTime
    if timeSinceLastKill < 5 then -- Within 5 seconds
        local streak = sessionData.currentStreak
        if streak == 2 then
            totalXP = totalXP + XP_VALUES.DoubleKill
            table.insert(bonuses, "Double Kill")
        elseif streak == 3 then
            totalXP = totalXP + XP_VALUES.TripleKill
            table.insert(bonuses, "Triple Kill")
        elseif streak >= 4 then
            totalXP = totalXP + XP_VALUES.QuadKill
            table.insert(bonuses, "Quad Kill+")
        end
    end
    
    sessionData.lastKillTime = tick()
    
    -- Award XP
    self:addXP(player, totalXP, table.concat(bonuses, " + "), {
        victim = victim and victim.Name or "Unknown",
        weapon = weapon,
        distance = distance,
        streak = sessionData.currentStreak
    })
end

function XPLevelingSystem:awardDeath(player, killer)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    local sessionData = self.sessionStats[userId]
    
    if not playerData or not sessionData then return end
    
    -- Update death stats
    playerData.totalDeaths = playerData.totalDeaths + 1
    sessionData.sessionDeaths = sessionData.sessionDeaths + 1
    sessionData.currentStreak = 0 -- Reset kill streak
    
    -- Update leaderstats
    self:updateLeaderstats(player)
end

function XPLevelingSystem:awardObjective(player, objectiveType, points)
    local xpAmount = XP_VALUES[objectiveType] or points or 50
    
    self:addXP(player, xpAmount, objectiveType, {
        points = points
    })
end

function XPLevelingSystem:awardAssist(player, killer, victim)
    self:addXP(player, XP_VALUES.Assist, "Assist", {
        killer = killer and killer.Name or "Unknown",
        victim = victim and victim.Name or "Unknown"
    })
end

function XPLevelingSystem:awardSpotting(player, spottedPlayer, action)
    local xpAmount = action == "kill" and XP_VALUES.SpottedKill or XP_VALUES.SpottedAssist
    
    self:addXP(player, xpAmount, "Spotted " .. action, {
        spotted = spottedPlayer and spottedPlayer.Name or "Unknown"
    })
end

function XPLevelingSystem:deductCredits(player, amount, reason)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    
    if not playerData then return false end
    
    if playerData.credits < amount then
        return false -- Insufficient credits
    end
    
    playerData.credits = playerData.credits - amount
    
    -- Update leaderstats
    self:updateLeaderstats(player)
    
    print(string.format("[XPLevelingSystem] %s spent %d credits (%s) - Remaining: %d", 
        player.Name, amount, reason or "Unknown", playerData.credits))
    
    return true
end

function XPLevelingSystem:addCredits(player, amount, reason)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    
    if not playerData then return false end
    
    playerData.credits = playerData.credits + amount
    
    -- Update leaderstats
    self:updateLeaderstats(player)
    
    print(string.format("[XPLevelingSystem] %s earned %d credits (%s) - Total: %d", 
        player.Name, amount, reason or "Unknown", playerData.credits))
    
    return true
end

function XPLevelingSystem:getPlayerStats(player)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    local sessionData = self.sessionStats[userId]
    
    if not playerData or not sessionData then return nil end
    
    local nextLevelXP = CREDIT_FORMULAS.getXPForRank(playerData.level + 1)
    local currentLevelXP = CREDIT_FORMULAS.getXPForRank(playerData.level)
    
    return {
        -- Persistent stats
        level = playerData.level,
        xp = playerData.xp,
        xpForNext = nextLevelXP,
        xpProgress = playerData.xp - currentLevelXP,
        xpNeeded = nextLevelXP - playerData.xp,
        credits = playerData.credits,
        totalKills = playerData.totalKills,
        totalDeaths = playerData.totalDeaths,
        totalKDR = playerData.totalDeaths > 0 and (playerData.totalKills / playerData.totalDeaths) or playerData.totalKills,
        playtime = playerData.playtime,
        
        -- Session stats
        sessionXP = sessionData.sessionXP,
        sessionKills = sessionData.sessionKills,
        sessionDeaths = sessionData.sessionDeaths,
        sessionKDR = sessionData.sessionDeaths > 0 and (sessionData.sessionKills / sessionData.sessionDeaths) or sessionData.sessionKills,
        currentStreak = sessionData.currentStreak,
        bestStreak = sessionData.bestStreak,
        
        -- Weapon stats
        weaponStats = playerData.weaponStats
    }
end

function XPLevelingSystem:sendPlayerStats(player)
    local stats = self:getPlayerStats(player)
    if stats then
        remoteEvents.StatsRequest:FireClient(player, stats)
    end
end

function XPLevelingSystem:spendCredits(player, amount, item)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    
    if not playerData then return false, "Player data not found" end
    
    if playerData.credits < amount then
        return false, string.format("Insufficient credits (need %d, have %d)", amount, playerData.credits)
    end
    
    playerData.credits = playerData.credits - amount
    
    -- Update leaderstats
    self:updateLeaderstats(player)
    
    print(string.format("[XPLevelingSystem] %s spent %d credits on %s", player.Name, amount, item or "Unknown"))
    
    return true, string.format("Purchased %s for %d credits", item or "item", amount)
end


-- Admin functions
function XPLevelingSystem:setPlayerLevel(player, level)
    local userId = player.UserId
    local playerData = self.playerData[userId]
    
    if not playerData then return false end
    
    local targetXP = CREDIT_FORMULAS.getXPForRank(level)
    playerData.xp = targetXP
    playerData.level = level
    
    self:sendPlayerStats(player)
    
    print(string.format("[XPLevelingSystem] Set %s to level %d", player.Name, level))
    return true
end

function XPLevelingSystem:resetPlayerStats(player)
    local userId = player.UserId
    
    self.playerData[userId] = {
        level = 0,
        xp = 0,
        credits = 200,
        totalKills = 0,
        totalDeaths = 0,
        totalScore = 0,
        playtime = 0,
        joinedTimestamp = os.time(),
        weaponStats = {},
        achievements = {},
        settings = {
            sensitivity = 1.0,
            ragdollFactor = 1.0,
            fov = 90
        }
    }
    
    self:sendPlayerStats(player)
    
    print(string.format("[XPLevelingSystem] Reset stats for %s", player.Name))
end

-- Initialize the system
XPLevelingSystem:initialize()

-- Global access for other scripts
_G.XPLevelingSystem = XPLevelingSystem

return XPLevelingSystem