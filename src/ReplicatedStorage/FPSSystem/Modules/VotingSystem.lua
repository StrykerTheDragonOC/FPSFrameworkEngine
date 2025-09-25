local VotingSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local gameMode = {
	["TDM"] = {
		Name = "Team Deathmatch",
		Description = "Eliminate enemy team members",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 600,
		ScoreLimit = 75
	},
	["KOTH"] = {
		Name = "King of the Hill",
		Description = "Control the hill to score points",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 480,
		ScoreLimit = 250
	},
	["KC"] = {
		Name = "Kill Confirmed",
		Description = "Collect dog tags to confirm kills",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 600,
		ScoreLimit = 30
	},
	["CTF"] = {
		Name = "Capture the Flag",
		Description = "Capture the enemy team's flag",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 900,
		ScoreLimit = 3
	},
	["FD"] = {
		Name = "Flare Domination",
		Description = "Control flare points across the map",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 720,
		ScoreLimit = 200
	},
	["HD"] = {
		Name = "Hardpoint",
		Description = "Secure rotating hardpoints",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 600,
		ScoreLimit = 250
	},
	["GG"] = {
		Name = "Gun Game",
		Description = "Progress through weapon tiers",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 480,
		ScoreLimit = 20
	},
	["Duel"] = {
		Name = "Duel",
		Description = "Secondary weapons only duel",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 300,
		ScoreLimit = 10
	},
	["Knife Fight"] = {
		Name = "Knife Fight",
		Description = "Melee weapons only combat",
		Icon = "rbxassetid://0", -- IconPlaceholder
		MaxTime = 300,
		ScoreLimit = 15
	}
}

local votingActive = false
local votingEndTime = 0
local playerVotes = {}
local modeOptions = {}
local voteCounts = {}

function VotingSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	-- Remote events are automatically created by RemoteEventsManager
	
	-- Server-side events
	if game:GetService("RunService"):IsServer() then
		local voteEvent = RemoteEventsManager:GetEvent("VoteForGamemode")
		if voteEvent then
			voteEvent.OnServerEvent:Connect(function(player, gamemode)
				self:ProcessVote(player, gamemode)
			end)
		end
	end
	
	print("VotingSystem initialized")
end

function VotingSystem:StartVoting(duration)
	if votingActive then return end
	
	votingActive = true
	votingEndTime = tick() + (duration or 30)
	playerVotes = {}
	voteCounts = {}
	
	-- Select random game modes (TDM always included)
	modeOptions = {"TDM"}
	local availableModes = {}
	
	for mode, _ in pairs(gameMode) do
		if mode ~= "TDM" then
			table.insert(availableModes, mode)
		end
	end
	
	-- Randomly select 3 additional modes
	for i = 1, 3 do
		if #availableModes > 0 then
			local randomIndex = math.random(1, #availableModes)
			table.insert(modeOptions, availableModes[randomIndex])
			table.remove(availableModes, randomIndex)
		end
	end
	
	-- Initialize vote counts
	for _, mode in ipairs(modeOptions) do
		voteCounts[mode] = 0
	end
	
	-- Broadcast voting start
	local startEvent = RemoteEventsManager:GetEvent("StartVoting")
	if startEvent then
		startEvent:FireAllClients({
			modes = modeOptions,
			duration = duration or 30,
			modeData = gameMode
		})
	end
	
	-- Auto-end voting
	task.wait(duration or 30)
	if votingActive then
		self:EndVoting()
	end
end

function VotingSystem:ProcessVote(player, gamemode)
	if not votingActive then return end
	if not table.find(modeOptions, gamemode) then return end
	
	-- Remove previous vote
	if playerVotes[player.Name] then
		voteCounts[playerVotes[player.Name]] = math.max(0, voteCounts[playerVotes[player.Name]] - 1)
	end
	
	-- Add new vote
	playerVotes[player.Name] = gamemode
	voteCounts[gamemode] = (voteCounts[gamemode] or 0) + 1
	
	-- Broadcast vote update
	local updateEvent = RemoteEventsManager:GetEvent("UpdateVotes")
	if updateEvent then
		updateEvent:FireAllClients({
			votes = voteCounts,
			playerVote = gamemode
		})
	end
end

function VotingSystem:EndVoting()
	if not votingActive then return end
	
	votingActive = false
	
	-- Find winner
	local winningMode = "TDM"
	local maxVotes = 0
	
	for mode, count in pairs(voteCounts) do
		if count > maxVotes then
			maxVotes = count
			winningMode = mode
		elseif count == maxVotes and mode == "TDM" then
			-- TDM wins ties
			winningMode = mode
		end
	end
	
	-- Broadcast result
	local endEvent = RemoteEventsManager:GetEvent("EndVoting")
	if endEvent then
		endEvent:FireAllClients({
			winner = winningMode,
			votes = voteCounts,
			modeData = gameMode[winningMode]
		})
	end
	
	return winningMode
end

function VotingSystem:GetGameModeData(mode)
	return gameMode[mode]
end

function VotingSystem:GetAllGameModes()
	return gameMode
end

function VotingSystem:IsVotingActive()
	return votingActive
end

function VotingSystem:GetVotingTimeLeft()
	if not votingActive then return 0 end
	return math.max(0, votingEndTime - tick())
end

function VotingSystem:GetCurrentVotes()
	return voteCounts
end

function VotingSystem:GetPlayerVote(playerName)
	return playerVotes[playerName]
end

-- Console commands for testing
_G.VotingCommands = {
	startVoting = function(duration)
		VotingSystem:StartVoting(tonumber(duration) or 30)
		print("Voting started for " .. (duration or 30) .. " seconds")
	end,
	
	vote = function(mode)
		local player = Players.LocalPlayer
		VotingSystem:ProcessVote(player, mode)
		print("Voted for: " .. mode)
	end,
	
	endVoting = function()
		local winner = VotingSystem:EndVoting()
		print("Voting ended. Winner: " .. winner)
	end,
	
	listModes = function()
		print("Available game modes:")
		for code, data in pairs(gameMode) do
			print("- " .. code .. ": " .. data.Name .. " - " .. data.Description)
		end
	end
}

return VotingSystem