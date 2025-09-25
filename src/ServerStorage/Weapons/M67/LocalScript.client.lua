local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GrenadeSystem = require(ReplicatedStorage.FPSSystem.Modules.GrenadeSystem)

local player = Players.LocalPlayer
local tool = script.Parent
local weaponName = tool.Name

function onActivated()
	GrenadeSystem:ThrowGrenade(weaponName)
end

function onEquipped()
	RemoteEventsManager:FireServer("WeaponEquipped", {
		WeaponName = weaponName,
		Player = player.Name
	})
end

function onUnequipped()
	RemoteEventsManager:FireServer("WeaponUnequipped", {
		WeaponName = weaponName,
		Player = player.Name
	})
end

tool.Activated:Connect(onActivated)
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

RemoteEventsManager:Initialize()
GrenadeSystem:Initialize()