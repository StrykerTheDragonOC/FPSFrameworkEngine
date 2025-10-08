--[[
	HotbarController.client.lua
	Handles weapon switching via 1,2,3,4 keys
	Updates hotbar UI and equips weapons from backpack
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

-- Wait for FPS System to load
repeat wait(0.1) until ReplicatedStorage:FindFirstChild("FPSSystem")

local HotbarController = {}

-- Weapon slot mapping
local SLOT_MAP = {
	[Enum.KeyCode.One] = "Primary",
	[Enum.KeyCode.Two] = "Secondary",
	[Enum.KeyCode.Three] = "Melee",
	[Enum.KeyCode.Four] = "Grenade",
	[Enum.KeyCode.Five] = "Special"
}

-- Current loadout tracking
local currentLoadout = {
	Primary = nil,
	Secondary = nil,
	Melee = nil,
	Grenade = nil,
	Special = nil
}

local currentlyEquipped = nil

-- Get HotbarUI reference
local function getHotbarUI()
	return _G.HotbarUI
end

-- Scan backpack for weapons and categorize them
function HotbarController:ScanBackpack()
	local newLoadout = {
		Primary = nil,
		Secondary = nil,
		Melee = nil,
		Grenade = nil,
		Special = nil
	}

	-- Scan backpack
	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local category = self:DetermineWeaponCategory(tool.Name)
			if category and not newLoadout[category] then
				newLoadout[category] = tool
			end
		end
	end

	-- Scan character (equipped weapon)
	if player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local category = self:DetermineWeaponCategory(tool.Name)
				if category and not newLoadout[category] then
					newLoadout[category] = tool
				end
			end
		end
	end

	-- Update loadout
	currentLoadout = newLoadout

	-- Update UI
	self:UpdateHotbarUI()

	return newLoadout
end

-- Determine weapon category based on name
function HotbarController:DetermineWeaponCategory(weaponName)
	-- Primary weapons (rifles, LMGs, etc.)
	if weaponName:match("G36") or weaponName:match("AK") or weaponName:match("M4") or
	   weaponName:match("SCAR") or weaponName:match("FAL") or weaponName:match("MP5") or
	   weaponName:match("UMP") or weaponName:match("P90") or weaponName:match("M249") or
	   weaponName:match("MG") or weaponName:match("Barrett") or weaponName:match("AWP") or
	   weaponName:match("Intervention") or weaponName:match("NTW") then
		return "Primary"
	end

	-- Secondary weapons (pistols)
	if weaponName:match("M9") or weaponName:match("Glock") or weaponName:match("Desert Eagle") or
	   weaponName:match("1911") or weaponName:match("USP") or weaponName:match("P250") or
	   weaponName:match("Revolver") or weaponName:match("Magnum") then
		return "Secondary"
	end

	-- Melee weapons
	if weaponName:match("Knife") or weaponName:match("Axe") or weaponName:match("Hammer") or
	   weaponName:match("Sword") or weaponName:match("Bat") or weaponName:match("Crowbar") or
	   weaponName:match("Machete") or weaponName:match("Katana") then
		return "Melee"
	end

	-- Grenades
	if weaponName:match("M67") or weaponName:match("M26") or weaponName:match("Grenade") or
	   weaponName:match("Flashbang") or weaponName:match("Smoke") or weaponName:match("C4") or
	   weaponName:match("Frag") then
		return "Grenade"
	end

	-- Special/Magic weapons
	if weaponName:match("ViciousStinger") or weaponName:match("Vicious") or
	   weaponName:match("NTW20_Admin") or weaponName:match("Admin") then
		return "Special"
	end

	-- Default to Primary if unknown
	return "Primary"
end

-- Update hotbar UI with current loadout
function HotbarController:UpdateHotbarUI()
	local hotbarUI = getHotbarUI()
	if not hotbarUI then return end

	for slotName, tool in pairs(currentLoadout) do
		if tool then
			-- Get ammo info if available
			local ammo = tool:FindFirstChild("Ammo")
			local maxAmmo = tool:FindFirstChild("MaxAmmo")

			local ammoCount = ammo and ammo.Value or nil
			local maxAmmoCount = maxAmmo and maxAmmo.Value or nil

			hotbarUI:UpdateSlot(slotName, tool.Name, ammoCount, maxAmmoCount)
		else
			hotbarUI:UpdateSlot(slotName, nil, nil, nil)
		end
	end

	-- Highlight currently equipped
	if currentlyEquipped then
		hotbarUI:HighlightSlot(currentlyEquipped)
	end
end

-- Equip weapon from slot
function HotbarController:EquipSlot(slotName)
	local tool = currentLoadout[slotName]

	if not tool then
		warn("No weapon in " .. slotName .. " slot")
		return
	end

	-- Check if tool still exists
	if not tool.Parent then
		warn("Tool no longer exists, rescanning backpack")
		self:ScanBackpack()
		return
	end

	-- If already equipped, unequip
	if currentlyEquipped == slotName and tool.Parent == player.Character then
		print("Unequipping " .. tool.Name)
		tool.Parent = backpack
		currentlyEquipped = nil
		self:UpdateHotbarUI()
		return
	end

	-- Unequip current tool
	if player.Character then
		for _, equippedTool in pairs(player.Character:GetChildren()) do
			if equippedTool:IsA("Tool") then
				equippedTool.Parent = backpack
			end
		end
	end

	-- Equip new tool
	print("Equipping " .. tool.Name .. " from " .. slotName .. " slot")
	tool.Parent = player.Character

	currentlyEquipped = slotName
	self:UpdateHotbarUI()
end

-- Handle key press
function HotbarController:OnKeyPress(input, gameProcessed)
	if gameProcessed then return end

	local slotName = SLOT_MAP[input.KeyCode]
	if slotName then
		self:EquipSlot(slotName)
	end
end

-- Setup event connections
function HotbarController:SetupConnections()
	-- Listen for key presses
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		self:OnKeyPress(input, gameProcessed)
	end)

	-- Listen for backpack changes
	backpack.ChildAdded:Connect(function()
		wait(0.1) -- Small delay to let changes settle
		self:ScanBackpack()
	end)

	backpack.ChildRemoved:Connect(function()
		wait(0.1)
		self:ScanBackpack()
	end)

	-- Listen for character changes
	player.CharacterAdded:Connect(function(character)
		wait(1) -- Wait for character to fully load
		currentlyEquipped = nil
		self:ScanBackpack()

		-- Setup tool equipped/unequipped tracking
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:ScanBackpack()
			end
		end)

		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				wait(0.1)
				self:ScanBackpack()
			end
		end)
	end)

	-- If character already exists
	if player.Character then
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:ScanBackpack()
			end
		end)

		player.Character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				wait(0.1)
				self:ScanBackpack()
			end
		end)
	end

	print("✓ HotbarController: Event connections established")
end

-- Initialize
function HotbarController:Initialize()
	print("HotbarController: Initializing...")

	-- Wait for HotbarUI to be ready
	local maxWait = 10
	local waited = 0
	while not getHotbarUI() and waited < maxWait do
		wait(0.1)
		waited = waited + 0.1
	end

	if not getHotbarUI() then
		warn("HotbarUI not found - hotbar controller may not work properly")
	end

	-- Initial scan
	self:ScanBackpack()

	-- Setup connections
	self:SetupConnections()

	-- Make globally accessible
	_G.HotbarController = self

	print("HotbarController: Initialization complete!")
end

-- Start initialization
HotbarController:Initialize()

return HotbarController
