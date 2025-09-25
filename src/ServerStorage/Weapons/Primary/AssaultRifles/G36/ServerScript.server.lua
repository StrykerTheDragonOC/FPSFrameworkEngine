local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)

local tool = script.Parent
local weaponName = tool.Name

local lastFireTimes = {}

function onWeaponFired(player, fireData)
	-- Validate player owns this tool
	if not player.Character or not player.Character:FindFirstChild(weaponName) then
		return
	end
	
	-- Rate limiting
	local currentTime = tick()
	local lastTime = lastFireTimes[player] or 0
	local weaponStats = WeaponConfig:GetWeaponStats(weaponName)
	local fireRate = 60 / weaponStats.FireRate
	
	if currentTime - lastTime < fireRate then
		return
	end
	
	lastFireTimes[player] = currentTime
	
	-- Validate hit
	if fireData.Hit and fireData.Hit.Character then
		local targetCharacter = fireData.Hit.Character
		local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
		
		if targetPlayer and targetPlayer ~= player then
			-- Apply damage
			local damage = weaponStats.Damage
			if fireData.Hit.Part.Name == "Head" then
				damage = damage * weaponStats.HeadshotMultiplier
			end
			
			DamageSystem:DamagePlayer(targetPlayer, player, {
				Damage = damage,
				WeaponName = weaponName,
				HitPart = fireData.Hit.Part.Name,
				Distance = fireData.Distance,
				IsHeadshot = fireData.Hit.Part.Name == "Head"
			})
		end
	end
	
	-- Broadcast to other players (not the shooter)
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			RemoteEventsManager:FireClient(otherPlayer, "WeaponFired", player, fireData)
		end
	end
end

function onPlayerRemoving(player)
	lastFireTimes[player] = nil
end

-- Initialize only if methods exist
if RemoteEventsManager.Initialize then
	RemoteEventsManager:Initialize()
end

if DamageSystem.Initialize then
	DamageSystem:Initialize()
end

-- Connect events
local weaponFiredEvent = RemoteEventsManager:GetEvent("WeaponFired")
if weaponFiredEvent then
	weaponFiredEvent.OnServerEvent:Connect(onWeaponFired)
end

Players.PlayerRemoving:Connect(onPlayerRemoving)