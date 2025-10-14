local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local ShopHandler = {}

-- Shop item database
local SHOP_ITEMS = {
	Weapons = {
		M4A1 = {Category = "Primary", Type = "AssaultRifles", Cost = 2000, Level = 5},
		AK47 = {Category = "Primary", Type = "AssaultRifles", Cost = 2500, Level = 10},
		AWP = {Category = "Primary", Type = "SniperRifles", Cost = 5000, Level = 15},
		Glock17 = {Category = "Secondary", Type = "Pistols", Cost = 800, Level = 3},
		DesertEagle = {Category = "Secondary", Type = "Pistols", Cost = 1500, Level = 8}
	},
	Attachments = {
		RedDotSight = {Category = "Sights", Cost = 300, Level = 2, ApplicableWeapons = {"Primary", "Secondary"}},
		ACOGScope = {Category = "Sights", Cost = 800, Level = 7, ApplicableWeapons = {"Primary"}},
		Suppressor = {Category = "Barrels", Cost = 600, Level = 5, ApplicableWeapons = {"Primary", "Secondary"}},
		Compensator = {Category = "Barrels", Cost = 400, Level = 4, ApplicableWeapons = {"Primary"}},
		VerticalGrip = {Category = "Underbarrel", Cost = 200, Level = 3, ApplicableWeapons = {"Primary"}}
	},
	Skins = {
		DesertCamo = {Category = "Skins", Cost = 500, Level = 1},
		UrbanCamo = {Category = "Skins", Cost = 750, Level = 4},
		GoldFinish = {Category = "Skins", Cost = 2000, Level = 12},
		CarbonFiber = {Category = "Skins", Cost = 1200, Level = 8}
	}
}

function ShopHandler:Initialize()
	DataStoreManager:Initialize()
	
	-- Handle purchase requests
	local purchaseItemEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PurchaseItem")
	if purchaseItemEvent then
		purchaseItemEvent.OnServerEvent:Connect(function(player, purchaseData)
			self:HandlePurchase(player, purchaseData)
		end)
	end
	
	_G.ShopHandler = self
	print("ShopHandler initialized")
end

function ShopHandler:HandlePurchase(player, purchaseData)
	if not player or not purchaseData then
		warn("Invalid purchase data")
		return
	end
	
	local itemName = purchaseData.ItemName
	local itemType = purchaseData.ItemType
	local cost = purchaseData.Cost
	
	-- Validate item exists
	local itemData = SHOP_ITEMS[itemType] and SHOP_ITEMS[itemType][itemName]
	if not itemData then
		self:SendPurchaseResult(player, false, "Item not found")
		return
	end
	
	-- Validate cost matches
	if itemData.Cost ~= cost then
		self:SendPurchaseResult(player, false, "Price mismatch")
		return
	end
	
	-- Get player data
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData then
		self:SendPurchaseResult(player, false, "Player data not loaded")
		return
	end
	
	-- Check level requirement
	if playerData.Level < itemData.Level then
		self:SendPurchaseResult(player, false, "Level " .. itemData.Level .. " required")
		return
	end
	
	-- Check if player has enough credits
	if playerData.Credits < cost then
		self:SendPurchaseResult(player, false, "Not enough credits")
		return
	end
	
	-- Check if player already owns item
	if self:PlayerOwnsItem(player, itemType, itemName) then
		self:SendPurchaseResult(player, false, "You already own this item")
		return
	end
	
	-- Process purchase
	local success = false
	if itemType == "Weapons" then
		success = DataStoreManager:UnlockWeapon(player, itemName, cost)
	elseif itemType == "Attachments" then
		success = self:UnlockAttachment(player, itemName, itemData, cost)
	elseif itemType == "Skins" then
		success = self:UnlockSkin(player, itemName, cost)
	end
	
	if success then
		self:SendPurchaseResult(player, true, "Purchased " .. itemName)
		print(player.Name .. " purchased " .. itemName .. " for " .. cost .. " credits")
	else
		self:SendPurchaseResult(player, false, "Purchase failed")
	end
end

function ShopHandler:PlayerOwnsItem(player, itemType, itemName)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData then return false end
	
	if itemType == "Weapons" then
		return table.find(playerData.UnlockedWeapons or {}, itemName) ~= nil
	elseif itemType == "Attachments" then
		for weaponName, attachments in pairs(playerData.UnlockedAttachments or {}) do
			if table.find(attachments, itemName) then
				return true
			end
		end
		return false
	elseif itemType == "Skins" then
		return table.find(playerData.UnlockedSkins or {}, itemName) ~= nil
	end
	
	return false
end

function ShopHandler:UnlockAttachment(player, attachmentName, attachmentData, cost)
	-- For now, unlock attachment for all applicable weapons player owns
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData then return false end
	
	local unlockedForWeapons = {}
	
	-- Check each weapon player owns
	for _, weaponName in pairs(playerData.UnlockedWeapons or {}) do
		local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
		if weaponConfig and self:AttachmentCompatible(attachmentData, weaponConfig) then
			if not playerData.UnlockedAttachments[weaponName] then
				playerData.UnlockedAttachments[weaponName] = {}
			end
			table.insert(playerData.UnlockedAttachments[weaponName], attachmentName)
			table.insert(unlockedForWeapons, weaponName)
		end
	end
	
	if #unlockedForWeapons > 0 then
		-- Spend credits
		DataStoreManager:SpendCredits(player, cost)
		return true
	end
	
	return false
end

function ShopHandler:AttachmentCompatible(attachmentData, weaponConfig)
	if not attachmentData.ApplicableWeapons then return true end
	
	for _, category in pairs(attachmentData.ApplicableWeapons) do
		if weaponConfig.Category == category then
			return true
		end
	end
	
	return false
end

function ShopHandler:UnlockSkin(player, skinName, cost)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData then return false end
	
	-- Initialize skins array if it doesn't exist
	if not playerData.UnlockedSkins then
		playerData.UnlockedSkins = {}
	end
	
	-- Add skin to unlocked skins
	table.insert(playerData.UnlockedSkins, skinName)
	
	-- Spend credits
	return DataStoreManager:SpendCredits(player, cost)
end

function ShopHandler:SendPurchaseResult(player, success, message)
	local purchaseResultEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PurchaseResult")
	if purchaseResultEvent then
		purchaseResultEvent:FireClient(player, {
			Success = success,
			Message = message
		})
	end

	if success then
		-- Refresh player data on client
		local playerData = DataStoreManager:GetPlayerData(player)
		local playerDataUpdatedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PlayerDataUpdated")
		if playerDataUpdatedEvent then
			playerDataUpdatedEvent:FireClient(player, {
				Data = DataStoreManager:GetClientSafeData(playerData)
			})
		end
	end
end

-- Admin commands for testing
_G.ShopCommands = {
	giveCredits = function(playerName, amount)
		local player = Players:FindFirstChild(playerName)
		if player and DataStoreManager then
			DataStoreManager:AddCredits(player, amount)
			print("Gave " .. amount .. " credits to " .. playerName)
		end
	end,
	
	setLevel = function(playerName, level)
		local player = Players:FindFirstChild(playerName)
		if player and DataStoreManager then
			local playerData = DataStoreManager:GetPlayerData(player)
			if playerData then
				playerData.Level = level
				print("Set " .. playerName .. " to level " .. level)
			end
		end
	end,
	
	unlockAll = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player and DataStoreManager then
			local playerData = DataStoreManager:GetPlayerData(player)
			if playerData then
				-- Unlock all default weapons plus shop weapons
				playerData.UnlockedWeapons = {"G36", "M9", "PocketKnife", "M67", "M4A1", "AK47", "AWP", "Glock17", "DesertEagle"}
				
				-- Give lots of credits
				playerData.Credits = 50000
				
				-- Set high level
				playerData.Level = 50
				
				print("Unlocked everything for " .. playerName)
			end
		end
	end
}

ShopHandler:Initialize()

return ShopHandler