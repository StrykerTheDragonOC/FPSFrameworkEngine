-- DamageSystem.lua
-- Basic damage system for FPS framework with test rig support
-- Handles damage calculation, health management, and death effects

local DamageSystem = {}
DamageSystem.__index = DamageSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Constants
local DAMAGE_SETTINGS = {
	-- Multipliers for different body parts
	HEADSHOT_MULTIPLIER = 2.0,
	CHEST_MULTIPLIER = 1.0,
	LIMB_MULTIPLIER = 0.8,
	
	-- Fall damage settings
	FALL_DAMAGE_ENABLED = true,
	SAFE_FALL_HEIGHT = 25,
	MAX_FALL_HEIGHT = 100,
	MAX_FALL_DAMAGE = 80,
	
	-- Damage over time
	BLEED_DAMAGE_PER_TICK = 2,
	BLEED_TICK_INTERVAL = 1.0,
	
	-- Visual effects
	BLOOD_EFFECT_DURATION = 2.0,
	DAMAGE_INDICATOR_DURATION = 1.5,
	
	-- Test rig settings
	TEST_RIG_HEALTH = 100,
	TEST_RIG_RESPAWN_TIME = 5.0
}

-- Body part detection mapping
local BODY_PARTS = {
	["Head"] = "HEAD",
	["Torso"] = "CHEST", 
	["UpperTorso"] = "CHEST",
	["LowerTorso"] = "CHEST",
	["LeftArm"] = "LIMB",
	["RightArm"] = "LIMB",
	["LeftLeg"] = "LIMB",
	["RightLeg"] = "LIMB",
	["LeftUpperArm"] = "LIMB",
	["RightUpperArm"] = "LIMB",
	["LeftLowerArm"] = "LIMB",
	["RightLowerArm"] = "LIMB",
	["LeftUpperLeg"] = "LIMB",
	["RightUpperLeg"] = "LIMB",
	["LeftLowerLeg"] = "LIMB",
	["RightLowerLeg"] = "LIMB"
}

-- Constructor
function DamageSystem.new()
	local self = setmetatable({}, DamageSystem)
	
	-- Active damage effects
	self.activeDamageEffects = {}
	self.testRigs = {}
	
	-- Set up remote events
	self:setupRemoteEvents()
	
	-- Initialize test rig management
	self:initializeTestRigs()
	
	-- Export to global
	_G.DamageSystem = self
	
	print("Damage System initialized")
	return self
end

-- Set up remote events
function DamageSystem:setupRemoteEvents()
	local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem")
	local remoteEventsFolder = fpsSystem:WaitForChild("RemoteEvents")
	
	-- Create damage event if it doesn't exist
	self.damageEvent = remoteEventsFolder:FindFirstChild("PlayerDamaged")
	if not self.damageEvent then
		self.damageEvent = Instance.new("RemoteEvent")
		self.damageEvent.Name = "PlayerDamaged"
		self.damageEvent.Parent = remoteEventsFolder
	end
	
	-- Create test rig damage event
	self.testRigDamageEvent = remoteEventsFolder:FindFirstChild("TestRigDamaged")
	if not self.testRigDamageEvent then
		self.testRigDamageEvent = Instance.new("RemoteEvent")
		self.testRigDamageEvent.Name = "TestRigDamaged"
		self.testRigDamageEvent.Parent = remoteEventsFolder
	end
	
	print("Damage system remote events setup complete")
end

-- Initialize test rig management
function DamageSystem:initializeTestRigs()
	-- Create test rigs folder if it doesn't exist
	local testRigsFolder = workspace:FindFirstChild("TestRigs")
	if not testRigsFolder then
		testRigsFolder = Instance.new("Folder")
		testRigsFolder.Name = "TestRigs"
		testRigsFolder.Parent = workspace
	end
	
	self.testRigsFolder = testRigsFolder
	
	-- Monitor for test rigs being added
	testRigsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child:FindFirstChild("Humanoid") then
			self:registerTestRig(child)
		end
	end)
	
	-- Register existing test rigs
	for _, child in ipairs(testRigsFolder:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild("Humanoid") then
			self:registerTestRig(child)
		end
	end
end

-- Create a test rig for damage testing
function DamageSystem:createTestRig(position)
	position = position or Vector3.new(0, 10, 0)
	
	-- Create basic humanoid model
	local testRig = Instance.new("Model")
	testRig.Name = "TestRig_" .. tick()
	
	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = DAMAGE_SETTINGS.TEST_RIG_HEALTH
	humanoid.Health = DAMAGE_SETTINGS.TEST_RIG_HEALTH
	humanoid.Parent = testRig
	
	-- Create root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 1, 1)
	rootPart.Position = position
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Transparency = 1
	rootPart.Parent = testRig
	
	-- Create visible body parts
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position
	torso.Anchored = true
	torso.Color = Color3.fromRGB(163, 162, 165)
	torso.Parent = testRig
	
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Position = position + Vector3.new(0, 1.5, 0)
	head.Shape = Enum.PartType.Ball
	head.Anchored = true
	head.Color = Color3.fromRGB(255, 204, 153)
	head.Parent = testRig
	
	-- Create arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Position = position + Vector3.new(-1.5, 0, 0)
	leftArm.Anchored = true
	leftArm.Color = Color3.fromRGB(255, 204, 153)
	leftArm.Parent = testRig
	
	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Position = position + Vector3.new(1.5, 0, 0)
	rightArm.Anchored = true
	rightArm.Color = Color3.fromRGB(255, 204, 153)
	rightArm.Parent = testRig
	
	-- Create legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Position = position + Vector3.new(-0.5, -2, 0)
	leftLeg.Anchored = true
	leftLeg.Color = Color3.fromRGB(0, 0, 255)
	leftLeg.Parent = testRig
	
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLeg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Position = position + Vector3.new(0.5, -2, 0)
	rightLeg.Anchored = true
	rightLeg.Color = Color3.fromRGB(0, 0, 255)
	rightLeg.Parent = testRig
	
	-- Set primary part
	testRig.PrimaryPart = rootPart
	
	-- Parent to test rigs folder
	testRig.Parent = self.testRigsFolder
	
	-- Register the test rig
	self:registerTestRig(testRig)
	
	print("Created test rig:", testRig.Name, "at position", position)
	return testRig
end

-- Register a test rig for damage handling
function DamageSystem:registerTestRig(testRig)
	if not testRig or not testRig:FindFirstChild("Humanoid") then return end
	
	local humanoid = testRig.Humanoid
	
	-- Store test rig data
	self.testRigs[testRig] = {
		maxHealth = humanoid.MaxHealth,
		originalPosition = testRig.PrimaryPart and testRig.PrimaryPart.Position or Vector3.new(0, 10, 0),
		isAlive = true,
		lastDamageTime = 0,
		damageHistory = {}
	}
	
	-- Connect to humanoid death
	local connection = humanoid.Died:Connect(function()
		self:handleTestRigDeath(testRig)
	end)
	
	-- Store connection for cleanup
	self.testRigs[testRig].deathConnection = connection
	
	-- Add health GUI
	self:createHealthGUI(testRig)
	
	print("Registered test rig:", testRig.Name)
end

-- Create health GUI for test rig
function DamageSystem:createHealthGUI(testRig)
	local humanoid = testRig:FindFirstChild("Humanoid")
	local head = testRig:FindFirstChild("Head")
	
	if not humanoid or not head then return end
	
	-- Create billboard GUI
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthGUI"
	billboardGui.Size = UDim2.new(4, 0, 1, 0)
	billboardGui.Adornee = head
	billboardGui.Parent = head
	
	-- Background frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0.3, 0)
	frame.Position = UDim2.new(0, 0, -0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui
	
	-- Health bar
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, -4, 1, -4)
	healthBar.Position = UDim2.new(0, 2, 0, 2)
	healthBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = frame
	
	-- Health text
	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.GothamBold
	healthText.Parent = frame
	
	-- Connect to health changes
	local connection = humanoid.HealthChanged:Connect(function(health)
		local healthPercent = health / humanoid.MaxHealth
		healthBar.Size = UDim2.new(healthPercent, -4, 1, -4)
		healthText.Text = math.floor(health) .. "/" .. math.floor(humanoid.MaxHealth)
		
		-- Change color based on health
		if healthPercent > 0.6 then
			healthBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		elseif healthPercent > 0.3 then
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
		else
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		end
	end)
	
	-- Store connection for cleanup
	if not self.testRigs[testRig] then
		self.testRigs[testRig] = {}
	end
	self.testRigs[testRig].healthConnection = connection
end

-- Handle test rig death
function DamageSystem:handleTestRigDeath(testRig)
	print("Test rig died:", testRig.Name)
	
	local rigData = self.testRigs[testRig]
	if rigData then
		rigData.isAlive = false
	end
	
	-- Create death effect
	self:createDeathEffect(testRig)
	
	-- Schedule respawn
	task.delay(DAMAGE_SETTINGS.TEST_RIG_RESPAWN_TIME, function()
		self:respawnTestRig(testRig)
	end)
end

-- Respawn test rig
function DamageSystem:respawnTestRig(testRig)
	local rigData = self.testRigs[testRig]
	if not rigData then return end
	
	local humanoid = testRig:FindFirstChild("Humanoid")
	if humanoid then
		-- Reset health
		humanoid.Health = rigData.maxHealth
		rigData.isAlive = true
		
		-- Reset position
		if testRig.PrimaryPart then
			testRig:SetPrimaryPartCFrame(CFrame.new(rigData.originalPosition))
		end
		
		print("Respawned test rig:", testRig.Name)
	end
end

-- Create death effect
function DamageSystem:createDeathEffect(testRig)
	local rootPart = testRig.PrimaryPart
	if not rootPart then return end
	
	-- Create explosion effect
	local explosion = Instance.new("Explosion")
	explosion.Position = rootPart.Position
	explosion.BlastRadius = 5
	explosion.BlastPressure = 0
	explosion.Parent = workspace
	
	-- Ragdoll effect (basic)
	for _, part in ipairs(testRig:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Anchored = false
			part.CanCollide = true
			
			-- Add some random velocity
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = Vector3.new(
				(math.random() - 0.5) * 20,
				math.random() * 15,
				(math.random() - 0.5) * 20
			)
			bodyVelocity.Parent = part
			
			-- Remove body velocity after a short time
			Debris:AddItem(bodyVelocity, 0.5)
			
			-- Fade out parts
			TweenService:Create(part, TweenInfo.new(2.0), {Transparency = 0.8}):Play()
			
			-- Re-anchor after ragdoll effect
			task.delay(2.0, function()
				part.Anchored = true
				part.CanCollide = false
				part.Transparency = 0
			end)
		end
	end
end

-- Apply damage to a character or test rig
function DamageSystem:applyDamage(target, damage, bodyPart, damageType, attacker)
	bodyPart = bodyPart or "Torso"
	damageType = damageType or "generic"
	damage = math.max(0, damage)
	
	-- Check if target is a player character or test rig
	local targetPlayer = Players:GetPlayerFromCharacter(target)
	
	if targetPlayer then
		-- Send damage to server for player characters
		self.damageEvent:FireServer(target, damage, bodyPart, damageType)
	else
		-- Check if it's a test rig
		if target:FindFirstChild("Humanoid") then
			self.testRigDamageEvent:FireServer(target.Name, damage, bodyPart, damageType)
		end
	end
	
	-- Create local damage effects
	self:createDamageEffects(target, damage, bodyPart, damageType)
	
	return true
end

-- Get damage multiplier for body part
function DamageSystem:getBodyPartMultiplier(bodyPart)
	local partType = BODY_PARTS[bodyPart] or "CHEST"
	
	if partType == "HEAD" then
		return DAMAGE_SETTINGS.HEADSHOT_MULTIPLIER
	elseif partType == "CHEST" then
		return DAMAGE_SETTINGS.CHEST_MULTIPLIER
	elseif partType == "LIMB" then
		return DAMAGE_SETTINGS.LIMB_MULTIPLIER
	else
		return DAMAGE_SETTINGS.CHEST_MULTIPLIER
	end
end

-- Create damage effects
function DamageSystem:createDamageEffects(target, damage, bodyPart, damageType)
	-- Find the hit part
	local hitPart = target:FindFirstChild(bodyPart)
	if not hitPart then
		hitPart = target.PrimaryPart or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
	end
	
	if not hitPart then return end
	
	-- Create blood effect
	self:createBloodEffect(hitPart, damage)
	
	-- Create damage number
	self:createDamageNumber(hitPart, damage, bodyPart)
end

-- Create blood effect
function DamageSystem:createBloodEffect(part, damage)
	-- Create blood particle
	local blood = Instance.new("Part")
	blood.Name = "BloodEffect"
	blood.Size = Vector3.new(0.1, 0.1, 0.1)
	blood.Shape = Enum.PartType.Ball
	blood.Material = Enum.Material.Neon
	blood.Color = Color3.fromRGB(150, 0, 0)
	blood.Anchored = true
	blood.CanCollide = false
	blood.CFrame = part.CFrame
	blood.Parent = workspace
	
	-- Animate blood effect
	local tween = TweenService:Create(blood, TweenInfo.new(DAMAGE_SETTINGS.BLOOD_EFFECT_DURATION), {
		Size = Vector3.new(0.5, 0.5, 0.5),
		Transparency = 1,
		Position = part.Position + Vector3.new(
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2
		)
	})
	
	tween:Play()
	
	-- Clean up
	Debris:AddItem(blood, DAMAGE_SETTINGS.BLOOD_EFFECT_DURATION)
end

-- Create floating damage number
function DamageSystem:createDamageNumber(part, damage, bodyPart)
	-- Create billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(2, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = workspace
	
	-- Position at hit location
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	billboard.Adornee = attachment
	
	-- Create damage label
	local damageLabel = Instance.new("TextLabel")
	damageLabel.Size = UDim2.new(1, 0, 1, 0)
	damageLabel.BackgroundTransparency = 1
	damageLabel.Text = "-" .. math.floor(damage)
	damageLabel.TextScaled = true
	damageLabel.Font = Enum.Font.GothamBold
	damageLabel.TextStrokeTransparency = 0
	damageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	
	-- Color based on body part
	if BODY_PARTS[bodyPart] == "HEAD" then
		damageLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for headshots
	elseif damage > 50 then
		damageLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red for high damage
	else
		damageLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for normal damage
	end
	
	damageLabel.Parent = billboard
	
	-- Animate damage number
	local tween = TweenService:Create(damageLabel, TweenInfo.new(DAMAGE_SETTINGS.DAMAGE_INDICATOR_DURATION), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Size = UDim2.new(1.5, 0, 1.5, 0)
	})
	
	-- Move upward
	local moveTween = TweenService:Create(billboard, TweenInfo.new(DAMAGE_SETTINGS.DAMAGE_INDICATOR_DURATION), {
		StudsOffset = Vector3.new(0, 5, 0)
	})
	
	tween:Play()
	moveTween:Play()
	
	-- Clean up
	Debris:AddItem(billboard, DAMAGE_SETTINGS.DAMAGE_INDICATOR_DURATION)
	Debris:AddItem(attachment, DAMAGE_SETTINGS.DAMAGE_INDICATOR_DURATION)
end

-- Get test rig statistics
function DamageSystem:getTestRigStats(testRig)
	local rigData = self.testRigs[testRig]
	if not rigData then return nil end
	
	local humanoid = testRig:FindFirstChild("Humanoid")
	if not humanoid then return nil end
	
	return {
		name = testRig.Name,
		health = humanoid.Health,
		maxHealth = humanoid.MaxHealth,
		isAlive = rigData.isAlive,
		totalDamageReceived = #rigData.damageHistory,
		lastDamageTime = rigData.lastDamageTime,
		damageHistory = rigData.damageHistory
	}
end

-- Print debug information
function DamageSystem:printDebugInfo()
	print("=== Damage System Debug Info ===")
	print("Registered test rigs:", #self.testRigs)
	
	for testRig, rigData in pairs(self.testRigs) do
		local humanoid = testRig:FindFirstChild("Humanoid")
		if humanoid then
			print(string.format("- %s: %.1f/%.1f HP, %d damage events", 
				testRig.Name, humanoid.Health, humanoid.MaxHealth, #rigData.damageHistory))
		end
	end
	
	print("===============================")
end

-- Clean up
function DamageSystem:destroy()
	-- Disconnect all connections
	for testRig, rigData in pairs(self.testRigs) do
		if rigData.deathConnection then
			rigData.deathConnection:Disconnect()
		end
		if rigData.healthConnection then
			rigData.healthConnection:Disconnect()
		end
	end
	
	-- Clear data
	self.testRigs = {}
	self.activeDamageEffects = {}
	
	print("Damage System destroyed")
end

return DamageSystem