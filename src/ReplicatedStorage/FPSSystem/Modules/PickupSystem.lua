local PickupSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Pickup configurations
local PICKUP_CONFIGS = {
	-- Armor pickups
	["Light Armor"] = {
		Type = "Armor",
		ArmorValue = 25,
		Model = "LightArmorPickup",
		Color = Color3.new(0.5, 0.7, 1),
        Sound = "rbxassetid://2848703459",
		Description = "Light Kevlar Vest (+25 Armor)",
		RespawnTime = 45,
		Rarity = "Common"
	},
	["Heavy Armor"] = {
		Type = "Armor",
		ArmorValue = 50,
		Model = "HeavyArmorPickup", 
		Color = Color3.new(0.2, 0.5, 0.8),
        Sound = "rbxassetid://2848703459",
		Description = "Heavy Tactical Vest (+50 Armor)",
		RespawnTime = 90,
		Rarity = "Rare"
	},
	["Riot Armor"] = {
		Type = "Armor",
		ArmorValue = 100,
		Model = "RiotArmorPickup",
		Color = Color3.new(0.1, 0.3, 0.6),
        Sound = "rbxassetid://2848703459",
		Description = "Riot Control Armor (+100 Armor)",
		RespawnTime = 120,
		Rarity = "Epic"
	},
	
	-- Ammunition pickups
	["Pistol Ammo"] = {
		Type = "Ammo",
		AmmoType = "9mm",
		AmmoAmount = 30,
		Model = "PistolAmmoPickup",
		Color = Color3.new(0.8, 0.6, 0.2),
        Sound = "rbxassetid://2848703459",
		Description = "9mm Ammunition (30 rounds)",
		RespawnTime = 20,
		Rarity = "Common"
	},
	["Rifle Ammo"] = {
		Type = "Ammo",
		AmmoType = "556",
		AmmoAmount = 60,
		Model = "RifleAmmoPickup",
		Color = Color3.new(0.7, 0.4, 0.1),
        Sound = "rbxassetid://2848703459",
		Description = "5.56mm Ammunition (60 rounds)",
		RespawnTime = 25,
		Rarity = "Common"
	},
	["Sniper Ammo"] = {
		Type = "Ammo",
		AmmoType = "762",
		AmmoAmount = 20,
		Model = "SniperAmmoPickup",
		Color = Color3.new(0.6, 0.3, 0.1),
        Sound = "rbxassetid://2848703459",
		Description = "7.62mm Ammunition (20 rounds)",
		RespawnTime = 40,
		Rarity = "Uncommon"
	},
	["Shotgun Shells"] = {
		Type = "Ammo",
		AmmoType = "12gauge",
		AmmoAmount = 16,
		Model = "ShotgunAmmoPickup",
		Color = Color3.new(0.8, 0.2, 0.2),
        Sound = "rbxassetid://2848703459",
		Description = "12 Gauge Shells (16 shells)",
		RespawnTime = 30,
		Rarity = "Uncommon"
	},
	
	-- Medical pickups
	["Health Pack"] = {
		Type = "Medical",
		HealAmount = 50,
		Model = "HealthPackPickup",
		Color = Color3.new(1, 0.2, 0.2),
        Sound = "rbxassetid://85211316284760",
		Description = "First Aid Kit (+50 Health)",
		RespawnTime = 30,
		Rarity = "Common"
	},
	["Medical Kit"] = {
		Type = "Medical",
		HealAmount = 100,
		RemoveStatusEffects = true,
		Model = "MedicalKitPickup",
		Color = Color3.new(0.8, 0.1, 0.1),
        Sound = "rbxassetid://85211316284760",
		Description = "Medical Kit (+100 Health, Cures Effects)",
		RespawnTime = 60,
		Rarity = "Rare"
	},
	["Adrenaline"] = {
		Type = "Medical",
		StatusEffect = "Adrenaline",
		Duration = 30,
		Model = "AdrenalinePickup",
		Color = Color3.new(0, 1, 0),
        Sound = "rbxassetid://118894757343366",
		Description = "Adrenaline Shot (30s boost)",
		RespawnTime = 90,
		Rarity = "Rare"
	},
	
	-- Equipment pickups
	["Night Vision"] = {
		Type = "Equipment",
		Equipment = "NVG",
		Model = "NVGPickup",
		Color = Color3.new(0, 0.8, 0),
        Sound = "rbxassetid://376178316",
		Description = "Night Vision Goggles",
		RespawnTime = 120,
		Rarity = "Epic"
	},
	["Thermal Scope"] = {
		Type = "Equipment",
		Equipment = "Thermal",
		Model = "ThermalPickup",
		Color = Color3.new(1, 0.5, 0),
        Sound = "rbxassetid://376178316",
		Description = "Thermal Vision Scope",
		RespawnTime = 150,
		Rarity = "Epic"
	},
	["Ghillie Suit"] = {
		Type = "Equipment",
		Equipment = "Ghillie",
		StatusEffect = "Camouflaged",
		Duration = 120,
		Model = "GhilliePickup",
		Color = Color3.new(0.3, 0.5, 0.2),
        Sound = "rbxassetid://7518441422",
		Description = "Ghillie Suit (2min camouflage)",
		RespawnTime = 180,
		Rarity = "Legendary"
	},
	
	-- Special pickups
	["Speed Boost"] = {
		Type = "Powerup",
		StatusEffect = "SpeedBoost",
		Duration = 20,
		Model = "SpeedPickup",
		Color = Color3.new(0, 0.5, 1),
        Sound = "rbxassetid://118779818494024",
		Description = "Speed Boost (20s +50% speed)",
		RespawnTime = 60,
		Rarity = "Rare"
	},
	["Damage Boost"] = {
		Type = "Powerup",
		StatusEffect = "DamageBoost",
		Duration = 15,
		Model = "DamagePickup",
		Color = Color3.new(1, 0.3, 0),
        Sound = "rbxassetid://640886764",
		Description = "Damage Boost (15s +25% damage)",
		RespawnTime = 75,
		Rarity = "Rare"
	},
	["Shield Generator"] = {
		Type = "Powerup", 
		Equipment = "Shield",
		Duration = 45,
		Model = "ShieldPickup",
		Color = Color3.new(0.5, 0.5, 1),
        Sound = "rbxassetid://6465177026",
		Description = "Energy Shield (45s protection)",
		RespawnTime = 120,
		Rarity = "Epic"
	}
}

local nearbyPickups = {}
local pickupGUI = nil
local currentlyNearPickup = nil
local pickupConnection = nil

function PickupSystem:Initialize()
	self:SetupPickupUI()
	self:SetupInputHandling()
	self:StartPickupDetection()

	-- Listen for pickup events from server
	local pickupTakenEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupTaken")
	if pickupTakenEvent then
		pickupTakenEvent.OnClientEvent:Connect(function(pickupData)
			self:HandlePickupTaken(pickupData)
		end)
	end

	local pickupSpawnedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupSpawned")
	if pickupSpawnedEvent then
		pickupSpawnedEvent.OnClientEvent:Connect(function(pickupData)
			self:HandlePickupSpawned(pickupData)
		end)
	end

	-- Listen for pickup removal from server
	local pickupRemovedEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupRemoved")
	if pickupRemovedEvent then
		pickupRemovedEvent.OnClientEvent:Connect(function(pickupId)
			self:HandlePickupRemoved(pickupId)
		end)
	end

	print("PickupSystem initialized")
end

function PickupSystem:SetupPickupUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	pickupGUI = Instance.new("ScreenGui")
	pickupGUI.Name = "PickupGUI"
	pickupGUI.ResetOnSpawn = false
	pickupGUI.Parent = playerGui
	
	-- Pickup prompt frame
	local promptFrame = Instance.new("Frame")
	promptFrame.Name = "PickupPrompt"
	promptFrame.Size = UDim2.new(0, 300, 0, 80)
	promptFrame.Position = UDim2.new(0.5, -150, 0.7, 0)
	promptFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	promptFrame.BackgroundTransparency = 0.3
	promptFrame.BorderSizePixel = 0
	promptFrame.Visible = false
	promptFrame.Parent = pickupGUI
	
	local promptCorner = Instance.new("UICorner")
	promptCorner.CornerRadius = UDim.new(0, 8)
	promptCorner.Parent = promptFrame
	
	-- Pickup icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 48, 0, 48)
	icon.Position = UDim2.new(0, 10, 0.5, -24)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://8560915132" -- Default icon
	icon.Parent = promptFrame
	
	-- Pickup name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -70, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 65, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Pickup Name"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = promptFrame
	
	-- Pickup description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -70, 0.3, 0)
	descLabel.Position = UDim2.new(0, 65, 0.4, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = "Description"
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = promptFrame
	
	-- Pickup key prompt
	local keyPrompt = Instance.new("TextLabel")
	keyPrompt.Name = "KeyPrompt"
	keyPrompt.Size = UDim2.new(1, -70, 0.3, 0)
	keyPrompt.Position = UDim2.new(0, 65, 0.7, 0)
	keyPrompt.BackgroundTransparency = 1
	keyPrompt.Text = "Press [E] to pickup"
	keyPrompt.TextColor3 = Color3.new(1, 1, 0)
	keyPrompt.TextScaled = true
	keyPrompt.Font = Enum.Font.SourceSansBold
	keyPrompt.TextXAlignment = Enum.TextXAlignment.Left
	keyPrompt.Parent = promptFrame
	
	-- Rarity border
	local rarityBorder = Instance.new("Frame")
	rarityBorder.Name = "RarityBorder"
	rarityBorder.Size = UDim2.new(1, 0, 0, 3)
	rarityBorder.Position = UDim2.new(0, 0, 0, 0)
	rarityBorder.BackgroundColor3 = Color3.new(1, 1, 1)
	rarityBorder.BorderSizePixel = 0
	rarityBorder.Parent = promptFrame
	
	-- Pickup notifications area
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "Notifications"
	notificationFrame.Size = UDim2.new(0, 250, 0, 200)
	notificationFrame.Position = UDim2.new(1, -270, 0, 100)
	notificationFrame.BackgroundTransparency = 1
	notificationFrame.Parent = pickupGUI
end

function PickupSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			self:TryPickupNearbyItem()
		end
	end)
end

function PickupSystem:StartPickupDetection()
	pickupConnection = RunService.Heartbeat:Connect(function()
		self:UpdateNearbyPickups()
	end)
end

function PickupSystem:UpdateNearbyPickups()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		self:HidePickupPrompt()
		return
	end
	
	local playerPosition = character.HumanoidRootPart.Position
	local nearestPickup = nil
	local nearestDistance = math.huge
	
	-- Find nearest pickup
	for _, pickup in pairs(workspace:GetChildren()) do
		if pickup.Name:find("Pickup") and pickup:FindFirstChild("PickupData") then
			local distance = (pickup.Position - playerPosition).Magnitude
			if distance <= 5 and distance < nearestDistance then -- 5 stud pickup range
				nearestDistance = distance
				nearestPickup = pickup
			end
		end
	end
	
	-- Update UI
	if nearestPickup and nearestPickup ~= currentlyNearPickup then
		currentlyNearPickup = nearestPickup
		self:ShowPickupPrompt(nearestPickup)
	elseif not nearestPickup and currentlyNearPickup then
		currentlyNearPickup = nil
		self:HidePickupPrompt()
	end
end

function PickupSystem:ShowPickupPrompt(pickupPart)
	local pickupData = pickupPart:FindFirstChild("PickupData")
	if not pickupData then return end
	
	local pickupName = pickupData.Value
	local config = PICKUP_CONFIGS[pickupName]
	if not config then return end
	
	local promptFrame = pickupGUI:FindFirstChild("PickupPrompt")
	if not promptFrame then return end
	
	-- Update prompt content
	promptFrame.Name.Text = pickupName
	promptFrame.Description.Text = config.Description
	promptFrame.Icon.ImageColor3 = config.Color
	
	-- Set rarity color
	local rarityColors = {
		Common = Color3.new(0.7, 0.7, 0.7),
		Uncommon = Color3.new(0.2, 0.8, 0.2),
		Rare = Color3.new(0.2, 0.4, 1),
		Epic = Color3.new(0.6, 0.2, 1),
		Legendary = Color3.new(1, 0.6, 0.1)
	}
	promptFrame.RarityBorder.BackgroundColor3 = rarityColors[config.Rarity] or Color3.new(1, 1, 1)
	
	-- Show with animation
	promptFrame.Visible = true
	promptFrame.Position = UDim2.new(0.5, -150, 0.8, 0)
	
	local showTween = TweenService:Create(promptFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -150, 0.7, 0)
	})
	showTween:Play()
end

function PickupSystem:HidePickupPrompt()
	local promptFrame = pickupGUI:FindFirstChild("PickupPrompt")
	if not promptFrame or not promptFrame.Visible then return end
	
	local hideTween = TweenService:Create(promptFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -150, 0.8, 0)
	})
	hideTween:Play()
	
	hideTween.Completed:Connect(function()
		promptFrame.Visible = false
	end)
end

function PickupSystem:TryPickupNearbyItem()
	if not currentlyNearPickup then return end
	
	local pickupData = currentlyNearPickup:FindFirstChild("PickupData")
	if not pickupData then return end


	-- Send pickup request to server
	local pickupItemEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("PickupItem")
	if pickupItemEvent then
		pickupItemEvent:FireServer({
			PickupId = currentlyNearPickup.Name,
			PickupType = pickupData.Value,
			Position = currentlyNearPickup.Position
		})
	end
end

function PickupSystem:HandlePickupTaken(pickupData)
	-- Show pickup notification
	self:ShowPickupNotification(pickupData)
	
	-- Play pickup sound
	local character = player.Character
	if character then
		local config = PICKUP_CONFIGS[pickupData.PickupType]
		if config and config.Sound then
			local sound = Instance.new("Sound")
			sound.SoundId = config.Sound
			sound.Volume = 0.5
			sound.Pitch = 1 + (math.random() - 0.5) * 0.2
			sound.Parent = character:FindFirstChild("Head") or character
			sound:Play()
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end
	end
	
	-- Apply pickup effects (handled by other systems)
	self:ApplyPickupEffects(pickupData)
end

function PickupSystem:HandlePickupSpawned(pickupData)
	-- Create visual pickup in world
	self:CreatePickupVisual(pickupData)
end

function PickupSystem:HandlePickupRemoved(pickupId)
	-- Remove pickup visual from workspace
	local pickup = workspace:FindFirstChild(pickupId)
	if pickup then
		-- Stop tweens
		for _, tween in pairs(TweenService:GetValue(pickup) or {}) do
			if tween then
				tween:Cancel()
			end
		end

		-- Destroy the pickup
		pickup:Destroy()
		print("Removed pickup visual:", pickupId)
	end

	-- Hide prompt if we were looking at this pickup
	if currentlyNearPickup and currentlyNearPickup.Name == pickupId then
		currentlyNearPickup = nil
		self:HidePickupPrompt()
	end
end

function PickupSystem:ShowPickupNotification(pickupData)
	local config = PICKUP_CONFIGS[pickupData.PickupType]
	if not config then return end
	
	local notificationFrame = pickupGUI:FindFirstChild("Notifications")
	if not notificationFrame then return end
	
	-- Create notification
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(1, 0, 0, 50)
	notification.BackgroundColor3 = Color3.new(0, 0, 0)
	notification.BackgroundTransparency = 0.2
	notification.BorderSizePixel = 0
	notification.Parent = notificationFrame
	
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 6)
	notifCorner.Parent = notification
	
	-- Icon
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 32, 0, 32)
	icon.Position = UDim2.new(0, 10, 0.5, -16)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://8560915132"
	icon.ImageColor3 = config.Color
	icon.Parent = notification
	
	-- Text
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -50, 1, 0)
	text.Position = UDim2.new(0, 45, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = "+" .. pickupData.PickupType
	text.TextColor3 = config.Color
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = notification
	
	-- Animate in and out
	notification.Position = UDim2.new(1, 50, 0, #notificationFrame:GetChildren() * 55)
	
	local slideIn = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, (#notificationFrame:GetChildren() - 1) * 55)
	})
	slideIn:Play()
	
	-- Auto-remove after 3 seconds
	spawn(function()
		wait(3)
		local fadeOut = TweenService:Create(notification, TweenInfo.new(0.3), {
			Position = UDim2.new(1, 50, 0, notification.Position.Y.Offset),
			BackgroundTransparency = 1
		})
		fadeOut:Play()
		
		TweenService:Create(text, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(icon, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
		
		fadeOut.Completed:Wait()
		notification:Destroy()
		
		-- Reposition remaining notifications
		for i, child in pairs(notificationFrame:GetChildren()) do
			if child ~= notification then
				TweenService:Create(child, TweenInfo.new(0.2), {
					Position = UDim2.new(0, 0, 0, (i - 1) * 55)
				}):Play()
			end
		end
	end)
end

function PickupSystem:ApplyPickupEffects(pickupData)
	local config = PICKUP_CONFIGS[pickupData.PickupType]
	if not config then return end
	
	-- These would integrate with other systems
	if config.Type == "Medical" and config.StatusEffect then
		-- Apply status effect via StatusEffectsSystem
		local statusSystem = _G.StatusEffectsSystem
		if statusSystem then
			statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 30)
		end
	elseif config.Type == "Powerup" and config.StatusEffect then
		-- Apply powerup effect
		local statusSystem = _G.StatusEffectsSystem  
		if statusSystem then
			statusSystem:ApplyStatusEffect(player, config.StatusEffect, config.Duration or 30)
		end
	elseif config.Type == "Equipment" then
		-- Handle equipment pickup
		print("Equipped: " .. config.Equipment)
	end
end

function PickupSystem:CreatePickupVisual(pickupData)
	local config = PICKUP_CONFIGS[pickupData.PickupType]
	if not config then return end
	
	-- Create pickup model
	local pickup = Instance.new("Part")
	pickup.Name = pickupData.PickupId or "Pickup"
	pickup.Size = Vector3.new(2, 1, 2)
	pickup.Material = Enum.Material.Neon
	pickup.Color = config.Color
	pickup.Shape = Enum.PartType.Cylinder
	pickup.CanCollide = false
	pickup.Anchored = true
	pickup.Position = pickupData.Position
	pickup.Parent = workspace
	
	-- Store pickup data
	local dataValue = Instance.new("StringValue")
	dataValue.Name = "PickupData"
	dataValue.Value = pickupData.PickupType
	dataValue.Parent = pickup
	
	-- Add glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = config.Color
	pointLight.Brightness = 2
	pointLight.Range = 10
	pointLight.Parent = pickup
	
	-- Add floating animation
	local floatTween = TweenService:Create(pickup, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = pickupData.Position + Vector3.new(0, 1, 0)
	})
	floatTween:Play()
	
	-- Add rotation animation
	local rotationTween = TweenService:Create(pickup, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
		CFrame = pickup.CFrame * CFrame.Angles(0, math.rad(360), 0)
	})
	rotationTween:Play()
	
	-- Add pickup effect particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = pickup
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
	particles.Texture = "rbxassetid://241650934"
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 10
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Speed = NumberRange.new(2, 5)
	particles.Color = ColorSequence.new(config.Color)
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.05)
	}
	particles.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	}
end

function PickupSystem:SpawnPickup(pickupType, position)
	-- For testing/admin commands
	local spawnPickupEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("SpawnPickup")
	if spawnPickupEvent then
		spawnPickupEvent:FireServer({
			PickupType = pickupType,
			Position = position
		})
	end
end

function PickupSystem:GetPickupConfig(pickupType)
	return PICKUP_CONFIGS[pickupType]
end

function PickupSystem:GetAllPickupTypes()
	local types = {}
	for name, _ in pairs(PICKUP_CONFIGS) do
		table.insert(types, name)
	end
	return types
end

-- Console commands for testing
_G.PickupCommands = {
	spawnPickup = function(pickupType, x, y, z)
		local position = Vector3.new(tonumber(x) or 0, tonumber(y) or 10, tonumber(z) or 0)
		if PICKUP_CONFIGS[pickupType] then
			PickupSystem:SpawnPickup(pickupType, position)
			print("Spawned " .. pickupType .. " at " .. tostring(position))
		else
			print("Invalid pickup type. Available types:")
			for name, _ in pairs(PICKUP_CONFIGS) do
				print("- " .. name)
			end
		end
	end,
	
	listPickups = function()
		print("Available pickup types:")
		for name, config in pairs(PICKUP_CONFIGS) do
			print("- " .. name .. " (" .. config.Type .. ", " .. config.Rarity .. "): " .. config.Description)
		end
	end,
	
	nearbyPickups = function()
		print("Pickups in world:")
		for _, pickup in pairs(workspace:GetChildren()) do
			if pickup.Name:find("Pickup") and pickup:FindFirstChild("PickupData") then
				print("- " .. pickup.PickupData.Value .. " at " .. tostring(pickup.Position))
			end
		end
	end,
	
	testPickup = function(pickupType)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local pos = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 5
			PickupSystem:SpawnPickup(pickupType, pos)
		end
	end
}

return PickupSystem