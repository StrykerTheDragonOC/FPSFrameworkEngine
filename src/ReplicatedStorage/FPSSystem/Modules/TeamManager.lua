local TeamManager = {}

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)

local FBI_TEAM_NAME = "FBI"
local KFC_TEAM_NAME = "KFC"
local LOBBY_TEAM_NAME = "Lobby"

local teamBalanceQueue = {}
local playerTeamData = {}
local teamScores = {FBI = 0, KFC = 0}

function TeamManager:GetTeamCounts()
	local fbiCount = 0
	local kfcCount = 0
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team then
			if player.Team.Name == FBI_TEAM_NAME then
				fbiCount = fbiCount + 1
			elseif player.Team.Name == KFC_TEAM_NAME then
				kfcCount = kfcCount + 1
			end
		end
	end
	
	return fbiCount, kfcCount
end

function TeamManager:BalanceTeams(player)
	local fbiCount, kfcCount = self:GetTeamCounts()
	
	if fbiCount <= kfcCount then
		self:AssignPlayerToTeam(player, FBI_TEAM_NAME)
	else
		self:AssignPlayerToTeam(player, KFC_TEAM_NAME)
	end
end

function TeamManager:AssignPlayerToTeam(player, teamName)
	local targetTeam = Teams:FindFirstChild(teamName)
	
	if not targetTeam then
		warn("Team not found: " .. teamName)
		return false
	end
	
	if player.Team == targetTeam then
		return false
	end
	
	local oldTeam = player.Team
	player.Team = targetTeam
	
	-- DISABLED: Team switching deaths (causing random death issues)
	-- Players will no longer die when switching teams
	-- if oldTeam and oldTeam ~= targetTeam and oldTeam.Name ~= "Lobby" and targetTeam.Name ~= "Lobby" then
	--     if player.Character and player.Character:FindFirstChild("Humanoid") then
	--         player.Character.Humanoid.Health = 0
	--     end
	-- end


	print(player.Name .. " assigned to " .. teamName .. " team")

	local updateStatsEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("UpdateStats")
	if updateStatsEvent then
		updateStatsEvent:FireAllClients(player, {
			Team = teamName
		})
	end

	return true
end

function TeamManager:GetTeam(teamName)
	return Teams:FindFirstChild(teamName)
end

function TeamManager:IsOnSameTeam(player1, player2)
	if not player1 or not player2 then return false end
	if not player1.Team or not player2.Team then return false end
	return player1.Team == player2.Team
end

function TeamManager:GetEnemyTeamName(teamName)
	if teamName == FBI_TEAM_NAME then
		return KFC_TEAM_NAME
	elseif teamName == KFC_TEAM_NAME then
		return FBI_TEAM_NAME
	end
	return nil
end

function TeamManager:Initialize()
	if RunService:IsServer() then
		self:CreateTeams()

		Players.PlayerAdded:Connect(function(player)
			self:OnPlayerJoined(player)
		end)
		
		Players.PlayerRemoving:Connect(function(player)
			self:OnPlayerLeft(player)
		end)
	end
	
	_G.TeamManager = self
	print("TeamManager initialized")
end

function TeamManager:CreateTeams()
	-- Create FBI team
	local fbiTeam = Teams:FindFirstChild(FBI_TEAM_NAME)
	if not fbiTeam then
		fbiTeam = Instance.new("Team")
		fbiTeam.Name = FBI_TEAM_NAME
		fbiTeam.TeamColor = BrickColor.new("Navy blue")
		fbiTeam.AutoAssignable = false
		fbiTeam.Parent = Teams
	end
	
	-- Create KFC team
	local kfcTeam = Teams:FindFirstChild(KFC_TEAM_NAME)
	if not kfcTeam then
		kfcTeam = Instance.new("Team")
		kfcTeam.Name = KFC_TEAM_NAME
		kfcTeam.TeamColor = BrickColor.new("Maroon")
		kfcTeam.AutoAssignable = false
		kfcTeam.Parent = Teams
	end
	
	-- Create Lobby team
	local lobbyTeam = Teams:FindFirstChild(LOBBY_TEAM_NAME)
	if not lobbyTeam then
		lobbyTeam = Instance.new("Team")
		lobbyTeam.Name = LOBBY_TEAM_NAME
		lobbyTeam.TeamColor = BrickColor.new("Medium stone grey")
		lobbyTeam.AutoAssignable = true
		lobbyTeam.Parent = Teams
	end
	
	print("Teams created: FBI (Navy), KFC (Maroon), Lobby (Gray)")
end

function TeamManager:OnPlayerJoined(player)
	-- Start all players in lobby
	player.Team = Teams:FindFirstChild(LOBBY_TEAM_NAME)
	
	playerTeamData[player] = {
		Team = LOBBY_TEAM_NAME,
		JoinTime = tick(),
		Deployed = false
	}
end

function TeamManager:OnPlayerLeft(player)
	playerTeamData[player] = nil
end

function TeamManager:DeployPlayer(player, preferredTeam)
	if not player or not player.Parent then return false end
	
	local targetTeam = preferredTeam
	if not targetTeam or (targetTeam ~= FBI_TEAM_NAME and targetTeam ~= KFC_TEAM_NAME) then
		targetTeam = self:GetBalancedTeam()
	end
	
	local success = self:AssignPlayerToTeam(player, targetTeam)
	if success then
		local data = playerTeamData[player]
		if data then
			data.Deployed = true
		end

		local playerDeployedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PlayerDeployed")
		if playerDeployedEvent then
			playerDeployedEvent:FireClient(player, {
				Team = targetTeam,
				TeamColor = self:GetTeamColor(targetTeam)
			})
		end
	end
	
	return success
end

function TeamManager:SendToLobby(player)
	local success = self:AssignPlayerToTeam(player, LOBBY_TEAM_NAME)
	if success then
		local data = playerTeamData[player]
		if data then
			data.Deployed = false
		end
	end
	return success
end

function TeamManager:GetBalancedTeam()
	local fbiCount, kfcCount = self:GetTeamCounts()
	
	if fbiCount < kfcCount then
		return FBI_TEAM_NAME
	elseif kfcCount < fbiCount then
		return KFC_TEAM_NAME
	else
		-- Equal teams, assign randomly
		return math.random(2) == 1 and FBI_TEAM_NAME or KFC_TEAM_NAME
	end
end

function TeamManager:GetTeamColor(teamName)
	if teamName == FBI_TEAM_NAME then
		return Color3.fromRGB(0, 0, 139) -- Navy Blue
	elseif teamName == KFC_TEAM_NAME then
		return Color3.fromRGB(139, 0, 0) -- Maroon
	else
		return Color3.fromRGB(128, 128, 128) -- Gray
	end
end

function TeamManager:GetTeamPlayers(teamName)
	local players = {}
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			table.insert(players, player)
		end
	end
	return players
end

function TeamManager:AddTeamScore(teamName, points)
	if teamScores[teamName] then
		teamScores[teamName] = teamScores[teamName] + points
		local updateStatsEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("UpdateStats")
		if updateStatsEvent then
			updateStatsEvent:FireAllClients({
				TeamScores = teamScores
			})
		end
	end
end

function TeamManager:GetTeamScore(teamName)
	return teamScores[teamName] or 0
end

function TeamManager:IsDeployed(player)
	local data = playerTeamData[player]
	return data and data.Deployed or false
end

function TeamManager:ResetTeamScores()
	teamScores.FBI = 0
	teamScores.KFC = 0
	print("Team scores reset")
end

return TeamManager