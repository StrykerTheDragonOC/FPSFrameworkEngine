--[[
	WeaponUI Module
	Handles all weapon-specific UI elements (ammo, crosshair, firemode, etc.)
	Separate from the in-game HUD system
]]

local WeaponUI = {}
WeaponUI.__index = WeaponUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI state
local weaponUIInstance = nil
local isInitialized = false

-- UI elements cache
local elements = {
	container = nil,
	ammoDisplay = nil,
	currentAmmo = nil,
	reserveAmmo = nil,
	weaponName = nil,
	fireMode = nil,
	crosshair = nil,
	hitmarker = nil,
	reloadIndicator = nil
}

-- Create the weapon UI
function WeaponUI:CreateUI()
	if weaponUIInstance then
		weaponUIInstance:Destroy()
	end

	-- Create ScreenGui
	weaponUIInstance = Instance.new("ScreenGui")
	weaponUIInstance.Name = "WeaponUI"
	weaponUIInstance.ResetOnSpawn = false
	weaponUIInstance.DisplayOrder = 10
	weaponUIInstance.IgnoreGuiInset = true
	weaponUIInstance.Parent = playerGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "WeaponContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Position = UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.Parent = weaponUIInstance
	elements.container = container

	-- Ammo Display (Bottom Right)
	local ammoDisplay = Instance.new("Frame")
	ammoDisplay.Name = "AmmoDisplay"
	ammoDisplay.Size = UDim2.new(0, 250, 0, 100)
	ammoDisplay.Position = UDim2.new(1, -270, 1, -120)
	ammoDisplay.BackgroundTransparency = 0.3
	ammoDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ammoDisplay.BorderSizePixel = 0
	ammoDisplay.Parent = container
	elements.ammoDisplay = ammoDisplay

	-- Rounded corners for ammo display
	local ammoCorner = Instance.new("UICorner")
	ammoCorner.CornerRadius = UDim.new(0, 8)
	ammoCorner.Parent = ammoDisplay

	-- Current Ammo (large text)
	local currentAmmo = Instance.new("TextLabel")
	currentAmmo.Name = "CurrentAmmo"
	currentAmmo.Size = UDim2.new(0.5, 0, 0.6, 0)
	currentAmmo.Position = UDim2.new(0.05, 0, 0.2, 0)
	currentAmmo.BackgroundTransparency = 1
	currentAmmo.Text = "30"
	currentAmmo.TextColor3 = Color3.fromRGB(255, 255, 255)
	currentAmmo.Font = Enum.Font.GothamBold
	currentAmmo.TextSize = 42
	currentAmmo.TextXAlignment = Enum.TextXAlignment.Left
	currentAmmo.Parent = ammoDisplay
	elements.currentAmmo = currentAmmo

	-- Separator
	local separator = Instance.new("TextLabel")
	separator.Name = "Separator"
	separator.Size = UDim2.new(0.1, 0, 0.6, 0)
	separator.Position = UDim2.new(0.45, 0, 0.2, 0)
	separator.BackgroundTransparency = 1
	separator.Text = "/"
	separator.TextColor3 = Color3.fromRGB(150, 150, 150)
	separator.Font = Enum.Font.GothamBold
	separator.TextSize = 32
	separator.Parent = ammoDisplay

	-- Reserve Ammo (smaller text)
	local reserveAmmo = Instance.new("TextLabel")
	reserveAmmo.Name = "ReserveAmmo"
	reserveAmmo.Size = UDim2.new(0.4, 0, 0.6, 0)
	reserveAmmo.Position = UDim2.new(0.55, 0, 0.2, 0)
	reserveAmmo.BackgroundTransparency = 1
	reserveAmmo.Text = "120"
	reserveAmmo.TextColor3 = Color3.fromRGB(200, 200, 200)
	reserveAmmo.Font = Enum.Font.Gotham
	reserveAmmo.TextSize = 28
	reserveAmmo.TextXAlignment = Enum.TextXAlignment.Left
	reserveAmmo.Parent = ammoDisplay
	elements.reserveAmmo = reserveAmmo

	-- Weapon Name (above ammo)
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Size = UDim2.new(0.9, 0, 0.25, 0)
	weaponName.Position = UDim2.new(0.05, 0, 0.05, 0)
	weaponName.BackgroundTransparency = 1
	weaponName.Text = "G36"
	weaponName.TextColor3 = Color3.fromRGB(220, 220, 220)
	weaponName.Font = Enum.Font.GothamMedium
	weaponName.TextSize = 14
	weaponName.TextXAlignment = Enum.TextXAlignment.Left
	weaponName.Parent = ammoDisplay
	elements.weaponName = weaponName

	-- Fire Mode Indicator (next to weapon name)
	local fireMode = Instance.new("TextLabel")
	fireMode.Name = "FireMode"
	fireMode.Size = UDim2.new(0.3, 0, 0.25, 0)
	fireMode.Position = UDim2.new(0.65, 0, 0.05, 0)
	fireMode.BackgroundTransparency = 1
	fireMode.Text = "AUTO"
	fireMode.TextColor3 = Color3.fromRGB(100, 200, 255)
	fireMode.Font = Enum.Font.GothamBold
	fireMode.TextSize = 12
	fireMode.TextXAlignment = Enum.TextXAlignment.Right
	fireMode.Parent = ammoDisplay
	elements.fireMode = fireMode

	-- Crosshair (Center)
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 20, 0, 20)
	crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
	crosshair.BackgroundTransparency = 1
	crosshair.Parent = container
	elements.crosshair = crosshair

	-- Crosshair parts (4 lines)
	self:CreateCrosshairParts(crosshair)

	-- Hitmarker (Center, hidden by default)
	local hitmarker = Instance.new("ImageLabel")
	hitmarker.Name = "Hitmarker"
	hitmarker.Size = UDim2.new(0, 30, 0, 30)
	hitmarker.Position = UDim2.new(0.5, -15, 0.5, -15)
	hitmarker.BackgroundTransparency = 1
	hitmarker.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	hitmarker.ImageColor3 = Color3.fromRGB(255, 255, 255)
	hitmarker.Visible = false
	hitmarker.Parent = container
	elements.hitmarker = hitmarker

	-- Reload Indicator (Center, below crosshair)
	local reloadIndicator = Instance.new("TextLabel")
	reloadIndicator.Name = "ReloadIndicator"
	reloadIndicator.Size = UDim2.new(0, 200, 0, 30)
	reloadIndicator.Position = UDim2.new(0.5, -100, 0.55, 0)
	reloadIndicator.BackgroundTransparency = 0.5
	reloadIndicator.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	reloadIndicator.Text = "RELOADING..."
	reloadIndicator.TextColor3 = Color3.fromRGB(255, 200, 0)
	reloadIndicator.Font = Enum.Font.GothamBold
	reloadIndicator.TextSize = 16
	reloadIndicator.Visible = false
	reloadIndicator.Parent = container
	elements.reloadIndicator = reloadIndicator

	-- Rounded corners for reload indicator
	local reloadCorner = Instance.new("UICorner")
	reloadCorner.CornerRadius = UDim.new(0, 6)
	reloadCorner.Parent = reloadIndicator

	print("✓ WeaponUI created successfully")
end

-- Create crosshair parts
function WeaponUI:CreateCrosshairParts(parent)
	local gap = 5
	local length = 8
	local thickness = 2
	local color = Color3.fromRGB(255, 255, 255)

	-- Top
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.Size = UDim2.new(0, thickness, 0, length)
	top.Position = UDim2.new(0.5, -thickness/2, 0, -gap - length)
	top.BackgroundColor3 = color
	top.BorderSizePixel = 0
	top.Parent = parent

	-- Bottom
	local bottom = Instance.new("Frame")
	bottom.Name = "Bottom"
	bottom.Size = UDim2.new(0, thickness, 0, length)
	bottom.Position = UDim2.new(0.5, -thickness/2, 1, gap)
	bottom.BackgroundColor3 = color
	bottom.BorderSizePixel = 0
	bottom.Parent = parent

	-- Left
	local left = Instance.new("Frame")
	left.Name = "Left"
	left.Size = UDim2.new(0, length, 0, thickness)
	left.Position = UDim2.new(0, -gap - length, 0.5, -thickness/2)
	left.BackgroundColor3 = color
	left.BorderSizePixel = 0
	left.Parent = parent

	-- Right
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.Size = UDim2.new(0, length, 0, thickness)
	right.Position = UDim2.new(1, gap, 0.5, -thickness/2)
	right.BackgroundColor3 = color
	right.BorderSizePixel = 0
	right.Parent = parent
end

-- Update ammo display
function WeaponUI:UpdateAmmo(current, reserve)
	if not elements.currentAmmo or not elements.reserveAmmo then return end

	elements.currentAmmo.Text = tostring(current)
	elements.reserveAmmo.Text = tostring(reserve)

	-- Change color if low ammo
	if current <= 5 then
		elements.currentAmmo.TextColor3 = Color3.fromRGB(255, 50, 50)
	else
		elements.currentAmmo.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

-- Update weapon name
function WeaponUI:UpdateWeaponName(name)
	if not elements.weaponName then return end
	elements.weaponName.Text = name:upper()
end

-- Update fire mode
function WeaponUI:UpdateFireMode(mode)
	if not elements.fireMode then return end
	elements.fireMode.Text = mode:upper()

	-- Color based on mode
	if mode == "AUTO" then
		elements.fireMode.TextColor3 = Color3.fromRGB(100, 200, 255)
	elseif mode == "SEMI" then
		elements.fireMode.TextColor3 = Color3.fromRGB(255, 200, 100)
	elseif mode == "BURST" then
		elements.fireMode.TextColor3 = Color3.fromRGB(255, 150, 200)
	end
end

-- Show hitmarker
function WeaponUI:ShowHitmarker()
	if not elements.hitmarker then return end

	elements.hitmarker.Visible = true
	elements.hitmarker.ImageTransparency = 0

	-- Fade out after 0.1 seconds
	local tween = TweenService:Create(elements.hitmarker,
		TweenInfo.new(0.1, Enum.EasingStyle.Linear),
		{ImageTransparency = 1}
	)
	tween:Play()

	tween.Completed:Connect(function()
		elements.hitmarker.Visible = false
	end)
end

-- Show reload indicator
function WeaponUI:ShowReloadIndicator()
	if not elements.reloadIndicator then return end
	elements.reloadIndicator.Visible = true
end

-- Hide reload indicator
function WeaponUI:HideReloadIndicator()
	if not elements.reloadIndicator then return end
	elements.reloadIndicator.Visible = false
end

-- Update crosshair spread (for recoil visualization)
function WeaponUI:UpdateCrosshairSpread(spread)
	if not elements.crosshair then return end

	local gap = 5 + (spread * 10)
	local length = 8
	local thickness = 2

	local top = elements.crosshair:FindFirstChild("Top")
	local bottom = elements.crosshair:FindFirstChild("Bottom")
	local left = elements.crosshair:FindFirstChild("Left")
	local right = elements.crosshair:FindFirstChild("Right")

	if top then
		top.Position = UDim2.new(0.5, -thickness/2, 0, -gap - length)
	end
	if bottom then
		bottom.Position = UDim2.new(0.5, -thickness/2, 1, gap)
	end
	if left then
		left.Position = UDim2.new(0, -gap - length, 0.5, -thickness/2)
	end
	if right then
		right.Position = UDim2.new(1, gap, 0.5, -thickness/2)
	end
end

-- Show weapon UI
function WeaponUI:Show()
	if weaponUIInstance then
		weaponUIInstance.Enabled = true
	end
end

-- Hide weapon UI
function WeaponUI:Hide()
	if weaponUIInstance then
		weaponUIInstance.Enabled = false
	end
end

-- Destroy weapon UI
function WeaponUI:Destroy()
	if weaponUIInstance then
		weaponUIInstance:Destroy()
		weaponUIInstance = nil
	end

	-- Clear elements cache
	for key, _ in pairs(elements) do
		elements[key] = nil
	end
end

-- Initialize
function WeaponUI:Initialize()
	if isInitialized then return end

	self:CreateUI()

	-- Hide by default
	self:Hide()

	isInitialized = true
	print("✓ WeaponUI initialized")
end

return WeaponUI