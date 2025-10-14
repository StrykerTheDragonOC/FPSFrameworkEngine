local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)
local XPSystem = require(ReplicatedStorage.FPSSystem.Modules.XPSystem)
local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)
local BallisticsSystem = require(ReplicatedStorage.FPSSystem.Modules.BallisticsSystem)
local TeamManager = require(ReplicatedStorage.FPSSystem.Modules.TeamManager)
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)
local AttachmentManager = require(ReplicatedStorage.FPSSystem.Modules.AttachmentManager)

print("=== FPS System Initializing ===")

-- Initialize core systems
RemoteEventsManager:Initialize()
GameConfig:Initialize()
TeamManager:Initialize()
DataStoreManager:Initialize()

-- Initialize combat systems
XPSystem:Initialize()
RaycastSystem:Initialize()
DamageSystem:Initialize()
BallisticsSystem:Initialize()

-- Weapon giving is handled by SimpleWeaponGiver for now
-- Players.PlayerAdded:Connect(function(player)
-- 	wait(2)
-- 	
-- 	local weaponScript = script.Parent:FindFirstChild("WeaponHandler")
-- 	if weaponScript then
-- 		local weaponHandler = require(weaponScript)
-- 		if weaponHandler then
-- 			weaponHandler:GivePlayerWeapon(player, "G36")
-- 			weaponHandler:GivePlayerWeapon(player, "M9")
-- 			weaponHandler:GivePlayerWeapon(player, "PocketKnife")
-- 			weaponHandler:GivePlayerWeapon(player, "M67")
-- 			
-- 			print("Gave default weapons to " .. player.Name)
-- 		end
-- 	end
-- end)

-- Setup player joining/leaving handlers
Players.PlayerAdded:Connect(function(player)
	-- Load player data first
	DataStoreManager:LoadPlayerData(player)
	
	-- Add player to lobby team initially
	wait(1) -- Wait for character to spawn
	TeamManager:OnPlayerJoined(player)
	
	print(player.Name .. " joined the game")
end)

Players.PlayerRemoving:Connect(function(player)
	-- Save player data
	DataStoreManager:SavePlayerData(player)
	
	-- Clean up team data
	TeamManager:OnPlayerLeft(player)
	
	print(player.Name .. " left the game")
end)

print("=== FPS System Initialized Successfully ===")
print("Available weapons: G36, M9, PocketKnife, M67")
print("Teams: FBI (Navy Blue), KFC (Maroon), Lobby (Gray)")
print("Systems: Team Management, Data Persistence, Health, XP, Ballistics, Gamemodes, Attachments")
print("Features: Advanced HUD, Radar, Movement (slide/dive), Shop System, Kill Streaks, Spectator Mode")
print("Gamemodes: TDM, KOTH, KC, CTF (rotating every 20 minutes)")
print("Controls: B = Shop, K = Attachments, Ctrl = Crouch, Shift = Slide, X (midair) = Dive, Z = Prone")
print("Systems ready for full gameplay!")