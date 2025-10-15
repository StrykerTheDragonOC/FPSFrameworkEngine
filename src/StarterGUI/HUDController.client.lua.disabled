-- HUDController.client.lua
-- Manages the in-game HUD using FPSGameHUD.rbxmx

local HUDController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for FPS System
repeat wait(0.1) until ReplicatedStorage:FindFirstChild("FPSSystem")

-- Get HUD UI
local hudGui = playerGui:WaitForChild("FPSGameHUD", 10)

-- UI Elements
local healthBar = nil
local healthText = nil
local currentAmmoLabel = nil
local reserveAmmoLabel = nil
local weaponNameLabel = nil
local crosshair = nil
local killFeed = nil
local scoreContainer = nil

-- Track current weapon
local currentWeapon = nil

-- Initialize HUD elements
function HUDController:InitializeElements()
	if not hudGui then
		warn("FPSGameHUD not found")
		return false
	end

	-- Health/Armor Container
	local healthArmorContainer = hudGui:FindFirstChild("HealthArmorContainer")
	if healthArmorContainer then
		local healthBackground = healthArmorContainer:FindFirstChild("HealthBackground")
		if healthBackground then
			healthBar = healthBackground:FindFirstChild("HealthFill")
			healthText = healthBackground:FindFirstChild("HealthText")
		end
	end

	-- Ammo Container
	local ammoContainer = hudGui:FindFirstChild("AmmoContainer")
	if ammoContainer then
		currentAmmoLabel = ammoContainer:FindFirstChild("CurrentAmmo")
		reserveAmmoLabel = ammoContainer:FindFirstChild("ReserveAmmo")
		weaponNameLabel = ammoContainer:FindFirstChild("WeaponName")
	end

	-- Crosshair
	crosshair = hudGui:FindFirstChild("Crosshair")

	-- Kill Feed
	killFeed = hudGui:FindFirstChild("KillFeed")

	-- Score Container
	scoreContainer = hudGui:FindFirstChild("ScoreContainer")

	print("✓ HUD elements initialized")
	return true
end

-- Update health display
function HUDController:UpdateHealth(health, maxHealth)
	if not healthBar or not healthText then return end

	local healthPercent = math.clamp(health / maxHealth, 0, 1)

	-- Update bar size
	healthBar.Size = UDim2.new(healthPercent, -4, 1, -4)

	-- Update text
	healthText.Text = tostring(math.floor(health))

	-- Change color based on health
	if healthPercent > 0.6 then
		healthBar.BackgroundColor3 = Color3.fromRGB(60, 180, 100) -- Green
	elseif healthPercent > 0.3 then
		healthBar.BackgroundColor3 = Color3.fromRGB(220, 180, 60) -- Yellow
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(220, 60, 60) -- Red
	end
end

-- Update ammo display
function HUDController:UpdateAmmo(current, reserve, weaponName)
	if currentAmmoLabel then
		currentAmmoLabel.Text = tostring(current or 0)
	end

	if reserveAmmoLabel then
		reserveAmmoLabel.Text = tostring(reserve or 0)
	end

	if weaponNameLabel and weaponName then
		weaponNameLabel.Text = weaponName:upper()
	end
end

-- Show/hide crosshair
function HUDController:SetCrosshairVisible(visible)
	if crosshair then
		crosshair.Visible = visible
	end
end

-- Add kill to kill feed
function HUDController:AddKillFeedEntry(killerName, victimName, weaponName, isHeadshot)
	if not killFeed then return end

	-- Create kill feed entry
	local entry = Instance.new("Frame")
	entry.Name = "KillEntry"
	entry.Size = UDim2.new(1, 0, 0, 30)
	entry.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = entry

	-- Killer name
	local killerLabel = Instance.new("TextLabel")
	killerLabel.Size = UDim2.new(0.4, 0, 1, 0)
	killerLabel.Position = UDim2.new(0, 5, 0, 0)
	killerLabel.BackgroundTransparency = 1
	killerLabel.Text = killerName
	killerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	killerLabel.TextSize = 14
	killerLabel.Font = Enum.Font.GothamBold
	killerLabel.TextXAlignment = Enum.TextXAlignment.Left
	killerLabel.Parent = entry

	-- Weapon/method
	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Size = UDim2.new(0.2, 0, 1, 0)
	weaponLabel.Position = UDim2.new(0.4, 0, 0, 0)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Text = isHeadshot and "[HS]" or weaponName
	weaponLabel.TextColor3 = isHeadshot and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(200, 200, 200)
	weaponLabel.TextSize = 12
	weaponLabel.Font = Enum.Font.Gotham
	weaponLabel.TextXAlignment = Enum.TextXAlignment.Center
	weaponLabel.Parent = entry

	-- Victim name
	local victimLabel = Instance.new("TextLabel")
	victimLabel.Size = UDim2.new(0.4, -5, 1, 0)
	victimLabel.Position = UDim2.new(0.6, 0, 0, 0)
	victimLabel.BackgroundTransparency = 1
	victimLabel.Text = victimName
	victimLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	victimLabel.TextSize = 14
	victimLabel.Font = Enum.Font.GothamBold
	victimLabel.TextXAlignment = Enum.TextXAlignment.Right
	victimLabel.Parent = entry

	entry.Parent = killFeed

	-- Remove after 5 seconds
	task.delay(5, function()
		if entry and entry.Parent then
			entry:Destroy()
		end
	end)
end

-- Update score display
function HUDController:UpdateScore(team1Score, team2Score, gamemodeName)
	if not scoreContainer then return end

	-- Clear existing content
	for _, child in pairs(scoreContainer:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	-- Team 1 score
	local team1Label = Instance.new("TextLabel")
	team1Label.Size = UDim2.new(0.4, -10, 1, 0)
	team1Label.Position = UDim2.new(0, 10, 0, 0)
	team1Label.BackgroundTransparency = 1
	team1Label.Text = "KFC: " .. tostring(team1Score or 0)
	team1Label.TextColor3 = Color3.fromRGB(255, 200, 100)
	team1Label.TextSize = 20
	team1Label.Font = Enum.Font.GothamBold
	team1Label.TextXAlignment = Enum.TextXAlignment.Left
	team1Label.Parent = scoreContainer

	-- Gamemode name
	local gamemodeLabel = Instance.new("TextLabel")
	gamemodeLabel.Size = UDim2.new(0.2, 0, 1, 0)
	gamemodeLabel.Position = UDim2.new(0.4, 0, 0, 0)
	gamemodeLabel.BackgroundTransparency = 1
	gamemodeLabel.Text = gamemodeName or "TDM"
	gamemodeLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
	gamemodeLabel.TextSize = 18
	gamemodeLabel.Font = Enum.Font.GothamBold
	gamemodeLabel.TextXAlignment = Enum.TextXAlignment.Center
	gamemodeLabel.Parent = scoreContainer

	-- Team 2 score
	local team2Label = Instance.new("TextLabel")
	team2Label.Size = UDim2.new(0.4, -10, 1, 0)
	team2Label.Position = UDim2.new(0.6, 0, 0, 0)
	team2Label.BackgroundTransparency = 1
	team2Label.Text = "FBI: " .. tostring(team2Score or 0)
	team2Label.TextColor3 = Color3.fromRGB(100, 150, 255)
	team2Label.TextSize = 20
	team2Label.Font = Enum.Font.GothamBold
	team2Label.TextXAlignment = Enum.TextXAlignment.Right
	team2Label.Parent = scoreContainer
end

-- Setup health tracking
function HUDController:SetupHealthTracking()
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Initial health
		self:UpdateHealth(humanoid.Health, humanoid.MaxHealth)

		-- Track health changes
		humanoid.HealthChanged:Connect(function(health)
			self:UpdateHealth(health, humanoid.MaxHealth)
		end)

		print("✓ Health tracking connected")
	end)

	-- If character already exists
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			self:UpdateHealth(humanoid.Health, humanoid.MaxHealth)

			humanoid.HealthChanged:Connect(function(health)
				self:UpdateHealth(health, humanoid.MaxHealth)
			end)
		end
	end
end

-- Setup weapon tracking
function HUDController:SetupWeaponTracking()
	-- Track equipped tools
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:OnWeaponEquipped(child)
			end
		end)

		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child == currentWeapon then
				self:OnWeaponUnequipped()
			end
		end)
	end)

	-- If character already exists
	if player.Character then
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:OnWeaponEquipped(child)
			end
		end)

		player.Character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child == currentWeapon then
				self:OnWeaponUnequipped()
			end
		end)
	end
end

-- Handle weapon equipped
function HUDController:OnWeaponEquipped(tool)
	currentWeapon = tool

	-- Get ammo values
	local ammo = tool:FindFirstChild("Ammo")
	local maxAmmo = tool:FindFirstChild("MaxAmmo")
	local reserveAmmo = tool:FindFirstChild("ReserveAmmo")

	local currentAmmo = ammo and ammo.Value or 0
	local reserve = reserveAmmo and reserveAmmo.Value or 0

	-- Update display
	self:UpdateAmmo(currentAmmo, reserve, tool.Name)

	-- Track ammo changes
	if ammo then
		ammo.Changed:Connect(function()
			local reserve = reserveAmmo and reserveAmmo.Value or 0
			self:UpdateAmmo(ammo.Value, reserve, tool.Name)
		end)
	end

	if reserveAmmo then
		reserveAmmo.Changed:Connect(function()
			local current = ammo and ammo.Value or 0
			self:UpdateAmmo(current, reserveAmmo.Value, tool.Name)
		end)
	end

	print("✓ Weapon equipped:", tool.Name)
end

-- Handle weapon unequipped
function HUDController:OnWeaponUnequipped()
	currentWeapon = nil
	self:UpdateAmmo(0, 0, "")
	print("✓ Weapon unequipped")
end

-- Setup event listeners
function HUDController:SetupEventListeners()
	-- Listen for kill feed events
	local killFeedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("KillFeedUpdate")
	if killFeedEvent then
		killFeedEvent.OnClientEvent:Connect(function(data)
			self:AddKillFeedEntry(data.Killer, data.Victim, data.Weapon, data.Headshot)
		end)
	end

	-- Listen for score updates
	local scoreUpdateEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("ScoreUpdate")
	if scoreUpdateEvent then
		scoreUpdateEvent.OnClientEvent:Connect(function(data)
			self:UpdateScore(data.Team1Score, data.Team2Score, data.Gamemode)
		end)
	end

	print("✓ Event listeners setup")
end

-- Show/hide HUD
function HUDController:ShowHUD()
	if hudGui then
		hudGui.Enabled = true
		print("✓ HUD shown")
	end
end

function HUDController:HideHUD()
	if hudGui then
		hudGui.Enabled = false
		print("✓ HUD hidden")
	end
end

-- Initialize
function HUDController:Initialize()
	print("HUDController: Initializing...")

	-- Initialize UI elements
	if not self:InitializeElements() then
		warn("Failed to initialize HUD elements")
		return
	end

	-- Setup tracking
	self:SetupHealthTracking()
	self:SetupWeaponTracking()

	-- Setup event listeners
	self:SetupEventListeners()

	-- Hide HUD by default (shown when deployed)
	self:HideHUD()

	-- Make globally accessible
	_G.HUDController = self

	print("✓ HUDController: Initialization complete")
end

-- Start initialization
HUDController:Initialize()

return HUDController
