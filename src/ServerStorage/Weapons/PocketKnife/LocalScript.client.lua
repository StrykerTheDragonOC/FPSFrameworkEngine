local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local MeleeSystem = require(ReplicatedStorage.FPSSystem.Modules.MeleeSystem)

local player = Players.LocalPlayer
local tool = script.Parent
local weaponName = tool.Name

function onActivated()
	MeleeSystem:PerformAttack(false)
end

function onEquipped()
	MeleeSystem:OnMeleeEquipped(tool)
	RemoteEventsManager:FireServer("WeaponEquipped", {
		WeaponName = weaponName,
		Player = player.Name
	})
end

function onUnequipped()
	MeleeSystem:OnMeleeUnequipped(tool)
	RemoteEventsManager:FireServer("WeaponUnequipped", {
		WeaponName = weaponName,
		Player = player.Name
	})
end

tool.Activated:Connect(onActivated)
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

RemoteEventsManager:Initialize()
MeleeSystem:Initialize()