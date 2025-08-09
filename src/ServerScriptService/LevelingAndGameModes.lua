-- LevelingAndGameModes.lua
-- Complete leveling system and game mode manager
-- Place in ServerScriptService

local LevelingSystem = {}
local GameModeManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")

-- Create RemoteEvents folder if needed
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Create remote events
local xpEvent = Instance.new("RemoteEvent")
xpEvent.Name = "UpdateXP"
xpEvent.Parent = remoteEvents

local levelUpEvent = Instance.new("RemoteEvent")
levelUpEvent.Name = "LevelUp"
levelUpEvent.Parent = remoteEvents

local gameModeEvent = Instance.new("RemoteEvent")
gameModeEvent.Name = "GameModeUpdate"
gameModeEvent.Parent = remoteEvents

--====================--
-- LEVELING SYSTEM
--====================--

LevelingSystem.playerData = {}

-- XP requirements per level
LevelingSystem.xpTable = {}
for i = 1, 100 do
    LevelingSystem.xpTable[i] = math.floor(1000 * (1.15 ^ (i - 1)))
end

-- XP rewards
LevelingSystem.xpRewards = {
    kill = 100,
    headshot = 150,
    assist = 50,
    objective = 200,
    win = 500,
    loss = 200,
    captureFlag = 300,
    defendPoint = 150,
    longshot = 125,
    multikill = 250,
    revenge = 75,
    savior = 100,
    firstBlood = 200
}

-- Initialize player data
function LevelingSystem:initPlayer(player)
    if not self.playerData[player.UserId] then
        self.playerData[player.UserId] = {
            level = 1,
            xp = 0,
            totalXp = 0,
            kills = 0,
            deaths = 0,
            assists = 0,
            headshots = 0,
            playtime = 0,
            unlockedWeapons = {"G36", "M9", "Knife", "M67 Frag"},
            achievements = {}
        }
    end

    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = self.playerData[player.UserId].level
    level.Parent = leaderstats

    local kills = Instance.new("IntValue")
    kills.Name = "Kills"
    kills.Value = self.playerData[player.UserId].kills
    kills.Parent = leaderstats

    local deaths = Instance.new("IntValue")
    deaths.Name = "Deaths"
    deaths.Value = self.playerData[player.UserId].deaths
    deaths.Parent = leaderstats

    print("Initialized player data for", player.Name)
end

-- Award XP
function LevelingSystem:awardXP(player, amount, reason)
    local userId = player.UserId
    local data = self.playerData[userId]

    if not data then return end

    data.xp = data.xp + amount
    data.totalXp = data.totalXp + amount

    -- Check for level up
    local requiredXp = self.xpTable[data.level]

    while data.xp >= requiredXp and data.level < 100 do
        data.xp = data.xp - requiredXp
        data.level = data.level + 1

        -- Update leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local levelValue = leaderstats:FindFirstChild("Level")
            if levelValue then
                levelValue.Value = data.level
            end
        end

        -- Unlock rewards
        self:checkUnlocks(player, data.level)

        -- Fire level up event
        levelUpEvent:FireClient(player, data.level)

        print(player.Name, "leveled up to", data.level)

        -- Get next requirement
        requiredXp = self.xpTable[data.level]
    end

    -- Update client
    xpEvent:FireClient(player, data.xp, requiredXp, amount, reason)
end

-- Check weapon unlocks
function LevelingSystem:checkUnlocks(player, level)
    local data = self.playerData[player.UserId]

    local unlocks = {
        [5] = {"UMP45", "Flashbang"},
        [8] = {"M4A1"},
        [10] = {"Machete"},
        [12] = {"Smoke"},
        [15] = {"AK-47", "Baseball Bat"},
        [20] = {"AWP", "Semtex"},
        [25] = {"Decoy"},
        [30] = {"SCAR-H", "AUG A3", "Impact"},
        [40] = {"Katana"},
        [50] = {"Desert Eagle"},
        [75] = {"NTW-20"}
    }

    if unlocks[level] then
        for _, weapon in ipairs(unlocks[level]) do
            table.insert(data.unlockedWeapons, weapon)
            print(player.Name, "unlocked", weapon)
        end
    end
end

-- Track player kill
function LevelingSystem:onPlayerKill(killer, victim, isHeadshot)
    if not killer or not victim then return end

    local killerData = self.playerData[killer.UserId]
    local victimData = self.playerData[victim.UserId]

    if killerData then
        killerData.kills = killerData.kills + 1

        -- Update leaderstats
        local leaderstats = killer:FindFirstChild("leaderstats")
        if leaderstats then
            local kills = leaderstats:FindFirstChild("Kills")
            if kills then
                kills.Value = killerData.kills
            end
        end

        -- Award XP
        if isHeadshot then
            killerData.headshots = killerData.headshots + 1
            self:awardXP(killer, self.xpRewards.headshot, "Headshot")
        else
            self:awardXP(killer, self.xpRewards.kill, "Kill")
        end
    end

    if victimData then
        victimData.deaths = victimData.deaths + 1

        -- Update leaderstats
        local leaderstats = victim:FindFirstChild("leaderstats")
        if leaderstats then
            local deaths = leaderstats:FindFirstChild("Deaths")
            if deaths then
                deaths.Value = victimData.deaths
            end
        end
    end
end

--====================--
-- GAME MODE MANAGER
--====================--

GameModeManager.currentMode = nil
GameModeManager.modeActive = false
GameModeManager.scores = {team1 = 0, team2 = 0}
GameModeManager.timeRemaining = 0
GameModeManager.objectives = {}

-- Game mode configurations
GameModeManager.modes = {
    TDM = {
        name = "Team Deathmatch",
        description = "First team to reach the score limit wins",
        scoreLimit = 75,
        timeLimit = 600, -- 10 minutes
        respawnTime = 5,
        teams = 2
    },
    KOTH = {
        name = "King of the Hill",
        description = "Control the hill to earn points",
        scoreLimit = 300,
        timeLimit = 600,
        respawnTime = 8,
        teams = 2,
        hillTime = 1, -- Points per second
        contestedMultiplier = 0 -- No points when contested
    },
    CTF = {
        name = "Capture the Flag",
        description = "Capture the enemy flag and return it to your base",
        scoreLimit = 3,
        timeLimit = 900, -- 15 minutes
        respawnTime = 10,
        teams = 2,
        flagReturnTime = 30
    },
    FFA = {
        name = "Free For All",
        description = "Every player for themselves",
        scoreLimit = 30,
        timeLimit = 600,
        respawnTime = 3,
        teams = 0
    }
}

-- Initialize game mode
function GameModeManager:init(modeName)
    local modeConfig = self.modes[modeName]
    if not modeConfig then
        warn("Invalid game mode:", modeName)
        return
    end

    self.currentMode = modeConfig
    self.modeActive = true
    self.scores = {team1 = 0, team2 = 0}
    self.timeRemaining = modeConfig.timeLimit

    print("Initializing game mode:", modeConfig.name)

    -- Create teams if needed
    if modeConfig.teams > 0 then
        self:createTeams()
    end

    -- Set up objectives
    if modeName == "KOTH" then
        self:setupKOTH()
    elseif modeName == "CTF" then
        self:setupCTF()
    end

    -- Start game loop
    self:startGameLoop()

    -- Notify clients
    gameModeEvent:FireAllClients("ModeStart", modeName, modeConfig)
end

-- Create teams
function GameModeManager:createTeams()
    -- Team 1
    local team1 = Teams:FindFirstChild("Team1")
    if not team1 then
        team1 = Instance.new("Team")
        team1.Name = "Team1"
        team1.TeamColor = BrickColor.new("Really blue")
        team1.Parent = Teams
    end

    -- Team 2
    local team2 = Teams:FindFirstChild("Team2")
    if not team2 then
        team2 = Instance.new("Team")
        team2.Name = "Team2"
        team2.TeamColor = BrickColor.new("Really red")
        team2.Parent = Teams
    end

    -- Auto-assign players
    local players = Players:GetPlayers()
    for i, player in ipairs(players) do
        if i % 2 == 0 then
            player.Team = team1
        else
            player.Team = team2
        end
    end
end

-- Setup King of the Hill
function GameModeManager:setupKOTH()
    -- Create hill zone
    local hill = workspace:FindFirstChild("HillZone")
    if not hill then
        hill = Instance.new("Part")
        hill.Name = "HillZone"
        hill.Size = Vector3.new(20, 10, 20)
        hill.Position = Vector3.new(0, 5, 0)
        hill.Anchored = true
        hill.CanCollide = false
        hill.Transparency = 0.5
        hill.BrickColor = BrickColor.new("Institutional white")
        hill.Parent = workspace
    end

    self.objectives.hill = hill
    self.objectives.controllingTeam = nil
    self.objectives.playersInHill = {}

    -- Monitor hill control
    RunService.Heartbeat:Connect(function()
        if self.modeActive and self.currentMode.name == "King of the Hill" then
            self:updateHillControl()
        end
    end)
end

-- Update hill control
function GameModeManager:updateHillControl()
    local hill = self.objectives.hill
    if not hill then return end

    local team1Count = 0
    local team2Count = 0

    -- Count players in hill
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - hill.Position).Magnitude

            if distance <= hill.Size.Magnitude / 2 then
                if player.Team and player.Team.Name == "Team1" then
                    team1Count = team1Count + 1
                elseif player.Team and player.Team.Name == "Team2" then
                    team2Count = team2Count + 1
                end
            end
        end
    end

    -- Determine control
    if team1Count > team2Count then
        self.objectives.controllingTeam = "Team1"
        hill.BrickColor = BrickColor.new("Really blue")
    elseif team2Count > team1Count then
        self.objectives.controllingTeam = "Team2"
        hill.BrickColor = BrickColor.new("Really red")
    else
        self.objectives.controllingTeam = nil
        hill.BrickColor = BrickColor.new("Institutional white")
    end
end

-- Setup Capture the Flag
function GameModeManager:setupCTF()
    -- Create flags
    local flag1 = self:createFlag("Team1Flag", Vector3.new(-50, 5, 0), BrickColor.new("Really blue"))
    local flag2 = self:createFlag("Team2Flag", Vector3.new(50, 5, 0), BrickColor.new("Really red"))

    self.objectives.flags = {
        Team1 = {flag = flag1, home = flag1.Position, carrier = nil},
        Team2 = {flag = flag2, home = flag2.Position, carrier = nil}
    }
end

-- Create flag
function GameModeManager:createFlag(name, position, color)
    local flag = Instance.new("Part")
    flag.Name = name
    flag.Size = Vector3.new(2, 6, 2)
    flag.Position = position
    flag.Anchored = true
    flag.BrickColor = color
    flag.Parent = workspace

    -- Add flag mesh or model here

    return flag
end

-- Main game loop
function GameModeManager:startGameLoop()
    spawn(function()
        while self.modeActive do
            wait(1)

            -- Update timer
            self.timeRemaining = self.timeRemaining - 1

            -- Update scores for KOTH
            if self.currentMode.name == "King of the Hill" and self.objectives.controllingTeam then
                if self.objectives.controllingTeam == "Team1" then
                    self.scores.team1 = self.scores.team1 + self.currentMode.hillTime
                else
                    self.scores.team2 = self.scores.team2 + self.currentMode.hillTime
                end
            end

            -- Check win conditions
            if self:checkWinCondition() then
                self:endGame()
                break
            end

            -- Update clients
            gameModeEvent:FireAllClients("Update", {
                scores = self.scores,
                time = self.timeRemaining,
                objectives = self.objectives
            })
        end
    end)
end

-- Check win condition
function GameModeManager:checkWinCondition()
    -- Time limit
    if self.timeRemaining <= 0 then
        return true
    end

    -- Score limit
    if self.scores.team1 >= self.currentMode.scoreLimit or 
        self.scores.team2 >= self.currentMode.scoreLimit then
        return true
    end

    return false
end

-- End game
function GameModeManager:endGame()
    self.modeActive = false

    local winner = self.scores.team1 > self.scores.team2 and "Team1" or "Team2"

    print("Game ended! Winner:", winner)

    -- Award XP
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team then
            if player.Team.Name == winner then
                LevelingSystem:awardXP(player, LevelingSystem.xpRewards.win, "Victory")
            else
                LevelingSystem:awardXP(player, LevelingSystem.xpRewards.loss, "Defeat")
            end
        end
    end

    -- Notify clients
    gameModeEvent:FireAllClients("GameEnd", winner, self.scores)

    -- Reset after delay
    wait(10)
    self:reset()
end

-- Reset game
function GameModeManager:reset()
    self.currentMode = nil
    self.modeActive = false
    self.scores = {team1 = 0, team2 = 0}
    self.timeRemaining = 0
    self.objectives = {}

    -- Clean up objectives
    local hill = workspace:FindFirstChild("HillZone")
    if hill then hill:Destroy() end

    local flag1 = workspace:FindFirstChild("Team1Flag")
    if flag1 then flag1:Destroy() end

    local flag2 = workspace:FindFirstChild("Team2Flag")
    if flag2 then flag2:Destroy() end

    print("Game reset complete")
end

-- Score points (for TDM)
function GameModeManager:scorePoint(team, points)
    points = points or 1

    if team == "Team1" then
        self.scores.team1 = self.scores.team1 + points
    elseif team == "Team2" then
        self.scores.team2 = self.scores.team2 + points
    end
end

--====================--
-- INITIALIZATION
--====================--

-- Handle player join
Players.PlayerAdded:Connect(function(player)
    LevelingSystem:initPlayer(player)

    -- Handle character spawn
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")

        -- Handle death
        humanoid.Died:Connect(function()
            -- Find killer (simplified - you'd implement proper detection)
            local killer = nil -- Implement killer detection
            LevelingSystem:onPlayerKill(killer, player, false)
        end)
    end)
end)

-- Export systems
_G.LevelingSystem = LevelingSystem
_G.GameModeManager = GameModeManager

print("Leveling System and Game Mode Manager initialized")

return {LevelingSystem = LevelingSystem, GameModeManager = GameModeManager}