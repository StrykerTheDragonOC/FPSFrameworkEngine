local ClassSystem = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer

-- Class configurations
local CLASS_CONFIGS = {
	Assault = {
		Name = "Assault",
		DisplayName = "Assault Trooper",
		Description = "Balanced combat effectiveness with versatile equipment",
        Icon = "rbxassetid://13488731085",
		Color = Color3.new(0.8, 0.3, 0.1),
		UnlockLevel = 0,
		
		-- Stats modifiers
		HealthMultiplier = 1.0,
		SpeedMultiplier = 1.0,
		StaminaMultiplier = 1.0,
		ReloadSpeedMultiplier = 1.1,
		WeaponSwitchSpeedMultiplier = 1.1,
		
		-- Equipment
		DefaultPrimary = "G36",
		DefaultSecondary = "M9",
		DefaultMelee = "PocketKnife",
		DefaultGrenade = "M67",
		StartingArmor = 25,
		
		-- Ammo
		StartingAmmo = {
			["556"] = 300,
			["9mm"] = 120
		},
		
		-- Special Abilities
		Abilities = {
			{
				Name = "Tactical Sprint",
				Key = "V",
				Cooldown = 45,
				Duration = 8,
				Description = "Increased movement speed and reduced stamina drain",
				Effects = {
					SpeedMultiplier = 1.4,
					StaminaDrainMultiplier = 0.3
				}
			},
			{
				Name = "Combat Stim",
				Key = "H",
				Cooldown = 90,
				Duration = 15,
				Description = "Enhanced combat performance and damage resistance",
				Effects = {
					DamageResistance = 0.15,
					RecoilReduction = 0.3,
					ReloadSpeedMultiplier = 1.3
				}
			}
		},
		
		-- Passive Skills
		PassiveSkills = {
			"Increased reload speed",
			"Faster weapon switching",
			"Explosive resistance +15%"
		}
	},
	
	Scout = {
		Name = "Scout",
		DisplayName = "Scout Sniper",
		Description = "Long-range specialist with enhanced mobility and stealth",
        Icon = "rbxassetid://111599000144067",
		Color = Color3.new(0.2, 0.6, 0.2),
		UnlockLevel = 5,
		
		-- Stats modifiers
		HealthMultiplier = 0.85,
		SpeedMultiplier = 1.15,
		StaminaMultiplier = 1.3,
		ReloadSpeedMultiplier = 0.9,
		WeaponSwitchSpeedMultiplier = 1.2,
		
		-- Equipment
		DefaultPrimary = "G36", -- Would be sniper rifle
		DefaultSecondary = "M9",
		DefaultMelee = "PocketKnife",
		DefaultGrenade = "Smoke",
		StartingArmor = 15,
		
		-- Ammo
		StartingAmmo = {
			["762"] = 200,
			["9mm"] = 90
		},
		
		-- Special Abilities
		Abilities = {
			{
				Name = "Cloak",
				Key = "V",
				Cooldown = 120,
				Duration = 12,
				Description = "Become nearly invisible to enemies",
				Effects = {
					Transparency = 0.8,
					MovementSilence = true,
					SpottingResistance = 0.7
				}
			},
			{
				Name = "Eagle Eye",
				Key = "H",
				Cooldown = 60,
				Duration = 20,
				Description = "Enhanced vision and enemy marking",
				Effects = {
					ZoomEnhancement = 1.5,
					EnemyHighlight = true,
					HeadshotDamageMultiplier = 1.3
				}
			}
		},
		
		-- Passive Skills
		PassiveSkills = {
			"Increased movement speed",
			"Silent footsteps when crouched",
			"Reduced scope sway"
		}
	},
	
	Support = {
		Name = "Support",
		DisplayName = "Support Specialist", 
		Description = "Team-focused role with healing and ammunition supplies",
        Icon = "rbxassetid://80599618375180",
		Color = Color3.new(0.2, 0.4, 0.8),
		UnlockLevel = 8,
		
		-- Stats modifiers
		HealthMultiplier = 1.2,
		SpeedMultiplier = 0.9,
		StaminaMultiplier = 1.1,
		ReloadSpeedMultiplier = 1.0,
		WeaponSwitchSpeedMultiplier = 0.9,
		
		-- Equipment
		DefaultPrimary = "G36", -- Would be LMG
		DefaultSecondary = "M9",
		DefaultMelee = "PocketKnife",
		DefaultGrenade = "Smoke",
		StartingArmor = 35,
		
		-- Ammo
		StartingAmmo = {
			["556"] = 400,
			["9mm"] = 150
		},
		
		-- Special Abilities
		Abilities = {
			{
				Name = "Med Pack",
				Key = "V",
				Cooldown = 30,
				Duration = 0,
				Description = "Deploy medical kit to heal nearby teammates",
				Effects = {
					HealAmount = 75,
					HealRadius = 8,
					TeamHeal = true
				}
			},
			{
				Name = "Ammo Crate",
				Key = "H", 
				Cooldown = 60,
				Duration = 45,
				Description = "Deploy ammunition resupply crate",
				Effects = {
					AmmoResupply = true,
					ResupplyRadius = 6,
					Duration = 45
				}
			}
		},
		
		-- Passive Skills
		PassiveSkills = {
			"Increased health",
			"Faster health regeneration",
			"Can revive teammates faster"
		}
	},
	
	Recon = {
		Name = "Recon",
		DisplayName = "Recon Operative",
		Description = "Intelligence gatherer with electronic warfare capabilities",
        Icon = "rbxassetid://5304588976",
		Color = Color3.new(0.6, 0.2, 0.6),
		UnlockLevel = 12,
		
		-- Stats modifiers
		HealthMultiplier = 0.9,
		SpeedMultiplier = 1.05,
		StaminaMultiplier = 1.2,
		ReloadSpeedMultiplier = 1.05,
		WeaponSwitchSpeedMultiplier = 1.15,
		
		-- Equipment
		DefaultPrimary = "G36", -- Would be carbine
		DefaultSecondary = "M9",
		DefaultMelee = "PocketKnife",
		DefaultGrenade = "Flashbang",
		StartingArmor = 20,
		
		-- Ammo
		StartingAmmo = {
			["556"] = 250,
			["9mm"] = 105
		},
		
		-- Special Abilities
		Abilities = {
			{
				Name = "UAV Scan",
				Key = "V",
				Cooldown = 90,
				Duration = 15,
				Description = "Reveal enemy positions to your team",
				Effects = {
					EnemyReveal = true,
					ScanRadius = 100,
					TeamShared = true
				}
			},
			{
				Name = "EMP Pulse",
				Key = "H",
				Cooldown = 120,
				Duration = 8,
				Description = "Disable enemy equipment and HUD",
				Effects = {
					DisableHUD = true,
					DisableRadar = true,
					EMPRadius = 15
				}
			}
		},
		
		-- Passive Skills
		PassiveSkills = {
			"Enemy movement detection",
			"Immune to EMP effects",
			"Faster spotting cooldown"
		}
	}
}

-- Current player class data
local playerClassData = {
	CurrentClass = "Assault",
	UnlockedClasses = {"Assault"},
	AbilityCooldowns = {},
	ActiveEffects = {}
}

-- UI elements
local classUI = nil
local classSelectorOpen = false
local abilityIndicators = {}

function ClassSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	-- Setup player class data
	self:InitializePlayerClass()
	
	-- Setup UI
	self:SetupClassUI()
	
	-- Setup input handling
	self:SetupInputHandling()
	
	-- Setup remote events
	self:SetupRemoteEvents()
	
	-- Start ability system
	self:StartAbilitySystem()
	
	print("ClassSystem initialized - Current class: " .. playerClassData.CurrentClass)
end

function ClassSystem:InitializePlayerClass()
	-- Initialize with default values
	playerClassData.CurrentClass = "Assault"
	playerClassData.UnlockedClasses = {"Assault"}
	playerClassData.AbilityCooldowns = {}
	playerClassData.ActiveEffects = {}
	
	-- Initialize cooldowns for current class
	self:ResetAbilityCooldowns()
end

function ClassSystem:SetupClassUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	classUI = Instance.new("ScreenGui")
	classUI.Name = "ClassSystemGUI"
	classUI.ResetOnSpawn = false
	classUI.Parent = playerGui
	
	-- Class indicator (top left)
	local classIndicator = Instance.new("Frame")
	classIndicator.Name = "ClassIndicator"
	classIndicator.Size = UDim2.new(0, 200, 0, 60)
	classIndicator.Position = UDim2.new(0, 20, 0, 80)
	classIndicator.BackgroundColor3 = Color3.new(0, 0, 0)
	classIndicator.BackgroundTransparency = 0.3
	classIndicator.BorderSizePixel = 0
	classIndicator.Parent = classUI
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 8)
	indicatorCorner.Parent = classIndicator
	
	-- Class color bar
	local colorBar = Instance.new("Frame")
	colorBar.Name = "ColorBar"
	colorBar.Size = UDim2.new(0, 6, 1, 0)
	colorBar.BackgroundColor3 = CLASS_CONFIGS.Assault.Color
	colorBar.BorderSizePixel = 0
	colorBar.Parent = classIndicator
	
	-- Class icon
	local classIcon = Instance.new("ImageLabel")
	classIcon.Name = "ClassIcon"
	classIcon.Size = UDim2.new(0, 40, 0, 40)
	classIcon.Position = UDim2.new(0, 10, 0.5, -20)
	classIcon.BackgroundTransparency = 1
	classIcon.Image = CLASS_CONFIGS.Assault.Icon
	classIcon.ImageColor3 = CLASS_CONFIGS.Assault.Color
	classIcon.Parent = classIndicator
	
	-- Class name
	local className = Instance.new("TextLabel")
	className.Name = "ClassName"
	className.Size = UDim2.new(1, -60, 0.6, 0)
	className.Position = UDim2.new(0, 55, 0, 0)
	className.BackgroundTransparency = 1
	className.Text = CLASS_CONFIGS.Assault.DisplayName
	className.TextColor3 = Color3.new(1, 1, 1)
	className.TextScaled = true
	className.Font = Enum.Font.SourceSansBold
	className.TextXAlignment = Enum.TextXAlignment.Left
	className.Parent = classIndicator
	
	-- Class selector hint
	local selectorHint = Instance.new("TextLabel")
	selectorHint.Name = "SelectorHint"
	selectorHint.Size = UDim2.new(1, -60, 0.4, 0)
	selectorHint.Position = UDim2.new(0, 55, 0.6, 0)
	selectorHint.BackgroundTransparency = 1
	selectorHint.Text = "[N] Change Class"
	selectorHint.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	selectorHint.TextScaled = true
	selectorHint.Font = Enum.Font.SourceSans
	selectorHint.TextXAlignment = Enum.TextXAlignment.Left
	selectorHint.Parent = classIndicator
	
	-- Ability indicators
	self:SetupAbilityIndicators()
	
	-- Class selector (initially hidden)
	self:SetupClassSelector()
end

function ClassSystem:SetupAbilityIndicators()
	local currentClass = CLASS_CONFIGS[playerClassData.CurrentClass]
	if not currentClass or not currentClass.Abilities then return end
	
	-- Clear existing indicators
	for _, indicator in pairs(abilityIndicators) do
		if indicator.Parent then
			indicator:Destroy()
		end
	end
	abilityIndicators = {}
	
	-- Create indicators for each ability
	for i, ability in pairs(currentClass.Abilities) do
		local indicator = Instance.new("Frame")
		indicator.Name = "Ability" .. i .. "Indicator"
		indicator.Size = UDim2.new(0, 80, 0, 80)
		indicator.Position = UDim2.new(0, 20 + ((i-1) * 90), 1, -100)
		indicator.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		indicator.BorderSizePixel = 2
		indicator.BorderColor3 = currentClass.Color
		indicator.Parent = classUI
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = indicator
		
		-- Ability icon (placeholder)
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0.7, 0, 0.7, 0)
		icon.Position = UDim2.new(0.15, 0, 0.05, 0)
		icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://9940310625"
		icon.ImageColor3 = currentClass.Color
		icon.Parent = indicator
		
		-- Key binding
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Size = UDim2.new(1, 0, 0.25, 0)
		keyLabel.Position = UDim2.new(0, 0, 0.75, 0)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Text = "[" .. ability.Key .. "]"
		keyLabel.TextColor3 = Color3.new(1, 1, 1)
		keyLabel.TextScaled = true
		keyLabel.Font = Enum.Font.SourceSansBold
		keyLabel.Parent = indicator
		
		-- Cooldown overlay
		local cooldownOverlay = Instance.new("Frame")
		cooldownOverlay.Name = "CooldownOverlay"
		cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
		cooldownOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		cooldownOverlay.BackgroundTransparency = 0.7
		cooldownOverlay.BorderSizePixel = 0
		cooldownOverlay.Visible = false
		cooldownOverlay.Parent = indicator
		
		local cooldownCorner = Instance.new("UICorner")
		cooldownCorner.CornerRadius = UDim.new(0, 8)
		cooldownCorner.Parent = cooldownOverlay
		
		-- Cooldown text
		local cooldownText = Instance.new("TextLabel")
		cooldownText.Name = "CooldownText"
		cooldownText.Size = UDim2.new(1, 0, 1, 0)
		cooldownText.BackgroundTransparency = 1
		cooldownText.Text = "5s"
		cooldownText.TextColor3 = Color3.new(1, 0.3, 0.3)
		cooldownText.TextScaled = true
		cooldownText.Font = Enum.Font.SourceSansBold
		cooldownText.Parent = cooldownOverlay
		
		table.insert(abilityIndicators, indicator)
	end
end

function ClassSystem:SetupClassSelector()
	local classSelector = Instance.new("Frame")
	classSelector.Name = "ClassSelector"
	classSelector.Size = UDim2.new(0, 600, 0, 400)
	classSelector.Position = UDim2.new(0.5, -300, 0.5, -200)
	classSelector.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
	classSelector.BorderSizePixel = 0
	classSelector.Visible = false
	classSelector.Parent = classUI
	
	local selectorCorner = Instance.new("UICorner")
	selectorCorner.CornerRadius = UDim.new(0, 12)
	selectorCorner.Parent = classSelector
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "SELECT CLASS"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = classSelector
	
	-- Class options container
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "ClassOptions"
	optionsFrame.Size = UDim2.new(1, -20, 1, -100)
	optionsFrame.Position = UDim2.new(0, 10, 0, 60)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Parent = classSelector
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 280, 0, 150)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = optionsFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = classSelector
	
	closeButton.MouseButton1Click:Connect(function()
		self:CloseClassSelector()
	end)
end

function ClassSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		local currentClass = CLASS_CONFIGS[playerClassData.CurrentClass]
		if not currentClass then return end
		
		-- Class selector
		if input.KeyCode == Enum.KeyCode.N then
			self:ToggleClassSelector()
		end
		
		-- Ability keys
		if currentClass.Abilities then
			for _, ability in pairs(currentClass.Abilities) do
				if input.KeyCode == Enum.KeyCode[ability.Key] then
					self:UseAbility(ability.Name)
				end
			end
		end
	end)
end

function ClassSystem:SetupRemoteEvents()
	local classUpdateEvent = RemoteEventsManager:GetEvent("ClassUpdate")
	if classUpdateEvent then
		classUpdateEvent.OnClientEvent:Connect(function(classData)
			self:HandleClassUpdate(classData)
		end)
	end
	
	local classUnlockEvent = RemoteEventsManager:GetEvent("ClassUnlock")
	if classUnlockEvent then
		classUnlockEvent.OnClientEvent:Connect(function(unlockedClass)
			self:HandleClassUnlock(unlockedClass)
		end)
	end
end

function ClassSystem:StartAbilitySystem()
	-- Update ability cooldowns and effects
	RunService.Heartbeat:Connect(function(deltaTime)
		self:UpdateAbilityCooldowns(deltaTime)
		self:UpdateActiveEffects(deltaTime)
		self:UpdateAbilityIndicators()
	end)
end

function ClassSystem:ToggleClassSelector()
	local selector = classUI:FindFirstChild("ClassSelector")
	if not selector then return end
	
	if classSelectorOpen then
		self:CloseClassSelector()
	else
		self:OpenClassSelector()
	end
end

function ClassSystem:OpenClassSelector()
	local selector = classUI:FindFirstChild("ClassSelector")
	if not selector then return end
	
	-- Populate class options
	self:PopulateClassOptions()
	
	-- Show with animation
	selector.Visible = true
	selector.Position = UDim2.new(0.5, -300, 0.6, -200)
	
	local showTween = TweenService:Create(selector, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -300, 0.5, -200)
	})
	showTween:Play()
	
	classSelectorOpen = true
end

function ClassSystem:CloseClassSelector()
	local selector = classUI:FindFirstChild("ClassSelector")
	if not selector then return end
	
	local hideTween = TweenService:Create(selector, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -300, 0.6, -200)
	})
	hideTween:Play()
	
	hideTween.Completed:Connect(function()
		selector.Visible = false
	end)
	
	classSelectorOpen = false
end

function ClassSystem:PopulateClassOptions()
	local optionsFrame = classUI.ClassSelector.ClassOptions
	
	-- Clear existing options
	for _, child in pairs(optionsFrame:GetChildren()) do
		if child ~= optionsFrame.UIGridLayout then
			child:Destroy()
		end
	end
	
	-- Create option for each class
	for className, config in pairs(CLASS_CONFIGS) do
		if table.find(playerClassData.UnlockedClasses, className) then
			self:CreateClassOption(optionsFrame, className, config)
		end
	end
end

function ClassSystem:CreateClassOption(parent, className, config)
	local option = Instance.new("Frame")
	option.Name = className .. "Option"
	option.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
	option.BorderSizePixel = 2
	option.BorderColor3 = config.Color
	option.Parent = parent
	
	-- Selected indicator
	local isSelected = (playerClassData.CurrentClass == className)
	if isSelected then
		option.BackgroundColor3 = Color3.new(0.2, 0.3, 0.4)
		option.BorderColor3 = Color3.new(1, 1, 1)
	end
	
	local optionCorner = Instance.new("UICorner")
	optionCorner.CornerRadius = UDim.new(0, 8)
	optionCorner.Parent = option
	
	-- Class icon
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Image = config.Icon
	icon.ImageColor3 = config.Color
	icon.Parent = option
	
	-- Class name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -80, 0, 30)
	nameLabel.Position = UDim2.new(0, 75, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.DisplayName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = option
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -80, 0, 40)
	descLabel.Position = UDim2.new(0, 75, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = config.Description
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = option
	
	-- Abilities list
	local abilitiesLabel = Instance.new("TextLabel")
	abilitiesLabel.Size = UDim2.new(1, -20, 0, 60)
	abilitiesLabel.Position = UDim2.new(0, 10, 0, 85)
	abilitiesLabel.BackgroundTransparency = 1
	
	local abilitiesText = "Abilities: "
	if config.Abilities then
		for i, ability in pairs(config.Abilities) do
			if i > 1 then abilitiesText = abilitiesText .. ", " end
			abilitiesText = abilitiesText .. ability.Name .. " [" .. ability.Key .. "]"
		end
	end
	
	abilitiesLabel.Text = abilitiesText
	abilitiesLabel.TextColor3 = config.Color
	abilitiesLabel.TextScaled = true
	abilitiesLabel.Font = Enum.Font.SourceSans
	abilitiesLabel.TextXAlignment = Enum.TextXAlignment.Left
	abilitiesLabel.TextWrapped = true
	abilitiesLabel.Parent = option
	
	-- Click handler
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = option
	
	button.MouseButton1Click:Connect(function()
		if not isSelected then
			self:SelectClass(className)
			self:CloseClassSelector()
		end
	end)
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		if not isSelected then
			option.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		end
	end)
	
	button.MouseLeave:Connect(function()
		if not isSelected then
			option.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
		end
	end)
end

function ClassSystem:SelectClass(className)
	if not table.find(playerClassData.UnlockedClasses, className) then
		print("Class not unlocked: " .. className)
		return
	end
	
	playerClassData.CurrentClass = className
	playerClassData.ActiveEffects = {} -- Clear active effects
	
	-- Reset ability cooldowns
	self:ResetAbilityCooldowns()
	
	-- Update UI
	self:UpdateClassIndicator()
	self:SetupAbilityIndicators()
	
	-- Notify server
	RemoteEventsManager:FireServer("SelectClass", {
		ClassName = className
	})
	
	-- Apply class modifiers
	self:ApplyClassModifiers()
	
	print("Selected class: " .. className)
end

function ClassSystem:UpdateClassIndicator()
	local indicator = classUI:FindFirstChild("ClassIndicator")
	if not indicator then return end
	
	local config = CLASS_CONFIGS[playerClassData.CurrentClass]
	if not config then return end
	
	indicator.ColorBar.BackgroundColor3 = config.Color
	indicator.ClassIcon.ImageColor3 = config.Color
	indicator.ClassName.Text = config.DisplayName
end

function ClassSystem:ResetAbilityCooldowns()
	local currentClass = CLASS_CONFIGS[playerClassData.CurrentClass]
	if not currentClass or not currentClass.Abilities then return end
	
	playerClassData.AbilityCooldowns = {}
	for _, ability in pairs(currentClass.Abilities) do
		playerClassData.AbilityCooldowns[ability.Name] = 0
	end
end

function ClassSystem:UseAbility(abilityName)
	local currentClass = CLASS_CONFIGS[playerClassData.CurrentClass]
	if not currentClass or not currentClass.Abilities then return end
	
	-- Find the ability
	local ability = nil
	for _, abilityData in pairs(currentClass.Abilities) do
		if abilityData.Name == abilityName then
			ability = abilityData
			break
		end
	end
	
	if not ability then return end
	
	-- Check cooldown
	local cooldownRemaining = playerClassData.AbilityCooldowns[abilityName] or 0
	if cooldownRemaining > 0 then
		print("Ability on cooldown: " .. math.ceil(cooldownRemaining) .. "s remaining")
		return
	end
	
	-- Use ability
	print("Using ability: " .. abilityName)
	
	-- Set cooldown
	playerClassData.AbilityCooldowns[abilityName] = ability.Cooldown
	
	-- Apply effects
	if ability.Duration > 0 then
		playerClassData.ActiveEffects[abilityName] = {
			TimeRemaining = ability.Duration,
			Effects = ability.Effects
		}
	else
		-- Instant effect
		self:ApplyInstantEffect(ability)
	end
	
	-- Notify server
	RemoteEventsManager:FireServer("UseAbility", {
		AbilityName = abilityName,
		ClassName = playerClassData.CurrentClass
	})
end

function ClassSystem:ApplyInstantEffect(ability)
	-- Handle instant effects like Med Pack
	if ability.Name == "Med Pack" then
		-- Heal player and nearby teammates
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") then
			local humanoid = character.Humanoid
			local healAmount = ability.Effects.HealAmount or 50
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
			
			-- Visual effect
			self:ShowHealEffect()
		end
	elseif ability.Name == "Ammo Crate" then
		-- Create ammo crate (handled by server)
		print("Deploying ammo crate...")
	end
end

function ClassSystem:ShowHealEffect()
	-- Create healing visual effect
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local rootPart = character.HumanoidRootPart
	
	-- Green healing particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = rootPart
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
    particles.Texture = "rbxassetid://122620850"
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 50
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Speed = NumberRange.new(2, 8)
	particles.Color = ColorSequence.new(Color3.new(0.2, 1, 0.2))
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.1)
	}
	particles.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	}
	
	particles:Emit(30)
	
	game:GetService("Debris"):AddItem(attachment, 3)
end

function ClassSystem:UpdateAbilityCooldowns(deltaTime)
	for abilityName, cooldown in pairs(playerClassData.AbilityCooldowns) do
		if cooldown > 0 then
			playerClassData.AbilityCooldowns[abilityName] = math.max(0, cooldown - deltaTime)
		end
	end
end

function ClassSystem:UpdateActiveEffects(deltaTime)
	for effectName, effectData in pairs(playerClassData.ActiveEffects) do
		effectData.TimeRemaining = effectData.TimeRemaining - deltaTime
		
		if effectData.TimeRemaining <= 0 then
			-- Effect expired
			playerClassData.ActiveEffects[effectName] = nil
			print("Effect expired: " .. effectName)
		end
	end
end

function ClassSystem:UpdateAbilityIndicators()
	local currentClass = CLASS_CONFIGS[playerClassData.CurrentClass]
	if not currentClass or not currentClass.Abilities then return end
	
	for i, ability in pairs(currentClass.Abilities) do
		local indicator = abilityIndicators[i]
		if indicator then
			local cooldownOverlay = indicator:FindFirstChild("CooldownOverlay")
			local cooldownText = cooldownOverlay and cooldownOverlay:FindFirstChild("CooldownText")
			
			local cooldownRemaining = playerClassData.AbilityCooldowns[ability.Name] or 0
			
			if cooldownRemaining > 0 then
				cooldownOverlay.Visible = true
				cooldownText.Text = math.ceil(cooldownRemaining) .. "s"
			else
				cooldownOverlay.Visible = false
			end
		end
	end
end

function ClassSystem:ApplyClassModifiers()
	-- This would integrate with other systems to apply class modifiers
	local config = CLASS_CONFIGS[playerClassData.CurrentClass]
	if not config then return end
	
	-- Would apply modifiers to health, speed, etc.
	print("Applied " .. config.DisplayName .. " modifiers")
end

function ClassSystem:GetCurrentClass()
	return playerClassData.CurrentClass
end

function ClassSystem:GetClassConfig(className)
	return CLASS_CONFIGS[className or playerClassData.CurrentClass]
end

function ClassSystem:IsClassUnlocked(className)
	return table.find(playerClassData.UnlockedClasses, className) ~= nil
end

function ClassSystem:HandleClassUpdate(classData)
	-- Update class data from server
	for key, value in pairs(classData) do
		playerClassData[key] = value
	end
	
	self:UpdateClassIndicator()
	self:SetupAbilityIndicators()
end

function ClassSystem:HandleClassUnlock(unlockedClass)
	if not table.find(playerClassData.UnlockedClasses, unlockedClass.ClassName) then
		table.insert(playerClassData.UnlockedClasses, unlockedClass.ClassName)
		print("Unlocked class: " .. unlockedClass.ClassName)
	end
end

-- Console commands for testing
_G.ClassCommands = {
	selectClass = function(className)
		if CLASS_CONFIGS[className] then
			ClassSystem:SelectClass(className)
		else
			print("Available classes:")
			for name, _ in pairs(CLASS_CONFIGS) do
				print("- " .. name)
			end
		end
	end,
	
	unlockClass = function(className)
		if CLASS_CONFIGS[className] then
			ClassSystem:HandleClassUnlock({ClassName = className})
		end
	end,
	
	useAbility = function(abilityName)
		ClassSystem:UseAbility(abilityName)
	end,
	
	listClasses = function()
		print("Available classes:")
		for name, config in pairs(CLASS_CONFIGS) do
			local status = table.find(playerClassData.UnlockedClasses, name) and "UNLOCKED" or "LOCKED"
			print("- " .. name .. ": " .. config.DisplayName .. " (" .. status .. ")")
		end
	end,
	
	currentClass = function()
		local config = CLASS_CONFIGS[playerClassData.CurrentClass]
		print("Current class: " .. playerClassData.CurrentClass .. " (" .. (config and config.DisplayName or "Unknown") .. ")")
	end,
	
	classInfo = function(className)
		local config = CLASS_CONFIGS[className or playerClassData.CurrentClass]
		if config then
			print("Class: " .. config.DisplayName)
			print("Description: " .. config.Description)
			print("Unlock Level: " .. config.UnlockLevel)
			if config.Abilities then
				print("Abilities:")
				for _, ability in pairs(config.Abilities) do
					print("  " .. ability.Name .. " [" .. ability.Key .. "]: " .. ability.Description)
				end
			end
		end
	end
}

return ClassSystem