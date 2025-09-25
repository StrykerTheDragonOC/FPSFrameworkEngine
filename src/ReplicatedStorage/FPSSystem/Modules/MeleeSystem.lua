local MeleeSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer

-- Melee weapon configurations
local MELEE_CONFIGS = {
	-- One-Handed Blades
	PocketKnife = {
		Name = "Pocket Knife",
		Category = "BladeOneHand",
		Class = "OneHanded",
		Type = "Blade",
		
		Damage = 50,
		BackstabDamage = 200,
		Range = 4,
		AttackSpeed = 1.2,
		MovementSpeedMultiplier = 1.1,
		
		CanBackstab = true,
		HasSpecialAttack = true,
		QuickSwapTime = 0.5,
		SwapKey = "F"
	},
	
	CombatKnife = {
		Name = "Combat Knife",
		Category = "BladeOneHand", 
		Class = "OneHanded",
		Type = "Blade",
		
		Damage = 65,
		BackstabDamage = 200,
		Range = 5,
		AttackSpeed = 1.0,
		MovementSpeedMultiplier = 1.05,
		
		CanBackstab = true,
		HasSpecialAttack = true,
		QuickSwapTime = 0.4
	},
	
	-- One-Handed Blunt
	Hammer = {
		Name = "Hammer",
		Category = "BluntOneHand",
		Class = "OneHanded", 
		Type = "Blunt",
		
		Damage = 75,
		BackstabDamage = 90,
		Range = 6,
		AttackSpeed = 0.8,
		MovementSpeedMultiplier = 0.95,
		
		CanBackstab = false,
		HasSpecialAttack = true,
		MultiHitCapable = true
	},
	
	Baton = {
		Name = "Police Baton",
		Category = "BluntOneHand",
		Class = "OneHanded",
		Type = "Blunt",
		
		Damage = 60,
		BackstabDamage = 70,
		Range = 5.5,
		AttackSpeed = 1.1,
		MovementSpeedMultiplier = 1.0,
		
		CanBackstab = false,
		HasSpecialAttack = true,
		MultiHitCapable = true
	},
	
	-- Two-Handed Blades
	FireAxe = {
		Name = "Fire Axe",
		Category = "BladeTwoHand",
		Class = "TwoHanded",
		Type = "Blade",
		
		Damage = 120,
		BackstabDamage = 180,
		Range = 8,
		AttackSpeed = 0.6,
		MovementSpeedMultiplier = 0.85,
		
		CanBackstab = true,
		HasSpecialAttack = true,
		MultiHitCapable = true
	},
	
	Katana = {
		Name = "Katana",
		Category = "BladeTwoHand",
		Class = "TwoHanded",
		Type = "Blade",
		
		Damage = 100,
		BackstabDamage = 200,
		Range = 7,
		AttackSpeed = 0.8,
		MovementSpeedMultiplier = 0.9,
		
		CanBackstab = true,
		HasSpecialAttack = true,
		SpecialAttackMultiplier = 1.5
	},
	
	-- Two-Handed Blunt
	Sledgehammer = {
		Name = "Sledgehammer",
		Category = "BluntTwoHand",
		Class = "TwoHanded",
		Type = "Blunt",
		
		Damage = 150,
		BackstabDamage = 170,
		Range = 9,
		AttackSpeed = 0.5,
		MovementSpeedMultiplier = 0.75,
		
		CanBackstab = false,
		HasSpecialAttack = true,
		MultiHitCapable = true,
		SpecialAttackMultiplier = 1.8
	},
	
	BaseballBat = {
		Name = "Baseball Bat",
		Category = "BluntTwoHand",
		Class = "TwoHanded",
		Type = "Blunt",
		
		Damage = 85,
		BackstabDamage = 100,
		Range = 7.5,
		AttackSpeed = 0.7,
		MovementSpeedMultiplier = 0.9,
		
		CanBackstab = false,
		HasSpecialAttack = true,
		MultiHitCapable = true
	}
}

local equippedMelee = nil
local isAttacking = false
local lastAttackTime = 0

function MeleeSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	self:SetupInputHandling()
	
	-- Listen for melee events
	local meleeHitEvent = RemoteEventsManager:GetEvent("MeleeHit")
	if meleeHitEvent then
		meleeHitEvent.OnClientEvent:Connect(function(hitData)
			self:HandleMeleeHitEffect(hitData)
		end)
	end
	
	print("MeleeSystem initialized")
end

function MeleeSystem:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.F then
			self:QuickSwapMelee()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and equippedMelee then
			self:PerformSpecialAttack()
		end
	end)
end

function MeleeSystem:QuickSwapMelee()
	local backpack = player.Backpack
	local character = player.Character
	
	if not character then return end
	
	-- Find melee tool
	local meleeTool = nil
	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and self:IsMeleeWeapon(tool.Name) then
			meleeTool = tool
			break
		end
	end
	
	if not meleeTool then
		-- Check if already equipped
		for _, tool in pairs(character:GetChildren()) do
			if tool:IsA("Tool") and self:IsMeleeWeapon(tool.Name) then
				return -- Already equipped
			end
		end
	end
	
	if meleeTool then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:EquipTool(meleeTool)
		end
	end
end

function MeleeSystem:IsMeleeWeapon(weaponName)
	return MELEE_CONFIGS[weaponName] ~= nil
end

function MeleeSystem:OnMeleeEquipped(tool)
	equippedMelee = tool
	local config = MELEE_CONFIGS[tool.Name]
	if not config then return end
	
	-- Apply movement speed modifier
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = humanoid.WalkSpeed * config.MovementSpeedMultiplier
		end
	end
	
	-- Setup attack handling
	tool.Activated:Connect(function()
		self:PerformAttack(false)
	end)
end

function MeleeSystem:OnMeleeUnequipped(tool)
	if equippedMelee == tool then
		local config = MELEE_CONFIGS[tool.Name]
		if config then
			-- Restore movement speed
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = humanoid.WalkSpeed / config.MovementSpeedMultiplier
				end
			end
		end
		equippedMelee = nil
	end
end

function MeleeSystem:PerformAttack(isSpecialAttack)
	if not equippedMelee or isAttacking then return end
	
	local config = MELEE_CONFIGS[equippedMelee.Name]
	if not config then return end
	
	-- Check attack speed cooldown
	local currentTime = tick()
	local timeSinceLastAttack = currentTime - lastAttackTime
	local attackCooldown = 1 / config.AttackSpeed
	
	if timeSinceLastAttack < attackCooldown then return end
	
	isAttacking = true
	lastAttackTime = currentTime
	
	-- Perform raycast attack
	self:PerformMeleeRaycast(config, isSpecialAttack)
	
	-- Attack animation and effects
	self:PlayAttackAnimation(config, isSpecialAttack)
	
	-- Reset attacking flag after animation
	spawn(function()
		wait(0.5)
		isAttacking = false
	end)
end

function MeleeSystem:PerformSpecialAttack()
	if not equippedMelee then return end
	
	local config = MELEE_CONFIGS[equippedMelee.Name]
	if not config or not config.HasSpecialAttack then return end
	
	self:PerformAttack(true)
end

function MeleeSystem:PerformMeleeRaycast(config, isSpecialAttack)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not humanoidRootPart or not head then return end
	
	-- Raycast parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}
	
	-- Multiple raycasts for better hit detection
	local hits = {}
	local centerDirection = humanoidRootPart.CFrame.LookVector
	local upOffset = head.Position - humanoidRootPart.Position
	
	-- Center raycast
	local centerRay = workspace:Raycast(
		head.Position,
		centerDirection * config.Range,
		raycastParams
	)
	if centerRay then 
		table.insert(hits, centerRay) 
	end
	
	-- Side raycasts for wider attacks
	if config.MultiHitCapable then
		local rightDirection = humanoidRootPart.CFrame.RightVector * 0.5 + centerDirection
		local leftDirection = -humanoidRootPart.CFrame.RightVector * 0.5 + centerDirection
		
		local rightRay = workspace:Raycast(head.Position, rightDirection * config.Range, raycastParams)
		local leftRay = workspace:Raycast(head.Position, leftDirection * config.Range, raycastParams)
		
		if rightRay then 
			table.insert(hits, rightRay) 
		end
		if leftRay then 
			table.insert(hits, leftRay) 
		end
	end
	
	-- Process hits
	local hitPlayers = {}
	for _, rayResult in pairs(hits) do
		local hitPart = rayResult.Instance
		local hitCharacter = hitPart.Parent
		
		if hitCharacter:FindFirstChild("Humanoid") then
			local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
			if hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then
				hitPlayers[hitPlayer] = {
					Player = hitPlayer,
					Position = rayResult.Position,
					Normal = rayResult.Normal,
					Distance = rayResult.Distance
				}
			end
		end
	end
	
	-- Send hits to server
	for _, hitData in pairs(hitPlayers) do
		local isBackstab = self:CheckBackstab(hitData.Player, centerDirection)
		
		RemoteEventsManager:FireServer("MeleeAttack", {
			Target = hitData.Player,
			WeaponName = equippedMelee.Name,
			IsSpecialAttack = isSpecialAttack,
			IsBackstab = isBackstab,
			HitPosition = hitData.Position,
			HitNormal = hitData.Normal,
			Distance = hitData.Distance
		})
	end
end

function MeleeSystem:CheckBackstab(targetPlayer, attackDirection)
	if not targetPlayer.Character then return false end
	
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return false end
	
	-- Check if attacking from behind
	local targetForward = targetRoot.CFrame.LookVector
	local angleToTarget = math.acos(attackDirection:Dot(-targetForward))
	
	-- Backstab if within 45 degrees of directly behind
	return angleToTarget < math.rad(45)
end

function MeleeSystem:PlayAttackAnimation(config, isSpecialAttack)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Camera shake effect
	self:CreateCameraShake(isSpecialAttack and 2 or 1)
	
	-- Attack sound effect
	local sound = Instance.new("Sound")
	if config.Type == "Blade" then
		sound.SoundId = "rbxassetid://18512262218" -- Blade slash sound
	else
		sound.SoundId = "rbxassetid://18512262219" -- Blunt impact sound
	end
	sound.Volume = 0.7
	sound.Parent = character:FindFirstChild("Head") or character
	sound:Play()
	sound.Ended:Connect(function() 
		sound:Destroy() 
	end)
	
	-- Visual effect
	if isSpecialAttack then
		self:CreateSpecialAttackEffect()
	end
end

function MeleeSystem:CreateCameraShake(intensity)
	local camera = workspace.CurrentCamera
	local originalCF = camera.CFrame
	
	spawn(function()
		for i = 1, 10 do
			local shake = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity
			)
			camera.CFrame = originalCF + shake
			wait(0.02)
		end
		camera.CFrame = originalCF
	end)
end

function MeleeSystem:CreateSpecialAttackEffect()
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create slash effect
	local effect = Instance.new("Part")
	effect.Size = Vector3.new(0.1, 0.1, 0.1)
	effect.Transparency = 1
	effect.CanCollide = false
	effect.Anchored = true
	effect.Position = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 3
	effect.Parent = workspace
	
	local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxassetid://15788309952" -- Slash particle texture
	particles.Lifetime = NumberRange.new(0.2, 0.5)
	particles.Rate = 200
	particles.Speed = NumberRange.new(10, 30)
	particles.Color = ColorSequence.new(Color3.new(1, 1, 0))
	particles.Parent = effect
	
	-- Cleanup
	spawn(function()
		wait(0.3)
		particles.Enabled = false
		wait(2)
		effect:Destroy()
	end)
end

function MeleeSystem:HandleMeleeHitEffect(hitData)
	-- Create blood effect
	if hitData.Damage > 0 then
		self:CreateBloodEffect(hitData.HitPosition, hitData.HitNormal)
	end
	
	-- Create hit sound
	local sound = Instance.new("Sound")
	if hitData.IsBackstab then
		sound.SoundId = "rbxassetid://8255306220" -- Critical hit sound
	else
		sound.SoundId = "rbxassetid://2331617000" -- Normal hit sound
	end
	sound.Volume = 0.8
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Connect(function() 
		sound:Destroy() 
	end)
end

function MeleeSystem:CreateBloodEffect(position, normal)
	-- Blood particles
	local bloodPart = Instance.new("Part")
	bloodPart.Size = Vector3.new(0.1, 0.1, 0.1)
	bloodPart.Transparency = 1
	bloodPart.CanCollide = false
	bloodPart.Anchored = true
	bloodPart.Position = position
	bloodPart.Parent = workspace
	
	local bloodEmitter = Instance.new("ParticleEmitter")
    bloodEmitter.Texture = "rbxassetid://8635071101" -- Blood texture
	bloodEmitter.Lifetime = NumberRange.new(0.5, 1.5)
	bloodEmitter.Rate = 50
	bloodEmitter.Speed = NumberRange.new(5, 15)
	bloodEmitter.Color = ColorSequence.new(Color3.new(0.7, 0, 0))
	bloodEmitter.Size = NumberSequence.new(0.3)
	bloodEmitter.Parent = bloodPart
	
	-- Cleanup
	spawn(function()
		wait(0.2)
		bloodEmitter.Enabled = false
		wait(3)
		bloodPart:Destroy()
	end)
	
	-- Blood pool on ground
	local raycast = workspace:Raycast(position, Vector3.new(0, -10, 0))
	if raycast then
		local bloodPool = Instance.new("Part")
		bloodPool.Size = Vector3.new(2, 0.1, 2)
		bloodPool.Material = Enum.Material.Neon
		bloodPool.BrickColor = BrickColor.new("Really red")
		bloodPool.Shape = Enum.PartType.Cylinder
		bloodPool.Anchored = true
		bloodPool.CanCollide = false
		bloodPool.Position = raycast.Position + Vector3.new(0, 0.1, 0)
		bloodPool.Parent = workspace
		
		-- Fade out blood pool
		local tween = TweenService:Create(bloodPool, TweenInfo.new(30), {
			Transparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			bloodPool:Destroy()
		end)
	end
end

function MeleeSystem:GetMeleeConfig(weaponName)
	return MELEE_CONFIGS[weaponName]
end

function MeleeSystem:GetAllMeleeConfigs()
	return MELEE_CONFIGS
end

return MeleeSystem