--[[
	PocketKnife Melee Client Script
	Fixed version with proper remote events
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- Modules
local MeleeSystem = require(ReplicatedStorage.FPSSystem.Modules.MeleeSystem)

-- Remote Events (NO RemoteEventsManager!)
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")

local player = Players.LocalPlayer
local tool = script.Parent
local weaponName = tool.Name

-- Melee attack
function onActivated()
	MeleeSystem:PerformAttack(false)
end

-- Tool equipped
function onEquipped()
	MeleeSystem:OnMeleeEquipped(tool)

	-- Notify server (FIXED: send table with WeaponName key, not just string)
	WeaponEquipped:FireServer({WeaponName = weaponName})

	print("Equipped melee:", weaponName)
end

-- Tool unequipped
function onUnequipped()
	MeleeSystem:OnMeleeUnequipped(tool)

	-- Notify server (FIXED: send table with WeaponName key, not just string)
	WeaponUnequipped:FireServer({WeaponName = weaponName})

	print("Unequipped melee:", weaponName)
end

-- Connect tool events
tool.Activated:Connect(onActivated)
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

print("PocketKnife script loaded ✓")
