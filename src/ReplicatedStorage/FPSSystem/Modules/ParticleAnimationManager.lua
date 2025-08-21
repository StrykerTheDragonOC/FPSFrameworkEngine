-- ParticleAnimationManager.lua
-- Manages particle animations to prevent them from getting stuck
-- Place in ReplicatedStorage/FPSSystem/Modules

local ParticleAnimationManager = {}
ParticleAnimationManager.__index = ParticleAnimationManager

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

function ParticleAnimationManager.new()
    local self = setmetatable({}, ParticleAnimationManager)
    
    -- Animation tracking
    self.activeAnimations = {}
    self.animationConnections = {}
    self.nextAnimationId = 1
    
    -- Initialize
    self:initialize()
    
    return self
end

-- Initialize the animation manager
function ParticleAnimationManager:initialize()
    print("[ParticleAnimationManager] Initializing particle animation manager...")
    
    -- Start animation update loop
    self:startAnimationLoop()
    
    print("[ParticleAnimationManager] Particle animation manager initialized")
end

-- Start the main animation loop
function ParticleAnimationManager:startAnimationLoop()
    self.animationConnections.heartbeat = RunService.Heartbeat:Connect(function()
        self:updateAnimations()
    end)
end

-- Update all active animations
function ParticleAnimationManager:updateAnimations()
    for animationId, animationData in pairs(self.activeAnimations) do
        if animationData.particle and animationData.particle.Parent then
            -- Continue animation
            self:updateParticleAnimation(animationData)
        else
            -- Clean up animation if particle is gone
            self:removeAnimation(animationId)
        end
    end
end

-- Create animated particle system
function ParticleAnimationManager:createAnimatedParticles(containerFrame, particleCount, animationConfig)
    local particles = {}
    
    for i = 1, particleCount do
        local particle = self:createSingleParticle(containerFrame, animationConfig)
        if particle then
            local animationId = self:addParticleAnimation(particle, animationConfig)
            table.insert(particles, {particle = particle, animationId = animationId})
        end
    end
    
    return particles
end

-- Initialize particle background for menu system (static function)
function ParticleAnimationManager.initializeParticleBackground(menuGui)
    if not menuGui or not menuGui.Parent then
        warn("[ParticleAnimationManager] Invalid menuGui provided for particle background")
        return
    end
    
    print("[ParticleAnimationManager] Initializing particle background for menu...")
    
    -- Create background container for particles
    local particleContainer = menuGui:FindFirstChild("ParticleBackground")
    if not particleContainer then
        particleContainer = Instance.new("Frame")
        particleContainer.Name = "ParticleBackground"
        particleContainer.Size = UDim2.new(1, 0, 1, 0)
        particleContainer.Position = UDim2.new(0, 0, 0, 0)
        particleContainer.BackgroundTransparency = 1
        particleContainer.ZIndex = 0
        particleContainer.Parent = menuGui
    end
    
    -- Create simple static particles for menu background
    for i = 1, 20 do
        local particle = Instance.new("Frame")
        particle.Name = "MenuParticle"
        particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromRGB(85, 170, 187)
        particle.BackgroundTransparency = 0.8
        particle.BorderSizePixel = 0
        particle.ZIndex = 1
        particle.Parent = particleContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
    end
    
    print("[ParticleAnimationManager] Particle background initialized with 20 static particles")
end

-- Create a single particle
function ParticleAnimationManager:createSingleParticle(parent, config)
    if not parent or not parent.Parent then
        warn("[ParticleAnimationManager] Invalid parent for particle creation")
        return nil
    end
    
    local particle = Instance.new("Frame")
    particle.Name = "AnimatedParticle"
    particle.Size = UDim2.new(0, config.size or math.random(2, 6), 0, config.size or math.random(2, 6))
    particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
    particle.BackgroundColor3 = config.color or Color3.fromRGB(85, 170, 187)
    particle.BackgroundTransparency = config.transparency or 0.7
    particle.BorderSizePixel = 0
    particle.ZIndex = config.zIndex or 1
    particle.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = particle
    
    return particle
end

-- Add particle animation to manager
function ParticleAnimationManager:addParticleAnimation(particle, config)
    local animationId = self.nextAnimationId
    self.nextAnimationId = self.nextAnimationId + 1
    
    local animationData = {
        id = animationId,
        particle = particle,
        config = config,
        startTime = tick(),
        currentPhase = "active",
        lastUpdate = tick(),
        targetPosition = self:generateRandomPosition(),
        animationSpeed = config.animationSpeed or math.random(8, 15)
    }
    
    self.activeAnimations[animationId] = animationData
    
    -- Start initial animation
    self:startParticleMovement(animationData)
    
    return animationId
end

-- Update a specific particle animation
function ParticleAnimationManager:updateParticleAnimation(animationData)
    local currentTime = tick()
    local elapsed = currentTime - animationData.lastUpdate
    
    -- Check if particle still exists and has valid parent
    if not animationData.particle or not animationData.particle.Parent then
        return
    end
    
    -- Update particle properties based on animation phase
    if animationData.currentPhase == "active" then
        -- Continue normal animation
        local timeSinceStart = currentTime - animationData.startTime
        
        -- Update transparency with subtle pulsing
        local pulseIntensity = 0.5 + 0.3 * math.sin(timeSinceStart * 2)
        animationData.particle.BackgroundTransparency = (animationData.config.transparency or 0.7) * pulseIntensity
        
        -- Check if animation should continue to next target
        if elapsed >= 1 then
            self:startParticleMovement(animationData)
            animationData.lastUpdate = currentTime
        end
    end
end

-- Start particle movement to new position
function ParticleAnimationManager:startParticleMovement(animationData)
    if not animationData.particle or not animationData.particle.Parent then
        return
    end
    
    -- Generate new target position
    animationData.targetPosition = self:generateRandomPosition()
    
    -- Create movement tween
    local moveTween = TweenService:Create(animationData.particle,
        TweenInfo.new(
            animationData.animationSpeed,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        ),
        {
            Position = animationData.targetPosition,
            BackgroundTransparency = math.random(0.5, 0.9)
        }
    )
    
    -- Store tween reference for cleanup
    animationData.currentTween = moveTween
    
    moveTween:Play()
    
    moveTween.Completed:Connect(function()
        if animationData.particle and animationData.particle.Parent then
            -- Continue to next movement
            task.wait(math.random(0.5, 2))
            if self.activeAnimations[animationData.id] then
                self:startParticleMovement(animationData)
            end
        end
    end)
end

-- Generate random position within bounds
function ParticleAnimationManager:generateRandomPosition()
    return UDim2.new(
        math.random() * 0.95,  -- Stay within 95% of container width
        0,
        math.random() * 0.95,  -- Stay within 95% of container height
        0
    )
end

-- Remove animation from manager
function ParticleAnimationManager:removeAnimation(animationId)
    local animationData = self.activeAnimations[animationId]
    if animationData then
        -- Stop any active tweens
        if animationData.currentTween then
            animationData.currentTween:Cancel()
        end
        
        -- Remove animation data
        self.activeAnimations[animationId] = nil
    end
end

-- Create persistent particle effect for UI containers
function ParticleAnimationManager:createPersistentParticleEffect(containerFrame, config)
    if not containerFrame then
        warn("[ParticleAnimationManager] Invalid container for persistent effect")
        return nil
    end
    
    local defaultConfig = {
        particleCount = 25,
        color = Color3.fromRGB(85, 170, 187),
        transparency = 0.7,
        size = 4,
        animationSpeed = 10,
        recreateOnDestroy = true,
        zIndex = 1
    }
    
    -- Merge with provided config
    for key, value in pairs(config or {}) do
        defaultConfig[key] = value
    end
    
    -- Create particle container within the UI element
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleContainer"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.BorderSizePixel = 0
    particleContainer.ZIndex = defaultConfig.zIndex
    particleContainer.Parent = containerFrame
    
    -- Create particles
    local particles = self:createAnimatedParticles(particleContainer, defaultConfig.particleCount, defaultConfig)
    
    -- Monitor container for destruction and recreation
    if defaultConfig.recreateOnDestroy then
        self:monitorContainerForRecreation(containerFrame, particleContainer, defaultConfig)
    end
    
    return {
        container = particleContainer,
        particles = particles,
        config = defaultConfig
    }
end

-- Monitor container for recreation needs
function ParticleAnimationManager:monitorContainerForRecreation(originalContainer, particleContainer, config)
    task.spawn(function()
        while originalContainer.Parent do
            task.wait(1)
            
            -- Check if particle container still exists
            if not particleContainer.Parent then
                print("[ParticleAnimationManager] Recreating particle container...")
                
                -- Recreate particle container
                local newParticleContainer = Instance.new("Frame")
                newParticleContainer.Name = "ParticleContainer"
                newParticleContainer.Size = UDim2.new(1, 0, 1, 0)
                newParticleContainer.BackgroundTransparency = 1
                newParticleContainer.BorderSizePixel = 0
                newParticleContainer.ZIndex = config.zIndex
                newParticleContainer.Parent = originalContainer
                
                -- Recreate particles
                self:createAnimatedParticles(newParticleContainer, config.particleCount, config)
                
                -- Update reference
                particleContainer = newParticleContainer
            end
        end
    end)
end

-- Create menu background particles
function ParticleAnimationManager:createMenuBackgroundParticles(menuContainer)
    local particleConfig = {
        particleCount = 30,
        color = Color3.fromRGB(85, 170, 187),
        transparency = 0.8,
        size = 5,
        animationSpeed = 12,
        recreateOnDestroy = true,
        zIndex = 1
    }
    
    return self:createPersistentParticleEffect(menuContainer, particleConfig)
end

-- Create HUD ambient particles
function ParticleAnimationManager:createHUDAmbientParticles(hudContainer)
    local particleConfig = {
        particleCount = 15,
        color = Color3.fromRGB(85, 170, 187),
        transparency = 0.9,
        size = 3,
        animationSpeed = 15,
        recreateOnDestroy = true,
        zIndex = 1
    }
    
    return self:createPersistentParticleEffect(hudContainer, particleConfig)
end

-- Clean up specific particle effect
function ParticleAnimationManager:cleanupParticleEffect(particleEffect)
    if not particleEffect then return end
    
    -- Remove all particle animations
    for _, particleData in pairs(particleEffect.particles) do
        if particleData.animationId then
            self:removeAnimation(particleData.animationId)
        end
    end
    
    -- Destroy container
    if particleEffect.container and particleEffect.container.Parent then
        particleEffect.container:Destroy()
    end
end

-- Cleanup all animations
function ParticleAnimationManager:cleanup()
    print("[ParticleAnimationManager] Cleaning up particle animation manager...")
    
    -- Stop animation loop
    if self.animationConnections.heartbeat then
        self.animationConnections.heartbeat:Disconnect()
    end
    
    -- Clean up all active animations
    for animationId, animationData in pairs(self.activeAnimations) do
        if animationData.currentTween then
            animationData.currentTween:Cancel()
        end
        if animationData.particle and animationData.particle.Parent then
            animationData.particle:Destroy()
        end
    end
    
    -- Clear data
    self.activeAnimations = {}
    self.animationConnections = {}
    
    print("[ParticleAnimationManager] Particle animation cleanup complete")
end

return ParticleAnimationManager