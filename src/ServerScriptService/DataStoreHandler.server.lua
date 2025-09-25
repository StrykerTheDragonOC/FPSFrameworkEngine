local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

RemoteEventsManager:Initialize()

local getPlayerDataFunction = RemoteEventsManager:GetFunction("GetPlayerData")
if getPlayerDataFunction then
	getPlayerDataFunction.OnServerInvoke = function(player)
		return DataStoreManager:GetPlayerData(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	DataStoreManager:LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataStoreManager:SavePlayerData(player)
	DataStoreManager:CleanupPlayerData(player)
end)

game:BindToClose(function()
	DataStoreManager:SaveAllPlayerData()
end)

spawn(function()
	while true do
		wait(600)
		DataStoreManager:AutoSaveAllPlayers()
	end
end)

print("DataStore Handler initialized")

_G.DataStoreManager = DataStoreManager