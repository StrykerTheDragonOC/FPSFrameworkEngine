local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)
local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)

local GamemodeManager = {}

local currentGamemode = "TDM"
local nextGamemode = "KOTH"
local gameStartTime = 0
local gameActive = false
local gameDuration = 1200 -- 20 minutes
local lobbyTime = 30
local votingTime = 20
local isVoting = false
local votes = {}
local votingCandidates = {}

-- Gamemode rotation queue
local gamemodeQueue = {"TDM", "KOTH", "KC", "CTF", "FD", "HD"}
local specialModes = {"GG", "DUEL", "KNIFE"} -- Only available through voting
local currentQueueIndex = 1

local gamemodeData = {
	TDM = {
		Name = "Team Deathmatch",
		ScoreLimit = 75,
		TimeLimit = 600, -- 10 minutes
		Description = "First team to reach 75 kills wins",
		Icon = "rbxassetid://7733715400", -- Placeholder
		MinPlayers = 2,
		MaxPlayers = 32,
		TeamBased = true
	},
	KOTH = {
		Name = "King of the Hill", 
		ScoreLimit = 250,
		TimeLimit = 600,
		Description = "Control the hill to earn points",
		Icon = "rbxassetid://7733715401", -- Placeholder
		MinPlayers = 4,
		MaxPlayers = 24,
		TeamBased = true
	},
	KC = {
		Name = "Kill Confirmed",
		ScoreLimit = 65, 
		TimeLimit = 600,
		Description = "Collect dog tags from eliminated enemies",
		Icon = "rbxassetid://7733715402", -- Placeholder
		MinPlayers = 4,
		MaxPlayers = 32,
		TeamBased = true
	},
	CTF = {
		Name = "Capture the Flag",
		ScoreLimit = 3,
		TimeLimit = 600,
		Description = "Capture the enemy flag 3 times",
		Icon = "rbxassetid://7733715403", -- Placeholder
		MinPlayers = 6,
		MaxPlayers = 24,
		TeamBased = true
	},
	FD = {
		Name = "Flare Domination",
		ScoreLimit = 400,
		TimeLimit = 900, -- 15 minutes
		Description = "Control multiple flare points to dominate",
		Icon = "rbxassetid://7733715404", -- Placeholder
		MinPlayers = 8,
		MaxPlayers = 32,
		TeamBased = true
	},
	HD = {
		Name = "Hardpoint",
		ScoreLimit = 250,
		TimeLimit = 600,
		Description = "Hold rotating hardpoints to earn score",
		Icon = "rbxassetid://7733715405", -- Placeholder
		MinPlayers = 6,
		MaxPlayers = 24,
		TeamBased = true
	},
	GG = {
		Name = "Gun Game",
		ScoreLimit = 20, -- 20 weapon levels
		TimeLimit = 600,
		Description = "Progress through weapons with each kill",
		Icon = "rbxassetid://7733715406", -- Placeholder
		MinPlayers = 4,
		MaxPlayers = 16,
		TeamBased = false
	},
	DUEL = {
		Name = "Duel",
		ScoreLimit = 15,
		TimeLimit = 300, -- 5 minutes
		Description = "Secondary weapons only combat",
		Icon = "rbxassetid://7733715407", -- Placeholder
		MinPlayers = 2,
		MaxPlayers = 12,
		TeamBased = false
	},
	KNIFE = {
		Name = "Knife Fight",
		ScoreLimit = 20,
		TimeLimit = 300,
		Description = "Melee weapons only combat",
		Icon = "rbxassetid://7733715408", -- Placeholder
		MinPlayers = 4,
		MaxPlayers = 16,
		TeamBased = false
	}
}

function GamemodeManager:Initialize()
	RemoteEventsManager:Initialize()
	GameConfig:Initialize()
	TeamManager:Initialize()
	
	-- Setup remote events
	local getGamemodeInfoFunction = RemoteEventsManager:GetFunction("GetGamemodeInfo")
	if getGamemodeInfoFunction then
		getGamemodeInfoFunction.OnServerInvoke = function(player)
			return self:GetCurrentGamemodeInfo()
		end
	end
	
	local getAvailableGamemodesFunction = RemoteEventsManager:GetFunction("GetAvailableGamemodes")
	if getAvailableGamemodesFunction then
		getAvailableGamemodesFunction.OnServerInvoke = function(player)
			return self:GetAvailableGamemodes()
		end
	end
	
	local voteGamemodeEvent = RemoteEventsManager:GetEvent("VoteGamemode")
	if voteGamemodeEvent then
		voteGamemodeEvent.OnServerEvent:Connect(function(player, gamemode)
			self:ProcessVote(player, gamemode)
		end)
	end
	
	-- Start gamemode rotation
	self:StartGamemodeRotation()
	
	_G.GamemodeManager = self
	print("GamemodeManager initialized - Starting with " .. currentGamemode)
end

function GamemodeManager:StartGamemodeRotation()
	spawn(function()
		while true do
			-- Lobby phase
			self:StartLobbyPhase()
			wait(lobbyTime)
			
			-- Game phase
			self:StartGamePhase()
			wait(gameDuration)
			
			-- End game
			self:EndGame()
			wait(10)
			
			-- Switch gamemode
			self:SwitchGamemode()
		end
	end)
end

function GamemodeManager:StartLobbyPhase()
	gameActive = false
	
	-- Send all players to lobby
	for _, player in pairs(Players:GetPlayers()) do
		TeamManager:SendToLobby(player)
	end
	
	-- Reset team scores
	TeamManager:ResetTeamScores()
	
	-- Start voting 5 seconds into lobby
	spawn(function()
		wait(5)
		if #Players:GetPlayers() >= 4 then -- Only start voting with enough players
			self:StartVoting()
		end
	end)
	
	RemoteEventsManager:FireAllClients("GamePhaseChanged", {
		Phase = "Lobby",
		NextGamemode = nextGamemode or currentGamemode,
		TimeRemaining = lobbyTime,
		CanVote = #Players:GetPlayers() >= 4
	})
	
	print("=== LOBBY PHASE ===")
	print("Next gamemode: " .. gamemodeData[nextGamemode or currentGamemode].Name)
	print("Players have " .. lobbyTime .. " seconds to prepare")
	if #Players:GetPlayers() >= 4 then
		print("Voting will start in 5 seconds")
	end
end

function GamemodeManager:StartGamePhase()
	gameActive = true
	gameStartTime = tick()
	
	-- Notify all players that game has started (they can now deploy)
	local playerList = Players:GetPlayers()
	for i, player in pairs(playerList) do
		-- Players will deploy themselves through the DeployController
		-- No automatic team assignment or weapon giving here
		print("Game started for player: " .. player.Name)
	end
	
	RemoteEventsManager:FireAllClients("GameStarted", {
		Gamemode = currentGamemode,
		GamemodeData = gamemodeData[currentGamemode],
		Duration = gameDuration
	})
	
	print("=== GAME STARTED ===")
	print("Gamemode: " .. gamemodeData[currentGamemode].Name)
	print("Duration: " .. (gameDuration / 60) .. " minutes")
	print("Score Limit: " .. gamemodeData[currentGamemode].ScoreLimit)
	
	-- Start gamemode-specific logic
	if currentGamemode == "TDM" then
		self:RunTeamDeathmatch()
	elseif currentGamemode == "KOTH" then
		self:RunKingOfTheHill()
	elseif currentGamemode == "KC" then
		self:RunKillConfirmed()
	elseif currentGamemode == "CTF" then
		self:RunCaptureTheFlag()
	end
end

function GamemodeManager:EndGame()
	gameActive = false
	
	local fbiScore = TeamManager:GetTeamScore("FBI")
	local kfcScore = TeamManager:GetTeamScore("KFC")
	
	local winner = "Draw"
	if fbiScore > kfcScore then
		winner = "FBI"
	elseif kfcScore > fbiScore then
		winner = "KFC"
	end
	
	RemoteEventsManager:FireAllClients("GameEnded", {
		Winner = winner,
		FinalScores = {FBI = fbiScore, KFC = kfcScore},
		Gamemode = currentGamemode
	})
	
	print("=== GAME ENDED ===")
	print("Winner: " .. winner)
	print("Final Scores - FBI: " .. fbiScore .. ", KFC: " .. kfcScore)
	
	-- Award match completion XP
	local dataStoreManager = _G.DataStoreManager
	if dataStoreManager then
		for _, player in pairs(Players:GetPlayers()) do
			local matchXP = winner == "Draw" and 50 or (player.Team and player.Team.Name == winner and 100 or 75)
			dataStoreManager:AddXP(player, matchXP, "Match Completion")
		end
	end
end

function GamemodeManager:SwitchGamemode()
	-- Check if we have a voted gamemode
	if nextGamemode and gamemodeData[nextGamemode] then
		currentGamemode = nextGamemode
	else
		-- Use queue rotation
		currentQueueIndex = currentQueueIndex + 1
		if currentQueueIndex > #gamemodeQueue then
			currentQueueIndex = 1
		end
		currentGamemode = gamemodeQueue[currentQueueIndex]
	end
	
	-- Reset voting state
	votes = {}
	votingCandidates = {}
	isVoting = false
	nextGamemode = nil
	
	print("Switched to gamemode: " .. gamemodeData[currentGamemode].Name)
end

-- Voting system
function GamemodeManager:StartVoting()
	if isVoting then return end
	
	isVoting = true
	votes = {}
	
	-- Select 3 random candidates (including current queue + special modes)
	local allModes = {}
	for _, mode in pairs(gamemodeQueue) do
		table.insert(allModes, mode)
	end
	for _, mode in pairs(specialModes) do
		table.insert(allModes, mode)
	end
	
	-- Shuffle and select 3 candidates
	votingCandidates = {}
	local availableModes = {}
	for _, mode in pairs(allModes) do
		if mode ~= currentGamemode then -- Don't vote for current mode
			table.insert(availableModes, mode)
		end
	end
	
	-- Randomly select 3 candidates
	for i = 1, math.min(3, #availableModes) do
		local randomIndex = math.random(1, #availableModes)
		table.insert(votingCandidates, availableModes[randomIndex])
		table.remove(availableModes, randomIndex)
	end
	
	-- Initialize vote counts
	for _, mode in pairs(votingCandidates) do
		votes[mode] = 0
	end
	
	-- Notify all players
	RemoteEventsManager:FireAllClients("VotingStarted", {
		Candidates = votingCandidates,
		GamemodeData = gamemodeData,
		VotingTime = votingTime
	})
	
	print("=== VOTING STARTED ===")
	print("Candidates:")
	for _, mode in pairs(votingCandidates) do
		print("- " .. gamemodeData[mode].Name)
	end
	
	-- End voting after time limit
	spawn(function()
		wait(votingTime)
		self:EndVoting()
	end)
end

function GamemodeManager:ProcessVote(player, gamemode)
	if not isVoting then return end
	if not gamemode or not votes[gamemode] then return end
	
	-- Remove player's previous vote
	for mode, _ in pairs(votes) do
		local playerVotes = votes[mode]
		votes[mode] = math.max(0, playerVotes - (player.Name == player.Name and 1 or 0))
	end
	
	-- Add new vote
	votes[gamemode] = votes[gamemode] + 1
	
	-- Update all players
	RemoteEventsManager:FireAllClients("VoteUpdate", {
		Votes = votes,
		Voter = player.Name,
		Choice = gamemode
	})
	
	print(player.Name .. " voted for " .. gamemodeData[gamemode].Name)
end

function GamemodeManager:EndVoting()
	if not isVoting then return end
	
	isVoting = false
	
	-- Count votes and determine winner
	local winningMode = nil
	local maxVotes = 0
	
	for mode, voteCount in pairs(votes) do
		if voteCount > maxVotes then
			maxVotes = voteCount
			winningMode = mode
		end
	end
	
	-- Set next gamemode
	if winningMode and maxVotes > 0 then
		nextGamemode = winningMode
		print("Voting ended - Winner: " .. gamemodeData[winningMode].Name .. " with " .. maxVotes .. " votes")
	else
		-- No votes, use queue system
		nextGamemode = nil
		print("Voting ended - No votes received, using queue rotation")
	end
	
	-- Notify all players
	RemoteEventsManager:FireAllClients("VotingEnded", {
		Winner = winningMode,
		Votes = votes,
		NextGamemode = nextGamemode or gamemodeQueue[currentQueueIndex + 1] or gamemodeQueue[1]
	})
end

function GamemodeManager:GetAvailableGamemodes()
	local available = {}
	
	for mode, data in pairs(gamemodeData) do
		local playerCount = #Players:GetPlayers()
		if playerCount >= data.MinPlayers and playerCount <= data.MaxPlayers then
			available[mode] = data
		end
	end
	
	return available
end

function GamemodeManager:RunTeamDeathmatch()
	spawn(function()
		while gameActive do
			wait(1)
			
			local fbiScore = TeamManager:GetTeamScore("FBI")
			local kfcScore = TeamManager:GetTeamScore("KFC")
			local scoreLimit = gamemodeData[currentGamemode].ScoreLimit
			
			-- Check win condition
			if fbiScore >= scoreLimit or kfcScore >= scoreLimit then
				gameActive = false
				break
			end
			
			-- Check time limit
			local timeElapsed = tick() - gameStartTime
			if timeElapsed >= gameDuration then
				gameActive = false
				break
			end
		end
	end)
	
	-- Listen for kills to add to team score
	local playerKilledEvent = RemoteEventsManager:GetEvent("PlayerKilled")
	if playerKilledEvent then
		local killConnection
		killConnection = playerKilledEvent.OnServerEvent:Connect(function(killData)
			if not gameActive then
				killConnection:Disconnect()
				return
			end
			
			if killData.Killer and killData.Killer.Team then
				TeamManager:AddTeamScore(killData.Killer.Team.Name, 1)
			end
		end)
	end
end

function GamemodeManager:RunKingOfTheHill()
	print("KOTH gamemode running")
	
	-- Find hill zone in workspace
	local hillZone = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Objectives") 
		and workspace.Map.Objectives:FindFirstChild("Hill") and workspace.Map.Objectives.Hill:FindFirstChild("HillZone")
	
	if not hillZone then
		warn("No hill zone found, falling back to TDM")
		return self:RunTeamDeathmatch()
	end
	
	local hillController = nil
	local lastControllerTeam = nil
	local controlStartTime = 0
	
	spawn(function()
		while gameActive do
			wait(1)
			
			-- Check who's controlling the hill
			local playersInHill = {}
			local fbiCount, kfcCount = 0, 0
			
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - hillZone.Position).Magnitude
					if distance <= hillZone.Size.Magnitude / 2 then
						table.insert(playersInHill, player)
						if player.Team and player.Team.Name == "FBI" then
							fbiCount = fbiCount + 1
						elseif player.Team and player.Team.Name == "KFC" then
							kfcCount = kfcCount + 1
						end
					end
				end
			end
			
			-- Determine controller
			local controllingTeam = nil
			if fbiCount > kfcCount then
				controllingTeam = "FBI"
			elseif kfcCount > fbiCount then
				controllingTeam = "KFC"
			end
			
			-- Award points for control
			if controllingTeam then
				TeamManager:AddTeamScore(controllingTeam, 1)
				
				-- Award XP to controlling players
				for _, player in pairs(playersInHill) do
					if player.Team and player.Team.Name == controllingTeam then
						local xpManager = _G.XPSystem
						if xpManager then
							xpManager:AwardXP(player, 5, "Hill Control")
						end
					end
				end
			end
			
			-- Check win condition
			local fbiScore = TeamManager:GetTeamScore("FBI")
			local kfcScore = TeamManager:GetTeamScore("KFC")
			local scoreLimit = gamemodeData[currentGamemode].ScoreLimit
			
			if fbiScore >= scoreLimit or kfcScore >= scoreLimit then
				gameActive = false
				break
			end
			
			-- Check time limit
			local timeElapsed = tick() - gameStartTime
			if timeElapsed >= gameDuration then
				gameActive = false
				break
			end
		end
	end)
end

function GamemodeManager:RunKillConfirmed()
	print("Kill Confirmed gamemode running")
	
	local dogTags = {} -- Track dropped dog tags
	
	-- Listen for kills to drop dog tags
	local playerKilledEvent = RemoteEventsManager:GetEvent("PlayerKilled")
	if playerKilledEvent then
		local killConnection
		killConnection = playerKilledEvent.OnServerEvent:Connect(function(killData)
			if not gameActive then
				killConnection:Disconnect()
				return
			end
			
			if killData.Victim and killData.Victim.Character then
				-- Drop dog tag at victim's position
				local tagId = self:DropDogTag(killData.Victim, killData.Victim.Character.HumanoidRootPart.Position)
				dogTags[tagId] = {
					VictimTeam = killData.Victim.Team and killData.Victim.Team.Name or "",
					Position = killData.Victim.Character.HumanoidRootPart.Position,
					Time = tick()
				}
			end
		end)
	end
	
	-- Dog tag collection logic
	spawn(function()
		while gameActive do
			wait(0.5) -- Check every half second
			
			-- Clean up old dog tags (30 seconds)
			for tagId, tagData in pairs(dogTags) do
				if tick() - tagData.Time > 30 then
					dogTags[tagId] = nil
					-- Remove visual dog tag
					local tagPart = workspace:FindFirstChild("DogTag_" .. tagId)
					if tagPart then tagPart:Destroy() end
				end
			end
			
			-- Check for players collecting tags
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local playerPos = player.Character.HumanoidRootPart.Position
					
					for tagId, tagData in pairs(dogTags) do
						local distance = (playerPos - tagData.Position).Magnitude
						if distance <= 5 then -- Collection range
							-- Collect the tag
							self:CollectDogTag(player, tagId, tagData)
							dogTags[tagId] = nil
						end
					end
				end
			end
			
			-- Check win condition
			local fbiScore = TeamManager:GetTeamScore("FBI")
			local kfcScore = TeamManager:GetTeamScore("KFC")
			local scoreLimit = gamemodeData[currentGamemode].ScoreLimit
			
			if fbiScore >= scoreLimit or kfcScore >= scoreLimit then
				gameActive = false
				break
			end
		end
	end)
end

function GamemodeManager:RunCaptureTheFlag()
	print("CTF gamemode running")
	
	-- Find flag locations
	local fbiFlag = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Objectives") 
		and workspace.Map.Objectives:FindFirstChild("Flags") and workspace.Map.Objectives.Flags:FindFirstChild("FBI_Flag")
	local kfcFlag = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Objectives") 
		and workspace.Map.Objectives:FindFirstChild("Flags") and workspace.Map.Objectives.Flags:FindFirstChild("KFC_Flag")
	
	if not fbiFlag or not kfcFlag then
		warn("Flags not found, falling back to TDM")
		return self:RunTeamDeathmatch()
	end
	
	local flagStates = {
		FBI = {Carrier = nil, AtBase = true, Position = fbiFlag.Position},
		KFC = {Carrier = nil, AtBase = true, Position = kfcFlag.Position}
	}
	
	spawn(function()
		while gameActive do
			wait(1)
			
			-- Check flag interactions
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Team then
					local playerPos = player.Character.HumanoidRootPart.Position
					local enemyTeam = player.Team.Name == "FBI" and "KFC" or "FBI"
					
					-- Check if player can capture enemy flag
					local enemyFlagState = flagStates[enemyTeam]
					if enemyFlagState.AtBase then
						local flagDistance = (playerPos - (enemyTeam == "FBI" and fbiFlag.Position or kfcFlag.Position)).Magnitude
						if flagDistance <= 10 then
							-- Capture enemy flag
							enemyFlagState.Carrier = player
							enemyFlagState.AtBase = false
							print(player.Name .. " captured the " .. enemyTeam .. " flag!")
							
							RemoteEventsManager:FireAllClients("FlagCaptured", {
								Player = player.Name,
								Team = enemyTeam,
								FlagTeam = enemyTeam
							})
						end
					end
					
					-- Check if player carrying flag can score
					if flagStates[enemyTeam].Carrier == player then
						local homeDistance = (playerPos - (player.Team.Name == "FBI" and fbiFlag.Position or kfcFlag.Position)).Magnitude
						if homeDistance <= 10 and flagStates[player.Team.Name].AtBase then
							-- Score!
							TeamManager:AddTeamScore(player.Team.Name, 1)
							flagStates[enemyTeam].Carrier = nil
							flagStates[enemyTeam].AtBase = true
							
							print(player.Name .. " scored for " .. player.Team.Name .. "!")
							
							-- Award XP
							local xpManager = _G.XPSystem
							if xpManager then
								xpManager:AwardXP(player, 100, "Flag Capture")
							end
						end
					end
				end
			end
			
			-- Check win condition
			local fbiScore = TeamManager:GetTeamScore("FBI")
			local kfcScore = TeamManager:GetTeamScore("KFC")
			local scoreLimit = gamemodeData[currentGamemode].ScoreLimit
			
			if fbiScore >= scoreLimit or kfcScore >= scoreLimit then
				gameActive = false
				break
			end
		end
	end)
end

-- Helper functions for Kill Confirmed
function GamemodeManager:DropDogTag(victim, position)
	local tagId = tostring(tick()) .. "_" .. victim.UserId
	
	-- Create visual dog tag
	local dogTag = Instance.new("Part")
	dogTag.Name = "DogTag_" .. tagId
	dogTag.Shape = Enum.PartType.Block
	dogTag.Size = Vector3.new(1, 0.1, 1)
	dogTag.Position = position + Vector3.new(0, 1, 0)
	dogTag.BrickColor = victim.Team and (victim.Team.Name == "FBI" and BrickColor.new("Navy blue") or BrickColor.new("Maroon")) or BrickColor.new("Medium stone grey")
	dogTag.Material = Enum.Material.Neon
	dogTag.CanCollide = false
	dogTag.Anchored = true
	dogTag.Parent = workspace
	
	-- Add floating animation
	spawn(function()
		local startY = dogTag.Position.Y
		while dogTag.Parent do
			wait(0.1)
			dogTag.Position = dogTag.Position + Vector3.new(0, math.sin(tick() * 3) * 0.1, 0)
			dogTag.Rotation = dogTag.Rotation + Vector3.new(0, 2, 0)
		end
	end)
	
	return tagId
end

function GamemodeManager:CollectDogTag(player, tagId, tagData)
	local isConfirm = player.Team and player.Team.Name == tagData.VictimTeam
	local isRevenge = player.Team and player.Team.Name ~= tagData.VictimTeam
	
	if isConfirm then
		-- Teammate confirming kill
		TeamManager:AddTeamScore(player.Team.Name, 1)
		print(player.Name .. " confirmed a kill")
		
		local xpManager = _G.XPSystem
		if xpManager then
			xpManager:AwardXP(player, 25, "Kill Confirm")
		end
	elseif isRevenge then
		-- Enemy denying kill
		print(player.Name .. " denied a kill")
		
		local xpManager = _G.XPSystem
		if xpManager then
			xpManager:AwardXP(player, 15, "Kill Deny")
		end
	end
	
	-- Remove visual dog tag
	local tagPart = workspace:FindFirstChild("DogTag_" .. tagId)
	if tagPart then tagPart:Destroy() end
	
	RemoteEventsManager:FireAllClients("DogTagCollected", {
		Player = player.Name,
		Type = isConfirm and "Confirm" or "Deny"
	})
end


function GamemodeManager:GetCurrentGamemodeInfo()
	return {
		Name = currentGamemode,
		Data = gamemodeData[currentGamemode],
		IsActive = gameActive,
		TimeElapsed = gameActive and (tick() - gameStartTime) or 0,
		TimeRemaining = gameActive and math.max(0, gameDuration - (tick() - gameStartTime)) or 0
	}
end

function GamemodeManager:ForceGamemodeChange(newGamemode)
	if gamemodeData[newGamemode] then
		currentGamemode = newGamemode
		print("Forced gamemode change to: " .. gamemodeData[currentGamemode].Name)
		return true
	end
	return false
end

function GamemodeManager:IsGameActive()
	return gameActive
end

function GamemodeManager:GetTimeRemaining()
	if not gameActive then return 0 end
	return math.max(0, gameDuration - (tick() - gameStartTime))
end

-- Console commands for testing
_G.GamemodeCommands = {
	switchMode = function(modeName)
		local manager = _G.GamemodeManager
		if manager and manager.ForceGamemodeChange then
			return manager:ForceGamemodeChange(modeName)
		end
		return false
	end,
	
	getInfo = function()
		local manager = _G.GamemodeManager
		if manager and manager.GetCurrentGamemodeInfo then
			local info = manager:GetCurrentGamemodeInfo()
			print("=== GAMEMODE INFO ===")
			print("Current: " .. info.Name)
			print("Active: " .. tostring(info.IsActive))
			print("Time Remaining: " .. math.floor(info.TimeRemaining) .. " seconds")
			print("Players: " .. #Players:GetPlayers())
			if nextGamemode then
				print("Next: " .. gamemodeData[nextGamemode].Name)
			end
			if isVoting then
				print("VOTING IN PROGRESS")
				for mode, voteCount in pairs(votes) do
					print("  " .. gamemodeData[mode].Name .. ": " .. voteCount .. " votes")
				end
			end
		end
	end,
	
	startVote = function()
		local manager = _G.GamemodeManager
		if manager and manager.StartVoting then
			manager:StartVoting()
			print("Voting started manually")
			return true
		end
		return false
	end,
	
	endVote = function()
		local manager = _G.GamemodeManager
		if manager and manager.EndVoting then
			manager:EndVoting()
			print("Voting ended manually")
			return true
		end
		return false
	end,
	
	listModes = function()
		print("=== AVAILABLE GAMEMODES ===")
		for mode, data in pairs(gamemodeData) do
			local playerCount = #Players:GetPlayers()
			local available = playerCount >= data.MinPlayers and playerCount <= data.MaxPlayers
			print(mode .. " - " .. data.Name .. " (" .. data.MinPlayers .. "-" .. data.MaxPlayers .. " players) " .. (available and "[AVAILABLE]" or "[UNAVAILABLE]"))
		end
	end,
	
	setQueue = function(...)
		local newQueue = {...}
		if #newQueue > 0 then
			-- Validate all modes exist
			for _, mode in pairs(newQueue) do
				if not gamemodeData[mode] then
					print("Invalid gamemode: " .. tostring(mode))
					return false
				end
			end
			gamemodeQueue = newQueue
			currentQueueIndex = 1
			print("Queue updated: " .. table.concat(newQueue, ", "))
			return true
		else
			print("Current queue: " .. table.concat(gamemodeQueue, ", "))
			return true
		end
	end,
	
	endGame = function()
		local manager = _G.GamemodeManager
		if manager then
			gameActive = false
			print("Force ended current game")
		end
	end,
	
	skipLobby = function()
		lobbyTime = 5
		print("Lobby time set to 5 seconds")
	end
}

GamemodeManager:Initialize()

return GamemodeManager