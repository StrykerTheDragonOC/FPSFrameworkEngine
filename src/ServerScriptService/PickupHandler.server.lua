local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local PickupHandler = {}

local activePickups = {} -- [pickupId] = {type, position, spawnTime, respawnTime}
local pickupSpawnPoints = {} -- Predefined spawn locations

-- Initialize spawn points (can be configured per map)
local DEFAULT_SPAWN_POINTS = {
	-- Health spawns
	{Position = Vector3.new(0, 5, 0), Type = "Health Pack", Probability = 0.3},
	{Position = Vector3.new(20, 5, 20), Type = "Medical Kit", Probability = 0.15},
	
	-- Ammo spawns
	{Position = Vector3.new(-20, 5, 0), Type = "Rifle Ammo", Probability = 0.4},
	{Position = Vector3.new(0, 5, -20), Type = "Pistol Ammo", Probability = 0.5},
	{Position = Vector3.new(20, 5, -20), Type = "Sniper Ammo", Probability = 0.2},
	
	-- Armor spawns
	{Position = Vector3.new(-20, 5, 20), Type = "Light Armor", Probability = 0.25},
	{Position = Vector3.new(30, 5, 0), Type = "Heavy Armor", Probability = 0.1},
	
	-- Special spawns
	{Position = Vector3.new(0, 5, 30), Type = "Night Vision", Probability = 0.05},
	{Position = Vector3.new(-30, 5, 0), Type = "Speed Boost", Probability = 0.15},
}

function PickupHandler:Initialize()
	RemoteEventsManager:Initialize()
	
	-- Handle pickup requests from clients
	local pickupEvent = RemoteEventsManager:GetEvent("PickupItem")
	if pickupEvent then
		pickupEvent.OnServerEvent:Connect(function(player, pickupData)
			self:HandlePickupRequest(player, pickupData)
		end)
	end
	
	-- Handle spawn pickup requests  
	local spawnEvent = RemoteEventsManager:GetEvent("SpawnPickup")
	if spawnEvent then
		spawnEvent.OnServerEvent:Connect(function(player, spawnData)
			-- Only allow admins/devs to spawn pickups
			if self:IsPlayerAdmin(player) then
				self:SpawnPickup(spawnData.PickupType, spawnData.Position)
			end
		end)
	end
	
	-- Initialize spawn points
	self:LoadSpawnPoints()
	
	-- Start pickup management loop
	self:StartPickupLoop()
	
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)
	
	_G.PickupHandler = self
	print("PickupHandler initialized")
end

function PickupHandler:LoadSpawnPoints()
	-- Use default spawn points for now
	pickupSpawnPoints = DEFAULT_SPAWN_POINTS
	
	-- TODO: Load from map configuration
	print("Loaded " .. #pickupSpawnPoints .. " pickup spawn points")
end

function PickupHandler:StartPickupLoop()
	spawn(function()
		while true do
			self:UpdatePickups()
			wait(1) -- Check every second
		end
	end)
	
	-- Initial spawn of pickups
	spawn(function()
		wait(5) -- Wait for players to load
		self:SpawnInitialPickups()
	end)
end

function PickupHandler:UpdatePickups()
	local currentTime = tick()
	
	-- Check for pickups that need to respawn
	for spawnPoint, spawnData in pairs(pickupSpawnPoints) do
		local pickupId = "spawn_" .. spawnPoint
		local pickup = activePickups[pickupId]
		
		if not pickup then
			-- Spawn new pickup if probability allows
			if math.random() < spawnData.Probability * 0.01 then -- Reduce spawn rate
				self:SpawnPickup(spawnData.Type, spawnData.Position, pickupId)
			end
		elseif pickup.respawnTime and currentTime >= pickup.respawnTime then
			-- Respawn pickup
			self:SpawnPickup(pickup.type, pickup.position, pickupId)
		end
	end
	
	-- Clean up expired pickups
	for pickupId, pickup in pairs(activePickups) do
		if pickup.expireTime and currentTime >= pickup.expireTime then
			self:RemovePickup(pickupId)
		end
	end
end

function PickupHandler:SpawnInitialPickups()
	for i, spawnData in pairs(pickupSpawnPoints) do
		if math.random() < spawnData.Probability then
			local pickupId = "spawn_" .. i
			self:SpawnPickup(spawnData.Type, spawnData.Position, pickupId)
		end
	end
end

function PickupHandler:HandlePickupRequest(player, pickupData)
	local pickupId = pickupData.PickupId
	local pickup = activePickups[pickupId]
	
	if not pickup then
		-- Pickup doesn't exist or was already taken
		return
	end
	
	-- Validate distance
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local distance = (character.HumanoidRootPart.Position - pickup.position).Magnitude
	if distance > 6 then -- 6 stud pickup range (slightly larger than client detection)
		return
	end
	
	-- Apply pickup effects
	local success = self:ApplyPickupToPlayer(player, pickup.type)
	if success then
		-- Remove pickup from world
		self:RemovePickup(pickupId)
		
		-- Set respawn timer
		local config = self:GetPickupConfig(pickup.type)
		if config and config.RespawnTime then
			pickup.respawnTime = tick() + config.RespawnTime
			pickup.taken = true
			activePickups[pickupId] = pickup -- Keep for respawn
		end
		
		-- Notify all clients that pickup was taken
		for _, clientPlayer in pairs(Players:GetPlayers()) do
			RemoteEventsManager:FireClient(clientPlayer, "PickupTaken", {
				Player = player,
				PickupType = pickup.type,
				PickupId = pickupId
			})
		end
		
		print(player.Name .. " picked up " .. pickup.type)
	end
end

function PickupHandler:ApplyPickupToPlayer(player, pickupType)
	local config = self:GetPickupConfig(pickupType)
	if not config then
		return false
	end
	
	local character = player.Character
	if not character then
		return false
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return false
	end
	
	-- Apply effects based on pickup type
	if config.Type == "Medical" then
		-- Heal player
		if config.HealAmount then
			local newHealth = math.min(humanoid.MaxHealth, humanoid.Health + config.HealAmount)
			humanoid.Health = newHealth
		end
		
		-- Remove status effects
		if config.RemoveStatusEffects then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:CureAllStatusEffects(player)
			end
		end
		
		-- Apply status effect
		if config.StatusEffect then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 30)
			end
		end
		
	elseif config.Type == "Armor" then
		-- Add armor (would integrate with armor system)
		local dataStore = DataStoreManager
		if dataStore then
			local currentArmor = dataStore:GetPlayerData(player, "Armor") or 0
			local newArmor = math.min(100, currentArmor + config.ArmorValue)
			dataStore:SetPlayerData(player, "Armor", newArmor)
		end
		
	elseif config.Type == "Ammo" then
		-- Add ammunition (would integrate with weapon system)
		local dataStore = DataStoreManager
		if dataStore then
			local currentAmmo = dataStore:GetPlayerData(player, config.AmmoType .. "_Ammo") or 0
			dataStore:SetPlayerData(player, config.AmmoType .. "_Ammo", currentAmmo + config.AmmoAmount)
		end
		
	elseif config.Type == "Equipment" then
		-- Give equipment
		local dataStore = DataStoreManager
		if dataStore then
			dataStore:SetPlayerData(player, config.Equipment, true)
		end
		
		-- Apply temporary effects if specified
		if config.StatusEffect then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 60)
			end
		end
		
	elseif config.Type == "Powerup" then
		-- Apply powerup status effect
		if config.StatusEffect then
			local statusSystem = _G.StatusEffectsSystem
			if statusSystem then
				statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 30)
			end
		end
	end
	
	-- Award XP for pickup
	local xpReward = 10
	if config.Rarity == "Uncommon" then xpReward = 15
	elseif config.Rarity == "Rare" then xpReward = 25
	elseif config.Rarity == "Epic" then xpReward = 40
	elseif config.Rarity == "Legendary" then xpReward = 75 end
	
	if DataStoreManager then
		DataStoreManager:AddXP(player, xpReward, "Item Pickup")
	end
	
	return true
end

function PickupHandler:SpawnPickup(pickupType, position, pickupId)
	pickupId = pickupId or tostring(tick()) .. "_" .. pickupType
	
	-- Store pickup data
	activePickups[pickupId] = {
		type = pickupType,
		position = position,
		spawnTime = tick(),
		taken = false,
		expireTime = tick() + 300 -- Expire after 5 minutes if not taken
	}
	
	-- Notify all clients to create visual
	for _, player in pairs(Players:GetPlayers()) do
		RemoteEventsManager:FireClient(player, "PickupSpawned", {
			PickupId = pickupId,
			PickupType = pickupType,
			Position = position
		})
	end
	
	print("Spawned pickup: " .. pickupType .. " at " .. tostring(position))
end

function PickupHandler:RemovePickup(pickupId)
	-- Remove from world
	local pickup = workspace:FindFirstChild(pickupId)
	if pickup then
		pickup:Destroy()
	end
	
	-- Remove from active list if permanently removed
	local pickupData = activePickups[pickupId]
	if pickupData and not pickupData.respawnTime then
		activePickups[pickupId] = nil
	end
end

function PickupHandler:GetPickupConfig(pickupType)
	-- Mirror of client-side config
	local PICKUP_CONFIGS = {
		-- Armor pickups
		["Light Armor"] = {Type = "Armor", ArmorValue = 25, RespawnTime = 45, Rarity = "Common"},
		["Heavy Armor"] = {Type = "Armor", ArmorValue = 50, RespawnTime = 90, Rarity = "Rare"},
		["Riot Armor"] = {Type = "Armor", ArmorValue = 100, RespawnTime = 120, Rarity = "Epic"},
		
		-- Medical pickups
		["Health Pack"] = {Type = "Medical", HealAmount = 50, RespawnTime = 30, Rarity = "Common"},
		["Medical Kit"] = {Type = "Medical", HealAmount = 100, RemoveStatusEffects = true, RespawnTime = 60, Rarity = "Rare"},
		["Adrenaline"] = {Type = "Medical", StatusEffect = "Adrenaline", Duration = 30, RespawnTime = 90, Rarity = "Rare"},
		
		-- Ammunition pickups
		["Pistol Ammo"] = {Type = "Ammo", AmmoType = "9mm", AmmoAmount = 30, RespawnTime = 20, Rarity = "Common"},
		["Rifle Ammo"] = {Type = "Ammo", AmmoType = "556", AmmoAmount = 60, RespawnTime = 25, Rarity = "Common"},
		["Sniper Ammo"] = {Type = "Ammo", AmmoType = "762", AmmoAmount = 20, RespawnTime = 40, Rarity = "Uncommon"},
		["Shotgun Shells"] = {Type = "Ammo", AmmoType = "12gauge", AmmoAmount = 16, RespawnTime = 30, Rarity = "Uncommon"},
		
		-- Equipment pickups
		["Night Vision"] = {Type = "Equipment", Equipment = "NVG", RespawnTime = 120, Rarity = "Epic"},
		["Thermal Scope"] = {Type = "Equipment", Equipment = "Thermal", RespawnTime = 150, Rarity = "Epic"},
		["Ghillie Suit"] = {Type = "Equipment", Equipment = "Ghillie", StatusEffect = "Camouflaged", Duration = 120, RespawnTime = 180, Rarity = "Legendary"},
		
		-- Special pickups
		["Speed Boost"] = {Type = "Powerup", StatusEffect = "SpeedBoost", Duration = 20, RespawnTime = 60, Rarity = "Rare"},
		["Damage Boost"] = {Type = "Powerup", StatusEffect = "DamageBoost", Duration = 15, RespawnTime = 75, Rarity = "Rare"},
		["Shield Generator"] = {Type = "Powerup", Equipment = "Shield", Duration = 45, RespawnTime = 120, Rarity = "Epic"}
	}
	
	return PICKUP_CONFIGS[pickupType]
end

function PickupHandler:IsPlayerAdmin(player)
	-- Check if player is admin/developer
	-- This should be integrated with your admin system
	return player.UserId == game.CreatorId or player.Name == "YourUsername" -- Replace with actual admin check
end

function PickupHandler:CleanupPlayerData(player)
	-- Clean up any player-specific pickup data
	-- Currently no per-player data to clean up
end

-- Admin commands
_G.AdminPickupCommands = {
	spawnPickup = function(pickupType, x, y, z)
		local position = Vector3.new(tonumber(x) or 0, tonumber(y) or 10, tonumber(z) or 0)
		PickupHandler:SpawnPickup(pickupType, position)
		print("Spawned " .. pickupType .. " at " .. tostring(position))
	end,
	
	clearAllPickups = function()
		for pickupId, _ in pairs(activePickups) do
			PickupHandler:RemovePickup(pickupId)
		end
		activePickups = {}
		print("Cleared all pickups")
	end,
	
	listActivePickups = function()
		print("Active pickups:")
		for pickupId, pickup in pairs(activePickups) do
			local status = pickup.taken and "TAKEN" or "ACTIVE"
			local respawn = pickup.respawnTime and ("respawn in " .. math.ceil(pickup.respawnTime - tick()) .. "s") or "no respawn"
			print("- " .. pickupId .. ": " .. pickup.type .. " (" .. status .. ", " .. respawn .. ")")
		end
	end,
	
	respawnAllPickups = function()
		PickupHandler:SpawnInitialPickups()
		print("Respawned all pickups")
	end,
	
	setSpawnPoint = function(pickupType, x, y, z, probability)
		local position = Vector3.new(tonumber(x) or 0, tonumber(y) or 5, tonumber(z) or 0)
		local prob = tonumber(probability) or 0.3
		
		table.insert(pickupSpawnPoints, {
			Position = position,
			Type = pickupType,
			Probability = prob
		})
		
		print("Added spawn point for " .. pickupType .. " at " .. tostring(position) .. " (prob: " .. prob .. ")")
	end
}

PickupHandler:Initialize()

return PickupHandler