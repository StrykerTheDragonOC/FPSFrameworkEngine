--[[
	HotbarUI.client.lua
	Creates custom weapon hotbar at bottom of screen
	Shows 4 slots: Primary, Secondary, Melee, Grenade
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for FPS System to load
repeat wait(0.1) until ReplicatedStorage:FindFirstChild("FPSSystem")

local HotbarUI = {}

-- Create the main hotbar UI
function HotbarUI:CreateHotbar()
    -- Avoid creating multiple hotbar instances in PlayerGui
    local existing = playerGui:FindFirstChild("FPSHotbar")
    if existing then
        print("✓ FPSHotbar already exists in PlayerGui, reusing it")
        return existing
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSHotbar"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

	-- Main hotbar container
	local hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name = "HotbarContainer"
	hotbarFrame.Size = UDim2.new(0, 750, 0, 100)
	hotbarFrame.Position = UDim2.new(0.5, -375, 1, -140)
	hotbarFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	hotbarFrame.BackgroundTransparency = 0.2
	hotbarFrame.BorderSizePixel = 0
	hotbarFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = hotbarFrame

	-- Create 5 weapon slots
	local slots = {"Primary", "Secondary", "Melee", "Grenade", "Special"}
	local slotColors = {
		Color3.fromRGB(180, 100, 100), -- Primary - Red
		Color3.fromRGB(100, 180, 100), -- Secondary - Green
		Color3.fromRGB(100, 100, 180), -- Melee - Blue
		Color3.fromRGB(180, 180, 100), -- Grenade - Yellow
		Color3.fromRGB(180, 100, 180)  -- Special - Purple
	}

	for i, slotName in ipairs(slots) do
		local slot = self:CreateWeaponSlot(slotName, i, slotColors[i])
		slot.Position = UDim2.new((i - 1) * 0.2 + 0.02, 0, 0.1, 0)
		slot.Parent = hotbarFrame
	end

	print("✓ HotbarUI created")
	return screenGui
end

-- Create individual weapon slot
function HotbarUI:CreateWeaponSlot(slotName, keyNumber, accentColor)
	local slot = Instance.new("Frame")
	slot.Name = slotName .. "Slot"
	slot.Size = UDim2.new(0.18, 0, 0.8, 0)
	slot.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	slot.BorderSizePixel = 2
	slot.BorderColor3 = Color3.fromRGB(60, 65, 70)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = slot

	-- Keybind number (top left)
	local keybind = Instance.new("TextLabel")
	keybind.Name = "Keybind"
	keybind.Size = UDim2.new(0, 30, 0, 30)
	keybind.Position = UDim2.new(0, 5, 0, 5)
	keybind.BackgroundColor3 = accentColor
	keybind.BorderSizePixel = 0
	keybind.Text = tostring(keyNumber)
	keybind.TextColor3 = Color3.fromRGB(255, 255, 255)
	keybind.Font = Enum.Font.GothamBold
	keybind.TextSize = 18
	keybind.Parent = slot

	local keybindCorner = Instance.new("UICorner")
	keybindCorner.CornerRadius = UDim.new(0, 4)
	keybindCorner.Parent = keybind

	-- Weapon icon placeholder (center)
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0.5, -20, 0.3, 0)
	icon.BackgroundColor3 = Color3.fromRGB(60, 65, 70)
	icon.BorderSizePixel = 0
	icon.Parent = slot

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 4)
	iconCorner.Parent = icon

	-- Weapon name (bottom)
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Size = UDim2.new(1, -10, 0, 20)
	weaponName.Position = UDim2.new(0, 5, 1, -25)
	weaponName.BackgroundTransparency = 1
	weaponName.Text = "Empty"
	weaponName.TextColor3 = Color3.fromRGB(180, 180, 180)
	weaponName.Font = Enum.Font.Gotham
	weaponName.TextSize = 12
	weaponName.TextScaled = true
	weaponName.Parent = slot

	-- Ammo display (top right)
	local ammo = Instance.new("TextLabel")
	ammo.Name = "Ammo"
	ammo.Size = UDim2.new(0, 50, 0, 20)
	ammo.Position = UDim2.new(1, -55, 0, 5)
	ammo.BackgroundTransparency = 1
	ammo.Text = ""
	ammo.TextColor3 = Color3.fromRGB(255, 255, 255)
	ammo.Font = Enum.Font.GothamBold
	ammo.TextSize = 14
	ammo.TextXAlignment = Enum.TextXAlignment.Right
	ammo.Parent = slot

	return slot
end

-- Update weapon in slot
function HotbarUI:UpdateSlot(slotName, weaponName, ammoCount, maxAmmo)
	local hotbar = playerGui:FindFirstChild("FPSHotbar")
	if not hotbar then return end

	local slot = hotbar.HotbarContainer:FindFirstChild(slotName .. "Slot")
	if not slot then return end

	local nameLabel = slot:FindFirstChild("WeaponName")
	local ammoLabel = slot:FindFirstChild("Ammo")

	if nameLabel then
		nameLabel.Text = weaponName or "Empty"
		nameLabel.TextColor3 = weaponName and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
	end

	if ammoLabel then
		if ammoCount and maxAmmo then
			ammoLabel.Text = ammoCount .. "/" .. maxAmmo
		else
			ammoLabel.Text = ""
		end
	end
end

-- Highlight equipped slot
function HotbarUI:HighlightSlot(slotName)
	local hotbar = playerGui:FindFirstChild("FPSHotbar")
	if not hotbar then return end

	-- Reset all slots
	for _, slot in pairs(hotbar.HotbarContainer:GetChildren()) do
		if slot:IsA("Frame") and slot.Name:match("Slot") then
			slot.BorderColor3 = Color3.fromRGB(60, 65, 70)
			slot.BorderSizePixel = 2
			slot.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
		end
	end

	-- Highlight active slot
	if slotName then
		local slot = hotbar.HotbarContainer:FindFirstChild(slotName .. "Slot")
		if slot then
			slot.BorderColor3 = Color3.fromRGB(255, 255, 255)
			slot.BorderSizePixel = 3
			slot.BackgroundColor3 = Color3.fromRGB(40, 45, 55)

			-- Pulse animation
			local tween = TweenService:Create(slot,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = Color3.fromRGB(50, 55, 65)}
			)
			tween:Play()
		end
	end
end

-- Clear all slots
function HotbarUI:ClearAllSlots()
	for _, slotName in ipairs({"Primary", "Secondary", "Melee", "Grenade", "Special"}) do
		self:UpdateSlot(slotName, nil, nil, nil)
	end
	self:HighlightSlot(nil)
end

-- Initialize
function HotbarUI:Initialize()
	print("HotbarUI: Initializing...")

	-- Create the hotbar
	self:CreateHotbar()

	-- Make globally accessible
	_G.HotbarUI = self

	print("HotbarUI: Initialization complete!")
end

-- Start initialization
HotbarUI:Initialize()

return HotbarUI
