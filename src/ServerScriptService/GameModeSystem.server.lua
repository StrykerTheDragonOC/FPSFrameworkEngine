-- GameModeSystem.server.lua  
-- Manages game modes and 20-minute rotation cycle
-- Place in ServerScriptService

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

-- Game mode system
local GameModeSystem = {}
GameModeSystem.currentMode = nil
GameModeSystem.currentModeData = {}
GameModeSystem.modeStartTime = 0
GameModeSystem.isGameActive = false
GameModeSystem.playerStats = {}
GameModeSystem.isCountdownActive = false
GameModeSystem.countdownEndTime = 0
GameModeSystem.isVotingActive = false
GameModeSystem.votingEndTime = 0
GameModeSystem.modeVotes = {}

-- Game mode configurations
local GAME_MODES = {
    ["TDM"] = {
        name = "Team Deathmatch",
        displayName = "Team Deathmatch",
        description = "Eliminate enemy team members to score points",
        duration = 1200, -- 20 minutes
        scoreLimit = 100,
        objectives = {},
        spawning = "team_based",
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 5,
            weapon_drops = false
        }
    },
    
    ["KOTH"] = {
        name = "King of the Hill", 
        displayName = "King of the Hill",
        description = "Control the hill to earn points for your team",
        duration = 1200,
        scoreLimit = 300, -- Points over time
        objectives = {"hill_control"},
        spawning = "team_based",
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 3,
            weapon_drops = false,
            hill_points_per_second = 1
        }
    },
    
    ["KC"] = {
        name = "Kill Confirmed",
        displayName = "Kill Confirmed", 
        description = "Collect enemy dog tags to confirm kills",
        duration = 1200,
        scoreLimit = 65,
        objectives = {"dog_tags"},
        spawning = "team_based", 
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 4,
            weapon_drops = false,
            tag_timeout = 30
        }
    },
    
    ["CTF"] = {
        name = "Capture the Flag",
        displayName = "Capture the Flag",
        description = "Capture the enemy flag and return it to your base",
        duration = 1200,
        scoreLimit = 5,
        objectives = {"flag_capture"},
        spawning = "team_based",
        winCondition = "score_limit", 
        rules = {
            friendly_fire = false,
            respawn_time = 6,
            weapon_drops = false,
            flag_return_time = 60
        }
    },
    
    ["FD"] = {
        name = "Flare Domination",
        displayName = "Flare Domination",
        description = "Control capture points marked by flares",
        duration = 1200,
        scoreLimit = 200,
        objectives = {"flare_points"},
        spawning = "team_based",
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 4,
            weapon_drops = false,
            points_per_flare = 2,
            capture_time = 10
        }
    },
    
    ["HD"] = {
        name = "Hardpoint",
        displayName = "Hardpoint",
        description = "Control rotating hardpoints to earn score",
        duration = 1200,
        scoreLimit = 250,
        objectives = {"hardpoint_control"},
        spawning = "team_based", 
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 3,
            weapon_drops = false,
            rotation_time = 90,
            points_per_second = 2
        }
    },
    
    ["GG"] = {
        name = "Gun Game",
        displayName = "Gun Game", 
        description = "Progress through weapons by getting kills",
        duration = 1200,
        scoreLimit = 25, -- Number of weapon tiers
        objectives = {},
        spawning = "ffa",
        winCondition = "progression",
        rules = {
            friendly_fire = false,
            respawn_time = 2,
            weapon_drops = false,
            fixed_loadouts = true,
            knife_setback = true
        }
    },
    
    ["Duel"] = {
        name = "Duel",
        displayName = "Pistols Only Duel",
        description = "Secondary weapons only, one-on-one combat",
        duration = 600, -- 10 minutes
        scoreLimit = 15,
        objectives = {},
        spawning = "ffa",
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 3,
            weapon_drops = false,
            weapons_allowed = {"secondary"},
            max_players = 8
        }
    },
    
    ["KnifeFight"] = {
        name = "Knife Fight",
        displayName = "Knife Fight",
        description = "Melee weapons only, close combat",
        duration = 600, -- 10 minutes  
        scoreLimit = 20,
        objectives = {},
        spawning = "ffa",
        winCondition = "score_limit",
        rules = {
            friendly_fire = false,
            respawn_time = 2,
            weapon_drops = false,
            weapons_allowed = {"melee"},
            max_players = 12
        }
    }
}

-- Default rotation order
local MODE_ROTATION = {
    "TDM", "KOTH", "KC", "CTF", "FD", "HD", "GG", "Duel", "KnifeFight"
}

local currentModeIndex = 1

function GameModeSystem:initialize()
    print("[GameModeSystem] Initializing game mode system...")
    
    -- Create remote events
    self:createRemoteEvents()
    
    -- Setup teams
    self:setupTeams()
    
    -- Setup objectives based on map
    self:setupObjectives()
    
    -- Start first game mode
    self:startGameMode(MODE_ROTATION[currentModeIndex])
    
    print("[GameModeSystem] Game mode system initialized")
end

function GameModeSystem:createRemoteEvents()
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
    
    -- Game mode events
    local gameModeUpdate = Instance.new("RemoteEvent")
    gameModeUpdate.Name = "GameModeUpdate"
    gameModeUpdate.Parent = remoteEventsFolder
    
    local objectiveUpdate = Instance.new("RemoteEvent")
    objectiveUpdate.Name = "ObjectiveUpdate"
    objectiveUpdate.Parent = remoteEventsFolder
    
    local scoreUpdate = Instance.new("RemoteEvent")
    scoreUpdate.Name = "ScoreUpdate" 
    scoreUpdate.Parent = remoteEventsFolder
    
    -- Voting system events
    local gameModeVote = Instance.new("RemoteEvent")
    gameModeVote.Name = "GameModeVote"
    gameModeVote.Parent = remoteEventsFolder
    
    local countdownUpdate = Instance.new("RemoteEvent")
    countdownUpdate.Name = "CountdownUpdate" 
    countdownUpdate.Parent = remoteEventsFolder
    
    -- Connect voting event
    gameModeVote.OnServerEvent:Connect(function(player, votedMode)
        self:handlePlayerVote(player, votedMode)
    end)
    
    print("[GameModeSystem] Remote events created")
end

function GameModeSystem:setupTeams()
    -- Teams should already be created by TeamSpawnSystem
    local fbiTeam = Teams:FindFirstChild("FBI")
    local kfcTeam = Teams:FindFirstChild("KFC")
    
    if not fbiTeam or not kfcTeam then
        warn("[GameModeSystem] Teams not found! Make sure TeamSpawnSystem is running.")
        return
    end
    
    -- Initialize team scores
    self.currentModeData.teamScores = {
        FBI = 0,
        KFC = 0
    }
    
    print("[GameModeSystem] Teams setup complete")
end

function GameModeSystem:setupObjectives()
    -- Find objectives folder in workspace
    local objectivesFolder = Workspace:FindFirstChild("Map")
    if objectivesFolder then
        objectivesFolder = objectivesFolder:FindFirstChild("Objectives")
    end
    
    if not objectivesFolder then
        warn("[GameModeSystem] No objectives folder found in Workspace.Map.Objectives")
        return
    end
    
    -- Setup different objective types
    self:setupHillObjectives(objectivesFolder)
    self:setupFlagObjectives(objectivesFolder)
    self:setupFlareObjectives(objectivesFolder)
    self:setupHardpointObjectives(objectivesFolder)
    
    print("[GameModeSystem] Objectives setup complete")
end

function GameModeSystem:setupHillObjectives(objectivesFolder)
    local hillFolder = objectivesFolder:FindFirstChild("Hill")
    if not hillFolder then return end
    
    self.currentModeData.hill = {
        part = hillFolder:FindFirstChild("HillZone"),
        controlled_by = nil,
        control_time = 0,
        players_in_hill = {FBI = {}, KFC = {}}
    }
end

function GameModeSystem:setupFlagObjectives(objectivesFolder)
    local flagsFolder = objectivesFolder:FindFirstChild("Flags")
    if not flagsFolder then return end
    
    self.currentModeData.flags = {
        FBI = {
            spawn = flagsFolder:FindFirstChild("FBI_Flag"),
            carrier = nil,
            at_base = true
        },
        KFC = {
            spawn = flagsFolder:FindFirstChild("KFC_Flag"),
            carrier = nil,
            at_base = true
        }
    }
end

function GameModeSystem:setupFlareObjectives(objectivesFolder)
    local flaresFolder = objectivesFolder:FindFirstChild("Flares")
    if not flaresFolder then return end
    
    self.currentModeData.flares = {}
    
    for _, flare in pairs(flaresFolder:GetChildren()) do
        if flare:IsA("BasePart") then
            table.insert(self.currentModeData.flares, {
                part = flare,
                controlled_by = nil,
                capture_progress = 0,
                capturing_team = nil
            })
        end
    end
end

function GameModeSystem:setupHardpointObjectives(objectivesFolder)
    local hardpointsFolder = objectivesFolder:FindFirstChild("Hardpoints")
    if not hardpointsFolder then return end
    
    self.currentModeData.hardpoints = {}
    local currentIndex = 1
    
    for _, hardpoint in pairs(hardpointsFolder:GetChildren()) do
        if hardpoint:IsA("BasePart") then
            table.insert(self.currentModeData.hardpoints, {
                part = hardpoint,
                active = false,
                controlled_by = nil,
                players_in_zone = {FBI = {}, KFC = {}}
            })
        end
    end
    
    -- Activate first hardpoint
    if #self.currentModeData.hardpoints > 0 then
        self.currentModeData.hardpoints[currentIndex].active = true
        self.currentModeData.currentHardpoint = currentIndex
    end
end

function GameModeSystem:startGameMode(modeName)
    local mode = GAME_MODES[modeName]
    if not mode then
        warn("[GameModeSystem] Unknown game mode:", modeName)
        return
    end
    
    print("[GameModeSystem] Starting game mode:", mode.displayName)
    
    -- Reset game state
    self:resetGameState()
    
    -- Set current mode
    self.currentMode = modeName
    self.modeStartTime = tick()
    self.isGameActive = true
    
    -- Reset team scores
    self.currentModeData.teamScores = {FBI = 0, KFC = 0}
    
    -- Setup mode-specific logic
    self:setupModeLogic(mode)
    
    -- Notify all players
    self:notifyGameModeStart(mode)
    
    -- Start game loop
    self:startGameLoop(mode)
    
    print("[GameModeSystem] Game mode started:", mode.displayName)
end

function GameModeSystem:setupModeLogic(mode)
    -- Reset player stats for new game
    self.playerStats = {}
    for _, player in pairs(Players:GetPlayers()) do
        self.playerStats[player.UserId] = {
            kills = 0,
            deaths = 0,
            score = 0,
            streak = 0,
            objectives = 0
        }
    end
    
    -- Mode-specific setup
    if mode.name == "Gun Game" then
        self:setupGunGameLogic()
    elseif mode.name == "Kill Confirmed" then
        self:setupKillConfirmedLogic()
    end
end

function GameModeSystem:setupGunGameLogic()
    -- Gun Game weapon progression
    local gunGameWeapons = {
        "G36", "M9", "MP5", "AK74", "M870", "AWM", "RPG", "Knife"
    }
    
    self.currentModeData.gunGameWeapons = gunGameWeapons
    self.currentModeData.playerWeaponTiers = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        self.currentModeData.playerWeaponTiers[player.UserId] = 1
    end
end

function GameModeSystem:setupKillConfirmedLogic()
    self.currentModeData.dogTags = {}
end

function GameModeSystem:startGameLoop(mode)
    -- Main game loop
    task.spawn(function()
        while self.isGameActive do
            local elapsed = tick() - self.modeStartTime
            local remaining = mode.duration - elapsed
            
            -- Check time limit
            if remaining <= 0 then
                self:endGameMode("time_limit")
                break
            end
            
            -- Update mode-specific logic
            self:updateModeLogic(mode)
            
            -- Check win conditions
            local winner = self:checkWinConditions(mode)
            if winner then
                self:endGameMode("win_condition", winner)
                break
            end
            
            -- Update UI
            self:updateGameModeUI(mode, remaining)
            
            task.wait(1) -- Update every second
        end
    end)
end

function GameModeSystem:updateModeLogic(mode)
    if mode.name == "King of the Hill" then
        self:updateKOTHLogic(mode)
    elseif mode.name == "Hardpoint" then
        self:updateHardpointLogic(mode)
    elseif mode.name == "Flare Domination" then
        self:updateFlareLogic(mode)
    end
end

function GameModeSystem:updateKOTHLogic(mode)
    if not self.currentModeData.hill or not self.currentModeData.hill.part then return end
    
    local hill = self.currentModeData.hill
    local fbiCount = #hill.players_in_hill.FBI
    local kfcCount = #hill.players_in_hill.KFC
    
    -- Determine control
    if fbiCount > 0 and kfcCount == 0 then
        hill.controlled_by = "FBI"
        self.currentModeData.teamScores.FBI = self.currentModeData.teamScores.FBI + mode.rules.hill_points_per_second
    elseif kfcCount > 0 and fbiCount == 0 then
        hill.controlled_by = "KFC" 
        self.currentModeData.teamScores.KFC = self.currentModeData.teamScores.KFC + mode.rules.hill_points_per_second
    else
        hill.controlled_by = nil -- Contested
    end
end

function GameModeSystem:checkWinConditions(mode)
    if mode.winCondition == "score_limit" then
        if self.currentModeData.teamScores.FBI >= mode.scoreLimit then
            return "FBI"
        elseif self.currentModeData.teamScores.KFC >= mode.scoreLimit then
            return "KFC"
        end
    elseif mode.winCondition == "progression" then
        -- Gun Game progression check
        for userId, tier in pairs(self.currentModeData.playerWeaponTiers or {}) do
            if tier > #self.currentModeData.gunGameWeapons then
                local player = Players:GetPlayerByUserId(userId)
                return player and player.Name or "Unknown"
            end
        end
    end
    
    return nil
end

function GameModeSystem:endGameMode(reason, winner)
    print("[GameModeSystem] Ending game mode. Reason:", reason, "Winner:", winner or "None")
    
    self.isGameActive = false
    
    -- Notify players of game end
    self:notifyGameModeEnd(reason, winner)
    
    -- Start voting phase for next mode
    self:startVotingPhase()
end

function GameModeSystem:startNextMode()
    currentModeIndex = currentModeIndex + 1
    if currentModeIndex > #MODE_ROTATION then
        currentModeIndex = 1
    end
    
    local nextMode = MODE_ROTATION[currentModeIndex]
    print("[GameModeSystem] Starting next mode:", nextMode)
    
    self:startGameMode(nextMode)
end

function GameModeSystem:notifyGameModeStart(mode)
    local remoteEvent = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents"):FindFirstChild("GameModeUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            action = "start",
            mode = mode,
            scores = self.currentModeData.teamScores
        })
    end
end

function GameModeSystem:notifyGameModeEnd(reason, winner)
    local remoteEvent = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents"):FindFirstChild("GameModeUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            action = "end",
            reason = reason,
            winner = winner,
            final_scores = self.currentModeData.teamScores
        })
    end
end

function GameModeSystem:updateGameModeUI(mode, timeRemaining)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("[GameModeSystem] FPSSystem not found in ReplicatedStorage")
        return
    end
    
    local remoteEvents = fpsSystem:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        warn("[GameModeSystem] RemoteEvents not found in FPSSystem")
        return
    end
    
    local remoteEvent = remoteEvents:FindFirstChild("GameModeUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            action = "update",
            mode = mode,
            scores = self.currentModeData.teamScores,
            timeRemaining = timeRemaining,
            objectives = self:getObjectiveStatus()
        })
    else
        warn("[GameModeSystem] GameModeUpdate RemoteEvent not found")
    end
end

function GameModeSystem:getObjectiveStatus()
    local status = {}
    
    if self.currentModeData.hill then
        status.hill = {
            controlled_by = self.currentModeData.hill.controlled_by,
            player_counts = {
                FBI = #self.currentModeData.hill.players_in_hill.FBI,
                KFC = #self.currentModeData.hill.players_in_hill.KFC
            }
        }
    end
    
    return status
end

function GameModeSystem:resetGameState()
    self.currentModeData = {}
    self.playerStats = {}
    
    -- Clear any existing objectives
    -- This will be repopulated by setupObjectives if needed
end

-- Voting and Countdown System
function GameModeSystem:startVotingPhase()
    print("[GameModeSystem] Starting voting phase...")
    
    self.isVotingActive = true
    self.votingEndTime = tick() + 30 -- 30 seconds to vote
    self.modeVotes = {}
    
    -- Get 3 random modes for voting (excluding current mode)
    local availableModes = {}
    for modeName, _ in pairs(GAME_MODES) do
        if modeName ~= self.currentMode then
            table.insert(availableModes, modeName)
        end
    end
    
    -- Shuffle and take 3
    for i = #availableModes, 2, -1 do
        local j = math.random(i)
        availableModes[i], availableModes[j] = availableModes[j], availableModes[i]
    end
    
    local votingOptions = {}
    for i = 1, math.min(3, #availableModes) do
        table.insert(votingOptions, availableModes[i])
        self.modeVotes[availableModes[i]] = 0
    end
    
    -- Notify players about voting
    self:notifyVotingStart(votingOptions)
    
    -- Start voting countdown
    task.spawn(function()
        while self.isVotingActive and tick() < self.votingEndTime do
            local remaining = self.votingEndTime - tick()
            self:updateVotingCountdown(remaining, votingOptions)
            task.wait(1)
        end
        
        if self.isVotingActive then
            self:endVotingPhase(votingOptions)
        end
    end)
end

function GameModeSystem:handlePlayerVote(player, votedMode)
    if not self.isVotingActive then
        return
    end
    
    if not self.modeVotes[votedMode] then
        warn("[GameModeSystem] Invalid vote from", player.Name, "for mode:", votedMode)
        return
    end
    
    -- Remove previous vote if exists
    for mode, _ in pairs(self.modeVotes) do
        if self.playerVotes and self.playerVotes[player.UserId] == mode then
            self.modeVotes[mode] = math.max(0, self.modeVotes[mode] - 1)
        end
    end
    
    -- Add new vote
    self.modeVotes[votedMode] = self.modeVotes[votedMode] + 1
    
    -- Track player vote
    if not self.playerVotes then
        self.playerVotes = {}
    end
    self.playerVotes[player.UserId] = votedMode
    
    print("[GameModeSystem] Vote from", player.Name, "for", votedMode)
end

function GameModeSystem:endVotingPhase(votingOptions)
    self.isVotingActive = false
    
    -- Find winning mode
    local winningMode = nil
    local maxVotes = 0
    
    for mode, votes in pairs(self.modeVotes) do
        if votes > maxVotes then
            maxVotes = votes
            winningMode = mode
        end
    end
    
    -- Fallback to random if no votes
    if not winningMode or maxVotes == 0 then
        winningMode = votingOptions[math.random(#votingOptions)]
    end
    
    print("[GameModeSystem] Voting ended. Winner:", winningMode, "with", maxVotes, "votes")
    
    -- Notify voting results
    self:notifyVotingEnd(winningMode, self.modeVotes)
    
    -- Start countdown to new mode
    self:startCountdownPhase(winningMode)
end

function GameModeSystem:startCountdownPhase(nextMode)
    print("[GameModeSystem] Starting countdown to", nextMode)
    
    self.isCountdownActive = true
    self.countdownEndTime = tick() + 10 -- 10 second countdown
    
    -- Countdown loop
    task.spawn(function()
        while self.isCountdownActive and tick() < self.countdownEndTime do
            local remaining = math.ceil(self.countdownEndTime - tick())
            self:updateCountdown(remaining, nextMode)
            task.wait(1)
        end
        
        if self.isCountdownActive then
            self.isCountdownActive = false
            self:startGameMode(nextMode)
        end
    end)
end

function GameModeSystem:notifyVotingStart(votingOptions)
    local remoteEvent = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents"):FindFirstChild("GameModeUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            action = "voting_start",
            options = votingOptions,
            duration = 30
        })
    end
end

function GameModeSystem:updateVotingCountdown(remaining, votingOptions)
    local remoteEvent = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents"):FindFirstChild("CountdownUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            type = "voting",
            timeRemaining = remaining,
            options = votingOptions,
            votes = self.modeVotes
        })
    end
end

function GameModeSystem:notifyVotingEnd(winningMode, voteResults)
    local remoteEvent = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents"):FindFirstChild("GameModeUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            action = "voting_end",
            winner = winningMode,
            results = voteResults
        })
    end
end

function GameModeSystem:updateCountdown(remaining, nextMode)
    local remoteEvent = ReplicatedStorage:FindFirstChild("FPSSystem"):FindFirstChild("RemoteEvents"):FindFirstChild("CountdownUpdate")
    if remoteEvent then
        remoteEvent:FireAllClients({
            type = "gamestart",
            timeRemaining = remaining,
            nextMode = nextMode,
            modeData = GAME_MODES[nextMode]
        })
    end
end

-- Admin commands for testing
function GameModeSystem:handleAdminCommand(player, command, args)
    if not (player:GetRankInGroup(0) >= 100) then -- Adjust as needed
        return false, "Insufficient permissions"
    end
    
    if command == "setmode" and args[1] then
        local modeName = args[1]:upper()
        if GAME_MODES[modeName] then
            self:endGameMode("admin_override")
            task.wait(1)
            self:startGameMode(modeName)
            return true, "Set game mode to " .. GAME_MODES[modeName].displayName
        else
            return false, "Unknown game mode: " .. modeName
        end
        
    elseif command == "endgame" then
        self:endGameMode("admin_override")
        return true, "Game ended by admin"
        
    elseif command == "score" and args[1] and args[2] then
        local team = args[1]:upper()
        local points = tonumber(args[2])
        
        if self.currentModeData.teamScores and self.currentModeData.teamScores[team] and points then
            self.currentModeData.teamScores[team] = self.currentModeData.teamScores[team] + points
            return true, string.format("Added %d points to %s", points, team)
        else
            return false, "Invalid team or points"
        end
    end
    
    return false, "Unknown command"
end

-- Initialize the system
GameModeSystem:initialize()

-- Global access for other scripts
_G.GameModeSystem = GameModeSystem

return GameModeSystem