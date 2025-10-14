local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local AmmoHandler = {}

-- Player ammo data on server
local playerAmmoData = {}

-- Ammo unlock requirements (level-based)
local AMMO_UNLOCK_LEVELS = {
	Standard = 0,
	Tracer = 3,
	HP = 8,
	Subsonic = 12,
	FMJ = 5,
	AP = 15,
	Frostbite = 20,
	Incendiary = 25,
	Match = 30,
	Explosive = 35
}

function AmmoHandler:Initialize()
	DataStoreManager:Initialize()

	-- Handle ammo selection from clients
	local selectAmmoEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SelectAmmoType")
	if selectAmmoEvent then
		selectAmmoEvent.OnServerEvent:Connect(function(player, ammoData)
			self:HandleAmmoSelection(player, ammoData)
		end)
	end
	
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerAmmo(player)
	end)
	
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerAmmo(player)
		playerAmmoData[player] = nil
	end)
	
	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		self:InitializePlayerAmmo(player)
	end
	
	-- Periodic save
	spawn(function()
		while true do
			wait(300) -- Save every 5 minutes
			for _, player in pairs(Players:GetPlayers()) do
				self:SavePlayerAmmo(player)
			end
		end
	end)
	
	_G.AmmoHandler = self
	print("AmmoHandler initialized")
end

function AmmoHandler:InitializePlayerAmmo(player)
	-- Initialize default ammo data
	playerAmmoData[player] = {
		CurrentAmmoType = {
			["9mm"] = "Standard",
			["556"] = "Standard", 
			["762"] = "Standard",
			["12gauge"] = "Standard",
			["45acp"] = "Standard"
		},
		AmmoCount = {
			["9mm"] = {Standard = 300, Tracer = 60, HP = 0, Subsonic = 0, FMJ = 0, AP = 0, Frostbite = 0, Incendiary = 0, Match = 0, Explosive = 0},
			["556"] = {Standard = 300, Tracer = 60, HP = 0, Subsonic = 0, FMJ = 0, AP = 0, Frostbite = 0, Incendiary = 0, Match = 0, Explosive = 0},
			["762"] = {Standard = 200, Tracer = 40, HP = 0, Subsonic = 0, FMJ = 0, AP = 0, Frostbite = 0, Incendiary = 0, Match = 0, Explosive = 0},
			["12gauge"] = {Standard = 100, Tracer = 20, HP = 0, Subsonic = 0, FMJ = 0, AP = 0, Frostbite = 0, Incendiary = 0, Match = 0, Explosive = 0},
			["45acp"] = {Standard = 250, Tracer = 50, HP = 0, Subsonic = 0, FMJ = 0, AP = 0, Frostbite = 0, Incendiary = 0, Match = 0, Explosive = 0}
		},
		UnlockedAmmoTypes = {"Standard", "Tracer"}
	}
	
	-- Load saved data if available
	self:LoadPlayerAmmo(player)
	
	-- Check for newly unlocked ammo types based on level
	self:CheckAmmoUnlocks(player)
	
	-- Send initial ammo data to client
	wait(2) -- Give client time to initialize
	self:SyncAmmoWithClient(player)
end

function AmmoHandler:LoadPlayerAmmo(player)
	if not DataStoreManager then return end
	
	-- Load ammo data from DataStore
	local savedAmmoData = DataStoreManager:GetPlayerData(player, "AmmoData")
	if savedAmmoData then
		-- Merge saved data with defaults
		for key, value in pairs(savedAmmoData) do
			if playerAmmoData[player][key] then
				playerAmmoData[player][key] = value
			end
		end
	end
end

function AmmoHandler:SavePlayerAmmo(player)
	if not DataStoreManager or not playerAmmoData[player] then return end
	
	-- Save ammo data to DataStore
	DataStoreManager:SetPlayerData(player, "AmmoData", playerAmmoData[player])
end

function AmmoHandler:HandleAmmoSelection(player, ammoData)
	local playerData = playerAmmoData[player]
	if not playerData then return end
	
	local caliber = ammoData.Caliber
	local ammoType = ammoData.AmmoType
	
	-- Validate ammo type is unlocked and available
	if not table.find(playerData.UnlockedAmmoTypes, ammoType) then
		print("Player " .. player.Name .. " tried to select locked ammo type: " .. ammoType)
		return
	end
	
	-- Check if player has ammo of this type
	if not playerData.AmmoCount[caliber] or (playerData.AmmoCount[caliber][ammoType] or 0) <= 0 then
		print("Player " .. player.Name .. " has no " .. ammoType .. " ammo for " .. caliber)
		return
	end
	
	-- Update current ammo type
	playerData.CurrentAmmoType[caliber] = ammoType
	
	-- Sync with client
	self:SyncAmmoWithClient(player)
	
	print("Player " .. player.Name .. " selected " .. ammoType .. " for " .. caliber)
end

function AmmoHandler:SyncAmmoWithClient(player)
	local playerData = playerAmmoData[player]
	if not playerData then return end

	local event = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AmmoUpdate")
	if event then
		event:FireClient(player, {
			CurrentAmmoType = playerData.CurrentAmmoType,
			AmmoCount = playerData.AmmoCount,
			UnlockedAmmoTypes = playerData.UnlockedAmmoTypes
		})
	end
end

function AmmoHandler:CheckAmmoUnlocks(player)
	if not DataStoreManager then return end
	
	local playerLevel = DataStoreManager:GetPlayerData(player, "Level") or 1
	local playerData = playerAmmoData[player]
	if not playerData then return end
	
	-- Check each ammo type's unlock level
	for ammoType, unlockLevel in pairs(AMMO_UNLOCK_LEVELS) do
		if playerLevel >= unlockLevel and not table.find(playerData.UnlockedAmmoTypes, ammoType) then
			-- Unlock this ammo type
			table.insert(playerData.UnlockedAmmoTypes, ammoType)
			
			-- Give some starting ammo for newly unlocked type
			for caliber, ammoTypes in pairs(playerData.AmmoCount) do
				if ammoType == "HP" or ammoType == "Subsonic" then
					ammoTypes[ammoType] = 30
				elseif ammoType == "FMJ" or ammoType == "AP" then
					ammoTypes[ammoType] = 50
				elseif ammoType == "Frostbite" or ammoType == "Incendiary" then
					ammoTypes[ammoType] = 20
				elseif ammoType == "Match" then
					ammoTypes[ammoType] = 40
				elseif ammoType == "Explosive" then
					ammoTypes[ammoType] = 10
				end
			end
			
			-- Notify client of unlock
			local event = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AmmoUnlock")
			if event then
				event:FireClient(player, {
					AmmoType = ammoType,
					UnlockLevel = unlockLevel
				})
			end
			
			print("Player " .. player.Name .. " unlocked ammo type: " .. ammoType)
		end
	end
end

function AmmoHandler:ConsumeAmmo(player, caliber, ammoType, amount)
	local playerData = playerAmmoData[player]
	if not playerData or not playerData.AmmoCount[caliber] then
		return false
	end
	
	local currentCount = playerData.AmmoCount[caliber][ammoType] or 0
	if currentCount >= amount then
		playerData.AmmoCount[caliber][ammoType] = currentCount - amount
		
		-- Sync with client
		self:SyncAmmoWithClient(player)
		return true
	end
	
	return false
end

function AmmoHandler:GiveAmmo(player, caliber, ammoType, amount)
	local playerData = playerAmmoData[player]
	if not playerData then return end
	
	if not playerData.AmmoCount[caliber] then
		playerData.AmmoCount[caliber] = {}
	end
	
	local currentCount = playerData.AmmoCount[caliber][ammoType] or 0
	playerData.AmmoCount[caliber][ammoType] = math.min(currentCount + amount, 999) -- Cap at 999
	
	-- Sync with client
	self:SyncAmmoWithClient(player)
	
	print("Gave " .. amount .. " " .. ammoType .. " rounds (" .. caliber .. ") to " .. player.Name)
end

function AmmoHandler:GetPlayerAmmoCount(player, caliber, ammoType)
	local playerData = playerAmmoData[player]
	if not playerData or not playerData.AmmoCount[caliber] then
		return 0
	end
	
	return playerData.AmmoCount[caliber][ammoType] or 0
end

function AmmoHandler:GetCurrentAmmoType(player, caliber)
	local playerData = playerAmmoData[player]
	if not playerData then
		return "Standard"
	end
	
	return playerData.CurrentAmmoType[caliber] or "Standard"
end

function AmmoHandler:IsAmmoTypeUnlocked(player, ammoType)
	local playerData = playerAmmoData[player]
	if not playerData then
		return false
	end
	
	return table.find(playerData.UnlockedAmmoTypes, ammoType) ~= nil
end

function AmmoHandler:ForceUnlockAmmoType(player, ammoType)
	local playerData = playerAmmoData[player]
	if not playerData then return end
	
	if not table.find(playerData.UnlockedAmmoTypes, ammoType) then
		table.insert(playerData.UnlockedAmmoTypes, ammoType)
		
		-- Give some starting ammo
		for caliber, ammoTypes in pairs(playerData.AmmoCount) do
			ammoTypes[ammoType] = 50
		end
		
		-- Notify client
		local event = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("AmmoUnlock")
		if event then
			event:FireClient(player, {
				AmmoType = ammoType,
				UnlockLevel = 0
			})
		end
		
		self:SyncAmmoWithClient(player)
		
		print("Force unlocked " .. ammoType .. " for " .. player.Name)
	end
end

function AmmoHandler:GetAmmoModifiers(player, caliber)
	-- Return ammo modifiers for current ammo type
	local currentAmmoType = self:GetCurrentAmmoType(player, caliber)
	
	-- Mirror client-side ammo configs
	local AMMO_CONFIGS = {
		Standard = {DamageMultiplier = 1.0, VelocityMultiplier = 1.0, PenetrationMultiplier = 1.0, RecoilMultiplier = 1.0, SpreadMultiplier = 1.0},
		FMJ = {DamageMultiplier = 0.9, VelocityMultiplier = 1.1, PenetrationMultiplier = 1.5, RecoilMultiplier = 1.1, SpreadMultiplier = 0.95},
		AP = {DamageMultiplier = 0.85, VelocityMultiplier = 1.2, PenetrationMultiplier = 2.0, RecoilMultiplier = 1.2, SpreadMultiplier = 0.9},
		HP = {DamageMultiplier = 1.25, VelocityMultiplier = 0.95, PenetrationMultiplier = 0.7, RecoilMultiplier = 0.9, SpreadMultiplier = 1.05},
		Tracer = {DamageMultiplier = 1.0, VelocityMultiplier = 1.0, PenetrationMultiplier = 1.0, RecoilMultiplier = 1.0, SpreadMultiplier = 1.0},
		Incendiary = {DamageMultiplier = 1.1, VelocityMultiplier = 0.9, PenetrationMultiplier = 1.2, RecoilMultiplier = 1.1, SpreadMultiplier = 1.1},
		Frostbite = {DamageMultiplier = 0.95, VelocityMultiplier = 0.95, PenetrationMultiplier = 0.9, RecoilMultiplier = 0.95, SpreadMultiplier = 0.9},
		Explosive = {DamageMultiplier = 1.3, VelocityMultiplier = 0.8, PenetrationMultiplier = 0.6, RecoilMultiplier = 1.4, SpreadMultiplier = 1.2},
		Subsonic = {DamageMultiplier = 0.9, VelocityMultiplier = 0.7, PenetrationMultiplier = 0.85, RecoilMultiplier = 0.8, SpreadMultiplier = 1.1},
		Match = {DamageMultiplier = 1.05, VelocityMultiplier = 1.1, PenetrationMultiplier = 1.1, RecoilMultiplier = 0.9, SpreadMultiplier = 0.7}
	}
	
	return AMMO_CONFIGS[currentAmmoType] or AMMO_CONFIGS.Standard
end

-- Admin commands for testing
_G.AdminAmmoCommands = {
	givePlayerAmmo = function(playerName, caliber, ammoType, amount)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer then
			AmmoHandler:GiveAmmo(targetPlayer, caliber, ammoType, tonumber(amount) or 100)
		else
			print("Player not found: " .. playerName)
		end
	end,
	
	unlockPlayerAmmo = function(playerName, ammoType)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer then
			AmmoHandler:ForceUnlockAmmoType(targetPlayer, ammoType)
		else
			print("Player not found: " .. playerName)
		end
	end,
	
	checkPlayerAmmo = function(playerName)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer then
			local playerData = playerAmmoData[targetPlayer]
			if playerData then
				print("Ammo data for " .. playerName .. ":")
				print("Unlocked types: " .. table.concat(playerData.UnlockedAmmoTypes, ", "))
				for caliber, ammoTypes in pairs(playerData.AmmoCount) do
					print(caliber .. ":")
					for ammoType, count in pairs(ammoTypes) do
						if count > 0 then
							print("  " .. ammoType .. ": " .. count)
						end
					end
				end
			end
		else
			print("Player not found: " .. playerName)
		end
	end,
	
	setPlayerAmmoType = function(playerName, caliber, ammoType)
		local targetPlayer = Players:FindFirstChild(playerName)
		if targetPlayer then
			AmmoHandler:HandleAmmoSelection(targetPlayer, {Caliber = caliber, AmmoType = ammoType})
		else
			print("Player not found: " .. playerName)
		end
	end,
	
	clearAllAmmo = function()
		for player, data in pairs(playerAmmoData) do
			for caliber, ammoTypes in pairs(data.AmmoCount) do
				for ammoType, _ in pairs(ammoTypes) do
					ammoTypes[ammoType] = 0
				end
			end
			AmmoHandler:SyncAmmoWithClient(player)
		end
		print("Cleared all player ammo")
	end,
	
	refillAllAmmo = function()
		for player, data in pairs(playerAmmoData) do
			for caliber, ammoTypes in pairs(data.AmmoCount) do
				for ammoType, _ in pairs(ammoTypes) do
					if table.find(data.UnlockedAmmoTypes, ammoType) then
						ammoTypes[ammoType] = ammoType == "Standard" and 300 or 100
					end
				end
			end
			AmmoHandler:SyncAmmoWithClient(player)
		end
		print("Refilled all player ammo")
	end
}

AmmoHandler:Initialize()

return AmmoHandler