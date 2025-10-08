--[[
	WeaponPoolManager
	Handles weapon unlock pools and random loadout selection
	Based on player rank and unlocked weapons
]]

local WeaponPoolManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

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
	-- TODO: Integrate with DataStore system when implemented
	-- For now, return default weapons
	return self:GetDefaultWeaponPool(category)
end

-- Check if a specific weapon is unlocked
function WeaponPoolManager:IsWeaponUnlocked(player, weaponName)
	-- TODO: Integrate with DataStore system
	-- For now, check if weapon is in default pools
	for category, weapons in pairs(DEFAULT_POOLS) do
		for _, weapon in pairs(weapons) do
			if weapon == weaponName then
				return true
			end
		end
	end
	return false
end

-- Add weapon to player's unlock pool
function WeaponPoolManager:AddWeaponToPool(player, weaponName)
	-- TODO: Integrate with DataStore system
	print("WeaponPoolManager: Unlocked", weaponName, "for", player.Name)
	return true
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
function WeaponPoolManager:GetCurrentLoadout(player)
	-- TODO: Store and retrieve player's current loadout
	-- For now, generate a new random one
	return self:GetRandomLoadout(player)
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