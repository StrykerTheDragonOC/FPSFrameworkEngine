-- Weapon Firing System
local WeaponFiringSystem = {}
WeaponFiringSystem.__index = WeaponFiringSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Constants
local DEFAULT_SETTINGS = {
    BULLET_SPEED = 1000,
    MAX_DISTANCE = 1000,
    IMPACT_SIZE = 0.2,
    TRACER_WIDTH = 0.05,
    TRACER_LIFETIME = 0.1,
    HIT_EFFECT_LIFETIME = 0.5,
    SHELL_CASING_LIFETIME = 2,
    DEFAULT_RECOIL = 0.3,
    MUZZLE_FLASH_DURATION = 0.05
}

function WeaponFiringSystem.new(viewmodelSystem)
    local self = setmetatable({}, WeaponFiringSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.viewmodel = viewmodelSystem
    self.camera = workspace.CurrentCamera

    -- State tracking
    self.isFiring = false
    self.canFire = true
    self.isReloading = false
    self.currentWeapon = nil
    self.lastFireTime = 0

    -- Ammunition tracking (for each weapon)
    self.ammoData = {}

    -- Check for remote events
    self:setupRemoteEvents()

    -- Create folder for visual effects
    self.effectsFolder = Instance.new("Folder")
    self.effectsFolder.Name = "WeaponEffects"
    self.effectsFolder.Parent = workspace

    return self
end

-- Setup remote events for server-side handling
function WeaponFiringSystem:setupRemoteEvents()
    -- Wait for FPS system folder
    local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem")
    local remoteEventsFolder = fpsSystem:WaitForChild("RemoteEvents")

    -- Get remote events from the correct location
    self.fireEvent = remoteEventsFolder:WaitForChild("WeaponFired")
    self.hitEvent = remoteEventsFolder:WaitForChild("WeaponHit")
    self.reloadEvent = remoteEventsFolder:WaitForChild("WeaponReload")
    
    print("WeaponFiringSystem: Remote events connected")
end

-- Set the current weapon
function WeaponFiringSystem:setWeapon(weaponModel, weaponData)
    self.currentWeapon = weaponModel

    -- Initialize ammo data if not already set
    if not self.ammoData[weaponModel.Name] then
        local magazineSize = weaponModel:GetAttribute("MagazineSize") or 30

        self.ammoData[weaponModel.Name] = {
            currentMagazine = magazineSize,
            reserveAmmo = magazineSize * 3,
            magazineSize = magazineSize
        }
    end

    print("Weapon set:", weaponModel.Name, "with", self.ammoData[weaponModel.Name].currentMagazine, "rounds")
end

-- Handle firing input
function WeaponFiringSystem:handleFiring(isPressed)
    -- Update firing state
    self.isFiring = isPressed

    -- Start continuous firing check if pressed
    if isPressed and not self.firingConnection then
        self.firingConnection = RunService.Heartbeat:Connect(function()
            self:tryFire()
        end)
    elseif not isPressed and self.firingConnection then
        self.firingConnection:Disconnect()
        self.firingConnection = nil
    end

    return true
end

-- Try to fire the current weapon
function WeaponFiringSystem:tryFire()
    if not self.isFiring or not self.canFire or not self.currentWeapon or self.isReloading then
        return false
    end

    local ammo = self.ammoData[self.currentWeapon.Name]
    if not ammo or ammo.currentMagazine <= 0 then
        -- Click sound for empty magazine
        self:playSound("EmptyClick")

        -- Auto-reload when empty
        if ammo and ammo.currentMagazine <= 0 and ammo.reserveAmmo > 0 then
            self:reload()
        end

        return false
    end

    -- Check fire rate
    local fireRate = self.currentWeapon:GetAttribute("FireRate") or 600
    local timeBetweenShots = 60 / fireRate

    local now = tick()
    if now - self.lastFireTime < timeBetweenShots then
        return false
    end

    -- Fire the weapon
    self.lastFireTime = now

    -- Reduce ammo
    ammo.currentMagazine = ammo.currentMagazine - 1

    -- Create visual and audio effects
    self:createMuzzleFlash()
    self:createShellCasing()
    self:playSound("Fire")

    -- Perform raycast to find target
    local hitInfo = self:performRaycast()

    -- Create bullet tracer and handle damage
    if hitInfo then
        self:createBulletTracer(hitInfo.hitPosition)
        self:createImpactEffect(hitInfo)
        self:handleDamage(hitInfo)
    end

    -- Apply recoil
    self:applyRecoil()

    -- Notify server about firing
    self.fireEvent:FireServer(self.currentWeapon.Name, hitInfo)

    return true
end

-- Perform raycast to find hit target with penetration
function WeaponFiringSystem:performRaycast()
    -- Get muzzle position
    local muzzleAttachment = self:getMuzzleAttachment()
    local rayOrigin = muzzleAttachment and muzzleAttachment.WorldPosition or self.camera.CFrame.Position

    -- Direction with random spread
    local spreadFactor = 0.01
    if self.viewmodel.isAiming then
        spreadFactor = 0.003 -- Less spread when aiming
    end

    local randomSpread = Vector3.new(
        (math.random() - 0.5) * spreadFactor,
        (math.random() - 0.5) * spreadFactor,
        (math.random() - 0.5) * spreadFactor
    )

    local rayDirection = (self.camera.CFrame.LookVector + randomSpread).Unit
    
    -- Get weapon penetration power
    local penetrationPower = self.currentWeapon:GetAttribute("PenetrationPower") or 1
    local maxPenetrations = self.currentWeapon:GetAttribute("MaxPenetrations") or 2
    
    -- Perform multiple raycasts for penetration
    local allHits = {}
    local currentOrigin = rayOrigin
    local currentDirection = rayDirection
    local remainingDistance = DEFAULT_SETTINGS.MAX_DISTANCE
    local remainingPenetration = penetrationPower
    local penetrationCount = 0
    
    -- Setup raycast params
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {self.player.Character, self.camera, self.viewmodel.container}

    while remainingDistance > 0 and penetrationCount < maxPenetrations do
        local raycastResult = workspace:Raycast(currentOrigin, currentDirection * remainingDistance, raycastParams)
        
        if raycastResult then
            local hitInfo = {
                hitPart = raycastResult.Instance,
                hitPosition = raycastResult.Position,
                hitNormal = raycastResult.Normal,
                material = raycastResult.Material,
                distance = (raycastResult.Position - currentOrigin).Magnitude,
                penetrationIndex = penetrationCount
            }
            
            table.insert(allHits, hitInfo)
            
            -- Calculate material penetration resistance
            local materialResistance = self:getMaterialPenetrationResistance(raycastResult.Material)
            
            -- Check if we can penetrate this material
            if remainingPenetration > materialResistance and penetrationCount < maxPenetrations then
                -- Calculate thickness of the object (rough estimate)
                local thickness = self:estimateObjectThickness(raycastResult.Instance, raycastResult.Position, currentDirection)
                
                -- Reduce penetration power based on material and thickness
                remainingPenetration = remainingPenetration - (materialResistance * thickness)
                
                if remainingPenetration > 0 then
                    -- Continue ray from exit point
                    currentOrigin = raycastResult.Position + currentDirection * (thickness + 0.1)
                    remainingDistance = remainingDistance - hitInfo.distance - thickness
                    penetrationCount = penetrationCount + 1
                    
                    -- Add the hit part to filter so we don't hit it again
                    table.insert(raycastParams.FilterDescendantsInstances, raycastResult.Instance)
                else
                    break
                end
            else
                break
            end
        else
            -- No more hits
            break
        end
    end
    
    -- Return the first hit (primary target) or endpoint if no hits
    if #allHits > 0 then
        local primaryHit = allHits[1]
        -- Create a safe copy of all hits without circular references
        local safePenetrationHits = {}
        for i, hit in ipairs(allHits) do
            safePenetrationHits[i] = {
                hitPart = hit.hitPart,
                hitPosition = hit.hitPosition,
                hitNormal = hit.hitNormal,
                material = hit.material,
                distance = hit.distance,
                penetrationIndex = hit.penetrationIndex
            }
        end
        primaryHit.penetrationHits = safePenetrationHits
        return primaryHit
    else
        return {
            hitPosition = rayOrigin + rayDirection * DEFAULT_SETTINGS.MAX_DISTANCE,
            distance = DEFAULT_SETTINGS.MAX_DISTANCE,
            isMaxDistance = true,
            penetrationHits = {}
        }
    end
end

-- Get material penetration resistance
function WeaponFiringSystem:getMaterialPenetrationResistance(material)
    local resistanceMap = {
        [Enum.Material.Fabric] = 0.1,
        [Enum.Material.Plastic] = 0.2,
        [Enum.Material.Wood] = 0.3,
        [Enum.Material.WoodPlanks] = 0.3,
        [Enum.Material.Glass] = 0.4,
        [Enum.Material.Concrete] = 0.7,
        [Enum.Material.Brick] = 0.8,
        [Enum.Material.Metal] = 0.9,
        [Enum.Material.DiamondPlate] = 1.0,
        [Enum.Material.CorrodedMetal] = 0.8,
        [Enum.Material.ForceField] = 10.0  -- Unpenetrable
    }
    
    return resistanceMap[material] or 0.5  -- Default resistance
end

-- Estimate object thickness for penetration calculation
function WeaponFiringSystem:estimateObjectThickness(part, hitPosition, direction)
    -- Simple thickness estimation based on part size and hit angle
    local size = part.Size
    local avgSize = (size.X + size.Y + size.Z) / 3
    
    -- For basic estimation, use a fraction of average size
    -- This is a simplified approach - in reality you'd want more sophisticated thickness calculation
    return math.min(avgSize * 0.3, 5)  -- Cap at 5 studs max thickness
end

-- Get the muzzle attachment from the weapon
function WeaponFiringSystem:getMuzzleAttachment()
    if not self.currentWeapon then return nil end

    return self.currentWeapon.PrimaryPart:FindFirstChild("MuzzlePoint")
end

-- Create muzzle flash effect
function WeaponFiringSystem:createMuzzleFlash()
    local muzzleAttachment = self:getMuzzleAttachment()
    if not muzzleAttachment then return end

    -- Create light
    local muzzleLight = Instance.new("PointLight")
    muzzleLight.Brightness = 2
    muzzleLight.Range = 5
    muzzleLight.Color = Color3.fromRGB(255, 200, 100)
    muzzleLight.Parent = muzzleAttachment

    -- Create flash part
    local flashPart = Instance.new("Part")
    flashPart.Size = Vector3.new(0.2, 0.2, 0.2)
    flashPart.CFrame = muzzleAttachment.WorldCFrame
    flashPart.Anchored = true
    flashPart.CanCollide = false
    flashPart.Material = Enum.Material.Neon
    flashPart.Color = Color3.fromRGB(255, 200, 100)
    flashPart.Transparency = 0.2
    flashPart.Shape = Enum.PartType.Ball
    flashPart.Parent = self.effectsFolder

    -- Auto-cleanup
    game:GetService("Debris"):AddItem(muzzleLight, DEFAULT_SETTINGS.MUZZLE_FLASH_DURATION)
    game:GetService("Debris"):AddItem(flashPart, DEFAULT_SETTINGS.MUZZLE_FLASH_DURATION)

    -- Fade out flash
    TweenService:Create(
        flashPart,
        TweenInfo.new(DEFAULT_SETTINGS.MUZZLE_FLASH_DURATION),
        {Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}
    ):Play()
end

-- Create shell casing ejection
function WeaponFiringSystem:createShellCasing()
    local shellPoint = self.currentWeapon.PrimaryPart:FindFirstChild("ShellEjectPoint")
    if not shellPoint then return end

    -- Create shell casing
    local shell = Instance.new("Part")
    shell.Size = Vector3.new(0.05, 0.15, 0.05)
    shell.CFrame = shellPoint.WorldCFrame
    shell.Color = Color3.fromRGB(200, 180, 0) -- Brass color
    shell.Material = Enum.Material.Metal
    shell.CanCollide = true
    shell.Parent = self.effectsFolder

    -- Apply physics
    shell.Velocity = shellPoint.WorldCFrame.RightVector * 5 + Vector3.new(0, 2, 0)
    shell.RotVelocity = Vector3.new(
        math.random(-20, 20),
        math.random(-20, 20),
        math.random(-20, 20)
    )

    -- Auto-cleanup
    game:GetService("Debris"):AddItem(shell, DEFAULT_SETTINGS.SHELL_CASING_LIFETIME)
end

-- Create bullet tracer
function WeaponFiringSystem:createBulletTracer(hitPosition)
    local muzzleAttachment = self:getMuzzleAttachment()
    if not muzzleAttachment then return end

    local startPos = muzzleAttachment.WorldPosition
    local endPos = hitPosition

    -- Create tracer part
    local tracer = Instance.new("Part")
    tracer.Size = Vector3.new(
        DEFAULT_SETTINGS.TRACER_WIDTH, 
        DEFAULT_SETTINGS.TRACER_WIDTH, 
        (endPos - startPos).Magnitude
    )
    tracer.CFrame = CFrame.lookAt(
        startPos, 
        endPos
    ) * CFrame.new(0, 0, -tracer.Size.Z/2)
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Material = Enum.Material.Neon
    tracer.Color = Color3.fromRGB(255, 200, 100)
    tracer.Transparency = 0.2
    tracer.Parent = self.effectsFolder

    -- Auto-cleanup
    game:GetService("Debris"):AddItem(tracer, DEFAULT_SETTINGS.TRACER_LIFETIME)

    -- Fade out tracer
    TweenService:Create(
        tracer, 
        TweenInfo.new(DEFAULT_SETTINGS.TRACER_LIFETIME), 
        {Transparency = 1}
    ):Play()
end

-- Create impact effect at hit position
function WeaponFiringSystem:createImpactEffect(hitInfo)
    if hitInfo.isMaxDistance then return end

    -- Create impact point
    local impact = Instance.new("Part")
    impact.Size = Vector3.new(
        DEFAULT_SETTINGS.IMPACT_SIZE, 
        DEFAULT_SETTINGS.IMPACT_SIZE, 
        DEFAULT_SETTINGS.IMPACT_SIZE / 10
    )
    impact.CFrame = CFrame.lookAt(
        hitInfo.hitPosition + hitInfo.hitNormal * 0.01, 
        hitInfo.hitPosition + hitInfo.hitNormal
    )
    impact.Anchored = true
    impact.CanCollide = false
    impact.Parent = self.effectsFolder

    -- Set material-based properties
    if hitInfo.material == Enum.Material.Concrete then
        impact.Color = Color3.fromRGB(150, 150, 150)
        impact.Material = Enum.Material.Concrete
    elseif hitInfo.material == Enum.Material.Metal then
        impact.Color = Color3.fromRGB(200, 200, 200)
        impact.Material = Enum.Material.Metal
    elseif hitInfo.material == Enum.Material.Wood then
        impact.Color = Color3.fromRGB(120, 80, 60)
        impact.Material = Enum.Material.Wood
    else
        impact.Color = Color3.fromRGB(100, 100, 100)
    end

    -- Auto-cleanup
    game:GetService("Debris"):AddItem(impact, DEFAULT_SETTINGS.HIT_EFFECT_LIFETIME)

    -- Fade out impact
    TweenService:Create(
        impact, 
        TweenInfo.new(DEFAULT_SETTINGS.HIT_EFFECT_LIFETIME), 
        {Transparency = 1}
    ):Play()

    -- Check if we hit a character
    if hitInfo.hitPart then
        local character = hitInfo.hitPart:FindFirstAncestorOfClass("Model")
        if character and character:FindFirstChild("Humanoid") then
            -- Create blood effect
            local blood = Instance.new("Part")
            blood.Size = Vector3.new(0.3, 0.3, 0.01)
            blood.CFrame = CFrame.lookAt(
                hitInfo.hitPosition + hitInfo.hitNormal * 0.02, 
                hitInfo.hitPosition + hitInfo.hitNormal
            )
            blood.Anchored = true
            blood.CanCollide = false
            blood.Color = Color3.fromRGB(150, 0, 0)
            blood.Material = Enum.Material.SmoothPlastic
            blood.Parent = self.effectsFolder

            -- Auto-cleanup
            game:GetService("Debris"):AddItem(blood, DEFAULT_SETTINGS.HIT_EFFECT_LIFETIME)

            -- Fade out blood
            TweenService:Create(
                blood, 
                TweenInfo.new(DEFAULT_SETTINGS.HIT_EFFECT_LIFETIME), 
                {Transparency = 1, Size = blood.Size * 1.5}
            ):Play()

            -- Notify server about hit
            self.hitEvent:FireServer(character, hitInfo.hitPart.Name, self.currentWeapon.Name)
        end
    end
end

-- Apply recoil to camera
function WeaponFiringSystem:applyRecoil()
    if not self.viewmodel then return end

    local recoilAmount = self.currentWeapon:GetAttribute("Recoil") or DEFAULT_SETTINGS.DEFAULT_RECOIL
    if self.viewmodel.isAiming then
        recoilAmount = recoilAmount * 0.7 -- Less recoil when aiming
    end

    -- Vertical recoil
    local verticalRecoil = recoilAmount * (0.8 + math.random() * 0.4)

    -- Horizontal recoil (random direction)
    local horizontalRecoil = recoilAmount * (math.random() - 0.5) * 0.5

    -- Apply to camera (if available)
    if self.viewmodel.addRecoil then
        self.viewmodel:addRecoil(verticalRecoil, horizontalRecoil)
    end
end

-- Reload the current weapon
function WeaponFiringSystem:reload()
    if self.isReloading or not self.currentWeapon then return false end

    local ammo = self.ammoData[self.currentWeapon.Name]
    if not ammo then return false end

    -- Check if we need to reload
    if ammo.currentMagazine >= ammo.magazineSize or ammo.reserveAmmo <= 0 then
        return false
    end

    -- Start reloading
    self.isReloading = true

    -- Get reload time
    local reloadTime = self.currentWeapon:GetAttribute("ReloadTime") or 2.5

    -- Play reload animation/sound
    self:playSound("Reload")

    -- Notify server
    self.reloadEvent:FireServer(self.currentWeapon.Name)

    -- Schedule reload completion
    task.delay(reloadTime, function()
        -- Calculate ammo to add
        local ammoNeeded = ammo.magazineSize - ammo.currentMagazine
        local ammoToAdd = math.min(ammoNeeded, ammo.reserveAmmo)

        -- Update ammo counts
        ammo.currentMagazine = ammo.currentMagazine + ammoToAdd
        ammo.reserveAmmo = ammo.reserveAmmo - ammoToAdd

        -- Complete reload
        self.isReloading = false

        print("Reload complete. Magazine: " .. ammo.currentMagazine .. ", Reserve: " .. ammo.reserveAmmo)
    end)

    return true
end

-- Play sound effect
function WeaponFiringSystem:playSound(soundName)
    local soundId
    
    -- Try to get sound from weapon config first
    if _G.FPSController and _G.FPSController.state and _G.FPSController.state.currentWeapon then
        local weaponConfig = _G.FPSController.state.currentWeapon.config
        if weaponConfig and weaponConfig.sounds then
            local soundKey = soundName:lower()
            soundId = weaponConfig.sounds[soundKey] or weaponConfig.sounds.fire
        end
    end
    
    -- Fallback to default sounds if weapon config not available
    if not soundId then
        if soundName == "Fire" then
            soundId = "rbxassetid://4759267374" -- G36 fire sound
        elseif soundName == "Reload" then
            soundId = "rbxassetid://799954844" -- Reload sound
        elseif soundName == "EmptyClick" then
            soundId = "rbxassetid://91170486" -- Empty click sound
        end
    end

    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.5
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
        sound.MaxDistance = 1000

        -- Play from weapon if possible, otherwise from camera
        if self.currentWeapon and self.currentWeapon.PrimaryPart then
            sound.Parent = self.currentWeapon.PrimaryPart
        else
            sound.Parent = self.camera
        end

        sound:Play()
        print("Playing weapon sound:", soundName, "ID:", soundId)

        -- Auto-cleanup
        game:GetService("Debris"):AddItem(sound, 2)
    else
        print("No sound ID found for:", soundName)
    end
end

-- Handle damage from weapon hit
function WeaponFiringSystem:handleDamage(hitInfo)
    if not hitInfo or not hitInfo.target then return end
    
    local target = hitInfo.target
    local hitPart = hitInfo.hitPart
    
    -- Check if target is a character with humanoid or test rig
    local character = target.Parent
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if not humanoid then
        -- Check if it's a test rig directly
        humanoid = target:FindFirstChild("Humanoid")
        if humanoid then
            character = target
        else
            return -- Not a valid damage target
        end
    end
    
    -- Get weapon damage
    local damage = 30 -- Default damage
    
    -- Try to get damage from weapon config
    if _G.FPSController and _G.FPSController.state and _G.FPSController.state.currentWeapon then
        local weaponConfig = _G.FPSController.state.currentWeapon.config
        if weaponConfig and weaponConfig.damage then
            damage = weaponConfig.damage
        end
    end
    
    -- Apply damage through damage system if available
    if _G.DamageSystem then
        _G.DamageSystem:applyDamage(character, damage, hitPart and hitPart.Name or "Torso", "bullet", self.player)
    else
        -- Fallback direct damage
        humanoid:TakeDamage(damage)
        print("Applied", damage, "damage to", character.Name, "at", hitPart and hitPart.Name or "unknown")
    end
end

-- Get ammo display information
function WeaponFiringSystem:getAmmoDisplay()
    if not self.currentWeapon then
        return "0 / 0"
    end

    local ammo = self.ammoData[self.currentWeapon.Name]
    if not ammo then
        return "0 / 0"
    end

    return ammo.currentMagazine .. " / " .. ammo.reserveAmmo
end

-- Clean up
function WeaponFiringSystem:cleanup()
    if self.firingConnection then
        self.firingConnection:Disconnect()
        self.firingConnection = nil
    end

    if self.effectsFolder then
        self.effectsFolder:Destroy()
    end
end

return WeaponFiringSystem
