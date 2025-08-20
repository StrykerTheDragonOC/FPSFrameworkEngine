-- DestructionPhysics.lua
-- Handles destruction and physics for environmental objects
-- ModuleScript for FPS System

local DestructionPhysics = {}

-- Services
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local DESTRUCTION_CONFIG = {
    explosionForce = 50,
    debrisLifetime = 30,
    maxDebrisCount = 100,
    explosionRadius = 20
}

-- Initialize destruction physics system
function DestructionPhysics:init()
    print("[DestructionPhysics] Initializing destruction physics system...")
    self.debrisCount = 0
    self.activeExplosions = {}
    print("[DestructionPhysics] Destruction physics system ready!")
end

-- Create explosion effect
function DestructionPhysics:createExplosion(position, force, radius)
    force = force or DESTRUCTION_CONFIG.explosionForce
    radius = radius or DESTRUCTION_CONFIG.explosionRadius
    
    -- Find nearby objects
    local nearbyObjects = self:findNearbyObjects(position, radius)
    
    -- Apply explosion force to objects
    for _, object in pairs(nearbyObjects) do
        self:applyExplosionForce(object, position, force)
    end
    
    -- Create visual effects
    self:createExplosionEffects(position, radius)
end

-- Find nearby objects for destruction
function DestructionPhysics:findNearbyObjects(position, radius)
    local objects = {}
    local region = Region3.new(
        position - Vector3.new(radius, radius, radius),
        position + Vector3.new(radius, radius, radius)
    )
    
    -- This is a simplified version - in practice you'd use spatial partitioning
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide then
            local distance = (obj.Position - position).Magnitude
            if distance <= radius then
                table.insert(objects, obj)
            end
        end
    end
    
    return objects
end

-- Apply explosion force to object
function DestructionPhysics:applyExplosionForce(object, explosionPos, force)
    if not object or not object.Parent then return end
    
    -- Calculate force direction and magnitude
    local direction = (object.Position - explosionPos).Unit
    local distance = (object.Position - explosionPos).Magnitude
    local forceMagnitude = force / (distance + 1) -- Falloff with distance
    
    -- Apply force using BodyVelocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = direction * forceMagnitude
    bodyVelocity.Parent = object
    
    -- Remove force after short time
    Debris:AddItem(bodyVelocity, 0.5)
end

-- Create explosion visual effects
function DestructionPhysics:createExplosionEffects(position, radius)
    -- Create explosion part
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = radius
    explosion.BlastPressure = 0 -- We handle physics manually
    explosion.Parent = workspace
end

-- Destroy object with debris
function DestructionPhysics:destroyObject(object, debrisCount)
    if not object or not object.Parent then return end
    
    debrisCount = debrisCount or 5
    local position = object.Position
    local size = object.Size
    
    -- Create debris pieces
    for i = 1, debrisCount do
        self:createDebris(position, size / debrisCount)
    end
    
    -- Remove original object
    object:Destroy()
end

-- Create debris piece
function DestructionPhysics:createDebris(position, size)
    if self.debrisCount >= DESTRUCTION_CONFIG.maxDebrisCount then
        return -- Don't create more debris if at limit
    end
    
    local debris = Instance.new("Part")
    debris.Name = "Debris"
    debris.Size = size
    debris.Position = position + Vector3.new(
        math.random(-5, 5),
        math.random(0, 5),
        math.random(-5, 5)
    )
    debris.BrickColor = BrickColor.new("Dark stone gray")
    debris.Material = Enum.Material.Concrete
    debris.CanCollide = true
    debris.Parent = workspace
    
    -- Add random rotation
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.AngularVelocity = Vector3.new(
        math.random(-10, 10),
        math.random(-10, 10),
        math.random(-10, 10)
    )
    bodyAngularVelocity.Parent = debris
    
    -- Clean up debris after lifetime
    Debris:AddItem(debris, DESTRUCTION_CONFIG.debrisLifetime)
    Debris:AddItem(bodyAngularVelocity, 2)
    
    self.debrisCount = self.debrisCount + 1
    
    -- Decrease debris count when cleaned up
    task.spawn(function()
        task.wait(DESTRUCTION_CONFIG.debrisLifetime)
        self.debrisCount = math.max(0, self.debrisCount - 1)
    end)
end

-- Damage building or structure
function DestructionPhysics:damageStructure(structure, damage, impactPoint)
    if not structure or not structure.Parent then return end
    
    -- Get or create health attribute
    local health = structure:GetAttribute("Health") or 100
    health = health - damage
    structure:SetAttribute("Health", health)
    
    -- Visual damage effects
    self:applyDamageEffects(structure, damage / 100)
    
    -- Destroy if health depleted
    if health <= 0 then
        self:destroyObject(structure, 8)
    end
end

-- Apply visual damage effects
function DestructionPhysics:applyDamageEffects(object, damagePercent)
    if not object or not object:IsA("BasePart") then return end
    
    -- Darken the object based on damage
    local originalColor = object.Color
    local darknessFactor = 1 - (damagePercent * 0.5)
    object.Color = Color3.new(
        originalColor.R * darknessFactor,
        originalColor.G * darknessFactor,
        originalColor.B * darknessFactor
    )
    
    -- Add transparency for heavy damage
    if damagePercent > 0.7 then
        object.Transparency = math.min(0.3, damagePercent - 0.7)
    end
end

-- Clean up all debris
function DestructionPhysics:cleanupDebris()
    for _, debris in pairs(workspace:GetChildren()) do
        if debris.Name == "Debris" then
            debris:Destroy()
        end
    end
    self.debrisCount = 0
end

-- Get destruction stats
function DestructionPhysics:getStats()
    return {
        debrisCount = self.debrisCount,
        maxDebris = DESTRUCTION_CONFIG.maxDebrisCount,
        activeExplosions = #self.activeExplosions
    }
end

return DestructionPhysics