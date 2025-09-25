local StatusEffectsSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer

-- Status effect configurations
local STATUS_EFFECTS = {
	Bleeding = {
		Name = "Bleeding",
		Type = "DOT", -- Damage Over Time
		DamagePerTick = 2,
		TickInterval = 1.0,
		Duration = 15,
		Color = Color3.fromRGB(150, 0, 0),
		Icon = "rbxassetid://0", -- Blood drop icon
		Description = "Taking damage over time",
		StackLimit = 3,
		RemovalItems = {"Bandage", "MedKit"}
	},
	
	Fracture = {
		Name = "Fracture",
		Type = "Movement",
		SpeedReduction = 0.4, -- 40% speed reduction
		Duration = 20,
		Color = Color3.fromRGB(139, 69, 19),
		Icon = "rbxassetid://0", -- Bone fracture icon
		Description = "Reduced movement speed",
		BloodTrail = true,
		RemovalItems = {"Tourniquet", "MedKit"}
	},
	
	Blinded = {
		Name = "Blinded",
		Type = "Vision",
		Duration = 5,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "rbxassetid://0", -- Eye icon
		Description = "Vision severely impaired",
		IntensityFalloff = true
	},
	
	Deafened = {
		Name = "Deafened",
		Type = "Audio",
		Duration = 8,
		Color = Color3.fromRGB(100, 100, 100),
		Icon = "rbxassetid://0", -- Ear icon
		Description = "Hearing impaired",
		RingingSound = true
	},
	
	Burning = {
		Name = "Burning",
		Type = "DOT",
		DamagePerTick = 3,
		TickInterval = 0.5,
		Duration = 10,
		Color = Color3.fromRGB(255, 100, 0),
		Icon = "rbxassetid://0", -- Fire icon
		Description = "Burning from incendiary rounds",
		VisualEffect = "Fire",
		StackLimit = 2
	},
	
	Frozen = {
		Name = "Frozen",
		Type = "Movement",
		SpeedReduction = 0.8, -- 80% speed reduction
		Duration = 8,
		Color = Color3.fromRGB(0, 191, 255),
		Icon = "rbxassetid://0", -- Ice icon
		Description = "Movement severely slowed",
		VisualEffect = "Ice",
		CanFreeze = true -- Can completely freeze player
	},
	
	Poisoned = {
		Name = "Poisoned",
		Type = "DOT",
		DamagePerTick = 1,
		TickInterval = 1.5,
		Duration = 30,
		Color = Color3.fromRGB(0, 255, 0),
		Icon = "rbxassetid://0", -- Skull icon
		Description = "Poisoned",
		VisionDistortion = true
	},
	
	Stunned = {
		Name = "Stunned",
		Type = "Control",
		Duration = 3,
		Color = Color3.fromRGB(255, 255, 0),
		Icon = "rbxassetid://0", -- Star icon
		Description = "Unable to move or act",
		DisableInput = true
	},
	
	Suppressed = {
		Name = "Suppressed",
		Type = "Mental",
		Duration = 5,
		Color = Color3.fromRGB(128, 128, 128),
		Icon = "rbxassetid://0", -- Warning icon
		Description = "Accuracy reduced by suppressive fire",
		AccuracyReduction = 0.3
	},
	
	Adrenaline = {
		Name = "Adrenaline",
		Type = "Buff",
		Duration = 12,
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "rbxassetid://0", -- Lightning icon
		Description = "Increased speed and reduced pain",
		SpeedBoost = 1.3,
		DamageResistance = 0.2
	}
}

local activeEffects = {}
local effectGUI = nil

function StatusEffectsSystem:Initialize()
	RemoteEventsManager:Initialize()
	
	self:CreateStatusEffectGUI()
	
	-- Listen for status effect events
	local statusEffectAppliedEvent = RemoteEventsManager:GetEvent("StatusEffectApplied")
	if statusEffectAppliedEvent then
		statusEffectAppliedEvent.OnClientEvent:Connect(function(effectData)
			self:ApplyStatusEffect(effectData)
		end)
	end
	
	local statusEffectRemovedEvent = RemoteEventsManager:GetEvent("StatusEffectRemoved")
	if statusEffectRemovedEvent then
		statusEffectRemovedEvent.OnClientEvent:Connect(function(effectData)
			self:RemoveStatusEffect(effectData.EffectName)
		end)
	end
	
	-- Update active effects
	RunService.Heartbeat:Connect(function()
		self:UpdateStatusEffects()
	end)
	
	print("StatusEffectsSystem initialized")
end

function StatusEffectsSystem:CreateStatusEffectGUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	effectGUI = Instance.new("ScreenGui")
	effectGUI.Name = "StatusEffectsGUI"
	effectGUI.ResetOnSpawn = false
	effectGUI.Parent = playerGui
	
	-- Effects container
	local effectsFrame = Instance.new("Frame")
	effectsFrame.Name = "EffectsFrame"
	effectsFrame.Size = UDim2.new(0, 400, 0, 100)
	effectsFrame.Position = UDim2.new(0, 20, 0.5, -50)
	effectsFrame.BackgroundTransparency = 1
	effectsFrame.Parent = effectGUI
	
	local effectsLayout = Instance.new("UIListLayout")
	effectsLayout.FillDirection = Enum.FillDirection.Vertical
	effectsLayout.Padding = UDim.new(0, 5)
	effectsLayout.Parent = effectsFrame
end

function StatusEffectsSystem:ApplyStatusEffect(effectData)
	local effectName = effectData.EffectName
	local duration = effectData.Duration
	local intensity = effectData.Intensity or 1
	local source = effectData.Source
	
	local effectConfig = STATUS_EFFECTS[effectName]
	if not effectConfig then
		warn("Unknown status effect: " .. effectName)
		return
	end
	
	-- Handle stacking
	if activeEffects[effectName] then
		if effectConfig.StackLimit and activeEffects[effectName].Stacks then
			if activeEffects[effectName].Stacks < effectConfig.StackLimit then
				activeEffects[effectName].Stacks = activeEffects[effectName].Stacks + 1
			end
		end
		-- Refresh duration
		activeEffects[effectName].StartTime = tick()
		activeEffects[effectName].Duration = duration
	else
		-- New effect
		activeEffects[effectName] = {
			Config = effectConfig,
			StartTime = tick(),
			Duration = duration,
			Intensity = intensity,
			Source = source,
			Stacks = 1,
			LastTickTime = tick()
		}
		
		self:StartStatusEffectVisuals(effectName)
	end
	
	self:UpdateStatusEffectGUI()
	
	print("Applied status effect: " .. effectName .. " for " .. duration .. "s")
end

function StatusEffectsSystem:RemoveStatusEffect(effectName)
	if not activeEffects[effectName] then return end
	
	self:EndStatusEffectVisuals(effectName)
	activeEffects[effectName] = nil
	
	self:UpdateStatusEffectGUI()
	
	print("Removed status effect: " .. effectName)
end

function StatusEffectsSystem:StartStatusEffectVisuals(effectName)
	local effectData = activeEffects[effectName]
	local config = effectData.Config
	
	if config.Type == "Vision" and config.Name == "Blinded" then
		self:CreateBlindEffect(effectData)
	elseif config.Type == "Audio" and config.RingingSound then
		self:CreateRingingEffect(effectData)
	elseif config.VisualEffect == "Fire" then
		self:CreateBurningEffect(effectData)
	elseif config.VisualEffect == "Ice" then
		self:CreateFreezeEffect(effectData)
	elseif config.VisionDistortion then
		self:CreateVisionDistortion(effectData)
	end
	
	-- Blood trail for fractures
	if config.BloodTrail then
		self:StartBloodTrail(effectData)
	end
end

function StatusEffectsSystem:CreateBlindEffect(effectData)
	local playerGui = player:WaitForChild("PlayerGui")
	
	local blindGui = Instance.new("ScreenGui")
	blindGui.Name = "BlindEffect"
	blindGui.Parent = playerGui
	
	local blindFrame = Instance.new("Frame")
	blindFrame.Size = UDim2.new(1, 0, 1, 0)
	blindFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	blindFrame.BackgroundTransparency = 0
	blindFrame.Parent = blindGui
	
	-- Fade out effect over time
	if effectData.Config.IntensityFalloff then
		spawn(function()
			local duration = effectData.Duration
			for i = 0, duration * 10 do
				if not activeEffects["Blinded"] then break end
				
				local progress = i / (duration * 10)
				blindFrame.BackgroundTransparency = progress
				wait(0.1)
			end
			if blindGui.Parent then
				blindGui:Destroy()
			end
		end)
	end
	
	effectData.VisualElement = blindGui
end

function StatusEffectsSystem:CreateRingingEffect(effectData)
	local character = player.Character
	if not character then return end
	
	local ringingSound = Instance.new("Sound")
	ringingSound.Name = "RingingEffect"
    ringingSound.SoundId = "rbxassetid://9069161602" -- Ringing sound
	ringingSound.Volume = 0.3
	ringingSound.Looped = true
	ringingSound.Parent = character:FindFirstChild("Head") or character
	ringingSound:Play()
	
	effectData.SoundElement = ringingSound
	
	-- Reduce other sound volumes
	local originalVolumes = {}
	for _, sound in pairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") and sound ~= ringingSound then
			originalVolumes[sound] = sound.Volume
			sound.Volume = sound.Volume * 0.3
		end
	end
	effectData.OriginalVolumes = originalVolumes
end

function StatusEffectsSystem:CreateBurningEffect(effectData)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Fire particles
	local fireEffect = Instance.new("ParticleEmitter")
	fireEffect.Name = "BurningEffect"
	fireEffect.Texture = "rbxassetid://0" -- Fire texture
	fireEffect.Lifetime = NumberRange.new(0.3, 1.2)
	fireEffect.Rate = 50
	fireEffect.Speed = NumberRange.new(5, 15)
	fireEffect.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0))
	}
	fireEffect.Size = NumberSequence.new(0.8)
	fireEffect.Parent = humanoidRootPart
	
	effectData.ParticleElement = fireEffect
end

function StatusEffectsSystem:CreateFreezeEffect(effectData)
	local character = player.Character
	if not character then return end
	
	-- Ice particles
	local iceEffect = Instance.new("ParticleEmitter")
	iceEffect.Name = "FreezeEffect"
	iceEffect.Texture = "rbxassetid://0" -- Ice/snow texture
	iceEffect.Lifetime = NumberRange.new(1, 3)
	iceEffect.Rate = 30
	iceEffect.Speed = NumberRange.new(1, 5)
	iceEffect.Color = ColorSequence.new(Color3.fromRGB(173, 216, 230))
	iceEffect.Size = NumberSequence.new(0.5)
	iceEffect.Parent = character:FindFirstChild("HumanoidRootPart")
	
	-- Freeze player completely if frozen enough
	if effectData.Config.CanFreeze and effectData.Stacks and effectData.Stacks >= 3 then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
		effectData.CompletelyFrozen = true
	end
	
	effectData.ParticleElement = iceEffect
end

function StatusEffectsSystem:CreateVisionDistortion(effectData)
	local playerGui = player:WaitForChild("PlayerGui")
	
	local distortionGui = Instance.new("ScreenGui")
	distortionGui.Name = "VisionDistortion"
	distortionGui.Parent = playerGui
	
	local distortionFrame = Instance.new("Frame")
	distortionFrame.Size = UDim2.new(1, 0, 1, 0)
	distortionFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	distortionFrame.BackgroundTransparency = 0.8
	distortionFrame.Parent = distortionGui
	
	-- Pulsing effect
	local pulseTween = TweenService:Create(distortionFrame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.9
	})
	pulseTween:Play()
	
	effectData.VisualElement = distortionGui
	effectData.PulseTween = pulseTween
end

function StatusEffectsSystem:StartBloodTrail(effectData)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Create blood drops periodically
	local bloodTrailConnection
	bloodTrailConnection = RunService.Heartbeat:Connect(function()
		if not activeEffects["Fracture"] then
			bloodTrailConnection:Disconnect()
			return
		end
		
		if math.random() < 0.1 then -- 10% chance per frame
			self:CreateBloodDrop(humanoidRootPart.Position)
		end
	end)
	
	effectData.BloodTrailConnection = bloodTrailConnection
end

function StatusEffectsSystem:CreateBloodDrop(position)
	local bloodDrop = Instance.new("Part")
	bloodDrop.Size = Vector3.new(0.2, 0.1, 0.2)
	bloodDrop.Material = Enum.Material.Neon
	bloodDrop.BrickColor = BrickColor.new("Really red")
	bloodDrop.Shape = Enum.PartType.Cylinder
	bloodDrop.Anchored = true
	bloodDrop.CanCollide = false
	bloodDrop.Position = position - Vector3.new(0, 3, 0)
	bloodDrop.Parent = workspace
	
	-- Fade out over time
	local fadeTween = TweenService:Create(bloodDrop, TweenInfo.new(10), {
		Transparency = 1
	})
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		bloodDrop:Destroy()
	end)
end

function StatusEffectsSystem:EndStatusEffectVisuals(effectName)
	local effectData = activeEffects[effectName]
	if not effectData then return end
	
	-- Clean up visual elements
	if effectData.VisualElement then
		effectData.VisualElement:Destroy()
	end
	
	if effectData.SoundElement then
		effectData.SoundElement:Destroy()
		
		-- Restore original sound volumes
		if effectData.OriginalVolumes then
			for sound, volume in pairs(effectData.OriginalVolumes) do
				if sound.Parent then
					sound.Volume = volume
				end
			end
		end
	end
	
	if effectData.ParticleElement then
		effectData.ParticleElement:Destroy()
	end
	
	if effectData.PulseTween then
		effectData.PulseTween:Cancel()
	end
	
	if effectData.BloodTrailConnection then
		effectData.BloodTrailConnection:Disconnect()
	end
	
	-- Restore movement if frozen
	if effectData.CompletelyFrozen then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
		end
	end
end

function StatusEffectsSystem:UpdateStatusEffects()
	local currentTime = tick()
	
	-- Update each active effect
	for effectName, effectData in pairs(activeEffects) do
		local config = effectData.Config
		
		-- Check if effect expired
		if currentTime - effectData.StartTime >= effectData.Duration then
			self:RemoveStatusEffect(effectName)
		else
		
		-- Handle DOT effects
		if config.Type == "DOT" and config.DamagePerTick then
			if currentTime - effectData.LastTickTime >= config.TickInterval then
				local damage = config.DamagePerTick
				if effectData.Stacks then
					damage = damage * effectData.Stacks
				end
				
				-- Apply damage via server
				RemoteEventsManager:FireServer("StatusEffectDamage", {
					EffectName = effectName,
					Damage = damage,
					Source = effectData.Source
				})
				
				effectData.LastTickTime = currentTime
			end
		end
		
		-- Handle movement speed changes
		if config.Type == "Movement" or config.SpeedBoost then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					local speedMultiplier = 1
					
					if config.SpeedReduction then
						speedMultiplier = speedMultiplier * (1 - config.SpeedReduction)
					end
					
					if config.SpeedBoost then
						speedMultiplier = speedMultiplier * config.SpeedBoost
					end
					
					-- Don't override other movement system changes
					-- MovementSystem is a client script, access it via global
					local movementSystem = _G.MovementSystem 
					if movementSystem and movementSystem.SetMovementSpeedMultiplier then
						movementSystem:SetMovementSpeedMultiplier(speedMultiplier)
					end
				end
			end
		end
		end -- Close the else block
	end
end

function StatusEffectsSystem:UpdateStatusEffectGUI()
	local effectsFrame = effectGUI.EffectsFrame
	
	-- Clear existing effect displays
	for _, child in pairs(effectsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Create displays for active effects
	for effectName, effectData in pairs(activeEffects) do
		local config = effectData.Config
		local timeLeft = math.ceil(effectData.Duration - (tick() - effectData.StartTime))
		
		local effectFrame = Instance.new("Frame")
		effectFrame.Size = UDim2.new(1, 0, 0, 25)
		effectFrame.BackgroundColor3 = config.Color
		effectFrame.BackgroundTransparency = 0.3
		effectFrame.BorderSizePixel = 1
		effectFrame.BorderColor3 = Color3.new(0, 0, 0)
		effectFrame.Parent = effectsFrame
		
		local effectIcon = Instance.new("ImageLabel")
		effectIcon.Size = UDim2.new(0, 20, 0, 20)
		effectIcon.Position = UDim2.new(0, 2, 0, 2)
		effectIcon.Image = config.Icon
		effectIcon.BackgroundTransparency = 1
		effectIcon.Parent = effectFrame
		
		local effectLabel = Instance.new("TextLabel")
		effectLabel.Size = UDim2.new(1, -50, 1, 0)
		effectLabel.Position = UDim2.new(0, 25, 0, 0)
		effectLabel.BackgroundTransparency = 1
		effectLabel.Text = config.Name .. " (" .. timeLeft .. "s)"
		effectLabel.TextColor3 = Color3.new(1, 1, 1)
		effectLabel.TextScaled = true
		effectLabel.Font = Enum.Font.SourceSansBold
		effectLabel.TextStrokeTransparency = 0
		effectLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		effectLabel.Parent = effectFrame
		
		-- Stack indicator
		if effectData.Stacks and effectData.Stacks > 1 then
			local stackLabel = Instance.new("TextLabel")
			stackLabel.Size = UDim2.new(0, 20, 1, 0)
			stackLabel.Position = UDim2.new(1, -22, 0, 0)
			stackLabel.BackgroundTransparency = 1
			stackLabel.Text = "x" .. effectData.Stacks
			stackLabel.TextColor3 = Color3.new(1, 1, 0)
			stackLabel.TextScaled = true
			stackLabel.Font = Enum.Font.SourceSansBold
			stackLabel.Parent = effectFrame
		end
	end
end

function StatusEffectsSystem:HasStatusEffect(effectName)
	return activeEffects[effectName] ~= nil
end

function StatusEffectsSystem:GetStatusEffectStacks(effectName)
	local effect = activeEffects[effectName]
	return effect and effect.Stacks or 0
end

function StatusEffectsSystem:GetActiveEffects()
	return activeEffects
end

return StatusEffectsSystem