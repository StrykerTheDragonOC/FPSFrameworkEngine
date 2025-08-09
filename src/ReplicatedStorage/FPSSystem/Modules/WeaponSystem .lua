-- EnhancedWeaponSystem.lua
-- Advanced weapon system with proper categorization and Include/Exclude raycasting
-- Place in ReplicatedStorage.FPSSystem.Modules

local WeaponSystem = {}
WeaponSystem.__index = WeaponSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Enhanced weapon configurations organized properly
local WEAPON_DATABASE = {
    -- ASSAULT RIFLES
    ["AK74"] = {
        name = "AK-74",
        category = "ASSAULT",
        damage = 42,
        headMultiplier = 1.4,
        maxRange = 150,
        minRange = 10,
        maxDamage = 42,
        minDamage = 28,
        rateOfFire = 650,
        magazineSize = 30,
        reserveAmmo = 120,
        reloadTime = 2.3,
        tacticalReloadTime = 1.8,
        penetration = 2.1,
        velocity = 900,
        recoil = {
            vertical = 0.8,
            horizontal = 0.6,
            firstShot = 1.2,
            pattern = {0, 0.3, 0.5, 0.4, 0.6, 0.8, 0.7, 0.9, 1.0, 0.8}
        },
        spread = {
            base = 0.1,
            moving = 0.3,
            ads = 0.05,
            crouched = 0.08
        },
        sounds = {
            fire = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            empty = "rbxassetid://131961136"
        },
        compatibleAttachments = {
            sight = {"KOBRA SIGHT", "REFLEX SIGHT", "ACOG SCOPE", "PSO-1"},
            barrel = {"AK SUPPRESSOR", "AK COMPENSATOR", "AK FLASH HIDER"},
            underbarrel = {"ANGLED GRIP", "VERTICAL GRIP", "BIPOD"},
            ammo = {"ARMOR PIERCING", "HOLLOW POINT", "TRACER"}
        }
    },

    ["M4A1"] = {
        name = "M4A1",
        category = "ASSAULT", 
        damage = 38,
        headMultiplier = 1.4,
        maxRange = 160,
        minRange = 15,
        maxDamage = 38,
        minDamage = 25,
        rateOfFire = 800,
        magazineSize = 30,
        reserveAmmo = 150,
        reloadTime = 2.1,
        tacticalReloadTime = 1.6,
        penetration = 1.8,
        velocity = 950,
        recoil = {
            vertical = 0.6,
            horizontal = 0.4,
            firstShot = 1.0,
            pattern = {0, 0.2, 0.4, 0.3, 0.5, 0.6, 0.5, 0.7, 0.8, 0.6}
        },
        spread = {
            base = 0.08,
            moving = 0.25,
            ads = 0.04,
            crouched = 0.06
        },
        sounds = {
            fire = "rbxassetid://131961136",
            reload = "rbxassetid://131961136", 
            empty = "rbxassetid://131961136"
        },
        compatibleAttachments = {
            sight = {"EOTech", "REFLEX SIGHT", "ACOG SCOPE", "RED DOT"},
            barrel = {"M4 SUPPRESSOR", "M4 COMPENSATOR", "M4 FLASH HIDER"},
            underbarrel = {"ANGLED GRIP", "VERTICAL GRIP", "LASER SIGHT"},
            ammo = {"ARMOR PIERCING", "HOLLOW POINT", "TRACER"}
        }
    },

    -- CARBINES & PDWs  
    ["HONEY BADGER"] = {
        name = "Honey Badger",
        category = "SCOUT",
        damage = 35,
        headMultiplier = 1.5,
        maxRange = 120,
        minRange = 8,
        maxDamage = 35,
        minDamage = 22,
        rateOfFire = 780,
        magazineSize = 30,
        reserveAmmo = 120,
        reloadTime = 2.0,
        tacticalReloadTime = 1.5,
        penetration = 1.5,
        velocity = 820,
        integrallySuppressed = true,
        recoil = {
            vertical = 0.5,
            horizontal = 0.3,
            firstShot = 0.8,
            pattern = {0, 0.1, 0.3, 0.2, 0.4, 0.5, 0.4, 0.6, 0.7, 0.5}
        },
        spread = {
            base = 0.12,
            moving = 0.28,
            ads = 0.06,
            crouched = 0.08
        },
        sounds = {
            fire = "rbxassetid://131961136",  -- Suppressed sound
            reload = "rbxassetid://131961136",
            empty = "rbxassetid://131961136"
        }
    },

    -- SNIPER RIFLES
    ["INTERVENTION"] = {
        name = "CheyTac Intervention",
        category = "RECON",
        damage = 95,
        headMultiplier = 3.0,
        maxRange = 300,
        minRange = 50,
        maxDamage = 95,
        minDamage = 65,
        rateOfFire = 45,  -- Bolt action
        magazineSize = 7,
        reserveAmmo = 35,
        reloadTime = 3.2,
        tacticalReloadTime = 2.8,
        penetration = 4.5,
        velocity = 1200,
        boltAction = true,
        recoil = {
            vertical = 2.5,
            horizontal = 0.8,
            firstShot = 3.0,
            pattern = {0, 2.0, 1.5, 2.2, 1.8}
        },
        spread = {
            base = 0.02,
            moving = 0.15,
            ads = 0.005,
            crouched = 0.01
        },
        sounds = {
            fire = "rbxassetid://131961136",
            bolt = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            empty = "rbxassetid://131961136"
        },
        compatibleAttachments = {
            sight = {"SNIPER SCOPE", "VARIABLE ZOOM", "THERMAL SCOPE"},
            barrel = {"SNIPER SUPPRESSOR", "MUZZLE BRAKE"},
            underbarrel = {"BIPOD", "LASER SIGHT"},
            ammo = {"ARMOR PIERCING", "EXPLOSIVE", "TRACER"}
        }
    },

    -- LIGHT MACHINE GUNS
    ["M60"] = {
        name = "M60",
        category = "SUPPORT",
        damage = 45,
        headMultiplier = 1.4,
        maxRange = 180,
        minRange = 20,
        maxDamage = 45,
        minDamage = 30,
        rateOfFire = 550,
        magazineSize = 100,
        reserveAmmo = 200,
        reloadTime = 4.5,
        tacticalReloadTime = 4.0,
        penetration = 2.8,
        velocity = 850,
        recoil = {
            vertical = 1.2,
            horizontal = 0.9,
            firstShot = 1.5,
            pattern = {0, 0.4, 0.6, 0.5, 0.7, 0.8, 0.7, 0.9, 1.0, 0.8}
        },
        spread = {
            base = 0.15,
            moving = 0.4,
            ads = 0.08,
            crouched = 0.1
        },
        sounds = {
            fire = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            empty = "rbxassetid://131961136"
        },
        compatibleAttachments = {
            sight = {"REFLEX SIGHT", "ACOG SCOPE", "HOLO SIGHT"},
            barrel = {"LMG SUPPRESSOR", "LMG COMPENSATOR"},
            underbarrel = {"BIPOD", "VERTICAL GRIP"},
            ammo = {"ARMOR PIERCING", "INCENDIARY", "TRACER"}
        }
    },

    -- PISTOLS
    ["M9"] = {
        name = "Beretta M9",
        category = "SECONDARY",
        damage = 32,
        headMultiplier = 1.8,
        maxRange = 80,
        minRange = 5,
        maxDamage = 32,
        minDamage = 18,
        rateOfFire = 400,
        magazineSize = 15,
        reserveAmmo = 75,
        reloadTime = 1.8,
        tacticalReloadTime = 1.3,
        penetration = 0.8,
        velocity = 350,
        recoil = {
            vertical = 0.4,
            horizontal = 0.2,
            firstShot = 0.6,
            pattern = {0, 0.2, 0.3, 0.2, 0.4, 0.3, 0.5}
        },
        spread = {
            base = 0.2,
            moving = 0.4,
            ads = 0.1,
            crouched = 0.15
        },
        sounds = {
            fire = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            empty = "rbxassetid://131961136"
        },
        compatibleAttachments = {
            sight = {"MINI SIGHT", "LASER SIGHT"},
            barrel = {"PISTOL SUPPRESSOR", "COMPENSATOR"},
            ammo = {"HOLLOW POINT", "ARMOR PIERCING"}
        }
    }
}

-- Firing modes
local FIRING_MODES = {
    SEMI = "SEMI",
    AUTO = "AUTO", 
    BURST = "BURST",
    BOLT = "BOLT"
}

-- Constructor
function WeaponSystem.new()
    local self = setmetatable({}, WeaponSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = self.player.Character or self.player.CharacterAdded:Wait()
    self.humanoid = self.character:WaitForChild("Humanoid")
    self.rootPart = self.character:WaitForChild("HumanoidRootPart")
    self.camera = workspace.CurrentCamera

    -- Weapon state
    self.currentWeapon = nil
    self.currentSlot = nil
    self.weaponData = {}
    self.attachments = {}

    -- Firing state
    self.isFiring = false
    self.isAiming = false
    self.lastShotTime = 0
    self.shotsInBurst = 0
    self.recoilAccumulation = 0
    self.spread = 0

    -- Ammo management
    self.currentAmmo = 0
    self.reserveAmmo = 0
    self.isReloading = false

    -- Effects and utilities
    self.effectsFolder = workspace:FindFirstChild("WeaponEffects") or self:createEffectsFolder()
    self.raycastUtility = nil  -- Will be set when available

    -- Performance tracking
    self.shotsFired = 0
    self.hitsRegistered = 0

    print("Enhanced Weapon System initialized")
    return self
end

-- Create effects folder
function WeaponSystem:createEffectsFolder()
    local folder = Instance.new("Folder")
    folder.Name = "WeaponEffects"
    folder.Parent = workspace
    return folder
end

-- Set raycast utility reference
function WeaponSystem:setRaycastUtility(utility)
    self.raycastUtility = utility
    print("Weapon System: Raycast utility connected")
end

-- Load weapon into system
function WeaponSystem:loadWeapon(slot, weaponName)
    local weaponConfig = WEAPON_DATABASE[weaponName]
    if not weaponConfig then
        warn("Weapon System: Unknown weapon:", weaponName)
        return false
    end

    -- Store weapon data
    self.weaponData[slot] = {
        name = weaponName,
        config = weaponConfig,
        currentAmmo = weaponConfig.magazineSize,
        reserveAmmo = weaponConfig.reserveAmmo,
        attachments = {},
        customizations = {}
    }

    print("Weapon System: Loaded", weaponName, "into", slot, "slot")
    return true
end

-- Equip weapon from slot
function WeaponSystem:equipWeapon(slot)
    local weaponData = self.weaponData[slot]
    if not weaponData then
        warn("Weapon System: No weapon in slot:", slot)
        return false
    end

    -- Update current weapon
    self.currentWeapon = weaponData
    self.currentSlot = slot
    self.currentAmmo = weaponData.currentAmmo
    self.reserveAmmo = weaponData.reserveAmmo

    -- Reset firing state
    self.isFiring = false
    self.isAiming = false
    self.recoilAccumulation = 0
    self.spread = 0

    print("Weapon System: Equipped", weaponData.name)
    return true
end

-- Start firing weapon
function WeaponSystem:startFiring()
    if not self.currentWeapon then return end
    if self.isReloading then return end
    if self.currentAmmo <= 0 then
        self:playEmptySound()
        return
    end

    self.isFiring = true

    -- Handle different firing modes
    local config = self.currentWeapon.config
    if config.boltAction then
        self:fireSingleShot()
    else
        self:beginAutoFire()
    end
end

-- Stop firing weapon
function WeaponSystem:stopFiring()
    self.isFiring = false
    self.shotsInBurst = 0
end

-- Begin automatic firing
function WeaponSystem:beginAutoFire()
    if not self.isFiring then return end

    local config = self.currentWeapon.config
    local timeBetweenShots = 60 / config.rateOfFire

    -- Check if enough time has passed since last shot
    local currentTime = tick()
    if currentTime - self.lastShotTime >= timeBetweenShots then
        self:fireSingleShot()

        -- Continue firing if still holding trigger
        if self.isFiring and self.currentAmmo > 0 then
            task.delay(timeBetweenShots, function()
                self:beginAutoFire()
            end)
        end
    end
end

-- Fire a single shot
function WeaponSystem:fireSingleShot()
    if not self.currentWeapon or self.currentAmmo <= 0 then return end

    local config = self.currentWeapon.config
    self.lastShotTime = tick()
    self.currentAmmo = self.currentAmmo - 1
    self.shotsFired = self.shotsFired + 1

    -- Calculate shot properties
    local damage = self:calculateDamage()
    local direction = self:calculateShotDirection()
    local penetration = config.penetration

    -- Perform raycast
    if self.raycastUtility then
        local hits = self.raycastUtility.weaponRaycast(
            self:getMuzzlePosition(),
            direction,
            config.maxRange,
            damage,
            penetration
        )

        -- Process hits
        self:processHits(hits, damage)
    end

    -- Apply recoil
    self:applyRecoil()

    -- Update spread
    self:updateSpread()

    -- Play effects
    self:playFireEffects()

    -- Update ammo in weapon data
    self.weaponData[self.currentSlot].currentAmmo = self.currentAmmo

    print("Weapon System: Fired shot, ammo:", self.currentAmmo)
end

-- Calculate damage with range falloff
function WeaponSystem:calculateDamage()
    local config = self.currentWeapon.config
    local baseDamage = config.damage

    -- Apply attachment modifiers
    for _, attachment in pairs(self.currentWeapon.attachments) do
        if attachment.damageModifier then
            baseDamage = baseDamage * attachment.damageModifier
        end
    end

    return baseDamage
end

-- Calculate shot direction with spread
function WeaponSystem:calculateShotDirection()
    local config = self.currentWeapon.config
    local baseDirection = self.camera.CFrame.LookVector

    -- Calculate current spread
    local currentSpread = config.spread.base

    -- Modify spread based on stance
    if self.isAiming then
        currentSpread = config.spread.ads
    elseif self:isMoving() then
        currentSpread = config.spread.moving
    elseif self:isCrouching() then
        currentSpread = config.spread.crouched
    end

    -- Add accumulated spread from continuous fire
    currentSpread = currentSpread + self.spread

    -- Apply random spread
    local spreadX = (math.random() - 0.5) * 2 * currentSpread
    local spreadY = (math.random() - 0.5) * 2 * currentSpread

    -- Convert spread to direction
    local spreadDirection = CFrame.Angles(math.rad(spreadY), math.rad(spreadX), 0) * baseDirection

    return spreadDirection
end

-- Get muzzle position for raycast origin
function WeaponSystem:getMuzzlePosition()
    -- Use camera position for first-person accuracy
    return self.camera.CFrame.Position + self.camera.CFrame.LookVector * 2
end

-- Process raycast hits
function WeaponSystem:processHits(hits, baseDamage)
    for _, hit in ipairs(hits) do
        local character = hit.instance.Parent

        -- Check if hit a player
        if character:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= self.player then

                -- Calculate final damage
                local finalDamage = baseDamage

                -- Check for headshot
                if self:isHeadshot(hit.instance) then
                    finalDamage = finalDamage * self.currentWeapon.config.headMultiplier
                    print("HEADSHOT!")
                end

                -- Apply range falloff
                finalDamage = self:applyRangeFalloff(finalDamage, hit.distance)

                -- Apply penetration reduction
                if hit.penetrationLevel > 1 then
                    finalDamage = finalDamage * (0.8 ^ (hit.penetrationLevel - 1))
                end

                -- Register hit
                self:registerHit(player, finalDamage, hit)

                print("Weapon System: Hit", player.Name, "for", finalDamage, "damage at", hit.distance, "studs")
            end
        end

        -- Create impact effects
        self:createImpactEffect(hit.position, hit.instance.Material)
    end
end

-- Check if hit was a headshot
function WeaponSystem:isHeadshot(hitPart)
    return hitPart.Name == "Head" or hitPart.Parent.Name == "Head"
end

-- Apply range-based damage falloff
function WeaponSystem:applyRangeFalloff(damage, distance)
    local config = self.currentWeapon.config

    if distance <= config.minRange then
        return damage  -- Maximum damage
    elseif distance >= config.maxRange then
        return config.minDamage  -- Minimum damage
    else
        -- Linear interpolation between min and max range
        local falloffFactor = (distance - config.minRange) / (config.maxRange - config.minRange)
        return damage - (damage - config.minDamage) * falloffFactor
    end
end

-- Register hit with damage system
function WeaponSystem:registerHit(player, damage, hitInfo)
    self.hitsRegistered = self.hitsRegistered + 1

    -- TODO: Integrate with damage system
    -- Send hit information to server for validation
    print("Hit registered:", player.Name, damage, "damage")
end

-- Apply weapon recoil
function WeaponSystem:applyRecoil()
    local config = self.currentWeapon.config
    local recoil = config.recoil

    -- Calculate recoil based on shot count and pattern
    local shotIndex = math.min(self.shotsFired % 10 + 1, #recoil.pattern)
    local recoilMultiplier = recoil.pattern[shotIndex] or 1

    -- Base recoil values
    local verticalRecoil = recoil.vertical * recoilMultiplier
    local horizontalRecoil = recoil.horizontal * recoilMultiplier * (math.random() - 0.5) * 2

    -- First shot recoil multiplier
    if self.recoilAccumulation == 0 then
        verticalRecoil = verticalRecoil * recoil.firstShot
    end

    -- Accumulate recoil
    self.recoilAccumulation = self.recoilAccumulation + verticalRecoil

    -- Apply recoil to camera (would need camera system integration)
    print("Recoil applied - Vertical:", verticalRecoil, "Horizontal:", horizontalRecoil)
end

-- Update weapon spread from continuous fire
function WeaponSystem:updateSpread()
    local config = self.currentWeapon.config

    -- Increase spread with each shot
    self.spread = self.spread + 0.02

    -- Cap maximum spread
    local maxSpread = config.spread.base * 3
    self.spread = math.min(self.spread, maxSpread)

    -- Reduce spread over time when not firing
    if not self.isFiring then
        task.delay(0.1, function()
            if not self.isFiring then
                self.spread = math.max(0, self.spread - 0.01)
            end
        end)
    end
end

-- Play firing effects
function WeaponSystem:playFireEffects()
    local config = self.currentWeapon.config

    -- Play fire sound
    self:playSound(config.sounds.fire, 0.8)

    -- Create muzzle flash
    self:createMuzzleFlash()

    -- Create shell ejection
    self:createShellEjection()

    -- Screen shake for heavy weapons
    if config.category == "SUPPORT" or config.category == "RECON" then
        self:applyScreenShake(0.5)
    end
end

-- Create muzzle flash effect
function WeaponSystem:createMuzzleFlash()
    local muzzlePos = self:getMuzzlePosition()

    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Size = Vector3.new(0.5, 0.5, 1)
    flash.Material = Enum.Material.Neon
    flash.Color = Color3.fromRGB(255, 255, 150)
    flash.Anchored = true
    flash.CanCollide = false
    flash.CFrame = CFrame.lookAt(muzzlePos, muzzlePos + self.camera.CFrame.LookVector)
    flash.Parent = self.effectsFolder

    -- Animate flash
    local flashTween = TweenService:Create(flash,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = 1, Size = Vector3.new(1, 1, 0.1)}
    )
    flashTween:Play()

    Debris:AddItem(flash, 0.15)
end

-- Create shell ejection
function WeaponSystem:createShellEjection()
    local shellPos = self.rootPart.Position + self.rootPart.CFrame.RightVector * 0.8

    local shell = Instance.new("Part")
    shell.Name = "Shell"
    shell.Size = Vector3.new(0.1, 0.05, 0.2)
    shell.Material = Enum.Material.Metal
    shell.Color = Color3.fromRGB(180, 160, 100)
    shell.Shape = Enum.PartType.Cylinder
    shell.Position = shellPos
    shell.Parent = self.effectsFolder

    -- Add physics to shell
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
    bodyVelocity.Velocity = self.rootPart.CFrame.RightVector * 10 + Vector3.new(0, 5, 0)
    bodyVelocity.Parent = shell

    -- Remove physics after brief moment
    task.delay(0.2, function()
        if bodyVelocity then bodyVelocity:Destroy() end
    end)

    Debris:AddItem(shell, 5)
end

-- Create impact effect
function WeaponSystem:createImpactEffect(position, material)
    -- Different effects based on material
    local effectColor = Color3.fromRGB(255, 255, 255)
    local particleCount = 3

    if material == Enum.Material.Metal or material == Enum.Material.CorrodedMetal then
        effectColor = Color3.fromRGB(255, 200, 100)  -- Sparks
        particleCount = 5
    elseif material == Enum.Material.Wood then
        effectColor = Color3.fromRGB(139, 69, 19)   -- Wood chips
    elseif material == Enum.Material.Concrete or material == Enum.Material.Brick then
        effectColor = Color3.fromRGB(150, 150, 150)  -- Dust
    end

    -- Create impact particles
    for i = 1, particleCount do
        local particle = Instance.new("Part")
        particle.Name = "ImpactParticle"
        particle.Size = Vector3.new(0.05, 0.05, 0.05)
        particle.Material = Enum.Material.Neon
        particle.Color = effectColor
        particle.Anchored = false
        particle.CanCollide = false
        particle.Position = position + Vector3.new(
            (math.random() - 0.5) * 0.5,
            (math.random() - 0.5) * 0.5,
            (math.random() - 0.5) * 0.5
        )

        -- Add random velocity
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(500, 500, 500)
        bodyVelocity.Velocity = Vector3.new(
            (math.random() - 0.5) * 15,
            math.random() * 8,
            (math.random() - 0.5) * 15
        )
        bodyVelocity.Parent = particle

        particle.Parent = self.effectsFolder

        -- Fade out
        task.delay(0.1, function()
            if bodyVelocity then bodyVelocity:Destroy() end
        end)

        local fadeTween = TweenService:Create(particle,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1, Size = Vector3.new(0.01, 0.01, 0.01)}
        )
        fadeTween:Play()

        Debris:AddItem(particle, 1)
    end
end

-- Reload weapon
function WeaponSystem:reload()
    if not self.currentWeapon then return end
    if self.isReloading then return end
    if self.reserveAmmo <= 0 then return end
    if self.currentAmmo >= self.currentWeapon.config.magazineSize then return end

    self.isReloading = true

    local config = self.currentWeapon.config
    local reloadTime = (self.currentAmmo > 0) and config.tacticalReloadTime or config.reloadTime

    -- Play reload sound
    self:playSound(config.sounds.reload, 0.7)

    print("Weapon System: Reloading", config.name, "for", reloadTime, "seconds")

    -- Reload after delay
    task.delay(reloadTime, function()
        local ammoNeeded = config.magazineSize - self.currentAmmo
        local ammoToReload = math.min(ammoNeeded, self.reserveAmmo)

        self.currentAmmo = self.currentAmmo + ammoToReload
        self.reserveAmmo = self.reserveAmmo - ammoToReload

        -- Update weapon data
        self.weaponData[self.currentSlot].currentAmmo = self.currentAmmo
        self.weaponData[self.currentSlot].reserveAmmo = self.reserveAmmo

        self.isReloading = false

        print("Weapon System: Reload complete, ammo:", self.currentAmmo .. "/" .. self.reserveAmmo)
    end)
end

-- Aiming methods
function WeaponSystem:startAiming()
    if not self.currentWeapon then return end
    self.isAiming = true
    print("Weapon System: Started aiming")
end

function WeaponSystem:stopAiming()
    self.isAiming = false
    print("Weapon System: Stopped aiming")
end

-- Utility methods
function WeaponSystem:isMoving()
    return self.humanoid.MoveDirection.Magnitude > 0.1
end

function WeaponSystem:isCrouching()
    -- Would integrate with movement system
    return false
end

-- Audio methods
function WeaponSystem:playSound(soundId, volume, position)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 1
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 100

    if position then
        local soundPart = Instance.new("Part")
        soundPart.Transparency = 1
        soundPart.Anchored = true
        soundPart.CanCollide = false
        soundPart.Position = position
        soundPart.Parent = self.effectsFolder

        sound.Parent = soundPart
        sound:Play()

        Debris:AddItem(soundPart, sound.TimeLength + 0.5)
    else
        sound.Parent = self.camera
        sound:Play()

        Debris:AddItem(sound, sound.TimeLength + 0.1)
    end
end

function WeaponSystem:playEmptySound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://131961136"  -- Empty click sound
    sound.Volume = 0.5
    sound.Parent = self.camera
    sound:Play()

    Debris:AddItem(sound, 1)
end

function WeaponSystem:applyScreenShake(intensity)
    -- Would integrate with camera system
    print("Screen shake applied:", intensity)
end

-- Get weapon information
function WeaponSystem:getCurrentWeaponInfo()
    if not self.currentWeapon then return nil end

    return {
        name = self.currentWeapon.name,
        config = self.currentWeapon.config,
        currentAmmo = self.currentAmmo,
        reserveAmmo = self.reserveAmmo,
        isReloading = self.isReloading,
        accuracy = self:calculateAccuracy()
    }
end

function WeaponSystem:calculateAccuracy()
    if self.shotsFired == 0 then return 100 end
    return math.floor((self.hitsRegistered / self.shotsFired) * 100)
end

-- Get available weapons by category
function WeaponSystem:getWeaponsByCategory(category)
    local weapons = {}
    for name, config in pairs(WEAPON_DATABASE) do
        if config.category == category then
            table.insert(weapons, {
                name = name,
                displayName = config.name,
                category = config.category,
                damage = config.damage,
                rateOfFire = config.rateOfFire,
                range = config.maxRange
            })
        end
    end
    return weapons
end

-- Cleanup
function WeaponSystem:cleanup()
    print("Cleaning up Enhanced Weapon System")

    -- Reset state
    self.isFiring = false
    self.isAiming = false
    self.isReloading = false

    -- Clear weapon data
    self.currentWeapon = nil
    self.weaponData = {}

    print("Enhanced Weapon System cleanup complete")
end

return WeaponSystem