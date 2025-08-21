-- DeathEffectsSystem.lua
-- Enhanced death effects with blood, camera shake, and dramatic visuals
-- Place in ReplicatedStorage/FPSSystem/Modules

local DeathEffectsSystem = {}
DeathEffectsSystem.__index = DeathEffectsSystem

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

-- Death effect configurations
local DEATH_EFFECTS = {
    bloodSplatter = {
        enabled = true,
        intensity = 0.8,
        duration = 5.0,
        fadeTime = 3.0,
        particleCount = 25
    },
    
    cameraShake = {
        enabled = true,
        intensity = 3.0,
        duration = 2.0,
        frequency = 20
    },
    
    screenFlash = {
        enabled = true,
        color = Color3.fromRGB(255, 0, 0),
        intensity = 0.6,
        duration = 0.8
    },
    
    ragdollEffect = {
        enabled = true,
        forceMultiplier = 2.0,
        spinForce = 50
    },
    
    deathSound = {
        enabled = true,
        volume = 0.7,
        pitch = 1.0
    },
    
    slowMotion = {
        enabled = true,
        factor = 0.3,
        duration = 1.5
    }
}

function DeathEffectsSystem.new()
    local self = setmetatable({}, DeathEffectsSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.camera = workspace.CurrentCamera
    
    -- Effect state
    self.isInDeathSequence = false
    self.effectConnections = {}
    self.activeEffects = {}
    
    -- Screen effects GUI
    self.deathEffectsGui = nil
    
    -- Initialize
    self:initialize()
    
    return self
end

-- Initialize the death effects system
function DeathEffectsSystem:initialize()
    print("[DeathEffectsSystem] Initializing enhanced death effects...")
    
    -- Create death effects GUI
    self:createDeathEffectsGui()
    
    -- Setup player death monitoring
    self:setupDeathMonitoring()
    
    print("[DeathEffectsSystem] Death effects system initialized")
end

-- Create death effects GUI container
function DeathEffectsSystem:createDeathEffectsGui()
    local deathGui = Instance.new("ScreenGui")
    deathGui.Name = "DeathEffects"
    deathGui.ResetOnSpawn = false
    deathGui.IgnoreGuiInset = true
    deathGui.DisplayOrder = 1000 -- Very high priority
    deathGui.Parent = self.playerGui
    
    self.deathEffectsGui = deathGui
    
    print("[DeathEffectsSystem] Death effects GUI created")
end

-- Setup death monitoring
function DeathEffectsSystem:setupDeathMonitoring()
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            self:onPlayerDeath(character)
        end)
        
        -- Also monitor health for near-death effects
        humanoid.HealthChanged:Connect(function(health)
            if health <= 10 and health > 0 then
                self:onNearDeath(health)
            end
        end)
    end
    
    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end
    
    self.player.CharacterAdded:Connect(onCharacterAdded)
end

-- Handle player death
function DeathEffectsSystem:onPlayerDeath(character)
    if self.isInDeathSequence then return end
    
    print("[DeathEffectsSystem] Player died - starting death sequence")
    self.isInDeathSequence = true
    
    -- Start death effects sequence
    self:startDeathSequence(character)
    
    -- Reset death sequence after delay
    task.delay(8, function()
        self.isInDeathSequence = false
        self:clearAllDeathEffects()
    end)
end

-- Start comprehensive death sequence
function DeathEffectsSystem:startDeathSequence(character)
    -- Blood splatter effect
    if DEATH_EFFECTS.bloodSplatter.enabled then
        self:createBloodSplatterEffect()
    end
    
    -- Screen flash effect
    if DEATH_EFFECTS.screenFlash.enabled then
        self:createScreenFlashEffect()
    end
    
    -- Camera shake
    if DEATH_EFFECTS.cameraShake.enabled then
        self:startDeathCameraShake()
    end
    
    -- Slow motion effect
    if DEATH_EFFECTS.slowMotion.enabled then
        self:applySlowMotionEffect()
    end
    
    -- Enhanced ragdoll
    if DEATH_EFFECTS.ragdollEffect.enabled then
        self:enhanceRagdollEffect(character)
    end
    
    -- Death sound
    if DEATH_EFFECTS.deathSound.enabled then
        self:playDeathSound()
    end
    
    -- Blood particles
    self:createBloodParticles(character)
    
    -- Screen edge blood effect
    self:createScreenBloodEffect()
    
    -- Death fade effect
    task.delay(3, function()
        self:createDeathFadeEffect()
    end)
end

-- Create blood splatter effect on screen
function DeathEffectsSystem:createBloodSplatterEffect()
    local bloodFrame = Instance.new("Frame")
    bloodFrame.Name = "BloodSplatter"
    bloodFrame.Size = UDim2.new(1, 0, 1, 0)
    bloodFrame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    bloodFrame.BackgroundTransparency = 1
    bloodFrame.BorderSizePixel = 0
    bloodFrame.ZIndex = 10
    bloodFrame.Parent = self.deathEffectsGui
    
    -- Create multiple blood splatter elements
    for i = 1, DEATH_EFFECTS.bloodSplatter.particleCount do
        local splatter = Instance.new("Frame")
        splatter.Name = "BloodSplat" .. i
        splatter.Size = UDim2.new(0, math.random(50, 150), 0, math.random(50, 150))
        splatter.Position = UDim2.new(math.random(), 0, math.random(), 0)
        splatter.BackgroundColor3 = Color3.fromRGB(math.random(100, 180), 0, math.random(0, 30))
        splatter.BackgroundTransparency = math.random(0.3, 0.8)
        splatter.BorderSizePixel = 0
        splatter.ZIndex = 11
        splatter.Rotation = math.random(0, 360)
        splatter.Parent = bloodFrame
        
        -- Random blood splatter shape
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, math.random(5, 25))
        corner.Parent = splatter
        
        -- Animate splatter appearance
        splatter.Size = UDim2.new(0, 0, 0, 0)
        local growTween = TweenService:Create(splatter,
            TweenInfo.new(0.3 + math.random() * 0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, math.random(50, 150), 0, math.random(50, 150))}
        )
        growTween:Play()
    end
    
    -- Fade out blood splatter
    task.delay(DEATH_EFFECTS.bloodSplatter.duration - DEATH_EFFECTS.bloodSplatter.fadeTime, function()
        local fadeTween = TweenService:Create(bloodFrame,
            TweenInfo.new(DEATH_EFFECTS.bloodSplatter.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        fadeTween:Play()
        
        -- Fade all splatter elements
        for _, child in pairs(bloodFrame:GetChildren()) do
            if child:IsA("Frame") then
                TweenService:Create(child,
                    TweenInfo.new(DEATH_EFFECTS.bloodSplatter.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1}
                ):Play()
            end
        end
        
        task.delay(DEATH_EFFECTS.bloodSplatter.fadeTime, function()
            bloodFrame:Destroy()
        end)
    end)
    
    table.insert(self.activeEffects, bloodFrame)
end

-- Create screen flash effect
function DeathEffectsSystem:createScreenFlashEffect()
    local flashFrame = Instance.new("Frame")
    flashFrame.Name = "DeathFlash"
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.BackgroundColor3 = DEATH_EFFECTS.screenFlash.color
    flashFrame.BackgroundTransparency = 1
    flashFrame.BorderSizePixel = 0
    flashFrame.ZIndex = 15
    flashFrame.Parent = self.deathEffectsGui
    
    -- Flash effect
    local flashTween1 = TweenService:Create(flashFrame,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1 - DEATH_EFFECTS.screenFlash.intensity}
    )
    flashTween1:Play()
    
    flashTween1.Completed:Connect(function()
        local flashTween2 = TweenService:Create(flashFrame,
            TweenInfo.new(DEATH_EFFECTS.screenFlash.duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        flashTween2:Play()
        
        flashTween2.Completed:Connect(function()
            flashFrame:Destroy()
        end)
    end)
    
    table.insert(self.activeEffects, flashFrame)
end

-- Start death camera shake
function DeathEffectsSystem:startDeathCameraShake()
    local originalCFrame = self.camera.CFrame
    local shakeIntensity = DEATH_EFFECTS.cameraShake.intensity
    local shakeFrequency = DEATH_EFFECTS.cameraShake.frequency
    local startTime = tick()
    
    local shakeConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= DEATH_EFFECTS.cameraShake.duration then
            return
        end
        
        -- Decrease intensity over time
        local currentIntensity = shakeIntensity * (1 - elapsed / DEATH_EFFECTS.cameraShake.duration)
        
        -- Apply random camera offset
        local shakeOffset = Vector3.new(
            (math.noise(elapsed * shakeFrequency, 0, 0) - 0.5) * currentIntensity,
            (math.noise(0, elapsed * shakeFrequency, 0) - 0.5) * currentIntensity,
            (math.noise(0, 0, elapsed * shakeFrequency) - 0.5) * currentIntensity
        )
        
        self.camera.CFrame = originalCFrame + shakeOffset
    end)
    
    self.effectConnections["deathShake"] = shakeConnection
    
    -- Stop shake after duration
    task.delay(DEATH_EFFECTS.cameraShake.duration, function()
        if self.effectConnections["deathShake"] then
            self.effectConnections["deathShake"]:Disconnect()
            self.effectConnections["deathShake"] = nil
        end
    end)
end

-- Apply slow motion effect
function DeathEffectsSystem:applySlowMotionEffect()
    -- Create a slow motion visual effect
    local slowMotionFrame = Instance.new("Frame")
    slowMotionFrame.Name = "SlowMotionEffect"
    slowMotionFrame.Size = UDim2.new(1, 0, 1, 0)
    slowMotionFrame.BackgroundTransparency = 1
    slowMotionFrame.BorderSizePixel = 0
    slowMotionFrame.ZIndex = 5
    slowMotionFrame.Parent = self.deathEffectsGui
    
    -- Create motion blur lines
    for i = 1, 15 do
        local blurLine = Instance.new("Frame")
        blurLine.Size = UDim2.new(0, math.random(100, 300), 0, math.random(2, 6))
        blurLine.Position = UDim2.new(math.random(), 0, math.random(), 0)
        blurLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        blurLine.BackgroundTransparency = 0.8
        blurLine.BorderSizePixel = 0
        blurLine.Rotation = math.random(-45, 45)
        blurLine.Parent = slowMotionFrame
        
        -- Animate motion lines
        task.spawn(function()
            while slowMotionFrame.Parent do
                local moveTween = TweenService:Create(blurLine,
                    TweenInfo.new(0.5, Enum.EasingStyle.Linear),
                    {Position = UDim2.new(math.random(), 0, math.random(), 0)}
                )
                moveTween:Play()
                moveTween.Completed:Wait()
            end
        end)
    end
    
    -- Remove slow motion effect after duration
    task.delay(DEATH_EFFECTS.slowMotion.duration, function()
        local fadeTween = TweenService:Create(slowMotionFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            slowMotionFrame:Destroy()
        end)
    end)
    
    table.insert(self.activeEffects, slowMotionFrame)
end

-- Enhance ragdoll effect
function DeathEffectsSystem:enhanceRagdollEffect(character)
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Add dramatic force to ragdoll
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(
        math.random(-50, 50) * DEATH_EFFECTS.ragdollEffect.forceMultiplier,
        math.random(10, 30) * DEATH_EFFECTS.ragdollEffect.forceMultiplier,
        math.random(-50, 50) * DEATH_EFFECTS.ragdollEffect.forceMultiplier
    )
    bodyVelocity.Parent = humanoidRootPart
    
    -- Add spin force
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, DEATH_EFFECTS.ragdollEffect.spinForce, 0)
    bodyAngularVelocity.Parent = humanoidRootPart
    
    -- Clean up forces after short time
    Debris:AddItem(bodyVelocity, 0.5)
    Debris:AddItem(bodyAngularVelocity, 1.0)
end

-- Play death sound
function DeathEffectsSystem:playDeathSound()
    local deathSound = Instance.new("Sound")
    deathSound.Name = "DeathSound"
    deathSound.SoundId = "rbxasset://sounds/impact_heavy.mp3" -- Placeholder sound
    deathSound.Volume = DEATH_EFFECTS.deathSound.volume
    deathSound.Pitch = DEATH_EFFECTS.deathSound.pitch
    deathSound.Parent = SoundService
    deathSound:Play()
    
    deathSound.Ended:Connect(function()
        deathSound:Destroy()
    end)
end

-- Create blood particles in 3D space
function DeathEffectsSystem:createBloodParticles(character)
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create blood particle effect
    for i = 1, 20 do
        local bloodParticle = Instance.new("Part")
        bloodParticle.Name = "BloodParticle"
        bloodParticle.Size = Vector3.new(0.2, 0.2, 0.2)
        bloodParticle.Material = Enum.Material.Neon
        bloodParticle.BrickColor = BrickColor.new("Really red")
        bloodParticle.CanCollide = false
        bloodParticle.Anchored = false
        bloodParticle.Position = humanoidRootPart.Position + Vector3.new(
            math.random(-2, 2),
            math.random(0, 3),
            math.random(-2, 2)
        )
        bloodParticle.Parent = workspace
        
        -- Add velocity to particles
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(
            math.random(-20, 20),
            math.random(5, 25),
            math.random(-20, 20)
        )
        bodyVelocity.Parent = bloodParticle
        
        -- Fade out particle
        task.spawn(function()
            task.wait(math.random(1, 3))
            local fadeTween = TweenService:Create(bloodParticle,
                TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 1}
            )
            fadeTween:Play()
            
            fadeTween.Completed:Connect(function()
                bloodParticle:Destroy()
            end)
        end)
        
        -- Clean up velocity after short time
        Debris:AddItem(bodyVelocity, 0.5)
        Debris:AddItem(bloodParticle, 5)
    end
end

-- Create screen edge blood effect
function DeathEffectsSystem:createScreenBloodEffect()
    local bloodEdgeFrame = Instance.new("Frame")
    bloodEdgeFrame.Name = "BloodEdgeEffect"
    bloodEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
    bloodEdgeFrame.BackgroundTransparency = 1
    bloodEdgeFrame.BorderSizePixel = 0
    bloodEdgeFrame.ZIndex = 8
    bloodEdgeFrame.Parent = self.deathEffectsGui
    
    -- Create blood vignette effect
    local bloodVignette = Instance.new("ImageLabel")
    bloodVignette.Name = "BloodVignette"
    bloodVignette.Size = UDim2.new(1, 0, 1, 0)
    bloodVignette.BackgroundTransparency = 1
    bloodVignette.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Would be blood texture
    bloodVignette.ImageColor3 = Color3.fromRGB(150, 0, 0)
    bloodVignette.ImageTransparency = 1
    bloodVignette.ZIndex = 9
    bloodVignette.Parent = bloodEdgeFrame
    
    -- Animate blood vignette
    local vignetteTween = TweenService:Create(bloodVignette,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {ImageTransparency = 0.4}
    )
    vignetteTween:Play()
    
    -- Fade out after delay
    task.delay(4, function()
        local fadeOutTween = TweenService:Create(bloodVignette,
            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {ImageTransparency = 1}
        )
        fadeOutTween:Play()
        
        fadeOutTween.Completed:Connect(function()
            bloodEdgeFrame:Destroy()
        end)
    end)
    
    table.insert(self.activeEffects, bloodEdgeFrame)
end

-- Create death fade effect
function DeathEffectsSystem:createDeathFadeEffect()
    local fadeFrame = Instance.new("Frame")
    fadeFrame.Name = "DeathFade"
    fadeFrame.Size = UDim2.new(1, 0, 1, 0)
    fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fadeFrame.BackgroundTransparency = 1
    fadeFrame.BorderSizePixel = 0
    fadeFrame.ZIndex = 20
    fadeFrame.Parent = self.deathEffectsGui
    
    -- Fade to black
    local fadeTween = TweenService:Create(fadeFrame,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.2}
    )
    fadeTween:Play()
    
    -- Add "You Died" text
    task.delay(1, function()
        local deathText = Instance.new("TextLabel")
        deathText.Name = "DeathText"
        deathText.Size = UDim2.new(0.6, 0, 0.2, 0)
        deathText.Position = UDim2.new(0.2, 0, 0.4, 0)
        deathText.BackgroundTransparency = 1
        deathText.Text = "K.I.A."
        deathText.TextColor3 = Color3.fromRGB(255, 0, 0)
        deathText.TextScaled = true
        deathText.Font = Enum.Font.GothamBold
        deathText.TextStrokeTransparency = 0.5
        deathText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        deathText.TextTransparency = 1
        deathText.ZIndex = 21
        deathText.Parent = fadeFrame
        
        -- Animate death text
        local textTween = TweenService:Create(deathText,
            TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        textTween:Play()
    end)
    
    table.insert(self.activeEffects, fadeFrame)
end

-- Handle near-death effects
function DeathEffectsSystem:onNearDeath(health)
    -- Create pulse effect for very low health
    if health <= 5 then
        self:createLowHealthPulse()
    end
end

-- Create low health pulse effect
function DeathEffectsSystem:createLowHealthPulse()
    if self.activeEffects["lowHealthPulse"] then return end
    
    local pulseFrame = Instance.new("Frame")
    pulseFrame.Name = "LowHealthPulse"
    pulseFrame.Size = UDim2.new(1, 0, 1, 0)
    pulseFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    pulseFrame.BackgroundTransparency = 1
    pulseFrame.BorderSizePixel = 0
    pulseFrame.ZIndex = 3
    pulseFrame.Parent = self.deathEffectsGui
    
    self.activeEffects["lowHealthPulse"] = pulseFrame
    
    -- Pulse effect
    task.spawn(function()
        while pulseFrame.Parent and self.player.Character and self.player.Character.Humanoid.Health <= 10 and self.player.Character.Humanoid.Health > 0 do
            local pulseTween = TweenService:Create(pulseFrame,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundTransparency = 0.7}
            )
            pulseTween:Play()
            pulseTween.Completed:Wait()
            
            local pulseTween2 = TweenService:Create(pulseFrame,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundTransparency = 1}
            )
            pulseTween2:Play()
            pulseTween2.Completed:Wait()
        end
        
        pulseFrame:Destroy()
        self.activeEffects["lowHealthPulse"] = nil
    end)
end

-- Clear all active death effects
function DeathEffectsSystem:clearAllDeathEffects()
    print("[DeathEffectsSystem] Clearing all death effects")
    
    -- Disconnect all effect connections
    for name, connection in pairs(self.effectConnections) do
        connection:Disconnect()
    end
    self.effectConnections = {}
    
    -- Destroy all active effects
    for _, effect in pairs(self.activeEffects) do
        if typeof(effect) == "Instance" and effect.Parent then
            effect:Destroy()
        end
    end
    self.activeEffects = {}
end

-- Cleanup
function DeathEffectsSystem:cleanup()
    print("[DeathEffectsSystem] Cleaning up death effects system...")
    
    self:clearAllDeathEffects()
    
    if self.deathEffectsGui then
        self.deathEffectsGui:Destroy()
    end
    
    print("[DeathEffectsSystem] Death effects cleanup complete")
end

return DeathEffectsSystem