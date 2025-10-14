local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)


local changeTeamEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ChangeTeam")
if changeTeamEvent then
	changeTeamEvent.OnServerEvent:Connect(function(player, teamName)
		TeamManager:AssignPlayerToTeam(player, teamName)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1)
		if not player.Team then
			TeamManager:BalanceTeams(player)
		end
	end)
end)

print("Team Handler initialized")

_G.TeamManager = TeamManager