local AmmoSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer

-- Ammo type configurations
local AMMO_CONFIGS = {
	-- Standard ammunition
	Standard = {
		Name = "Standard",
		DisplayName = "Standard Ball",
		Color = Color3.new(0.8, 0.8, 0.8),
		Description = "Standard military ammunition",
		DamageMultiplier = 1.0,
		VelocityMultiplier = 1.0,
		PenetrationMultiplier = 1.0,
		RecoilMultiplier = 1.0,
		SpreadMultiplier = 1.0,
		TracerChance = 0.0,
		Effects = {},
		Cost = 0,
		UnlockLevel = 0
	},
	
	-- Full Metal Jacket - better penetration
	FMJ = {
		Name = "FMJ",
		DisplayName = "Full Metal Jacket",
		Color = Color3.new(0.7, 0.6, 0.4),
		Description = "Enhanced penetration, reduced stopping power",
		DamageMultiplier = 0.9,
		VelocityMultiplier = 1.1,
		PenetrationMultiplier = 1.5,
		RecoilMultiplier = 1.1,
		SpreadMultiplier = 0.95,
		TracerChance = 0.0,
		Effects = {"Enhanced_Penetration"},
		Cost = 50,
		UnlockLevel = 5
	},
	
	-- Armor Piercing - maximum penetration
	AP = {
		Name = "AP",
		DisplayName = "Armor Piercing",
		Color = Color3.new(0.3, 0.3, 0.3),
		Description = "Maximum penetration against armor",
		DamageMultiplier = 0.85,
		VelocityMultiplier = 1.2,
		PenetrationMultiplier = 2.0,
		RecoilMultiplier = 1.2,
		SpreadMultiplier = 0.9,
		TracerChance = 0.0,
		Effects = {"Armor_Piercing", "Enhanced_Penetration"},
		Cost = 100,
		UnlockLevel = 15
	},
	
	-- Hollow Point - maximum damage
	HP = {
		Name = "HP",
		DisplayName = "Hollow Point",
		Color = Color3.new(0.8, 0.4, 0.2),
		Description = "Maximum damage, poor penetration",
		DamageMultiplier = 1.25,
		VelocityMultiplier = 0.95,
		PenetrationMultiplier = 0.7,
		RecoilMultiplier = 0.9,
		SpreadMultiplier = 1.05,
		TracerChance = 0.0,
		Effects = {"Increased_Damage", "Reduced_Penetration"},
		Cost = 75,
		UnlockLevel = 8
	},
	
	-- Tracer rounds - visible trajectory
	Tracer = {
		Name = "Tracer",
		DisplayName = "Tracer",
		Color = Color3.new(1, 0.8, 0.2),
		Description = "Visible trajectory for target correction",
		DamageMultiplier = 1.0,
		VelocityMultiplier = 1.0,
		PenetrationMultiplier = 1.0,
		RecoilMultiplier = 1.0,
		SpreadMultiplier = 1.0,
		TracerChance = 1.0,
		Effects = {"Tracer_Trail", "Light_Emission"},
		Cost = 30,
		UnlockLevel = 3
	},
	
	-- Incendiary rounds - fire effect
	Incendiary = {
		Name = "Incendiary",
		DisplayName = "Incendiary",
		Color = Color3.new(1, 0.3, 0.1),
		Description = "Ignites targets and creates fire",
		DamageMultiplier = 1.1,
		VelocityMultiplier = 0.9,
		PenetrationMultiplier = 1.2,
		RecoilMultiplier = 1.1,
		SpreadMultiplier = 1.1,
		TracerChance = 0.8,
		Effects = {"Fire_Damage", "Ignition", "Light_Emission"},
		StatusEffect = "Burning",
		Cost = 150,
		UnlockLevel = 25
	},
	
	-- Frostbite rounds - ice effect
	Frostbite = {
		Name = "Frostbite",
		DisplayName = "Frostbite",
		Color = Color3.new(0.5, 0.8, 1),
		Description = "Slows and freezes targets",
		DamageMultiplier = 0.95,
		VelocityMultiplier = 0.95,
		PenetrationMultiplier = 0.9,
		RecoilMultiplier = 0.95,
		SpreadMultiplier = 0.9,
		TracerChance = 0.5,
		Effects = {"Ice_Damage", "Slow_Effect", "Frost_Particles"},
		StatusEffect = "Frozen",
		Cost = 125,
		UnlockLevel = 20
	},
	
	-- Explosive rounds - small explosions
	Explosive = {
		Name = "Explosive",
		DisplayName = "Explosive",
		Color = Color3.new(1, 0.5, 0),
		Description = "Small explosive impact for area damage",
		DamageMultiplier = 1.3,
		VelocityMultiplier = 0.8,
		PenetrationMultiplier = 0.6,
		RecoilMultiplier = 1.4,
		SpreadMultiplier = 1.2,
		TracerChance = 1.0,
		Effects = {"Explosion_Impact", "Area_Damage", "Enhanced_Recoil"},
		ExplosionRadius = 3,
		Cost = 200,
		UnlockLevel = 35
	},
	
	-- Subsonic rounds - quiet
	Subsonic = {
		Name = "Subsonic",
		DisplayName = "Subsonic",
		Color = Color3.new(0.4, 0.4, 0.4),
		Description = "Reduced noise and muzzle flash",
		DamageMultiplier = 0.9,
		VelocityMultiplier = 0.7,
		PenetrationMultiplier = 0.85,
		RecoilMultiplier = 0.8,
		SpreadMultiplier = 1.1,
		TracerChance = 0.0,
		Effects = {"Reduced_Noise", "Reduced_Flash", "Reduced_Detection"},
		SoundReduction = 0.4,
		FlashReduction = 0.6,
		Cost = 80,
		UnlockLevel = 12
	},
	
	-- Match Grade - maximum accuracy
	Match = {
		Name = "Match",
		DisplayName = "Match Grade",
		Color = Color3.new(0.9, 0.9, 0.9),
		Description = "Tournament-grade accuracy ammunition",
		DamageMultiplier = 1.05,
		VelocityMultiplier = 1.1,
		PenetrationMultiplier = 1.1,
		RecoilMultiplier = 0.9,
		SpreadMultiplier = 0.7,
		TracerChance = 0.0,
		Effects = {"Enhanced_Accuracy", "Consistent_Performance"},
		Cost = 120,
		UnlockLevel = 30
	}
}

-- Player ammo inventory
local playerAmmo = {
	CurrentAmmoType = {},
	AmmoCount = {},
	UnlockedAmmoTypes = {}
}

-- UI elements
local ammoUI = nil
local ammoSelectorOpen = false

function AmmoSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	-- Setup player ammo data
	self:InitializePlayerAmmo()
	
	-- Setup UI
	self:SetupAmmoUI()
	
	-- Setup input handling
	self:SetupInputHandling()
	
	-- Setup remote events
	self:SetupRemoteEvents()
	
	print("AmmoSystem initialized")
end

function AmmoSystem:InitializePlayerAmmo()
	-- Initialize default ammo types and counts
	playerAmmo.UnlockedAmmoTypes = {"Standard", "Tracer"} -- Start with basic types
	
	-- Initialize ammo counts for different calibers
	local ammoCalibers = {"9mm", "556", "762", "12gauge", "45acp"}
	for _, caliber in pairs(ammoCalibers) do
		playerAmmo.AmmoCount[caliber] = {}
		playerAmmo.CurrentAmmoType[caliber] = "Standard"
		
		-- Give some starting ammo
		for ammoType, config in pairs(AMMO_CONFIGS) do
			if table.find(playerAmmo.UnlockedAmmoTypes, ammoType) then
				playerAmmo.AmmoCount[caliber][ammoType] = ammoType == "Standard" and 300 or 60
			else
				playerAmmo.AmmoCount[caliber][ammoType] = 0
			end
		end
	end
end

function AmmoSystem:SetupAmmoUI()
	-- Connect to unified HUD system instead of creating separate UI
	print("AmmoSystem: Connecting to unified FPSHUD")

	local playerGui = player:WaitForChild("PlayerGui")
	local fpshud = playerGui:FindFirstChild("FPSHUD")

	if fpshud then
		local ammoFrame = fpshud:WaitForChild("AmmoFrame", 5)
		if ammoFrame then
			-- Store reference to unified ammo display
			ammoUI = fpshud -- Use the main HUD instead of separate GUI
			print("AmmoSystem: Connected to unified ammo display")
			return
		end
	end

	warn("AmmoSystem: Could not find unified HUD ammo display")
	return
end

function AmmoSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.B then
			self:ToggleAmmoSelector()
		end
	end)
end

function AmmoSystem:SetupRemoteEvents()
	local ammoUpdateEvent = RemoteEventsManager:GetEvent("AmmoUpdate")
	if ammoUpdateEvent then
		ammoUpdateEvent.OnClientEvent:Connect(function(ammoData)
			self:HandleAmmoUpdate(ammoData)
		end)
	end
	
	local ammoUnlockEvent = RemoteEventsManager:GetEvent("AmmoUnlock")
	if ammoUnlockEvent then
		ammoUnlockEvent.OnClientEvent:Connect(function(unlockedAmmo)
			self:HandleAmmoUnlock(unlockedAmmo)
		end)
	end
end

function AmmoSystem:ToggleAmmoSelector()
	local selector = ammoUI:FindFirstChild("AmmoSelector")
	if not selector then return end
	
	if ammoSelectorOpen then
		self:CloseAmmoSelector()
	else
		self:OpenAmmoSelector()
	end
end

function AmmoSystem:OpenAmmoSelector()
	local selector = ammoUI:FindFirstChild("AmmoSelector")
	if not selector then return end
	
	-- Get current weapon's caliber
	local currentWeapon = self:GetCurrentWeapon()
	if not currentWeapon then
		return
	end
	
	local weaponConfig = WeaponConfig:GetWeaponConfig(currentWeapon)
	if not weaponConfig or not weaponConfig.AmmoType then
		return
	end
	
	local caliber = weaponConfig.AmmoType
	
	-- Populate ammo options
	self:PopulateAmmoOptions(caliber)
	
	-- Show selector with animation
	selector.Visible = true
	selector.Position = UDim2.new(0.5, -175, 0.6, -150)
	
	local showTween = TweenService:Create(selector, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -175, 0.5, -150)
	})
	showTween:Play()
	
	ammoSelectorOpen = true
end

function AmmoSystem:CloseAmmoSelector()
	local selector = ammoUI:FindFirstChild("AmmoSelector")
	if not selector then return end
	
	local hideTween = TweenService:Create(selector, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -175, 0.6, -150)
	})
	hideTween:Play()
	
	hideTween.Completed:Connect(function()
		selector.Visible = false
	end)
	
	ammoSelectorOpen = false
end

function AmmoSystem:PopulateAmmoOptions(caliber)
	local scrollFrame = ammoUI.AmmoSelector.AmmoOptions
	
	-- Clear existing options
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child ~= scrollFrame.UIListLayout then
			child:Destroy()
		end
	end
	
	-- Create option for each available ammo type
	local yOffset = 0
	for ammoType, config in pairs(AMMO_CONFIGS) do
		if table.find(playerAmmo.UnlockedAmmoTypes, ammoType) then
			local ammoCount = playerAmmo.AmmoCount[caliber][ammoType] or 0
			if ammoCount > 0 then
				self:CreateAmmoOption(scrollFrame, ammoType, config, caliber, ammoCount)
				yOffset = yOffset + 60
			end
		end
	end
	
	-- Update scroll frame size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function AmmoSystem:CreateAmmoOption(parent, ammoType, config, caliber, ammoCount)
	local option = Instance.new("Frame")
	option.Name = ammoType .. "Option"
	option.Size = UDim2.new(1, -20, 0, 50)
	option.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	option.BorderSizePixel = 0
	option.Parent = parent
	
	-- Selected indicator
	local isSelected = (playerAmmo.CurrentAmmoType[caliber] == ammoType)
	if isSelected then
		option.BackgroundColor3 = Color3.new(0.3, 0.4, 0.6)
	end
	
	local optionCorner = Instance.new("UICorner")
	optionCorner.CornerRadius = UDim.new(0, 6)
	optionCorner.Parent = option
	
	-- Color indicator
	local colorIndicator = Instance.new("Frame")
	colorIndicator.Size = UDim2.new(0, 6, 1, 0)
	colorIndicator.BackgroundColor3 = config.Color
	colorIndicator.BorderSizePixel = 0
	colorIndicator.Parent = option
	
	-- Ammo name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, -15, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 15, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.DisplayName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = option
	
	-- Ammo description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.6, -15, 0.5, 0)
	descLabel.Position = UDim2.new(0, 15, 0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = config.Description
	descLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = option
	
	-- Ammo count
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(0.4, -10, 1, 0)
	countLabel.Position = UDim2.new(0.6, 5, 0, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ammoCount .. " rounds"
	countLabel.TextColor3 = ammoCount > 0 and Color3.new(0.8, 1, 0.8) or Color3.new(1, 0.5, 0.5)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.SourceSans
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.Parent = option
	
	-- Click handling
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = option
	
	button.MouseButton1Click:Connect(function()
		if ammoCount > 0 then
			self:SelectAmmoType(caliber, ammoType)
			self:CloseAmmoSelector()
		end
	end)
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		if not isSelected then
			option.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
		end
	end)
	
	button.MouseLeave:Connect(function()
		if not isSelected then
			option.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		end
	end)
end

function AmmoSystem:SelectAmmoType(caliber, ammoType)
	playerAmmo.CurrentAmmoType[caliber] = ammoType
	
	-- Update UI
	self:UpdateAmmoIndicator()
	
	-- Notify server
	RemoteEventsManager:FireServer("SelectAmmoType", {
		Caliber = caliber,
		AmmoType = ammoType
	})
	
	-- Apply ammo effects to current weapon
	self:ApplyAmmoEffects()
	
	print("Selected ammo type: " .. ammoType .. " for " .. caliber)
end

function AmmoSystem:UpdateAmmoIndicator()
	local indicator = ammoUI:FindFirstChild("AmmoIndicator")
	if not indicator then return end
	
	local currentWeapon = self:GetCurrentWeapon()
	if not currentWeapon then return end
	
	local weaponConfig = WeaponConfig:GetWeaponConfig(currentWeapon)
	if not weaponConfig or not weaponConfig.AmmoType then return end
	
	local caliber = weaponConfig.AmmoType
	local currentAmmoType = playerAmmo.CurrentAmmoType[caliber] or "Standard"
	local config = AMMO_CONFIGS[currentAmmoType]
	local ammoCount = playerAmmo.AmmoCount[caliber][currentAmmoType] or 0
	
	if config then
		indicator.ColorBar.BackgroundColor3 = config.Color
		indicator.AmmoType.Text = config.DisplayName
		indicator.AmmoCount.Text = ammoCount .. " rounds"
		
		-- Update color based on ammo count
		if ammoCount == 0 then
			indicator.AmmoCount.TextColor3 = Color3.new(1, 0.3, 0.3)
		elseif ammoCount < 30 then
			indicator.AmmoCount.TextColor3 = Color3.new(1, 0.7, 0.3)
		else
			indicator.AmmoCount.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		end
	end
end

function AmmoSystem:GetCurrentWeapon()
	local character = player.Character
	if not character then return nil end
	
	local tool = character:FindFirstChildOfClass("Tool")
	return tool and tool.Name or nil
end

function AmmoSystem:GetAmmoConfig(ammoType)
	return AMMO_CONFIGS[ammoType]
end

function AmmoSystem:GetCurrentAmmoType(caliber)
	return playerAmmo.CurrentAmmoType[caliber] or "Standard"
end

function AmmoSystem:GetAmmoCount(caliber, ammoType)
	if not playerAmmo.AmmoCount[caliber] then
		return 0
	end
	return playerAmmo.AmmoCount[caliber][ammoType] or 0
end

function AmmoSystem:ConsumeAmmo(caliber, ammoType, amount)
	if not playerAmmo.AmmoCount[caliber] then
		return false
	end
	
	local currentCount = playerAmmo.AmmoCount[caliber][ammoType] or 0
	if currentCount >= amount then
		playerAmmo.AmmoCount[caliber][ammoType] = currentCount - amount
		self:UpdateAmmoIndicator()
		return true
	end
	
	return false
end

function AmmoSystem:AddAmmo(caliber, ammoType, amount)
	if not playerAmmo.AmmoCount[caliber] then
		playerAmmo.AmmoCount[caliber] = {}
	end
	
	local currentCount = playerAmmo.AmmoCount[caliber][ammoType] or 0
	playerAmmo.AmmoCount[caliber][ammoType] = currentCount + amount
	
	self:UpdateAmmoIndicator()
end

function AmmoSystem:ApplyAmmoEffects()
	-- This would integrate with the weapon system to apply ammo modifiers
	local currentWeapon = self:GetCurrentWeapon()
	if not currentWeapon then return end
	
	local weaponConfig = WeaponConfig:GetWeaponConfig(currentWeapon)
	if not weaponConfig or not weaponConfig.AmmoType then return end
	
	local caliber = weaponConfig.AmmoType
	local ammoType = self:GetCurrentAmmoType(caliber)
	local ammoConfig = AMMO_CONFIGS[ammoType]
	
	if not ammoConfig then return end
	
	-- Apply effects (would be handled by weapon system)
	local weaponSystem = _G.WeaponSystem
	if weaponSystem then
		weaponSystem:ApplyAmmoModifiers(ammoConfig)
	end
end

function AmmoSystem:HandleAmmoUpdate(ammoData)
	-- Update ammo counts from server
	for caliber, ammoTypes in pairs(ammoData.AmmoCount or {}) do
		if not playerAmmo.AmmoCount[caliber] then
			playerAmmo.AmmoCount[caliber] = {}
		end
		for ammoType, count in pairs(ammoTypes) do
			playerAmmo.AmmoCount[caliber][ammoType] = count
		end
	end
	
	-- Update current ammo types
	for caliber, ammoType in pairs(ammoData.CurrentAmmoType or {}) do
		playerAmmo.CurrentAmmoType[caliber] = ammoType
	end
	
	self:UpdateAmmoIndicator()
end

function AmmoSystem:HandleAmmoUnlock(unlockedAmmo)
	if not table.find(playerAmmo.UnlockedAmmoTypes, unlockedAmmo.AmmoType) then
		table.insert(playerAmmo.UnlockedAmmoTypes, unlockedAmmo.AmmoType)
		
		-- Show unlock notification
		self:ShowAmmoUnlockNotification(unlockedAmmo.AmmoType)
		
		print("Unlocked ammo type: " .. unlockedAmmo.AmmoType)
	end
end

function AmmoSystem:ShowAmmoUnlockNotification(ammoType)
	local config = AMMO_CONFIGS[ammoType]
	if not config then return end
	
	-- Create unlock notification
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 300, 0, 80)
	notification.Position = UDim2.new(0.5, -150, 0, -100)
	notification.BackgroundColor3 = Color3.new(0, 0, 0)
	notification.BackgroundTransparency = 0.2
	notification.BorderSizePixel = 0
	notification.Parent = ammoUI
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification
	
	-- Color bar
	local colorBar = Instance.new("Frame")
	colorBar.Size = UDim2.new(0, 4, 1, 0)
	colorBar.BackgroundColor3 = config.Color
	colorBar.BorderSizePixel = 0
	colorBar.Parent = notification
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -15, 0.5, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "AMMO UNLOCKED"
	title.TextColor3 = Color3.new(1, 1, 0)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = notification
	
	-- Ammo type
	local ammoLabel = Instance.new("TextLabel")
	ammoLabel.Size = UDim2.new(1, -15, 0.5, 0)
	ammoLabel.Position = UDim2.new(0, 10, 0.5, 0)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.Text = config.DisplayName
	ammoLabel.TextColor3 = config.Color
	ammoLabel.TextScaled = true
	ammoLabel.Font = Enum.Font.SourceSansBold
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
	ammoLabel.Parent = notification
	
	-- Animate in
	local slideTween = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -150, 0, 20)
	})
	slideTween:Play()
	
	-- Auto-remove after 4 seconds
	spawn(function()
		wait(4)
		local fadeOut = TweenService:Create(notification, TweenInfo.new(0.5), {
			Position = UDim2.new(0.5, -150, 0, -100),
			BackgroundTransparency = 1
		})
		TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(ammoLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		fadeOut:Play()
		
		fadeOut.Completed:Wait()
		notification:Destroy()
	end)
end

function AmmoSystem:IsAmmoTypeUnlocked(ammoType)
	return table.find(playerAmmo.UnlockedAmmoTypes, ammoType) ~= nil
end

function AmmoSystem:GetPlayerAmmoData()
	return playerAmmo
end

-- Console commands for testing
_G.AmmoCommands = {
	giveAmmo = function(caliber, ammoType, amount)
		AmmoSystem:AddAmmo(caliber, ammoType, tonumber(amount) or 100)
		print("Added " .. amount .. " " .. ammoType .. " rounds for " .. caliber)
	end,
	
	unlockAmmo = function(ammoType)
		AmmoSystem:HandleAmmoUnlock({AmmoType = ammoType})
	end,
	
	listAmmo = function()
		print("Available ammo types:")
		for ammoType, config in pairs(AMMO_CONFIGS) do
			print("- " .. ammoType .. ": " .. config.DisplayName .. " (Unlock Level " .. config.UnlockLevel .. ")")
		end
	end,
	
	currentAmmo = function()
		local weapon = AmmoSystem:GetCurrentWeapon()
		if weapon then
			local config = WeaponConfig:GetWeaponConfig(weapon)
			if config then
				local caliber = config.AmmoType
				local ammoType = AmmoSystem:GetCurrentAmmoType(caliber)
				local count = AmmoSystem:GetAmmoCount(caliber, ammoType)
				print("Current weapon: " .. weapon .. " (" .. caliber .. ")")
				print("Current ammo: " .. ammoType .. " (" .. count .. " rounds)")
			end
		else
			print("No weapon equipped")
		end
	end,
	
	ammoInventory = function()
		print("Ammo inventory:")
		for caliber, ammoTypes in pairs(playerAmmo.AmmoCount) do
			print(caliber .. ":")
			for ammoType, count in pairs(ammoTypes) do
				if count > 0 then
					print("  " .. ammoType .. ": " .. count)
				end
			end
		end
	end,
	
	selectAmmo = function(ammoType)
		local weapon = AmmoSystem:GetCurrentWeapon()
		if weapon then
			local config = WeaponConfig:GetWeaponConfig(weapon)
			if config then
				AmmoSystem:SelectAmmoType(config.AmmoType, ammoType)
			end
		end
	end
}

return AmmoSystem