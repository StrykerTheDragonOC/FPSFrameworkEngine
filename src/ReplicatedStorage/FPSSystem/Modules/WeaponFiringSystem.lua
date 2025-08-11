-- WeaponFiringSystem.lua
-- Fixed weapon firing system with modern raycast and proper Include/Exclude terminology
-- Place in ReplicatedStorage.FPSSystem.Modules.WeaponFiringSystem

local WeaponFiringSystem = {}
WeaponFiringSystem.__index = WeaponFiringSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

-- Default weapon settings
local DEFAULT_SETTINGS = {
    DAMAGE = 30,
    RANGE = 1000,
    FIRE_RATE = 600,  -- RPM
    MAGAZINE_SIZE = 30,
    RESERVE_AMMO = 120,
    RECOIL_PATTERN = {
        {0, 0.1}, {-0.05, 0.15}, {0.1, 0.2}, {-0.1, 0.25}, {0.05, 0.3}
    },
    SPREAD = {
        HIP = 0.05,
        ADS = 0.02,
        MOVING = 0.08,
        JUMPING = 0.15
    },
    PENETRATION_POWER = 1.0,
    MAX_PENETRATIONS = 2,
    BULLET_VELOCITY = 800,
    BULLET_DROP = 9.81,
    MUZZLE_VELOCITY = 400
}

-- Fire modes
local FIRE_MODES = {
    SEMI = "Semi",
    AUTO = "Auto", 
    BURST = "Burst"
}

function WeaponFiringSystem.new(viewmodelSystem)
    local self = setmetatable({}, WeaponFiringSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.camera = workspace.CurrentCamera
    self.viewmodel = viewmodelSystem

    -- Weapon state
    self.currentWeapon = nil
    self.weaponStats = {}
    self.ammoData = {}
    self.isEquipped = false

    -- Firing state
    self.canFire = true
    self.isFiring = false
    self.isReloading = false
    self.fireMode = FIRE_MODES.AUTO
    self.burstCount = 0
    self.lastFireTime = 0

    -- Recoil system
    self.recoilPattern = {}
    self.currentRecoilIndex = 1
    self.recoilMultiplier = 1
    self.currentRecoil = Vector2.new()
    self.targetRecoil = Vector2.new()

    -- Effects and folders
    self.effectsFolder = workspace:FindFirstChild("WeaponEffects")
    if not self.effectsFolder then
        self.effectsFolder = Instance.new("Folder")
        self.effectsFolder.Name = "WeaponEffects"
        self.effectsFolder.Parent = workspace
    end

    -- Get modern raycast system
    self.raycastSystem = self:getRaycastSystem()

    -- Setup connections
    self:setupConnections()

    return self
end

-- Get or create modern raycast system
function WeaponFiringSystem:getRaycastSystem()
    if _G.ModernRaycastSystem then
        return _G.ModernRaycastSystem
    end

    -- Try to require the modern raycast system
    local success, raycastModule = pcall(function()
        return require(ReplicatedStorage.FPSSystem.Modules.ModernRaycastSystem)
    end)

    if success and raycastModule then
        local system = raycastModule.new()
        _G.ModernRaycastSystem = system
        return system
    end

    warn("[WeaponFiring] Could not load ModernRaycastSystem, using fallback")
    return nil
end

-- Setup input connections
function WeaponFiringSystem:setupConnections()
    -- Fire input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:startFiring()
        elseif input.KeyCode == Enum.KeyCode.R then
            self:reload()
        elseif input.KeyCode == Enum.KeyCode.B then
            self:cyclefireMode()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:stopFiring()
        end
    end)

    -- Character setup
    local function onCharacterAdded(character)
        self.character = character
        if self.raycastSystem then
            self.raycastSystem:updateDefaultExcludes()
        end
    end

    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end
    self.player.CharacterAdded:Connect(onCharacterAdded)
end

-- Set current weapon
function WeaponFiringSystem:setWeapon(weaponModel)
    if not weaponModel then
        warn("[WeaponFiring] Invalid weapon model")
        return false
    end

    self.currentWeapon = weaponModel

    -- Load weapon stats
    self:loadWeaponStats(weaponModel)

    -- Initialize ammo data if not already set
    if not self.ammoData[weaponModel.Name] then
        local magazineSize = self:getWeaponStat("MagazineSize", DEFAULT_SETTINGS.MAGAZINE_SIZE)

        self.ammoData[weaponModel.Name] = {
            currentMagazine = magazineSize,
            reserveAmmo = magazineSize * 3,
            magazineSize = magazineSize
        }
    end

    self.isEquipped = true
    print("[WeaponFiring] Weapon set:", weaponModel.Name)
    return true
end

-- Load weapon stats from attributes or config
function WeaponFiringSystem:loadWeaponStats(weaponModel)
    self.weaponStats = {
        damage = weaponModel:GetAttribute("Damage") or DEFAULT_SETTINGS.DAMAGE,
        range = weaponModel:GetAttribute("Range") or DEFAULT_SETTINGS.RANGE,
        fireRate = weaponModel:GetAttribute("FireRate") or DEFAULT_SETTINGS.FIRE_RATE,
        magazineSize = weaponModel:GetAttribute("MagazineSize") or DEFAULT_SETTINGS.MAGAZINE_SIZE,
        reserveAmmo = weaponModel:GetAttribute("ReserveAmmo") or DEFAULT_SETTINGS.RESERVE_AMMO,
        penetrationPower = weaponModel:GetAttribute("PenetrationPower") or DEFAULT_SETTINGS.PENETRATION_POWER,
        maxPenetrations = weaponModel:GetAttribute("MaxPenetrations") or DEFAULT_SETTINGS.MAX_PENETRATIONS,
        bulletVelocity = weaponModel:GetAttribute("BulletVelocity") or DEFAULT_SETTINGS.BULLET_VELOCITY,
        muzzleVelocity = weaponModel:GetAttribute("MuzzleVelocity") or DEFAULT_SETTINGS.MUZZLE_VELOCITY
    }

    -- Load recoil pattern
    self.recoilPattern = DEFAULT_SETTINGS.RECOIL_PATTERN
    self.currentRecoilIndex = 1

    print("[WeaponFiring] Loaded stats for:", weaponModel.Name)
end

-- Get weapon stat with fallback
function WeaponFiringSystem:getWeaponStat(statName, fallback)
    if self.weaponStats and self.weaponStats[statName] then
        local value = self.weaponStats[statName]
        if type(value) == "number" and value == value then -- Check for NaN
            return value
        end
    end
    return fallback or 0
end

-- Start firing
function WeaponFiringSystem:startFiring()
    if not self:canStartFiring() then return end

    self.isFiring = true

    if self.fireMode == FIRE_MODES.SEMI then
        self:fireBullet()
    elseif self.fireMode == FIRE_MODES.AUTO then
        self:startAutoFire()
    elseif self.fireMode == FIRE_MODES.BURST then
        self:fireBurst()
    end
end

-- Stop firing
function WeaponFiringSystem:stopFiring()
    self.isFiring = false
    self.burstCount = 0
end

-- Check if can start firing
function WeaponFiringSystem:canStartFiring()
    if not self.isEquipped or not self.currentWeapon then return false end
    if self.isReloading then return false end
    if not self.canFire then return false end

    local ammoData = self.ammoData[self.currentWeapon.Name]
    if not ammoData or ammoData.currentMagazine <= 0 then
        self:playDryFireSound()
        return false
    end

    return true
end

-- Start automatic firing
function WeaponFiringSystem:startAutoFire()
    local fireRate = self:getWeaponStat("fireRate", DEFAULT_SETTINGS.FIRE_RATE)
    local fireInterval = 60 / fireRate -- Convert RPM to seconds between shots

    local function autoFireLoop()
        if not self.isFiring or not self:canStartFiring() then return end

        self:fireBullet()

        task.wait(fireInterval)
        autoFireLoop()
    end

    autoFireLoop()
end

-- Fire burst
function WeaponFiringSystem:fireBurst()
    local burstSize = 3
    local burstDelay = 0.1

    for i = 1, burstSize do
        if not self:canStartFiring() then break end

        self:fireBullet()
        self.burstCount = self.burstCount + 1

        if i < burstSize then
            task.wait(burstDelay)
        end
    end

    self.burstCount = 0
end

-- Fire a single bullet
function WeaponFiringSystem:fireBullet()
    local currentTime = tick()
    local fireRate = self:getWeaponStat("fireRate", DEFAULT_SETTINGS.FIRE_RATE)
    local fireInterval = 60 / fireRate

    if currentTime - self.lastFireTime < fireInterval then
        return false
    end

    self.lastFireTime = currentTime

    -- Check ammo
    local ammoData = self.ammoData[self.currentWeapon.Name]
    if not ammoData or ammoData.currentMagazine <= 0 then
        return false
    end

    -- Consume ammo
    ammoData.currentMagazine = ammoData.currentMagazine - 1

    -- Perform raycast
    local hits = self:performAdvancedRaycast()

    -- Process hits
    for _, hitData in ipairs(hits) do
        self:processHit(hitData)
    end

    -- Apply recoil
    self:applyRecoil()

    -- Play effects
    self:playMuzzleFlash()
    self:playFireSound()
    self:ejectShell()

    -- Create bullet trail
    if #hits > 0 then
        self:createBulletTrail(hits[1].result.Position)
    end

    return true
end

-- Enhanced raycast with penetration using Include/Exclude terminology
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

    -- Get weapon stats
    local maxDistance = self:getWeaponStat("range", DEFAULT_SETTINGS.RANGE)
    local penetrationPower = self:getWeaponStat("penetrationPower", DEFAULT_SETTINGS.PENETRATION_POWER)
    local damage = self:getWeaponStat("damage", DEFAULT_SETTINGS.DAMAGE)

    -- Use modern raycast system if available
    if self.raycastSystem then
        return self.raycastSystem:weaponRaycast(rayOrigin, rayDirection, maxDistance, penetrationPower, damage)
    else
        -- Fallback to simple raycast with modern Include/Exclude terminology
        return self:fallbackRaycast(rayOrigin, rayDirection, maxDistance, damage)
    end
end

-- Fallback raycast using modern Include/Exclude terminology
function WeaponFiringSystem:fallbackRaycast(origin, direction, maxDistance, damage)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude  -- Using EXCLUDE instead of blacklist

    -- Build exclude list
    local excludeList = {
        self.player.Character, 
        self.camera, 
        self.effectsFolder
    }

    -- Add viewmodel to exclude list
    if self.viewmodel and self.viewmodel.currentViewmodel then
        table.insert(excludeList, self.viewmodel.currentViewmodel)
    end

    raycastParams.FilterDescendantsInstances = excludeList
    raycastParams.RespectCanCollide = true

    local rayDirection = direction * maxDistance
    local result = workspace:Raycast(origin, rayDirection, raycastParams)

    if result then
        return {{
            result = result,
            damage = damage,
            penetrationCount = 0,
            distance = (result.Position - origin).Magnitude
        }}
    else
        return {}
    end
end

-- Calculate spread based on current state
function WeaponFiringSystem:calculateSpread()
    local baseSpread = DEFAULT_SETTINGS.SPREAD.HIP

    -- Check if aiming
    if self.viewmodel and self.viewmodel.isAiming then
        baseSpread = DEFAULT_SETTINGS.SPREAD.ADS
    end

    -- Check if moving
    if self.character and self.character:FindFirstChild("Humanoid") then
        local humanoid = self.character.Humanoid
        if humanoid.MoveDirection.Magnitude > 0 then
            baseSpread = baseSpread + DEFAULT_SETTINGS.SPREAD.MOVING
        end

        -- Check if jumping
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall or 
            humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            baseSpread = baseSpread + DEFAULT_SETTINGS.SPREAD.JUMPING
        end
    end

    return baseSpread
end

-- Process hit result
function WeaponFiringSystem:processHit(hitData)
    local result = hitData.result
    local damage = hitData.damage

    if not result or not result.Instance then return end

    -- Create hit effect
    self:createHitEffect(result.Position, result.Normal, result.Instance.Material)

    -- Check for humanoid hit
    local humanoid = result.Instance.Parent:FindFirstChild("Humanoid")
    if humanoid and humanoid.Parent ~= self.character then
        self:damagePlayer(humanoid.Parent, damage, result.Instance.Name)
    end

    -- Create bullet hole
    self:createBulletHole(result.Position, result.Normal, result.Instance)
end

-- Apply recoil
function WeaponFiringSystem:applyRecoil()
    if not self.recoilPattern or #self.recoilPattern == 0 then return end

    local recoilData = self.recoilPattern[self.currentRecoilIndex] or self.recoilPattern[#self.recoilPattern]

    self.targetRecoil = self.targetRecoil + Vector2.new(recoilData[1], recoilData[2]) * self.recoilMultiplier

    -- Advance recoil pattern
    self.currentRecoilIndex = math.min(self.currentRecoilIndex + 1, #self.recoilPattern)

    -- Apply to camera
    local camera = self.camera
    local recoilCFrame = CFrame.Angles(
        math.rad(-self.targetRecoil.Y),
        math.rad(self.targetRecoil.X),
        0
    )

    camera.CFrame = camera.CFrame * recoilCFrame

    -- Gradually reduce recoil
    task.delay(0.1, function()
        self.targetRecoil = self.targetRecoil * 0.8
    end)
end

-- Reset recoil pattern
function WeaponFiringSystem:resetRecoil()
    self.currentRecoilIndex = 1
    self.targetRecoil = Vector2.new()
    self.currentRecoil = Vector2.new()
end

-- Get muzzle attachment
function WeaponFiringSystem:getMuzzleAttachment()
    if self.viewmodel then
        return self.viewmodel:getMuzzleAttachment()
    end
    return nil
end

-- Damage player
function WeaponFiringSystem:damagePlayer(targetCharacter, damage, hitPart)
    print(string.format("[WeaponFiring] Hit %s for %d damage on %s", 
        targetCharacter.Name, damage, hitPart))

    -- TODO: Implement server-side damage validation
    -- This should send a remote event to the server for damage processing
end

-- Reload weapon
function WeaponFiringSystem:reload()
    if not self.isEquipped or not self.currentWeapon then return end
    if self.isReloading then return end

    local ammoData = self.ammoData[self.currentWeapon.Name]
    if not ammoData then return end

    if ammoData.currentMagazine >= ammoData.magazineSize or ammoData.reserveAmmo <= 0 then
        return
    end

    self.isReloading = true
    self.canFire = false

    print("[WeaponFiring] Reloading...")

    -- Play reload sound
    self:playReloadSound()

    -- Calculate reload time based on weapon
    local reloadTime = 2.5 -- Default reload time

    task.wait(reloadTime)

    -- Calculate ammo to reload
    local neededAmmo = ammoData.magazineSize - ammoData.currentMagazine
    local ammoToReload = math.min(neededAmmo, ammoData.reserveAmmo)

    ammoData.currentMagazine = ammoData.currentMagazine + ammoToReload
    ammoData.reserveAmmo = ammoData.reserveAmmo - ammoToReload

    self.isReloading = false
    self.canFire = true

    -- Reset recoil
    self:resetRecoil()

    print("[WeaponFiring] Reload complete")
end

-- Cycle fire mode
function WeaponFiringSystem:cyclefireMode()
    local modes = {FIRE_MODES.SEMI, FIRE_MODES.AUTO, FIRE_MODES.BURST}
    local currentIndex = 1

    for i, mode in ipairs(modes) do
        if mode == self.fireMode then
            currentIndex = i
            break
        end
    end

    currentIndex = currentIndex + 1
    if currentIndex > #modes then
        currentIndex = 1
    end

    self.fireMode = modes[currentIndex]
    print("[WeaponFiring] Fire mode:", self.fireMode)
end

-- Get ammo display string
function WeaponFiringSystem:getAmmoDisplay()
    if not self.currentWeapon then return "0 / 0" end

    local ammoData = self.ammoData[self.currentWeapon.Name]
    if not ammoData then return "0 / 0" end

    return string.format("%d / %d", ammoData.currentMagazine, ammoData.reserveAmmo)
end

-- Effects functions (simplified for now)
function WeaponFiringSystem:playMuzzleFlash()
    -- TODO: Implement muzzle flash effect
end

function WeaponFiringSystem:playFireSound()
    -- TODO: Implement fire sound
end

function WeaponFiringSystem:playReloadSound()
    -- TODO: Implement reload sound
end

function WeaponFiringSystem:playDryFireSound()
    -- TODO: Implement dry fire sound
end

function WeaponFiringSystem:ejectShell()
    -- TODO: Implement shell ejection
end

function WeaponFiringSystem:createBulletTrail(hitPosition)
    -- TODO: Implement bullet trail
end

function WeaponFiringSystem:createHitEffect(position, normal, material)
    -- TODO: Implement hit effects
end

function WeaponFiringSystem:createBulletHole(position, normal, surface)
    -- TODO: Implement bullet holes
end

-- Cleanup
function WeaponFiringSystem:cleanup()
    self.isFiring = false
    self.isReloading = false
    self.currentWeapon = nil
    self.isEquipped = false

    if self.raycastSystem then
        self.raycastSystem:cleanup()
    end
end

return WeaponFiringSystem