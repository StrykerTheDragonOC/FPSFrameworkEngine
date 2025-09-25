local GrenadeSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer

-- Grenade configurations
local GRENADE_CONFIGS = {
	M67 = {
		Name = "M67 Frag Grenade",
		Type = "Frag",
		FuseTime = 4.0,
		CookTime = 3.5,
		CanCook = true,
		ThrowForce = 50,
		Damage = 120,
		ExplosionRadius = 15,
		MinDamageRadius = 5,
		Effect = "Explosion",
		StatusEffect = nil
	},
	
	M26 = {
		Name = "M26 Frag Grenade", 
		Type = "Frag",
		FuseTime = 4.5,
		CookTime = 4.0,
		CanCook = true,
		ThrowForce = 45,
		Damage = 100,
		ExplosionRadius = 12,
		MinDamageRadius = 4,
		Effect = "Explosion",
		StatusEffect = nil
	},
	
	Impact = {
		Name = "Impact Grenade",
		Type = "Impact",
		FuseTime = 0.1,
		CookTime = 0,
		CanCook = false,
		ThrowForce = 60,
		Damage = 90,
		ExplosionRadius = 10,
		MinDamageRadius = 3,
		Effect = "Explosion",
		StatusEffect = nil
	},
	
	Sticky = {
		Name = "Sticky Grenade",
		Type = "Sticky",
		FuseTime = 3.0,
		CookTime = 0,
		CanCook = false,
		ThrowForce = 40,
		Damage = 110,
		ExplosionRadius = 13,
		MinDamageRadius = 4,
		Effect = "Explosion",
		StatusEffect = nil,
		CanStick = true
	},
	
	Smoke = {
		Name = "Smoke Grenade",
		Type = "Smoke",
		FuseTime = 2.0,
		CookTime = 0,
		CanCook = false,
		ThrowForce = 35,
		Damage = 0,
		ExplosionRadius = 0,
		SmokeRadius = 20,
		SmokeDuration = 45,
		Effect = "Smoke",
		StatusEffect = "Concealment"
	},
	
	Flashbang = {
		Name = "Flashbang",
		Type = "Flashbang", 
		FuseTime = 2.5,
		CookTime = 0,
		CanCook = false,
		ThrowForce = 45,
		Damage = 10,
		ExplosionRadius = 0,
		EffectRadius = 25,
		Effect = "Flash",
		StatusEffect = "Blinded"
	},
	
	Flare = {
		Name = "Flare",
		Type = "Flare",
		FuseTime = 1.0,
		CookTime = 0,
		CanCook = false,
		ThrowForce = 30,
		Damage = 5,
		ExplosionRadius = 0,
		EffectRadius = 30,
		BurnDuration = 60,
		Effect = "Flare",
		StatusEffect = "Blinded"
	},
	
	C4 = {
		Name = "C4 Explosive",
		Type = "Remote",
		FuseTime = 0,
		CookTime = 0,
		CanCook = false,
		ThrowForce = 20,
		Damage = 200,
		ExplosionRadius = 20,
		MinDamageRadius = 8,
		Effect = "Explosion",
		StatusEffect = nil,
		IsRemoteDetonated = true,
		MaxPlaced = 3
	}
}

local activeGrenades = {}
local placedC4s = {}
local cookingGrenades = {}

function GrenadeSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	-- Setup input handling
	self:SetupInputHandling()
	
	-- Listen for grenade events
	local grenadeExplodedEvent = RemoteEventsManager:GetEvent("GrenadeExploded")
	if grenadeExplodedEvent then
		grenadeExplodedEvent.OnClientEvent:Connect(function(explosionData)
			self:HandleExplosionEffect(explosionData)
		end)
	end
	
	print("GrenadeSystem initialized")
end

function GrenadeSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.G then
			self:QuickSwapGrenade()
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Handle grenade release after cooking
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:ReleaseGrenade()
		end
	end)
end

function GrenadeSystem:QuickSwapGrenade()
	-- Quick swap to grenade tool
	local backpack = player.Backpack
	local character = player.Character
	
	if not character then return end
	
	-- Find grenade tool
	local grenadeTool = nil
	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and self:IsGrenadeWeapon(tool.Name) then
			grenadeTool = tool
			break
		end
	end
	
	if not grenadeTool then
		-- Check if already equipped
		for _, tool in pairs(character:GetChildren()) do
			if tool:IsA("Tool") and self:IsGrenadeWeapon(tool.Name) then
				return -- Already equipped
			end
		end
	end
	
	if grenadeTool then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:EquipTool(grenadeTool)
		end
	end
end

function GrenadeSystem:IsGrenadeWeapon(weaponName)
	return GRENADE_CONFIGS[weaponName] ~= nil
end

function GrenadeSystem:StartCooking(grenadeName)
	local config = GRENADE_CONFIGS[grenadeName]
	if not config or not config.CanCook then return false end
	
	local cookData = {
		StartTime = tick(),
		MaxCookTime = config.CookTime,
		TickInterval = config.CookTime / 4, -- 4 ticks max
		CurrentTick = 0,
		GrenadeConfig = config
	}
	
	cookingGrenades[grenadeName] = cookData
	
	-- Start cooking UI indication
	self:StartCookingUI(cookData)
	
	return true
end

function GrenadeSystem:StartCookingUI(cookData)
	-- Create expanding crosshair effect
	local playerGui = player:WaitForChild("PlayerGui")
	
	local cookingGui = Instance.new("ScreenGui")
	cookingGui.Name = "CookingGUI"
	cookingGui.Parent = playerGui
	
	local crosshair = Instance.new("ImageLabel")
	crosshair.Size = UDim2.new(0, 20, 0, 20)
	crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
	crosshair.BackgroundTransparency = 1
    crosshair.Image = "rbxassetid://316279305" -- Placeholder crosshair
	crosshair.ImageColor3 = Color3.new(1, 0, 0)
	crosshair.Parent = cookingGui
	
	-- Animate expansion
	local tickTime = cookData.TickInterval
	local maxSize = 60
	
	spawn(function()
		for tick = 1, 4 do
			local targetSize = 20 + (tick * 10)
			local tween = TweenService:Create(crosshair, TweenInfo.new(0.2), {
				Size = UDim2.new(0, targetSize, 0, targetSize),
				Position = UDim2.new(0.5, -targetSize/2, 0.5, -targetSize/2)
			})
			tween:Play()
			
			wait(tickTime)
			
			-- Check if still cooking
			local stillCooking = false
			for _, data in pairs(cookingGrenades) do
				if data == cookData then
					stillCooking = true
					break
				end
			end
			
			if not stillCooking then
				cookingGui:Destroy()
				return
			end
		end
		
		-- Final tick - explode
		crosshair.ImageColor3 = Color3.new(1, 1, 0)
		wait(0.1)
		cookingGui:Destroy()
		
		-- Kill player
		self:ExplodeInHand(cookData.GrenadeConfig)
	end)
end

function GrenadeSystem:ReleaseGrenade()
	for grenadeName, cookData in pairs(cookingGrenades) do
		local cookTime = tick() - cookData.StartTime
		local remainingFuse = cookData.GrenadeConfig.FuseTime - cookTime
		
		-- Throw grenade with remaining fuse time
		self:ThrowGrenade(grenadeName, remainingFuse)
		
		cookingGrenades[grenadeName] = nil
		break
	end
end

function GrenadeSystem:ThrowGrenade(grenadeName, fuseTime)
	local config = GRENADE_CONFIGS[grenadeName]
	if not config then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Calculate throw direction and force
	local camera = workspace.CurrentCamera
	local throwDirection = camera.CFrame.LookVector
	local throwPosition = humanoidRootPart.Position + throwDirection * 2
	
	-- Send to server
	RemoteEventsManager:FireServer("ThrowGrenade", {
		GrenadeType = grenadeName,
		Position = throwPosition,
		Direction = throwDirection,
		Force = config.ThrowForce,
		FuseTime = fuseTime or config.FuseTime
	})
end

function GrenadeSystem:HandleExplosionEffect(explosionData)
	local config = GRENADE_CONFIGS[explosionData.GrenadeType]
	if not config then return end
	
	if config.Effect == "Explosion" then
		self:CreateExplosionEffect(explosionData)
	elseif config.Effect == "Smoke" then
		self:CreateSmokeEffect(explosionData)
	elseif config.Effect == "Flash" then
		self:CreateFlashEffect(explosionData)
	elseif config.Effect == "Flare" then
		self:CreateFlareEffect(explosionData)
	end
end

function GrenadeSystem:CreateExplosionEffect(explosionData)
	local position = explosionData.Position
	
	-- Create Roblox explosion
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = explosionData.Radius or 15
	explosion.BlastPressure = 500000
	explosion.Parent = workspace
	
	-- Custom particle effects
	local particles = Instance.new("ParticleEmitter")
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.Position = position
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.Transparency = 1
	effectPart.Parent = workspace
	
	particles.Enabled = true
    particles.Texture = "rbxassetid://89089422721427" -- Custom explosion texture
	particles.Lifetime = NumberRange.new(0.5, 2.0)
	particles.Rate = 500
	particles.Speed = NumberRange.new(10, 50)
	particles.Parent = effectPart
	
	-- Cleanup
	Debris:AddItem(effectPart, 5)
	
	spawn(function()
		wait(0.5)
		particles.Enabled = false
	end)
end

function GrenadeSystem:CreateSmokeEffect(explosionData)
	local position = explosionData.Position
	local config = GRENADE_CONFIGS[explosionData.GrenadeType]
	
	-- Create smoke cloud
	local smokePart = Instance.new("Part")
	smokePart.Size = Vector3.new(1, 1, 1)
	smokePart.Position = position
	smokePart.Anchored = true
	smokePart.CanCollide = false
	smokePart.Transparency = 1
	smokePart.Parent = workspace
	
	local smokeEmitter = Instance.new("ParticleEmitter")
    smokeEmitter.Texture = "rbxassetid://248294227" -- Smoke texture
	smokeEmitter.Lifetime = NumberRange.new(8, 15)
	smokeEmitter.Rate = 100
	smokeEmitter.Speed = NumberRange.new(2, 8)
	smokeEmitter.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 2.0),
		NumberSequenceKeypoint.new(1, 4.0)
	}
	smokeEmitter.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	}
	smokeEmitter.Color = ColorSequence.new(Color3.new(0.5, 0.5, 0.5))
	smokeEmitter.Parent = smokePart
	
	-- Cleanup after smoke duration
	Debris:AddItem(smokePart, config.SmokeDuration or 45)
end

function GrenadeSystem:CreateFlashEffect(explosionData)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Calculate distance to flash
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local distance = (character.HumanoidRootPart.Position - explosionData.Position).Magnitude
	local config = GRENADE_CONFIGS[explosionData.GrenadeType]
	
	if distance > (config.EffectRadius or 25) then return end
	
	-- Create flash effect
	local flashGui = Instance.new("ScreenGui")
	flashGui.Name = "FlashEffect"
	flashGui.Parent = playerGui
	
	local flashFrame = Instance.new("Frame")
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	flashFrame.BackgroundTransparency = 0
	flashFrame.Parent = flashGui
	
	-- Flash intensity based on distance
	local intensity = math.max(0, 1 - (distance / config.EffectRadius))
	local duration = 2 + (intensity * 3) -- 2-5 seconds
	
	-- Fade out flash
	local tween = TweenService:Create(flashFrame, TweenInfo.new(duration), {
		BackgroundTransparency = 1
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		flashGui:Destroy()
	end)
	
	-- Apply blinded status effect
	RemoteEventsManager:FireServer("ApplyStatusEffect", {
		Effect = "Blinded",
		Duration = duration * 0.7
	})
end

function GrenadeSystem:CreateFlareEffect(explosionData)
	local position = explosionData.Position
	local config = GRENADE_CONFIGS[explosionData.GrenadeType]
	
	-- Create bright light source
	local flarePart = Instance.new("Part")
	flarePart.Size = Vector3.new(0.5, 0.5, 0.5)
	flarePart.Position = position
	flarePart.Anchored = true
	flarePart.CanCollide = false
	flarePart.Material = Enum.Material.Neon
	flarePart.BrickColor = BrickColor.new("Really red")
	flarePart.Shape = Enum.PartType.Ball
	flarePart.Parent = workspace
	
	local light = Instance.new("PointLight")
	light.Brightness = 10
	light.Range = 100
	light.Color = Color3.new(1, 0.3, 0.3)
	light.Parent = flarePart
	
	-- Particle effects
	local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxassetid://15049808173" -- Flare particle texture
	particles.Lifetime = NumberRange.new(1, 3)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 15)
	particles.Color = ColorSequence.new(Color3.new(1, 0.5, 0))
	particles.Parent = flarePart
	
	-- Cleanup after duration
	Debris:AddItem(flarePart, config.BurnDuration or 60)
end

function GrenadeSystem:ExplodeInHand(config)
	-- Player cooked grenade too long
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
	
	print("Grenade exploded in hand!")
end

function GrenadeSystem:GetGrenadeConfig(grenadeName)
	return GRENADE_CONFIGS[grenadeName]
end

function GrenadeSystem:GetAllGrenadeConfigs()
	return GRENADE_CONFIGS
end

return GrenadeSystem