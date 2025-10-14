--[[
	M9 Pistol Server Script
	Fixed version with proper remote events
	Handles server-side weapon validation and damage
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- Modules
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)

-- Remote Events (NO RemoteEventsManager!)
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFired = RemoteEvents:WaitForChild("WeaponFired")

local tool = script.Parent
local weaponName = tool.Name

local lastFireTimes = {}

-- Handle weapon fired event from client
function onWeaponFired(player, weaponName, origin, direction, raycastResult)
	-- Validate player owns this tool
	if not player.Character or not player.Character:FindFirstChild(weaponName) then
		return
	end

	-- Rate limiting
	local currentTime = tick()
	local lastTime = lastFireTimes[player] or 0
	local weaponStats = WeaponConfig:GetWeaponStats(weaponName)
	local fireRate = 60 / (weaponStats.FireRate or 450)

	if currentTime - lastTime < fireRate then
		return
	end

	lastFireTimes[player] = currentTime

	-- Validate and apply damage if hit
	if raycastResult and raycastResult.Instance then
		local hitPart = raycastResult.Instance
		local targetCharacter = hitPart.Parent

		if targetCharacter and targetCharacter:FindFirstChild("Humanoid") then
			local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

			if targetPlayer and targetPlayer ~= player then
				-- Calculate damage
				local damage = weaponStats.Damage or 25
				if hitPart.Name == "Head" then
					damage = damage * (weaponStats.HeadshotMultiplier or 2.5)
				end

				-- Apply damage through DamageSystem
				DamageSystem:DamagePlayer(targetPlayer, player, {
					Damage = damage,
					WeaponName = weaponName,
					HitPart = hitPart.Name,
					Distance = raycastResult.Distance or 0,
					IsHeadshot = hitPart.Name == "Head"
				})
			end
		end
	end

	-- Broadcast to other players (not the shooter) for visual effects
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			WeaponFired:FireClient(otherPlayer, player, weaponName, origin, direction, raycastResult)
		end
	end
end

-- Clean up player data on leave
function onPlayerRemoving(player)
	lastFireTimes[player] = nil
end

-- Connect events
WeaponFired.OnServerEvent:Connect(onWeaponFired)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("M9 server script loaded ✓")
