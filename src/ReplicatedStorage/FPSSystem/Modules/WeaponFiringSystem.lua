-- Enhanced Weapon Firing System with Fixed Arithmetic Operations
-- Place in ReplicatedStorage.FPSSystem.Modules.WeaponFiringSystem
local WeaponFiringSystem = {}
WeaponFiringSystem.__index = WeaponFiringSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

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
    MUZZLE_FLASH_DURATION = 0.05,
    PENETRATION_POWER = 1.0,
    MAX_PENETRATIONS = 3
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
    local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem")
    local remoteEventsFolder = fpsSystem:WaitForChild("RemoteEvents")

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

    print("Weapon set:", weaponModel.Name)
end

-- Enhanced raycast with penetration and Include/Exclude terminology
function WeaponFiringSystem:performAdvancedRaycast()
    local muzzleAttachment = self:getMuzzleAttachment()
    local rayOrigin = muzzleAttachment and muzzleAttachment.WorldPosition or self.camera.CFrame.Position

    -- Direction with dynamic spread based on weapon state
    local spreadFactor = self:calculateSpread()
    local randomSpread = Vector3.new(
        (math.random() - 0.5) * spreadFactor,
        (math.random() - 0.5) * spreadFactor,
        (math.random() - 0.5) * spreadFactor
    )

    local rayDirection = (self.camera.CFrame.LookVector + randomSpread).Unit

    -- Get weapon stats with safe number checking
    local penetrationPower = self:getWeaponStat("PenetrationPower", DEFAULT_SETTINGS.PENETRATION_POWER)
    local maxPenetrations = self:getWeaponStat("MaxPenetrations", DEFAULT_SETTINGS.MAX_PENETRATIONS)

    -- Perform multiple raycasts for penetration
    local allHits = {}
    local currentOrigin = rayOrigin
    local currentDirection = rayDirection
    local remainingDistance = DEFAULT_SETTINGS.MAX_DISTANCE
    local remainingPenetration = penetrationPower
    local penetrationCount = 0

    -- Setup raycast params with Include/Exclude terminology
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude  -- Using EXCLUDE instead of blacklist
    raycastParams.FilterDescendantsInstances = {
        self.player.Character, 
        self.camera, 
        self.viewmodel and self.viewmodel.container or nil,
        self.effectsFolder
    }

    -- Clean nil values from filter
    local cleanFilter = {}
    for _, instance in ipairs(raycastParams.FilterDescendantsInstances) do
        if instance then
            table.insert(cleanFilter, instance)
        end
    end
    raycastParams.FilterDescendantsInstances = cleanFilter

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
                local thickness = self:estimateObjectThickness(raycastResult.Instance, raycastResult.Position, currentDirection)

                -- Reduce penetration power based on material and thickness
                remainingPenetration = remainingPenetration - (materialResistance * thickness)

                if remainingPenetration > 0 then
                    -- Continue ray from exit point
                    currentOrigin = raycastResult.Position + currentDirection * (thickness + 0.1)
                    remainingDistance = remainingDistance - hitInfo.distance - thickness
                    penetrationCount = penetrationCount + 1

                    -- Add hit part to exclude list
                    table.insert(raycastParams.FilterDescendantsInstances, raycastResult.Instance)
                else
                    break
                end
            else
                break
            end
        else
            break
        end
    end

    return allHits
end

-- Safe weapon stat getter to prevent table multiplication errors
function WeaponFiringSystem:getWeaponStat(statName, defaultValue)
    if not self.currentWeapon then 
        return defaultValue or 0 
    end

    local value = self.currentWeapon:GetAttribute(statName)

    -- Ensure we return a number, not a table
    if type(value) == "number" then
        return value
    elseif type(value) == "table" then
        -- If it's a table, try to get a reasonable number value
        if value.base then
            return tonumber(value.base) or defaultValue or 0
        elseif value[1] then
            return tonumber(value[1]) or defaultValue or 0
        else
            warn("Weapon stat '" .. statName .. "' is a table but cannot extract number value")
            return defaultValue or 0
        end
    else
        return defaultValue or 0
    end
end

-- Calculate weapon spread
function WeaponFiringSystem:calculateSpread()
    local baseSpread = self:getWeaponStat("BaseSpread", 0.01)
    local aimingSpread = self:getWeaponStat("AimingSpread", 0.003)
    local movementSpread = self:getWeaponStat("MovementSpread", 0.005)

    local currentSpread = baseSpread

    -- Reduce spread when aiming
    if self.viewmodel and self.viewmodel.isAiming then
        currentSpread = aimingSpread
    end

    -- Increase spread when moving
    if self.player.Character and self.player.Character:FindFirstChild("Humanoid") then
        local humanoid = self.player.Character.Humanoid
        if humanoid.MoveDirection.Magnitude > 0 then
            currentSpread = currentSpread + movementSpread
        end
    end

    return currentSpread
end

-- Fire the weapon
function WeaponFiringSystem:fire()
    if not self.canFire or not self.currentWeapon then return false end

    local currentTime = tick()
    local fireRate = self:getWeaponStat("FireRate", 600) -- RPM
    local fireInterval = 60 / fireRate

    -- Check fire rate
    if currentTime - self.lastFireTime < fireInterval then
        return false
    end

    -- Check ammo
    local ammo = self.ammoData[self.currentWeapon.Name]
    if not ammo or ammo.currentMagazine <= 0 then
        print("Out of ammo!")
        return false
    end

    -- Perform raycast
    local hits = self:performAdvancedRaycast()

    -- Process hits
    if #hits > 0 then
        local primaryHit = hits[1]
        self:handleHit(primaryHit, hits)

        -- Create visual effects
        self:createBulletTracer(primaryHit.hitPosition)
        self:createImpactEffect(primaryHit.hitPosition, primaryHit.hitNormal, primaryHit.material)
    end

    -- Create weapon effects
    self:createMuzzleFlash()
    self:createShellCasing()

    -- Apply recoil
    self:applyRecoil()

    -- Update ammo
    ammo.currentMagazine = ammo.currentMagazine - 1

    -- Update last fire time
    self.lastFireTime = currentTime

    -- Send to server
    if self.fireEvent then
        self.fireEvent:FireServer(hits)
    end

    return true
end

-- Handle weapon hit
function WeaponFiringSystem:handleHit(primaryHit, allHits)
    local hitPart = primaryHit.hitPart
    local hitPosition = primaryHit.hitPosition

    -- Find character and humanoid
    local character = hitPart:FindFirstAncestorOfClass("Model")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and character ~= self.player.Character then
        -- Calculate damage
        local baseDamage = self:getWeaponStat("Damage", 25)
        local headMultiplier = self:getWeaponStat("HeadMultiplier", 2.0)
        local limbMultiplier = self:getWeaponStat("LimbMultiplier", 0.9)

        local damage = baseDamage

        -- Apply multipliers based on hit location
        if hitPart.Name == "Head" then
            damage = damage * headMultiplier
        elseif hitPart.Name:find("Arm") or hitPart.Name:find("Leg") then
            damage = damage * limbMultiplier
        end

        -- Apply damage through server
        if self.hitEvent then
            self.hitEvent:FireServer(character, damage, hitPart.Name, allHits)
        end

        print("Hit " .. character.Name .. " for " .. damage .. " damage")
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
        [Enum.Material.ForceField] = 10.0
    }

    return resistanceMap[material] or 0.5
end

-- Estimate object thickness
function WeaponFiringSystem:estimateObjectThickness(part, hitPosition, direction)
    local size = part.Size
    local avgSize = (size.X + size.Y + size.Z) / 3
    return math.min(avgSize * 0.3, 5)
end

-- Get muzzle attachment
function WeaponFiringSystem:getMuzzleAttachment()
    if not self.currentWeapon or not self.currentWeapon.PrimaryPart then return nil end
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
    Debris:AddItem(muzzleLight, DEFAULT_SETTINGS.MUZZLE_FLASH_DURATION)
    Debris:AddItem(flashPart, DEFAULT_SETTINGS.MUZZLE_FLASH_DURATION)

    -- Fade out flash
    TweenService:Create(
        flashPart,
        TweenInfo.new(DEFAULT_SETTINGS.MUZZLE_FLASH_DURATION),
        {Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}
    ):Play()
end

-- Create shell casing ejection
function WeaponFiringSystem:createShellCasing()
    local weapon = self.currentWeapon
    if not weapon or not weapon.PrimaryPart then return end

    local shellPoint = weapon.PrimaryPart:FindFirstChild("ShellEjectPoint")
    if not shellPoint then return end

    local shell = Instance.new("Part")
    shell.Size = Vector3.new(0.05, 0.15, 0.05)
    shell.CFrame = shellPoint.WorldCFrame
    shell.Color = Color3.fromRGB(200, 180, 0)
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

    Debris:AddItem(shell, DEFAULT_SETTINGS.SHELL_CASING_LIFETIME)
end

-- Create bullet tracer
function WeaponFiringSystem:createBulletTracer(hitPosition)
    local muzzleAttachment = self:getMuzzleAttachment()
    if not muzzleAttachment then return end

    local startPos = muzzleAttachment.WorldPosition
    local endPos = hitPosition

    local tracer = Instance.new("Part")
    tracer.Size = Vector3.new(
        DEFAULT_SETTINGS.TRACER_WIDTH, 
        DEFAULT_SETTINGS.TRACER_WIDTH, 
        (endPos - startPos).Magnitude
    )
    tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -tracer.Size.Z/2)
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Material = Enum.Material.Neon
    tracer.Color = Color3.fromRGB(255, 200, 100)
    tracer.Transparency = 0.2
    tracer.Parent = self.effectsFolder

    Debris:AddItem(tracer, DEFAULT_SETTINGS.TRACER_LIFETIME)

    TweenService:Create(
        tracer, 
        TweenInfo.new(DEFAULT_SETTINGS.TRACER_LIFETIME), 
        {Transparency = 1}
    ):Play()
end

-- Create impact effect
function WeaponFiringSystem:createImpactEffect(position, normal, material)
    local impactPart = Instance.new("Part")
    impactPart.Size = Vector3.new(DEFAULT_SETTINGS.IMPACT_SIZE, DEFAULT_SETTINGS.IMPACT_SIZE, DEFAULT_SETTINGS.IMPACT_SIZE)
    impactPart.CFrame = CFrame.new(position, position + normal)
    impactPart.Anchored = true
    impactPart.CanCollide = false
    impactPart.Material = Enum.Material.Neon
    impactPart.Color = Color3.fromRGB(255, 255, 0)
    impactPart.Shape = Enum.PartType.Ball
    impactPart.Parent = self.effectsFolder

    Debris:AddItem(impactPart, DEFAULT_SETTINGS.HIT_EFFECT_LIFETIME)

    TweenService:Create(
        impactPart,
        TweenInfo.new(DEFAULT_SETTINGS.HIT_EFFECT_LIFETIME),
        {Size = Vector3.new(0, 0, 0), Transparency = 1}
    ):Play()
end

-- Apply recoil
function WeaponFiringSystem:applyRecoil()
    if not self.viewmodel then return end

    local verticalRecoil = self:getWeaponStat("VerticalRecoil", 0.3)
    local horizontalRecoil = self:getWeaponStat("HorizontalRecoil", 0.1)

    -- Apply recoil to viewmodel
    if self.viewmodel.applyRecoil then
        self.viewmodel:applyRecoil(verticalRecoil, horizontalRecoil)
    end
end

-- Reload weapon
function WeaponFiringSystem:reload()
    if self.isReloading or not self.currentWeapon then return false end

    local ammo = self.ammoData[self.currentWeapon.Name]
    if not ammo or ammo.currentMagazine >= ammo.magazineSize or ammo.reserveAmmo <= 0 then
        return false
    end

    self.isReloading = true

    local reloadTime = self:getWeaponStat("ReloadTime", 2.5)

    -- Play reload animation
    if self.viewmodel and self.viewmodel.playAnimation then
        self.viewmodel:playAnimation("reload")
    end

    -- Complete reload after delay
    wait(reloadTime)

    -- Calculate ammo to reload
    local ammoNeeded = ammo.magazineSize - ammo.currentMagazine
    local ammoToReload = math.min(ammoNeeded, ammo.reserveAmmo)

    ammo.currentMagazine = ammo.currentMagazine + ammoToReload
    ammo.reserveAmmo = ammo.reserveAmmo - ammoToReload

    self.isReloading = false

    -- Send to server
    if self.reloadEvent then
        self.reloadEvent:FireServer()
    end

    return true
end

-- Get ammo display
function WeaponFiringSystem:getAmmoDisplay()
    if not self.currentWeapon then return "0 / 0" end

    local ammo = self.ammoData[self.currentWeapon.Name]
    if not ammo then return "0 / 0" end

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