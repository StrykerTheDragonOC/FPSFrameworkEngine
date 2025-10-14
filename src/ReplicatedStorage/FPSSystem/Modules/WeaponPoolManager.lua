--[[
	WeaponPoolManager
	Handles weapon unlock pools and random loadout selection
	Based on player rank and unlocked weapons
]]

local WeaponPoolManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

-- Only require DataStoreManager on server
local DataStoreManager = nil
if RunService:IsServer() then
	DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)
end

-- Default weapon pools for Rank 0 players
local DEFAULT_POOLS = {
	Primary = {"G36"}, -- Will expand with more default weapons
	Secondary = {"M9"}, -- Will expand with more default pistols
	Melee = {"PocketKnife"},
	Grenade = {"M67"}, -- Changed from M26 per CLAUDE.md
	Special = {"ViciousStinger"} -- For testing purposes (magic weapons)
}

-- Get default weapon pool for a category
function WeaponPoolManager:GetDefaultWeaponPool(category)
	return DEFAULT_POOLS[category] or {}
end

-- Get all unlocked weapons for a player in a category
function WeaponPoolManager:GetUnlockedWeapons(player, category)
	-- Get all weapons in the category from WeaponConfig
	local allWeapons = WeaponConfig:GetWeaponsByCategory(category)
	local unlockedWeapons = {}

	-- Check if DataStoreManager is available (server-side)
	if DataStoreManager then
		-- Check each weapon to see if it's unlocked
		for weaponName, weaponConfig in pairs(allWeapons) do
			if DataStoreManager:HasWeaponUnlocked(player, weaponName) then
				table.insert(unlockedWeapons, weaponName)
			end
		end

		-- If no weapons unlocked, return defaults
		if #unlockedWeapons == 0 then
			return self:GetDefaultWeaponPool(category)
		end

		return unlockedWeapons
	else
		-- Client-side or DataStoreManager not available - return defaults
		return self:GetDefaultWeaponPool(category)
	end
end

-- Check if a specific weapon is unlocked
function WeaponPoolManager:IsWeaponUnlocked(player, weaponName)
	-- Use DataStoreManager if available (server-side)
	if DataStoreManager then
		return DataStoreManager:HasWeaponUnlocked(player, weaponName)
	else
		-- Client-side fallback - check if weapon is in default pools
		for category, weapons in pairs(DEFAULT_POOLS) do
			for _, weapon in pairs(weapons) do
				if weapon == weaponName then
					return true
				end
			end
		end
		return false
	end
end

-- Add weapon to player's unlock pool
function WeaponPoolManager:AddWeaponToPool(player, weaponName, cost)
	-- Use DataStoreManager if available (server-side)
	if DataStoreManager then
		local success = DataStoreManager:UnlockWeapon(player, weaponName, cost)
		if success then
			print("WeaponPoolManager: Unlocked", weaponName, "for", player.Name)
			return true
		else
			warn("WeaponPoolManager: Failed to unlock", weaponName, "for", player.Name)
			return false
		end
	else
		-- Client-side - can't unlock weapons
		warn("WeaponPoolManager:AddWeaponToPool can only be called on server")
		return false
	end
end

-- Get a random weapon from a category pool
function WeaponPoolManager:GetRandomWeaponFromPool(pool)
	if #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

-- Generate a random loadout for a player
function WeaponPoolManager:GetRandomLoadout(player)
	local loadout = {}

	-- Get weapon pools for player
	local primaryPool = self:GetUnlockedWeapons(player, "Primary")
	local secondaryPool = self:GetUnlockedWeapons(player, "Secondary")
	local meleePool = self:GetUnlockedWeapons(player, "Melee")
	local grenadePool = self:GetUnlockedWeapons(player, "Grenade")
	local specialPool = self:GetUnlockedWeapons(player, "Special")

	-- Randomly select from each pool
	loadout.Primary = self:GetRandomWeaponFromPool(primaryPool)
	loadout.Secondary = self:GetRandomWeaponFromPool(secondaryPool)
	loadout.Melee = self:GetRandomWeaponFromPool(meleePool)
	loadout.Grenade = self:GetRandomWeaponFromPool(grenadePool)
	loadout.Special = self:GetRandomWeaponFromPool(specialPool)

	print("WeaponPoolManager: Generated loadout for", player.Name)
	print("  Primary:", loadout.Primary or "none")
	print("  Secondary:", loadout.Secondary or "none")
	print("  Melee:", loadout.Melee or "none")
	print("  Grenade:", loadout.Grenade or "none")
	print("  Special:", loadout.Special or "none")

	return loadout
end

-- Get current player loadout (for respawns)
function WeaponPoolManager:GetCurrentLoadout(player, className)
	-- Use DataStoreManager if available (server-side)
	if DataStoreManager then
		local loadout = DataStoreManager:GetPlayerLoadout(player, className or "Assault")
		if loadout then
			print("WeaponPoolManager: Retrieved saved loadout for", player.Name, "(" .. (className or "Assault") .. ")")
			return loadout
		else
			-- No saved loadout - generate a random one
			warn("WeaponPoolManager: No saved loadout found for", player.Name, "- generating random loadout")
			return self:GetRandomLoadout(player)
		end
	else
		-- Client-side - generate random loadout
		return self:GetRandomLoadout(player)
	end
end

-- Save player's current loadout
function WeaponPoolManager:SaveLoadout(player, className, loadout)
	-- Use DataStoreManager if available (server-side)
	if DataStoreManager then
		local success = DataStoreManager:SetPlayerLoadout(player, className, loadout)
		if success then
			print("WeaponPoolManager: Saved loadout for", player.Name, "(" .. className .. ")")
			return true
		else
			warn("WeaponPoolManager: Failed to save loadout for", player.Name)
			return false
		end
	else
		-- Client-side - can't save loadouts
		warn("WeaponPoolManager:SaveLoadout can only be called on server")
		return false
	end
end

-- Get player's level (for unlock requirements)
function WeaponPoolManager:GetPlayerLevel(player)
	if DataStoreManager then
		return DataStoreManager:GetPlayerLevel(player)
	else
		return 0
	end
end

-- Get player's credits
function WeaponPoolManager:GetPlayerCredits(player)
	if DataStoreManager then
		return DataStoreManager:GetPlayerCredits(player)
	else
		return 0
	end
end

-- Initialize the weapon pool manager
function WeaponPoolManager:Initialize()
	print("WeaponPoolManager initialized")
	print("Default weapon pools:")
	for category, weapons in pairs(DEFAULT_POOLS) do
		print("  " .. category .. ":", table.concat(weapons, ", "))
	end
end

return WeaponPoolManager