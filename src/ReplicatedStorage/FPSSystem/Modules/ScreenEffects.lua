-- ScreenEffects.lua
-- Advanced screen effects system for blood, flashbang, explosions, etc.
-- Place in ReplicatedStorage/FPSSystem/Modules

local ScreenEffects = {}
ScreenEffects.__index = ScreenEffects

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Screen effect configurations
local EFFECT_CONFIGS = {
    blood = {
        color = Color3.fromRGB(150, 0, 0),
        intensity = 0.6,
        duration = 3.0,
        fadeTime = 2.0,
        pulseEffect = true,
        edgeVignette = true
    },

    flashbang = {
        color = Color3.fromRGB(255, 255, 255),
        intensity = 1.0,
        duration = 5.0,
        fadeTime = 4.0,
        pulseEffect = false,
        blindEffect = true,
        audioMuffle = true
    },

    explosion = {
        color = Color3.fromRGB(255, 150, 0),
        intensity = 0.8,
        duration = 2.0,
        fadeTime = 1.5,
        pulseEffect = true,
        shakeEffect = true
    },

    lowHealth = {
        color = Color3.fromRGB(200, 0, 0),
        intensity = 0.4,
        duration = -1, -- Persistent until health improves
        fadeTime = 0.5,
        pulseEffect = true,
        heartbeat = true
    },

    smoke = {
        color = Color3.fromRGB(100, 100, 100),
        intensity = 0.7,
        duration = 10.0,
        fadeTime = 3.0,
        pulseEffect = false,
        particleEffect = true
    },

    nightVision = {
        color = Color3.fromRGB(0, 255, 0),
        intensity = 0.3,
        duration = -1, -- Persistent until disabled
        fadeTime = 0.2,
        pulseEffect = false,
        edgeVignette = true,
        scanLines = true
    }
}

function ScreenEffects.new()
    local self = setmetatable({}, ScreenEffects)

    -- Core references
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")

    -- Effect management
    self.activeEffects = {}
    self.effectGuis = {}
    self.effectConnections = {}

    -- Screen shake
    self.camera = workspace.CurrentCamera
    self.originalCameraCFrame = nil
    self.shakeIntensity = 0
    self.shakeConnection = nil

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the screen effects system
function ScreenEffects:initialize()
    print("[ScreenEffects] Initializing screen effects system...")

    -- Create main effects GUI
    self:createEffectsGui()

    -- Setup health monitoring for low health effects
    self:setupHealthMonitoring()

    print("[ScreenEffects] Screen effects system initialized")
end

-- Create the main effects GUI container
function ScreenEffects:createEffectsGui()
    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScreenEffects"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999 -- High priority overlay
    screenGui.Parent = self.playerGui

    self.mainGui = screenGui

    print("[ScreenEffects] Main effects GUI created")
end

-- Apply a screen effect
function ScreenEffects:applyEffect(effectType, customIntensity, customDuration)
    local config = EFFECT_CONFIGS[effectType]
    if not config then
        warn("[ScreenEffects] Unknown effect type:", effectType)
        return false
    end

    print("[ScreenEffects] Applying effect:", effectType, "Intensity:", customIntensity or config.intensity)

    -- Use custom values if provided
    local intensity = customIntensity or config.intensity
    local duration = customDuration or config.duration

    -- Stop existing effect of same type
    self:stopEffect(effectType)

    -- Create effect GUI
    local effectFrame = self:createEffectFrame(effectType, config, intensity)
    if not effectFrame then return false end

    -- Store effect data
    local effectData = {
        type = effectType,
        config = config,
        intensity = intensity,
        duration = duration,
        startTime = tick(),
        frame = effectFrame,
        active = true
    }

    self.activeEffects[effectType] = effectData

    -- Start effect animation
    self:startEffectAnimation(effectData)

    -- Handle special effects
    if config.shakeEffect then
        self:startCameraShake(intensity)
    end

    if config.audioMuffle then
        self:applyAudioMuffle(intensity, duration)
    end

    -- Auto-remove effect after duration (if not persistent)
    if duration > 0 then
        task.delay(duration, function()
            self:stopEffect(effectType)
        end)
    end

    return true
end

-- Create effect frame GUI
function ScreenEffects:createEffectFrame(effectType, config, intensity)
    local frame = Instance.new("Frame")
    frame.Name = "Effect_" .. effectType
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = config.color
    frame.BackgroundTransparency = 1 - intensity
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = self.mainGui

    -- Add vignette effect if specified
    if config.edgeVignette then
        self:addVignetteEffect(frame, config.color)
    end

    -- Add scan lines for night vision
    if config.scanLines then
        self:addScanLines(frame)
    end

    -- Add particle effects for smoke
    if config.particleEffect then
        self:addParticleEffect(frame, config.color)
    end

    return frame
end

-- Add vignette (edge darkening) effect
function ScreenEffects:addVignetteEffect(frame, color)
    local vignette = Instance.new("ImageLabel")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- You'd want a proper vignette texture
    vignette.ImageColor3 = color
    vignette.ImageTransparency = 0.3
    vignette.ZIndex = 11
    vignette.Parent = frame

    return vignette
end

-- Add scan lines for night vision effect
function ScreenEffects:addScanLines(frame)
    for i = 1, 20 do
        local line = Instance.new("Frame")
        line.Name = "ScanLine_" .. i
        line.Size = UDim2.new(1, 0, 0, 2)
        line.Position = UDim2.new(0, 0, i / 20, 0)
        line.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        line.BackgroundTransparency = 0.8
        line.BorderSizePixel = 0
        line.ZIndex = 12
        line.Parent = frame

        -- Animate scan lines
        local tween = TweenService:Create(line, 
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {BackgroundTransparency = 0.95}
        )
        tween:Play()
    end
end

-- Add particle effect for smoke
function ScreenEffects:addParticleEffect(frame, color)
    -- Create multiple small particles
    for i = 1, 15 do
        local particle = Instance.new("Frame")
        particle.Name = "Particle_" .. i
        particle.Size = UDim2.new(0, math.random(20, 60), 0, math.random(20, 60))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = color
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.ZIndex = 11
        particle.Parent = frame

        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle

        -- Animate particles
        local tween = TweenService:Create(particle,
            TweenInfo.new(math.random(3, 8), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
            {
                Position = UDim2.new(math.random(), 0, math.random(), 0),
                BackgroundTransparency = 0.9
            }
        )
        tween:Play()
    end
end

-- Start effect animation (pulsing, fading, etc.)
function ScreenEffects:startEffectAnimation(effectData)
    local config = effectData.config
    local frame = effectData.frame

    -- Pulse effect
    if config.pulseEffect then
        local pulseConnection = RunService.Heartbeat:Connect(function()
            if not effectData.active then return end

            local time = tick() - effectData.startTime
            local pulseIntensity = 0.5 + 0.5 * math.sin(time * 3) -- 3 Hz pulse

            if config.heartbeat then
                -- Heartbeat pattern (faster pulse for low health)
                pulseIntensity = 0.3 + 0.7 * math.sin(time * 5)
            end

            frame.BackgroundTransparency = 1 - (effectData.intensity * pulseIntensity)
        end)

        self.effectConnections[effectData.type .. "_pulse"] = pulseConnection
    end

    -- Fade out animation
    if effectData.duration > 0 then
        local fadeDelay = effectData.duration - config.fadeTime

        task.delay(fadeDelay, function()
            if effectData.active then
                local fadeTween = TweenService:Create(frame,
                    TweenInfo.new(config.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1}
                )
                fadeTween:Play()

                -- Fade vignette if present
                local vignette = frame:FindFirstChild("Vignette")
                if vignette then
                    TweenService:Create(vignette,
                        TweenInfo.new(config.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {ImageTransparency = 1}
                    ):Play()
                end
            end
        end)
    end
end

-- Stop a specific effect
function ScreenEffects:stopEffect(effectType)
    local effectData = self.activeEffects[effectType]
    if not effectData then return end

    print("[ScreenEffects] Stopping effect:", effectType)

    effectData.active = false

    -- Destroy effect GUI
    if effectData.frame then
        effectData.frame:Destroy()
    end

    -- Disconnect effect connections
    local pulseConnection = self.effectConnections[effectType .. "_pulse"]
    if pulseConnection then
        pulseConnection:Disconnect()
        self.effectConnections[effectType .. "_pulse"] = nil
    end

    -- Remove from active effects
    self.activeEffects[effectType] = nil

    -- Stop camera shake if it was from this effect
    if effectData.config.shakeEffect then
        self:stopCameraShake()
    end
end

-- Start camera shake
function ScreenEffects:startCameraShake(intensity)
    if self.shakeConnection then
        self.shakeConnection:Disconnect()
    end

    self.shakeIntensity = intensity
    self.originalCameraCFrame = self.camera.CFrame

    self.shakeConnection = RunService.Heartbeat:Connect(function()
        if self.shakeIntensity <= 0 then return end

        -- Apply random camera offset
        local shakeOffset = Vector3.new(
            (math.random() - 0.5) * self.shakeIntensity * 2,
            (math.random() - 0.5) * self.shakeIntensity * 2,
            (math.random() - 0.5) * self.shakeIntensity * 2
        )

        self.camera.CFrame = self.camera.CFrame + shakeOffset

        -- Gradually reduce shake intensity
        self.shakeIntensity = self.shakeIntensity * 0.95

        if self.shakeIntensity < 0.01 then
            self:stopCameraShake()
        end
    end)
end

-- Stop camera shake
function ScreenEffects:stopCameraShake()
    if self.shakeConnection then
        self.shakeConnection:Disconnect()
        self.shakeConnection = nil
    end

    self.shakeIntensity = 0
end

-- Apply audio muffling effect
function ScreenEffects:applyAudioMuffle(intensity, duration)
    -- Reduce all sound volumes temporarily
    local soundService = game:GetService("SoundService")
    local originalVolume = soundService.AmbientReverb

    -- Muffle sound
    soundService.AmbientReverb = Enum.ReverbType.UnderWater

    -- Restore after duration
    task.delay(duration, function()
        soundService.AmbientReverb = originalVolume
    end)
end

-- Setup health monitoring for low health effects
function ScreenEffects:setupHealthMonitoring()
    local function checkHealth()
        local character = self.player.Character
        if not character then return end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local healthPercent = humanoid.Health / humanoid.MaxHealth

        -- Apply low health effect when below 30%
        if healthPercent < 0.3 and not self.activeEffects.lowHealth then
            local intensity = 1 - healthPercent -- More intense as health gets lower
            self:applyEffect("lowHealth", intensity, -1) -- Persistent
        elseif healthPercent >= 0.3 and self.activeEffects.lowHealth then
            self:stopEffect("lowHealth")
        end
    end

    -- Check health every second
    RunService.Heartbeat:Connect(function()
        checkHealth()
    end)

    -- Handle character respawn
    self.player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to fully load
        checkHealth()
    end)
end

-- Quick effect functions for common use cases
function ScreenEffects:takeDamage(damage)
    local intensity = math.min(damage / 100, 0.8) -- Max 80% intensity
    self:applyEffect("blood", intensity, 2.0)
end

function ScreenEffects:flashbanged(intensity, duration)
    self:applyEffect("flashbang", intensity or 1.0, duration or 5.0)
end

function ScreenEffects:explosion(intensity, duration)
    self:applyEffect("explosion", intensity or 0.8, duration or 2.0)
end

function ScreenEffects:enterSmoke(intensity, duration)
    self:applyEffect("smoke", intensity or 0.7, duration or 10.0)
end

function ScreenEffects:toggleNightVision(enabled)
    if enabled then
        self:applyEffect("nightVision", 0.3, -1)
    else
        self:stopEffect("nightVision")
    end
end

-- Clear all effects
function ScreenEffects:clearAllEffects()
    print("[ScreenEffects] Clearing all effects")

    for effectType, _ in pairs(self.activeEffects) do
        self:stopEffect(effectType)
    end

    self:stopCameraShake()
end

-- Check if effect is active
function ScreenEffects:isEffectActive(effectType)
    return self.activeEffects[effectType] ~= nil
end

-- Get active effects list
function ScreenEffects:getActiveEffects()
    local effects = {}
    for effectType, effectData in pairs(self.activeEffects) do
        table.insert(effects, {
            type = effectType,
            intensity = effectData.intensity,
            duration = effectData.duration,
            timeRemaining = effectData.duration > 0 and (effectData.duration - (tick() - effectData.startTime)) or -1
        })
    end
    return effects
end

-- Cleanup
function ScreenEffects:cleanup()
    print("[ScreenEffects] Cleaning up screen effects system...")

    -- Clear all effects
    self:clearAllEffects()

    -- Disconnect all connections
    for name, connection in pairs(self.effectConnections) do
        connection:Disconnect()
    end

    -- Destroy main GUI
    if self.mainGui then
        self.mainGui:Destroy()
    end

    -- Clear references
    self.effectConnections = {}
    self.activeEffects = {}
    self.effectGuis = {}

    print("[ScreenEffects] Screen effects cleanup complete")
end

return ScreenEffects