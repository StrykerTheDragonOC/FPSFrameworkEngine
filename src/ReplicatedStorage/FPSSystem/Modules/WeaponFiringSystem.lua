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
    -- Get or create RemoteEvent for weapon firing
    self.fireEvent = ReplicatedStorage:FindFirstChild("WeaponFired")
    if not self.fireEvent then
        self.fireEvent = Instance.new("RemoteEvent")
        self.fireEvent.Name = "WeaponFired"
        self.fireEvent.Parent = ReplicatedStorage
    end

    -- Get or create RemoteEvent for hit registration
    self.hitEvent = ReplicatedStorage:FindFirstChild("WeaponHit")
    if not self.hitEvent then
        self.hitEvent = Instance.new("RemoteEvent")
        self.hitEvent.Name = "WeaponHit"
        self.hitEvent.Parent = ReplicatedStorage
    end

    -- Get or create RemoteEvent for reloading
    self.reloadEvent = ReplicatedStorage:FindFirstChild("WeaponReload")
    if not self.reloadEvent then
        self.reloadEvent = Instance.new("RemoteEvent")
        self.reloadEvent.Name = "WeaponReload"
        self.reloadEvent.Parent = ReplicatedStorage
    end
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

    -- Create visual effects
    self:createMuzzleFlash()
    self:createShellCasing()

    -- Perform raycast to find target
    local hitInfo = self:performRaycast()

    -- Create bullet tracer
    if hitInfo then
        self:createBulletTracer(hitInfo.hitPosition)
        self:createImpactEffect(hitInfo)
    end

    -- Apply recoil
    self:applyRecoil()

    -- Notify server about firing
    self.fireEvent:FireServer(self.currentWeapon.Name, hitInfo)

    return true
end

-- Perform raycast to find hit target
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

    local rayDirection = (self.camera.CFrame.LookVector + randomSpread).Unit * DEFAULT_SETTINGS.MAX_DISTANCE

    -- Setup raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude -- Updated from Blacklist (deprecated)
    raycastParams.FilterDescendantsInstances = {self.player.Character, self.camera, self.viewmodel.container}

    -- Perform raycast
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        return {
            hitPart = raycastResult.Instance,
            hitPosition = raycastResult.Position,
            hitNormal = raycastResult.Normal,
            material = raycastResult.Material,
            distance = (raycastResult.Position - rayOrigin).Magnitude
        }
    else
        -- No hit, return endpoint
        return {
            hitPosition = rayOrigin + rayDirection,
            distance = DEFAULT_SETTINGS.MAX_DISTANCE,
            isMaxDistance = true
        }
    end
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
    -- This is a placeholder. In a real implementation, you would:
    -- 1. Check if the weapon has the specific sound
    -- 2. Or use a generic sound from a sound library
    print("Playing sound: " .. soundName)

    -- Example implementation:
    local soundId
    if soundName == "Fire" then
        soundId = "rbxassetid://1905367471" -- Placeholder
    elseif soundName == "Reload" then
        soundId = "rbxassetid://138084889" -- Placeholder
    elseif soundName == "EmptyClick" then
        soundId = "rbxassetid://255061173" -- Placeholder
    end

    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 1

        -- Play from weapon if possible
        if self.currentWeapon and self.currentWeapon.PrimaryPart then
            sound.Parent = self.currentWeapon.PrimaryPart
        else
            sound.Parent = self.camera
        end

        sound:Play()

        -- Auto-cleanup
        game:GetService("Debris"):AddItem(sound, 2)
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