local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local DayNightSystem = require(ReplicatedStorage.FPSSystem.Modules.DayNightSystem)

local DayNightHandler = {}

function DayNightHandler:Initialize()
	RemoteEventsManager:Initialize()
	DayNightSystem:Initialize()
	
	-- Sync time with clients every few seconds
	spawn(function()
		while true do
			wait(5) -- Sync every 5 seconds
			self:SyncTimeWithClients()
		end
	end)
	
	-- Handle player joining (send current time)
	Players.PlayerAdded:Connect(function(player)
		-- Wait a moment for client to load
		wait(3)
		self:SyncTimeWithPlayer(player)
	end)
	
	_G.DayNightHandler = self
	print("DayNightHandler initialized (Server)")
end

function DayNightHandler:SyncTimeWithClients()
	local currentTime = DayNightSystem:GetCurrentTime()
	local currentPreset = DayNightSystem:GetCurrentPresetName()
	
	-- Send to all clients
	for _, player in pairs(Players:GetPlayers()) do
		RemoteEventsManager:FireClient(player, "TimeUpdate", {
			Time = currentTime,
			Preset = currentPreset
		})
	end
end

function DayNightHandler:SyncTimeWithPlayer(player)
	local currentTime = DayNightSystem:GetCurrentTime()
	local currentPreset = DayNightSystem:GetCurrentPresetName()
	
	RemoteEventsManager:FireClient(player, "TimeUpdate", {
		Time = currentTime,
		Preset = currentPreset
	})
end

-- Server commands for admins
_G.AdminTimeCommands = {
	setServerTime = function(hour)
		local time = tonumber(hour)
		if time and time >= 0 and time <= 24 then
			DayNightSystem:SetTimeOfDay(time)
			DayNightHandler:SyncTimeWithClients()
			print("Server time set to: " .. DayNightSystem:FormatTime(time))
		end
	end,
	
	setServerPreset = function(presetName)
		DayNightSystem:SetPreset(presetName)
		DayNightHandler:SyncTimeWithClients()
		print("Server preset set to: " .. presetName)
	end,
	
	toggleServerCycle = function()
		DayNightSystem:ToggleCycle()
		print("Server day/night cycle toggled")
	end,
	
	setServerSpeed = function(speed)
		DayNightSystem:SetCycleSpeed(tonumber(speed) or 1)
		print("Server cycle speed set to: " .. (tonumber(speed) or 1) .. "x")
	end
}

DayNightHandler:Initialize()

return DayNightHandler