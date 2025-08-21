-- DestructionPhysics.server.lua
-- Advanced destruction physics system for KFCS FUNNY RANDOMIZER
-- Handles building destruction, debris, and environmental damage
-- Realistic physics-based destruction with performance optimization

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

-- Destruction Physics System Class
local DestructionPhysics = {}
DestructionPhysics.__index = DestructionPhysics

-- Destruction configurations
DestructionPhysics.MaterialProperties = {
    [Enum.Material.Concrete] = {
        health = 500,
        fragments = 8,
        fragmentSize = {2, 4},
        dustAmount = 15,
        breakForce = 1000,
        sound = "concrete_break"
    },
    [Enum.Material.Brick] = {
        health = 300,
        fragments = 6,
        fragmentSize = {1, 3},
        dustAmount = 10,
        breakForce = 800,
        sound = "brick_break"
    },
    [Enum.Material.Wood] = {
        health = 150,
        fragments = 4,
        fragmentSize = {1, 2},
        dustAmount = 5,
        breakForce = 400,
        sound = "wood_break"
    },
    [Enum.Material.Metal] = {
        health = 800,
        fragments = 12,
        fragmentSize = {1, 3},
        dustAmount = 8,
        breakForce = 1500,
        sound = "metal_break"
    },
    [Enum.Material.Glass] = {
        health = 50,
        fragments = 20,
        fragmentSize = {0.5, 1},
        dustAmount = 3,
        breakForce = 100,
        sound = "glass_shatter"
    },
    [Enum.Material.Plastic] = {
        health = 100,
        fragments = 5,
        fragmentSize = {1, 2},
        dustAmount = 2,
        breakForce = 200,
        sound = "plastic_break"
    }
}

-- Weapon damage types
DestructionPhysics.WeaponDamage = {
    ["Explosion"] = {
        damage = 300,
        radius = 20,
        forceMultiplier = 2.0,
        penetration = 0.8
    },
    ["HighCaliber"] = {
        damage = 150,
        radius = 2,
        forceMultiplier = 1.2,
        penetration = 0.9
    },
    ["Artillery"] = {
        damage = 500,
        radius = 35,
        forceMultiplier = 3.0,
        penetration = 1.0
    },
    ["VehicleCannon"] = {
        damage = 400,
        radius = 15,
        forceMultiplier = 2.5,
        penetration = 0.95
    },
    ["Grenade"] = {
        damage = 200,
        radius = 12,
        forceMultiplier = 1.8,
        penetration = 0.6
    }
}

-- Initialize Destruction System
function DestructionPhysics.new()
    local self = setmetatable({}, DestructionPhysics)
    
    self.destructibleParts = {}
    self.activeDebris = {}
    self.damageQueue = {}
    self.remoteEvents = {}
    self.soundEffects = {}
    
    self:setupRemoteEvents()
    self:scanForDestructibleParts()
    self:setupSoundEffects()
    self:startDestructionUpdates()
    
    print("[DestructionPhysics] ✓ Advanced destruction system initialized")
    return self
end

-- Setup RemoteEvents for client communication
function DestructionPhysics:setupRemoteEvents()
    local remoteFolder = ReplicatedStorage.FPSSystem:FindFirstChild("RemoteEvents") or Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
    
    local destructionEvents = {
        "ApplyDamage",
        "CreateExplosion",
        "DestroyPart",
        "SpawnDebris",
        "UpdateDestruction"
    }
    
    -- Use centralized RemoteEvents manager
    local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.Modules.RemoteEventsManager)
    
    for _, eventName in pairs(destructionEvents) do
        local remoteEvent = RemoteEventsManager.getOrCreateRemoteEvent(eventName, "Destruction physics: " .. eventName)
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Connect event handlers
    self.remoteEvents.ApplyDamage.OnServerEvent:Connect(function(player, part, damage, damageType, position)
        self:applyDamage(part, damage, damageType, position)
    end)
    
    self.remoteEvents.CreateExplosion.OnServerEvent:Connect(function(player, position, explosionType)
        self:createExplosion(position, explosionType)
    end)
end

-- Scan workspace for destructible parts
function DestructionPhysics:scanForDestructibleParts()
    local function scanModel(model)
        for _, child in pairs(model:GetChildren()) do
            if child:IsA("BasePart") and child.CanCollide then
                self:registerDestructiblePart(child)
            elseif child:IsA("Model") then
                scanModel(child)
            end
        end
    end
    
    -- Scan specific folders or the entire workspace
    local destructibleFolders = {"Buildings", "Structures", "Environment"}
    
    for _, folderName in pairs(destructibleFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            scanModel(folder)
        end
    end
    
    -- Also scan loose parts in workspace
    for _, child in pairs(workspace:GetChildren()) do
        if child:IsA("BasePart") and child.CanCollide and child.Size.Magnitude > 2 then
            self:registerDestructiblePart(child)
        end
    end
    
    print("[DestructionPhysics] ✓✓ Registered", #self.destructibleParts, "destructible parts")
end

-- Register a part as destructible
function DestructionPhysics:registerDestructiblePart(part)
    if self.destructibleParts[part] then return end
    
    local materialProps = self.MaterialProperties[part.Material] or self.MaterialProperties[Enum.Material.Concrete]
    
    local destructibleData = {
        part = part,
        originalCFrame = part.CFrame,
        originalSize = part.Size,
        material = part.Material,
        health = materialProps.health * (part.Size.Magnitude / 10), -- Scale health by size
        maxHealth = materialProps.health * (part.Size.Magnitude / 10),
        properties = materialProps,
        isDestroyed = false,
        damageHistory = {},
        lastDamageTime = 0
    }
    
    self.destructibleParts[part] = destructibleData
    
    -- Add destruction attributes for identification
    part:SetAttribute("Destructible", true)
    part:SetAttribute("Health", destructibleData.health)
    part:SetAttribute("MaxHealth", destructibleData.maxHealth)
end

-- Apply damage to a part
function DestructionPhysics:applyDamage(part, damage, damageType, hitPosition)
    local destructibleData = self.destructibleParts[part]
    if not destructibleData or destructibleData.isDestroyed then return end
    
    local weaponData = self.WeaponDamage[damageType] or self.WeaponDamage["HighCaliber"]
    local finalDamage = damage * weaponData.penetration
    
    -- Apply damage
    destructibleData.health = destructibleData.health - finalDamage
    destructibleData.lastDamageTime = tick()
    
    -- Record damage for analysis
    table.insert(destructibleData.damageHistory, {
        damage = finalDamage,
        type = damageType,
        position = hitPosition,
        time = tick()
    })
    
    -- Update part attributes
    part:SetAttribute("Health", destructibleData.health)
    
    -- Visual damage effects
    self:createDamageEffects(part, hitPosition, finalDamage, damageType)
    
    -- Check for destruction
    if destructibleData.health <= 0 then
        self:destroyPart(part, hitPosition, damageType)
    elseif destructibleData.health < destructibleData.maxHealth * 0.5 then
        self:applyDamageVisuals(part, destructibleData)
    end
    
    print("[DestructionPhysics] ⚡⚡ Applied", finalDamage, "damage to", part.Name, "- Health:", math.floor(destructibleData.health))
end

-- Create visual damage effects
function DestructionPhysics:createDamageEffects(part, hitPosition, damage, damageType)
    -- Impact effect
    local impactEffect = Instance.new("Explosion")
    impactEffect.Position = hitPosition
    impactEffect.BlastRadius = math.min(damage / 20, 10)
    impactEffect.BlastPressure = 0
    impactEffect.Visible = false
    impactEffect.Parent = workspace
    
    -- Damage sparks
    for i = 1, math.min(damage / 10, 8) do
        local spark = Instance.new("Part")
        spark.Name = "DamageSpark"
        spark.Size = Vector3.new(0.2, 0.2, 0.2)
        spark.Position = hitPosition + Vector3.new(
            (math.random() - 0.5) * 4,
            (math.random() - 0.5) * 4,
            (math.random() - 0.5) * 4
        )
        spark.Material = Enum.Material.Neon
        spark.BrickColor = BrickColor.new("Bright orange")
        spark.CanCollide = false
        spark.Parent = workspace
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
        bodyVelocity.Velocity = Vector3.new(
            (math.random() - 0.5) * 50,
            math.random() * 30,
            (math.random() - 0.5) * 50
        )
        bodyVelocity.Parent = spark
        
        Debris:AddItem(spark, 2)
    end
    
    -- Dust cloud
    self:createDustCloud(hitPosition, damage / 50)
    
    -- Sound effect
    self:playDestructionSound(part.Material, hitPosition)
end

-- Apply visual damage to parts
function DestructionPhysics:applyDamageVisuals(part, destructibleData)
    local damagePercentage = 1 - (destructibleData.health / destructibleData.maxHealth)
    
    -- Create cracks and holes
    if damagePercentage > 0.3 and not part:FindFirstChild("DamageDecal") then
        local damageDecal = Instance.new("Decal")
        damageDecal.Name = "DamageDecal"
        damageDecal.Texture = "rbxassetid://8560915195" -- Damage texture
        damageDecal.Face = Enum.NormalId.Front
        damageDecal.Transparency = 0.3
        damageDecal.Parent = part
    end
    
    -- Darken the part
    if part.BrickColor ~= BrickColor.new("Really black") then
        local originalColor = part.Color
        part.Color = originalColor:Lerp(Color3.new(0.2, 0.2, 0.2), damagePercentage * 0.5)
    end
    
    -- Add structural instability
    if damagePercentage > 0.7 then
        local bodyAngularVelocity = part:FindFirstChild("StructuralInstability")
        if not bodyAngularVelocity then
            bodyAngularVelocity = Instance.new("BodyAngularVelocity")
            bodyAngularVelocity.Name = "StructuralInstability"
            bodyAngularVelocity.MaxTorque = Vector3.new(100, 100, 100)
            bodyAngularVelocity.AngularVelocity = Vector3.new(
                (math.random() - 0.5) * 0.5,
                (math.random() - 0.5) * 0.5,
                (math.random() - 0.5) * 0.5
            )
            bodyAngularVelocity.Parent = part
        end
    end
end

-- Destroy a part completely
function DestructionPhysics:destroyPart(part, hitPosition, damageType)
    local destructibleData = self.destructibleParts[part]
    if not destructibleData or destructibleData.isDestroyed then return end
    
    destructibleData.isDestroyed = true
    
    -- Create destruction effects
    self:createDestructionEffects(part, hitPosition, damageType)
    
    -- Generate debris
    self:generateDebris(part, hitPosition, damageType)
    
    -- Sound effects
    self:playDestructionSound(part.Material, hitPosition, true)
    
    -- Remove from tracking
    self.destructibleParts[part] = nil
    
    -- Notify clients
    self.remoteEvents.DestroyPart:FireAllClients(part, hitPosition)
    
    -- Delay removal for effects
    task.wait(0.1)
    part:Destroy()
    
    print("[DestructionPhysics] ☠☠ Destroyed part:", part.Name)
end

-- Create destruction effects
function DestructionPhysics:createDestructionEffects(part, hitPosition, damageType)
    -- Large explosion effect
    local explosion = Instance.new("Explosion")
    explosion.Position = part.Position
    explosion.BlastRadius = math.min(part.Size.Magnitude * 2, 30)
    explosion.BlastPressure = 0
    explosion.Parent = workspace
    
    -- Destruction particles
    for i = 1, 20 do
        local particle = Instance.new("Part")
        particle.Name = "DestructionParticle"
        particle.Size = Vector3.new(
            math.random(1, 3),
            math.random(1, 3),
            math.random(1, 3)
        )
        particle.Position = part.Position + Vector3.new(
            (math.random() - 0.5) * part.Size.X,
            (math.random() - 0.5) * part.Size.Y,
            (math.random() - 0.5) * part.Size.Z
        )
        particle.Material = part.Material
        particle.BrickColor = part.BrickColor
        particle.CanCollide = true
        particle.Parent = workspace
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
        bodyVelocity.Velocity = Vector3.new(
            (math.random() - 0.5) * 80,
            math.random() * 60,
            (math.random() - 0.5) * 80
        )
        bodyVelocity.Parent = particle
        
        -- Add rotation
        local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.MaxTorque = Vector3.new(500, 500, 500)
        bodyAngularVelocity.AngularVelocity = Vector3.new(
            (math.random() - 0.5) * 10,
            (math.random() - 0.5) * 10,
            (math.random() - 0.5) * 10
        )
        bodyAngularVelocity.Parent = particle
        
        Debris:AddItem(particle, 10)
    end
    
    -- Large dust cloud
    self:createDustCloud(part.Position, part.Size.Magnitude)
end

-- Generate realistic debris
function DestructionPhysics:generateDebris(part, hitPosition, damageType)
    local destructibleData = self.destructibleParts[part]
    if not destructibleData then return end
    
    local props = destructibleData.properties
    local fragmentCount = props.fragments
    
    for i = 1, fragmentCount do
        local fragmentSize = Vector3.new(
            math.random(props.fragmentSize[1], props.fragmentSize[2]),
            math.random(props.fragmentSize[1], props.fragmentSize[2]),
            math.random(props.fragmentSize[1], props.fragmentSize[2])
        )
        
        local fragment = Instance.new("Part")
        fragment.Name = "Debris_" .. part.Name
        fragment.Size = fragmentSize
        fragment.Position = part.Position + Vector3.new(
            (math.random() - 0.5) * part.Size.X,
            (math.random() - 0.5) * part.Size.Y,
            (math.random() - 0.5) * part.Size.Z
        )
        fragment.Material = part.Material
        fragment.BrickColor = part.BrickColor
        fragment.CanCollide = true
        fragment.Parent = workspace
        
        -- Add physics
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1500, 1500, 1500)
        bodyVelocity.Velocity = (fragment.Position - hitPosition).Unit * math.random(20, 60)
        bodyVelocity.Parent = fragment
        
        local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.MaxTorque = Vector3.new(300, 300, 300)
        bodyAngularVelocity.AngularVelocity = Vector3.new(
            (math.random() - 0.5) * 8,
            (math.random() - 0.5) * 8,
            (math.random() - 0.5) * 8
        )
        bodyAngularVelocity.Parent = fragment
        
        -- Track debris
        self.activeDebris[fragment] = {
            spawnTime = tick(),
            material = part.Material
        }
        
        -- Auto-cleanup
        Debris:AddItem(fragment, math.random(30, 60))
    end
end

-- Create dust cloud effects
function DestructionPhysics:createDustCloud(position, intensity)
    local dustCount = math.min(intensity * 3, 15)
    
    for i = 1, dustCount do
        local dust = Instance.new("Part")
        dust.Name = "DustParticle"
        dust.Size = Vector3.new(
            math.random(2, 6),
            math.random(2, 6),
            math.random(2, 6)
        )
        dust.Position = position + Vector3.new(
            (math.random() - 0.5) * 20,
            math.random() * 10,
            (math.random() - 0.5) * 20
        )
        dust.Material = Enum.Material.Sand
        dust.BrickColor = BrickColor.new("Dusty Rose")
        dust.CanCollide = false
        dust.Transparency = 0.7
        dust.Parent = workspace
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(500, 500, 500)
        bodyVelocity.Velocity = Vector3.new(
            (math.random() - 0.5) * 20,
            math.random() * 15,
            (math.random() - 0.5) * 20
        )
        bodyVelocity.Parent = dust
        
        -- Fade out dust
        TweenService:Create(dust, TweenInfo.new(3, Enum.EasingStyle.Quad), {
            Transparency = 1,
            Size = dust.Size * 2
        }):Play()
        
        Debris:AddItem(dust, 4)
    end
end

-- Setup sound effects
function DestructionPhysics:setupSoundEffects()
    local soundFolder = ReplicatedStorage:FindFirstChild("DestructionSounds") or Instance.new("Folder")
    soundFolder.Name = "DestructionSounds"
    soundFolder.Parent = ReplicatedStorage
    
    -- Create placeholder sounds (replace with actual sound IDs)
    local soundConfigs = {
        ["concrete_break"] = "rbxassetid://0",
        ["brick_break"] = "rbxassetid://0", 
        ["wood_break"] = "rbxassetid://0",
        ["metal_break"] = "rbxassetid://0",
        ["glass_shatter"] = "rbxassetid://0",
        ["plastic_break"] = "rbxassetid://0"
    }
    
    for soundName, soundId in pairs(soundConfigs) do
        local sound = soundFolder:FindFirstChild(soundName) or Instance.new("Sound")
        sound.Name = soundName
        sound.SoundId = soundId
        sound.Volume = 0.5
        sound.Parent = soundFolder
        self.soundEffects[soundName] = sound
    end
end

-- Play destruction sound
function DestructionPhysics:playDestructionSound(material, position, isDestroy)
    local materialProps = self.MaterialProperties[material]
    if not materialProps then return end
    
    local soundName = materialProps.sound
    local sound = self.soundEffects[soundName]
    
    if sound then
        local soundClone = sound:Clone()
        soundClone.Volume = isDestroy and 0.8 or 0.3
        soundClone.PlaybackSpeed = math.random(80, 120) / 100
        soundClone.Parent = workspace
        soundClone:Play()
        
        Debris:AddItem(soundClone, 3)
    end
end

-- Create explosion at position
function DestructionPhysics:createExplosion(position, explosionType)
    local weaponData = self.WeaponDamage[explosionType] or self.WeaponDamage["Explosion"]
    
    -- Main explosion
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = weaponData.radius
    explosion.BlastPressure = weaponData.damage * 1000
    explosion.Parent = workspace
    
    -- Find parts in radius and apply damage
    local parts = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(weaponData.radius * 2, weaponData.radius * 2, weaponData.radius * 2))
    
    for _, part in pairs(parts) do
        if self.destructibleParts[part] then
            local distance = (part.Position - position).Magnitude
            local damageMultiplier = math.max(0, 1 - (distance / weaponData.radius))
            local damage = weaponData.damage * damageMultiplier * weaponData.forceMultiplier
            
            self:applyDamage(part, damage, explosionType, position)
        end
    end
    
    print("[DestructionPhysics] 💥💥 Created", explosionType, "explosion at", position)
end

-- Start destruction update loop
function DestructionPhysics:startDestructionUpdates()
    RunService.Heartbeat:Connect(function()
        -- Clean up old debris
        local currentTime = tick()
        for debris, data in pairs(self.activeDebris) do
            if not debris.Parent or currentTime - data.spawnTime > 60 then
                self.activeDebris[debris] = nil
            end
        end
        
        -- Process damage queue
        while #self.damageQueue > 0 do
            local damageEvent = table.remove(self.damageQueue, 1)
            self:applyDamage(damageEvent.part, damageEvent.damage, damageEvent.type, damageEvent.position)
        end
    end)
end

-- Public methods for external systems
function DestructionPhysics:registerExplosion(position, damage, radius, explosionType)
    table.insert(self.damageQueue, {
        position = position,
        damage = damage,
        radius = radius,
        type = explosionType or "Explosion"
    })
end

function DestructionPhysics:registerPartDamage(part, damage, damageType, hitPosition)
    table.insert(self.damageQueue, {
        part = part,
        damage = damage,
        type = damageType or "HighCaliber",
        position = hitPosition or part.Position
    })
end

-- Initialize the system
local destructionPhysics = DestructionPhysics.new()

print("[DestructionPhysics] 🌟🌟🌟 ADVANCED DESTRUCTION FEATURES:")
print("  • Material-based destruction properties")
print("  • Realistic debris generation and physics")
print("  • Progressive damage visualization")
print("  • Weapon-specific damage types")
print("  • Environmental particle effects")
print("  • Dynamic sound system")
print("  • Performance-optimized cleanup")
print("  • Explosion-based area damage")

return destructionPhysics