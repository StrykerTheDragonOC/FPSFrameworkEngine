--[[
	M67 Grenade Client Script
	Fixed version with proper remote events
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- Modules
local GrenadeSystem = require(ReplicatedStorage.FPSSystem.Modules.GrenadeSystem)

-- Remote Events (NO RemoteEventsManager!)
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")

local player = Players.LocalPlayer
local tool = script.Parent
local weaponName = tool.Name

-- Throw grenade
function onActivated()
	GrenadeSystem:ThrowGrenade(weaponName)
end

-- Tool equipped
function onEquipped()
	-- Notify server (FIXED: send table with WeaponName key, not just string)
	WeaponEquipped:FireServer({WeaponName = weaponName})

	print("Equipped grenade:", weaponName)
end

-- Tool unequipped
function onUnequipped()
	-- Notify server (FIXED: send table with WeaponName key, not just string)
	WeaponUnequipped:FireServer({WeaponName = weaponName})

	print("Unequipped grenade:", weaponName)
end

-- Connect tool events
tool.Activated:Connect(onActivated)
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

print("M67 grenade script loaded ✓")
