-- DamageSystemServer.server.lua
-- Server-side damage system that manages test rigs and damage events
-- Place in ServerScriptService

local DamageSystemServer = {}

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

-- Server state
local testRigs = {}
local damageEvents = {}

-- Set up remote events
local function setupRemoteEvents()
	-- Ensure FPSSystem folder exists
	local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
	if not fpsSystem then
		fpsSystem = Instance.new("Folder")
		fpsSystem.Name = "FPSSystem"
		fpsSystem.Parent = ReplicatedStorage
	end
	
	local remoteEventsFolder = fpsSystem:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = fpsSystem
	end
	
	-- Create damage event
	local damageEvent = remoteEventsFolder:FindFirstChild("PlayerDamaged")
	if not damageEvent then
		damageEvent = Instance.new("RemoteEvent")
		damageEvent.Name = "PlayerDamaged"
		damageEvent.Parent = remoteEventsFolder
	end
	
	-- Create test rig damage event
	local testRigDamageEvent = remoteEventsFolder:FindFirstChild("TestRigDamaged")
	if not testRigDamageEvent then
		testRigDamageEvent = Instance.new("RemoteEvent")
		testRigDamageEvent.Name = "TestRigDamaged"
		testRigDamageEvent.Parent = remoteEventsFolder
	end
	
	-- Connect damage events
	damageEvent.OnServerEvent:Connect(function(player, target, damage, bodyPart, damageType)
		DamageSystemServer.handlePlayerDamage(player, target, damage, bodyPart, damageType)
	end)
	
	testRigDamageEvent.OnServerEvent:Connect(function(player, rigName, damage, bodyPart, damageType)
		DamageSystemServer.handleTestRigDamage(player, rigName, damage, bodyPart, damageType)
	end)
	
	print("Damage system remote events setup complete")
	return damageEvent, testRigDamageEvent
end

-- Create test rigs folder and initial test rigs
local function initializeTestRigs()
	local testRigsFolder = workspace:FindFirstChild("TestRigs")
	if not testRigsFolder then
		testRigsFolder = Instance.new("Folder")
		testRigsFolder.Name = "TestRigs"
		testRigsFolder.Parent = workspace
	end
	
	-- Create some initial test rigs
	DamageSystemServer.createTestRig(Vector3.new(10, 5, -10))
	DamageSystemServer.createTestRig(Vector3.new(-10, 5, -10))
	DamageSystemServer.createTestRig(Vector3.new(0, 5, -20))
	
	print("Test rigs initialized")
end

-- Create a test rig
function DamageSystemServer.createTestRig(position)
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
	
	-- Parent to workspace test rigs folder
	local testRigsFolder = workspace:FindFirstChild("TestRigs")
	testRig.Parent = testRigsFolder
	
	-- Register the test rig
	testRigs[testRig] = {
		maxHealth = humanoid.MaxHealth,
		originalPosition = position,
		isAlive = true,
		lastDamageTime = 0,
		damageHistory = {}
	}
	
	-- Create health GUI
	DamageSystemServer.createHealthGUI(testRig)
	
	-- Connect to death
	humanoid.Died:Connect(function()
		DamageSystemServer.handleTestRigDeath(testRig)
	end)
	
	print("Created test rig:", testRig.Name, "at position", position)
	return testRig
end

-- Create health GUI for test rig
function DamageSystemServer.createHealthGUI(testRig)
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
	humanoid.HealthChanged:Connect(function(health)
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
end

-- Handle test rig death
function DamageSystemServer.handleTestRigDeath(testRig)
	print("Test rig died:", testRig.Name)
	
	local rigData = testRigs[testRig]
	if rigData then
		rigData.isAlive = false
	end
	
	-- Create death effect
	DamageSystemServer.createDeathEffect(testRig)
	
	-- Schedule respawn
	task.delay(DAMAGE_SETTINGS.TEST_RIG_RESPAWN_TIME, function()
		DamageSystemServer.respawnTestRig(testRig)
	end)
end

-- Respawn test rig
function DamageSystemServer.respawnTestRig(testRig)
	local rigData = testRigs[testRig]
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
		
		-- Reset part anchoring and transparency
		for _, part in ipairs(testRig:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Anchored = true
				part.CanCollide = false
				part.Transparency = 0
			end
		end
		
		print("Respawned test rig:", testRig.Name)
	end
end

-- Create death effect
function DamageSystemServer.createDeathEffect(testRig)
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
		end
	end
end

-- Handle player damage
function DamageSystemServer.handlePlayerDamage(attacker, target, damage, bodyPart, damageType)
	local targetPlayer = Players:GetPlayerFromCharacter(target)
	if not targetPlayer then return end
	
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Calculate damage multiplier
	local multiplier = DamageSystemServer.getBodyPartMultiplier(bodyPart)
	local finalDamage = damage * multiplier
	
	-- Apply damage
	humanoid:TakeDamage(finalDamage)
	
	print(string.format("%s dealt %.1f damage to %s (%s)", 
		attacker.Name, finalDamage, targetPlayer.Name, bodyPart or "unknown"))
end

-- Handle test rig damage
function DamageSystemServer.handleTestRigDamage(attacker, rigName, damage, bodyPart, damageType)
	-- Find the test rig
	local testRig = nil
	for rig, _ in pairs(testRigs) do
		if rig.Name == rigName then
			testRig = rig
			break
		end
	end
	
	if not testRig then return end
	
	local humanoid = testRig:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Calculate damage multiplier
	local multiplier = DamageSystemServer.getBodyPartMultiplier(bodyPart)
	local finalDamage = damage * multiplier
	
	-- Apply damage
	humanoid:TakeDamage(finalDamage)
	
	-- Store damage history
	local rigData = testRigs[testRig]
	if rigData then
		table.insert(rigData.damageHistory, {
			damage = finalDamage,
			bodyPart = bodyPart,
			damageType = damageType,
			attacker = attacker.Name,
			timestamp = tick()
		})
		rigData.lastDamageTime = tick()
	end
	
	print(string.format("%s dealt %.1f damage to %s (%s)", 
		attacker.Name, finalDamage, testRig.Name, bodyPart or "unknown"))
end

-- Get damage multiplier for body part
function DamageSystemServer.getBodyPartMultiplier(bodyPart)
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

-- Initialize the system
setupRemoteEvents()
initializeTestRigs()

print("Damage System Server initialized with test rigs")