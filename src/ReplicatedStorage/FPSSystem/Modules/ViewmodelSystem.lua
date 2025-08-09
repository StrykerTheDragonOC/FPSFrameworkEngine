-- FixedViewmodelSystem.lua
-- Place in ReplicatedStorage/FPSSystem/Modules/ViewmodelSystem.lua

local ViewmodelSystem = {}
ViewmodelSystem.__index = ViewmodelSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Constants
local VIEWMODEL_SETTINGS = {
    DEFAULT_POSITION = CFrame.new(0.5, -0.4, -0.6),
    ADS_POSITION = CFrame.new(0, -0.35, -0.3),
    SPRINT_POSITION = CFrame.new(0.7, -0.6, -0.8),

    SWAY = {
        AMOUNT = 0.015,
        SPEED = 10,
        MAX = 0.08
    },

    BOB = {
        AMOUNT = 0.03,
        SPEED = 8,
        SPRINT_MULTIPLIER = 1.8
    }
}

-- Constructor
function ViewmodelSystem.new()
    local self = setmetatable({}, ViewmodelSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.camera = workspace.CurrentCamera

    -- Viewmodel components
    self.currentViewmodel = nil
    self.currentWeaponName = nil
    self.currentWeaponType = nil

    -- Animation system
    self.animator = nil
    self.animationTracks = {}

    -- State tracking
    self.isAiming = false
    self.isSprinting = false
    self.isReloading = false
    self.isFiring = false

    -- Movement effects
    self.currentSway = Vector3.new()
    self.targetSway = Vector3.new()
    self.bobCycle = 0
    self.lastMouseDelta = Vector2.new()

    -- Server viewmodel (for other players to see)
    self.serverViewmodel = nil

    -- Update connection
    self.updateConnection = nil

    return self
end

-- FIXED: Add setupArms method that was missing
function ViewmodelSystem:setupArms(customRig)
    print("[Viewmodel] Setting up arms...")

    -- Create viewmodel container in camera
    local container = self.camera:FindFirstChild("ViewmodelContainer")
    if not container then
        container = Instance.new("Model")
        container.Name = "ViewmodelContainer"
        container.Parent = self.camera
    end

    -- Use custom rig if provided, otherwise create default arms
    if customRig then
        print("[Viewmodel] Using custom viewmodel rig")
        local arms = customRig:Clone()
        arms.Name = "ViewmodelRig"
        arms.Parent = container

        -- Ensure proper visibility and collision settings
        for _, part in pairs(arms:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false  -- FIXED: Prevent collision issues
                part.Anchored = true     -- FIXED: Prevent physics problems
                part.CastShadow = false

                -- Make visible only to local player
                if part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 0
                else
                    part.LocalTransparencyModifier = 1
                end
            end
        end

        print("[Viewmodel] Custom arms setup complete")
    else
        print("[Viewmodel] Creating default arms")
        self:createDefaultArms(container)
    end
end

-- Create default arms if no custom rig
function ViewmodelSystem:createDefaultArms(container)
    local arms = Instance.new("Model")
    arms.Name = "ViewmodelRig"
    arms.Parent = container

    -- Create basic arm parts
    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.BrickColor = BrickColor.new("Light orange")
    leftArm.CanCollide = false
    leftArm.Anchored = true
    leftArm.Parent = arms

    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.BrickColor = BrickColor.new("Light orange")
    rightArm.CanCollide = false
    rightArm.Anchored = true
    rightArm.Parent = arms

    arms.PrimaryPart = rightArm

    print("[Viewmodel] Default arms created")
end

-- Equip weapon using its specific viewmodel rig
function ViewmodelSystem:equipWeapon(weaponName, weaponType)
    print("[Viewmodel] Equipping weapon:", weaponName, "Type:", weaponType)

    -- Clean up existing viewmodel
    if self.currentViewmodel then
        self.currentViewmodel:Destroy()
        self.currentViewmodel = nil
    end

    -- Stop all animations
    self:stopAllAnimations()

    -- Find the weapon's viewmodel rig
    local viewmodelRig = self:findWeaponViewmodel(weaponName, weaponType)
    if not viewmodelRig then
        warn("[Viewmodel] Could not find viewmodel for weapon:", weaponName)
        return false
    end

    -- Clone and setup viewmodel
    self.currentViewmodel = viewmodelRig:Clone()
    self.currentViewmodel.Name = "CurrentViewmodel"
    self.currentViewmodel.Parent = self.camera

    -- Store weapon info
    self.currentWeaponName = weaponName
    self.currentWeaponType = weaponType

    -- Make viewmodel parts invisible to server but visible to client
    for _, part in pairs(self.currentViewmodel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CastShadow = false
            part.Anchored = true  -- FIXED: Prevent physics interference

            -- Set up local transparency
            if part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 0
            else
                part.LocalTransparencyModifier = 1
            end
        end
    end

    -- Setup animator
    self:setupAnimator()

    -- Load animations
    self:loadWeaponAnimations(weaponName, weaponType)

    -- Play idle animation
    self:playAnimation("idle")

    -- Create server-side viewmodel
    self:createServerViewmodel(weaponName)

    print("[Viewmodel] Weapon equipped successfully!")
    return true
end

-- Find weapon's specific viewmodel rig
function ViewmodelSystem:findWeaponViewmodel(weaponName, weaponType)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return nil end

    local animationsFolder = fpsSystem:FindFirstChild("Animations")
    if not animationsFolder then return nil end

    -- Determine category
    local category = nil
    if weaponType == "PRIMARY" then
        category = animationsFolder:FindFirstChild("Primary")
    elseif weaponType == "SECONDARY" then
        category = animationsFolder:FindFirstChild("Secondary")
    elseif weaponType == "MELEE" then
        category = animationsFolder:FindFirstChild("Melee")
    elseif weaponType == "GRENADE" then
        category = animationsFolder:FindFirstChild("Grenades")
    end

    if not category then
        warn("[Viewmodel] Category not found for type:", weaponType)
        return nil
    end

    -- Search in subcategories
    for _, subCategory in pairs(category:GetChildren()) do
        if subCategory:IsA("Folder") then
            local weaponFolder = subCategory:FindFirstChild(weaponName)
            if weaponFolder then
                -- The viewmodel rig should be the model with Humanoid
                for _, child in pairs(weaponFolder:GetChildren()) do
                    if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                        return child
                    end
                end
            end
        end
    end

    -- Direct search as fallback
    local weaponFolder = category:FindFirstChild(weaponName)
    if weaponFolder then
        for _, child in pairs(weaponFolder:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                return child
            end
        end
    end

    return nil
end

-- Setup animator
function ViewmodelSystem:setupAnimator()
    if not self.currentViewmodel then return end

    local humanoid = self.currentViewmodel:FindFirstChild("Humanoid")
        or self.currentViewmodel:FindFirstChild("AnimationController")

    if not humanoid then
        humanoid = Instance.new("Humanoid")
        humanoid.Parent = self.currentViewmodel
    end

    self.animator = humanoid:FindFirstChild("Animator")
    if not self.animator then
        self.animator = Instance.new("Animator")
        self.animator.Parent = humanoid
    end

    print("[Viewmodel] Animator setup complete")
end

-- Load weapon animations
function ViewmodelSystem:loadWeaponAnimations(weaponName, weaponType)
    self.animationTracks = {}

    if not self.animator then
        warn("[Viewmodel] No animator found!")
        return
    end

    -- Find AnimSaves in the viewmodel
    local animSaves = self.currentViewmodel:FindFirstChild("AnimSaves")
    if animSaves then
        for _, anim in pairs(animSaves:GetChildren()) do
            if anim:IsA("Animation") then
                local track = self.animator:LoadAnimation(anim)
                local animName = anim.Name:lower()
                self.animationTracks[animName] = track
                print("[Viewmodel] Loaded animation:", anim.Name)
            end
        end
        return
    end

    -- Fallback: Look in Animations folder
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end

    local animationsFolder = fpsSystem:FindFirstChild("Animations")
    if not animationsFolder then return end

    local category = nil
    if weaponType == "PRIMARY" then
        category = animationsFolder:FindFirstChild("Primary")
    elseif weaponType == "SECONDARY" then
        category = animationsFolder:FindFirstChild("Secondary")
    end

    if category then
        -- Look for weapon folder
        for _, subCategory in pairs(category:GetChildren()) do
            local weaponFolder = subCategory:FindFirstChild(weaponName)
            if weaponFolder then
                local animSaves = weaponFolder:FindFirstChild("AnimSaves")
                if animSaves then
                    for _, anim in pairs(animSaves:GetChildren()) do
                        if anim:IsA("Animation") then
                            local track = self.animator:LoadAnimation(anim)
                            local animName = anim.Name:lower()
                            self.animationTracks[animName] = track
                            print("[Viewmodel] Loaded animation:", anim.Name)
                        end
                    end
                end
            end
        end
    end
end

-- Play animation
function ViewmodelSystem:playAnimation(animName, fadeTime, weight, speed)
    fadeTime = fadeTime or 0.1
    weight = weight or 1
    speed = speed or 1

    local track = self.animationTracks[animName:lower()]
    if track then
        track:Play(fadeTime, weight, speed)
        print("[Viewmodel] Playing animation:", animName)
        return track
    else
        -- Don't warn for missing animations that might not exist for certain weapon types
        if animName ~= "fire" then
            warn("[Viewmodel] Animation not found:", animName)
        end
    end
end

-- Stop animation
function ViewmodelSystem:stopAnimation(animName)
    local track = self.animationTracks[animName:lower()]
    if track then
        track:Stop(0.1)
    end
end

-- Stop all animations
function ViewmodelSystem:stopAllAnimations()
    for name, track in pairs(self.animationTracks) do
        if track.IsPlaying then
            track:Stop()
        end
    end
end

-- Update loop
function ViewmodelSystem:update(deltaTime)
    if not self.currentViewmodel then return end

    -- Find root part (could be HumanoidRootPart or ViewmodelRoot)
    local rootPart = self.currentViewmodel:FindFirstChild("HumanoidRootPart")
        or self.currentViewmodel:FindFirstChild("ViewmodelRoot")
        or self.currentViewmodel.PrimaryPart

    if not rootPart then return end

    -- Update sway
    self:updateSway(deltaTime)

    -- Update bob
    self:updateBob(deltaTime)

    -- Get target position
    local targetCFrame = self:getTargetCFrame()

    -- Apply sway and bob
    local swayOffset = CFrame.new(self.currentSway)
    local bobOffset = CFrame.new(self:getBobOffset())

    -- Update viewmodel position
    self.currentViewmodel:SetPrimaryPartCFrame(
        self.camera.CFrame * targetCFrame * swayOffset * bobOffset
    )

    -- Update server viewmodel
    self:updateServerViewmodel()
end

-- Get target CFrame based on state
function ViewmodelSystem:getTargetCFrame()
    if self.isAiming then
        -- Check for AimPoint attachment
        local aimPoint = self.currentViewmodel:FindFirstChild("AimPoint", true)
        if aimPoint then
            -- Position viewmodel so AimPoint aligns with camera
            local offset = aimPoint.CFrame:Inverse()
            return CFrame.new(0, -0.2, 0) * offset
        else
            return VIEWMODEL_SETTINGS.ADS_POSITION
        end
    elseif self.isSprinting then
        return VIEWMODEL_SETTINGS.SPRINT_POSITION
    else
        return VIEWMODEL_SETTINGS.DEFAULT_POSITION
    end
end

-- Update sway
function ViewmodelSystem:updateSway(deltaTime)
    local swayAmount = VIEWMODEL_SETTINGS.SWAY.AMOUNT
    if self.isAiming then
        swayAmount = swayAmount * 0.3
    end

    self.targetSway = Vector3.new(
        -self.lastMouseDelta.X * swayAmount,
        -self.lastMouseDelta.Y * swayAmount,
        0
    )

    -- Clamp sway
    self.targetSway = Vector3.new(
        math.clamp(self.targetSway.X, -VIEWMODEL_SETTINGS.SWAY.MAX, VIEWMODEL_SETTINGS.SWAY.MAX),
        math.clamp(self.targetSway.Y, -VIEWMODEL_SETTINGS.SWAY.MAX, VIEWMODEL_SETTINGS.SWAY.MAX),
        0
    )

    -- Smooth sway
    local lerpSpeed = VIEWMODEL_SETTINGS.SWAY.SPEED * deltaTime
    self.currentSway = self.currentSway:Lerp(self.targetSway, lerpSpeed)

    -- Decay mouse delta
    self.lastMouseDelta = self.lastMouseDelta * 0.8
end

-- Update bob
function ViewmodelSystem:updateBob(deltaTime)
    local character = self.player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            local bobSpeed = VIEWMODEL_SETTINGS.BOB.SPEED
            if self.isSprinting then
                bobSpeed = bobSpeed * VIEWMODEL_SETTINGS.BOB.SPRINT_MULTIPLIER
            end

            self.bobCycle = self.bobCycle + (deltaTime * bobSpeed)
        end
    end
end

-- Get bob offset
function ViewmodelSystem:getBobOffset()
    local amount = VIEWMODEL_SETTINGS.BOB.AMOUNT

    if self.isAiming then
        amount = amount * 0.1
    elseif self.isSprinting then
        amount = amount * 2
    end

    local character = self.player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            return Vector3.new(
                math.sin(self.bobCycle) * amount,
                math.abs(math.cos(self.bobCycle * 2)) * amount * 0.5,
                0
            )
        end
    end

    return Vector3.new(0, 0, 0)
end

-- Set aiming state
function ViewmodelSystem:setAiming(isAiming)
    self.isAiming = isAiming

    -- Play/stop aim animation
    if isAiming then
        self:playAnimation("aim", 0.2)
    else
        self:stopAnimation("aim")
        self:playAnimation("idle", 0.2)
    end
end

-- Set sprinting state
function ViewmodelSystem:setSprinting(isSprinting)
    self.isSprinting = isSprinting

    if isSprinting then
        self:playAnimation("sprint", 0.3)
    else
        self:stopAnimation("sprint")
        self:playAnimation("idle", 0.3)
    end
end

-- Fire weapon (FIXED: No fire animation required, just recoil)
function ViewmodelSystem:fire()
    self.isFiring = true

    -- FIXED: No fire animation, just add recoil effect
    self:addRecoil(0.08, math.random(-0.02, 0.02))

    -- Brief firing state
    task.wait(0.1)
    self.isFiring = false
end

-- Add recoil
function ViewmodelSystem:addRecoil(vertical, horizontal)
    self.currentSway = self.currentSway + Vector3.new(horizontal, vertical, 0)
end

-- Reload weapon
function ViewmodelSystem:reload()
    if self.isReloading then return end

    self.isReloading = true

    -- Stop current animations
    self:stopAnimation("idle")
    self:stopAnimation("aim")

    -- Play reload animation
    local reloadTrack = self:playAnimation("reload", 0.1)

    if reloadTrack then
        reloadTrack.Stopped:Connect(function()
            self.isReloading = false
            self:playAnimation("idle", 0.2)
        end)
    else
        self.isReloading = false
    end
end

-- Create server-side viewmodel (for debugging and other players)
function ViewmodelSystem:createServerViewmodel(weaponName)
    -- This will be called by a RemoteEvent to create server-side viewmodel
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvents then
        local createViewmodelEvent = remoteEvents:FindFirstChild("CreateServerViewmodel")
        if not createViewmodelEvent then
            createViewmodelEvent = Instance.new("RemoteEvent")
            createViewmodelEvent.Name = "CreateServerViewmodel"
            createViewmodelEvent.Parent = remoteEvents
        end

        createViewmodelEvent:FireServer(weaponName, self.currentWeaponType)
    end
end

-- Update server viewmodel
function ViewmodelSystem:updateServerViewmodel()
    -- Update server viewmodel position/animation via RemoteEvent
    -- This is throttled to reduce network traffic
end

-- Start update loop
function ViewmodelSystem:startUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    self.updateConnection = RunService.RenderStepped:Connect(function(dt)
        self:update(dt)
    end)

    print("[Viewmodel] Update loop started")
end

-- Handle mouse movement
function ViewmodelSystem:handleMouseDelta(delta)
    self.lastMouseDelta = delta
end

-- Cleanup
function ViewmodelSystem:cleanup()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    if self.currentViewmodel then
        self.currentViewmodel:Destroy()
    end

    self:stopAllAnimations()

    print("[Viewmodel] Cleanup complete")
end

return ViewmodelSystem