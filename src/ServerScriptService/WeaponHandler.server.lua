local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local WeaponHandler = {}

local playerWeaponData = {}
local lastShotTimes = {}

function WeaponHandler:Initialize()
	RemoteEventsManager:Initialize()
	GameConfig:Initialize()
	
	local weaponFiredEvent = RemoteEventsManager:GetEvent("WeaponFired")
	local weaponReloadedEvent = RemoteEventsManager:GetEvent("WeaponReloaded")
	local weaponEquippedEvent = RemoteEventsManager:GetEvent("WeaponEquipped")
	local weaponUnequippedEvent = RemoteEventsManager:GetEvent("WeaponUnequipped")
	local meleeAttackEvent = RemoteEventsManager:GetEvent("MeleeAttack")
	local grenadeThrownEvent = RemoteEventsManager:GetEvent("GrenadeThrown")
	
	local getWeaponConfigFunction = RemoteEventsManager:GetFunction("GetWeaponConfig")
	local validateWeaponActionFunction = RemoteEventsManager:GetFunction("ValidateWeaponAction")
	
	if weaponFiredEvent then
		weaponFiredEvent.OnServerEvent:Connect(function(player, fireData)
			self:HandleWeaponFired(player, fireData)
		end)
	end
	
	if weaponReloadedEvent then
		weaponReloadedEvent.OnServerEvent:Connect(function(player, reloadData)
			self:HandleWeaponReloaded(player, reloadData)
		end)
	end
	
	if weaponEquippedEvent then
		weaponEquippedEvent.OnServerEvent:Connect(function(player, weaponData)
			self:HandleWeaponEquipped(player, weaponData)
		end)
	end
	
	if weaponUnequippedEvent then
		weaponUnequippedEvent.OnServerEvent:Connect(function(player, weaponData)
			self:HandleWeaponUnequipped(player, weaponData)
		end)
	end
	
	if getWeaponConfigFunction then
		getWeaponConfigFunction.OnServerInvoke = function(player, weaponName)
			return self:GetWeaponConfig(weaponName)
		end
	end
	
	if validateWeaponActionFunction then
		validateWeaponActionFunction.OnServerInvoke = function(player, actionData)
			return self:ValidateWeaponAction(player, actionData)
		end
	end
	
	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerWeaponData(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerWeaponData(player)
	end)
	
	print("WeaponHandler initialized")
end

function WeaponHandler:InitializePlayerWeaponData(player)
	playerWeaponData[player] = {
		equippedWeapon = nil,
		ammoCount = {},
		lastFireTime = 0,
		lastReloadTime = 0
	}
	
	lastShotTimes[player] = {}
end

function WeaponHandler:CleanupPlayerWeaponData(player)
	playerWeaponData[player] = nil
	lastShotTimes[player] = nil
end

function WeaponHandler:HandleWeaponFired(player, fireData)
	if not self:ValidateFireData(player, fireData) then
		warn("Invalid fire data from player: " .. player.Name)
		return
	end
	
	local weaponConfig = WeaponConfig:GetWeaponConfig(fireData.WeaponName)
	if not weaponConfig then
		warn("Unknown weapon: " .. fireData.WeaponName)
		return
	end
	
	local currentTime = tick()
	local timeBetweenShots = 60 / weaponConfig.FireRate
	
	if currentTime - (lastShotTimes[player][fireData.WeaponName] or 0) < timeBetweenShots * 0.8 then
		warn("Player " .. player.Name .. " firing too fast")
		return
	end
	
	lastShotTimes[player][fireData.WeaponName] = currentTime
	
	local playerData = playerWeaponData[player]
	if playerData then
		playerData.lastFireTime = currentTime
	end
	
	self:ProcessWeaponFire(player, fireData, weaponConfig)
	
	print(player.Name .. " fired " .. fireData.WeaponName)
end

function WeaponHandler:ProcessWeaponFire(player, fireData, weaponConfig)
	RemoteEventsManager:FireAllClients("WeaponFired", player, {
		WeaponName = fireData.WeaponName,
		Origin = fireData.Origin,
		Direction = fireData.Direction,
		PlayerId = player.UserId
	})
end

function WeaponHandler:HandleWeaponReloaded(player, reloadData)
	local weaponConfig = WeaponConfig:GetWeaponConfig(reloadData.WeaponName)
	if not weaponConfig then
		warn("Unknown weapon for reload: " .. reloadData.WeaponName)
		return
	end
	
	local playerData = playerWeaponData[player]
	if playerData then
		playerData.lastReloadTime = tick()
	end
	
	print(player.Name .. " reloaded " .. reloadData.WeaponName)
end

function WeaponHandler:HandleWeaponEquipped(player, weaponData)
	local playerData = playerWeaponData[player]
	if playerData then
		playerData.equippedWeapon = weaponData.WeaponName
	end
	
	print(player.Name .. " equipped " .. weaponData.WeaponName)
end

function WeaponHandler:HandleWeaponUnequipped(player, weaponData)
	local playerData = playerWeaponData[player]
	if playerData then
		playerData.equippedWeapon = nil
	end
	
	print(player.Name .. " unequipped " .. weaponData.WeaponName)
end

function WeaponHandler:ValidateFireData(player, fireData)
	if not fireData.WeaponName or not fireData.Origin or not fireData.Direction then
		warn("Missing required fire data fields")
		return false
	end
	
	if not player.Character then
		warn("Player has no character")
		return false
	end
	
	local head = player.Character:FindFirstChild("Head")
	if not head then
		warn("Player character has no head")
		return false
	end
	
	local distance = (fireData.Origin - head.Position).Magnitude
	if distance > 50 then -- Increased from 10 to 50
		warn("Fire origin too far from player head: " .. distance)
		return false
	end
	
	return true
end

function WeaponHandler:GetWeaponConfig(weaponName)
	return WeaponConfig:GetWeaponConfig(weaponName)
end

function WeaponHandler:ValidateWeaponAction(player, actionData)
	local weaponConfig = WeaponConfig:GetWeaponConfig(actionData.WeaponName)
	if not weaponConfig then
		return false
	end
	
	return true
end

function WeaponHandler:GivePlayerWeapon(player, weaponName)
	if not WeaponConfig:IsValidWeapon(weaponName) then
		warn("Unknown weapon: " .. weaponName)
		return false
	end
	
	local weaponTool = ServerStorage.Weapons:FindFirstChild(weaponName)
	if not weaponTool then
		warn("Weapon tool not found: " .. weaponName)
		return false
	end
	
	if player.Character then
		local clonedTool = weaponTool:Clone()
		clonedTool.Parent = player.Character
		return true
	end
	
	return false
end

function WeaponHandler:GetPlayerWeaponData(player)
	return playerWeaponData[player]
end

WeaponHandler:Initialize()

return WeaponHandler