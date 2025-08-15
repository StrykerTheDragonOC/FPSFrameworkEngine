-- ViewmodelSystem.lua
-- Fixed viewmodel system with proper arm visibility and performance
-- Place in ReplicatedStorage/FPSSystem/Modules/ViewmodelSystem

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
    self.viewmodelContainer = nil
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

    -- Setup character connection
    self:setupCharacterConnection()

    return self
end

-- Setup character connection
function ViewmodelSystem:setupCharacterConnection()
    local function onCharacterAdded(character)
        self.character = character
        task.wait(1) -- Wait for character to fully load
        print("[Viewmodel] Character loaded, updating references")
    end

    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end

    self.player.CharacterAdded:Connect(onCharacterAdded)
end

-- Setup arms with proper visibility fixes
function ViewmodelSystem:setupArms(customRig)
    print("[Viewmodel] Setting up arms...")

    -- Create or get viewmodel container in camera
    self.viewmodelContainer = self.camera:FindFirstChild("ViewmodelContainer")
    if not self.viewmodelContainer then
        self.viewmodelContainer = Instance.new("Model")
        self.viewmodelContainer.Name = "ViewmodelContainer"
        self.viewmodelContainer.Parent = self.camera
        print("[Viewmodel] Created ViewmodelContainer")
    end

    -- Clean up existing viewmodel
    local existingRig = self.viewmodelContainer:FindFirstChild("ViewmodelRig")
    if existingRig then
        existingRig:Destroy()
    end

    -- Use custom rig if provided, otherwise create default arms
    if customRig then
        print("[Viewmodel] Using custom viewmodel rig")
        local arms = customRig:Clone()
        arms.Name = "ViewmodelRig"
        arms.Parent = self.viewmodelContainer

        -- CRITICAL FIX: Ensure proper visibility and collision settings
        self:configureViewmodelParts(arms)
        self.currentViewmodel = arms

        print("[Viewmodel] Custom arms setup complete")
    else
        print("[Viewmodel] Creating default arms")
        self:createDefaultArms()
    end

    -- Verify arm visibility after setup
    task.delay(0.1, function()
        self:verifyArmVisibility()
    end)
end

-- Configure viewmodel parts with proper settings
function ViewmodelSystem:configureViewmodelParts(viewmodel)
    for _, descendant in ipairs(viewmodel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- CRITICAL FIXES for viewmodel parts
            descendant.CanCollide = false  -- Prevent collision issues
            descendant.Anchored = true     -- Prevent physics problems
            descendant.CastShadow = false  -- Optimize rendering
            descendant.CanTouch = false    -- Prevent touch events

            -- Proper transparency settings for arms
            if self:isArmPart(descendant) then
                descendant.Transparency = 0              -- Make visible to player
                descendant.LocalTransparencyModifier = 0 -- Force local visibility
                print("[Viewmodel] Configured arm part:", descendant.Name)
            elseif descendant.Name == "HumanoidRootPart" then
                descendant.Transparency = 1              -- Hide root part
                descendant.LocalTransparencyModifier = 1
            else
                -- For weapon parts and other components
                descendant.LocalTransparencyModifier = 0
            end
        end
    end
end

-- Check if a part is an arm part
function ViewmodelSystem:isArmPart(part)
    local armNames = {
        "LeftArm", "RightArm", "LeftHand", "RightHand",
        "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm",
        "LeftForeArm", "RightForeArm"
    }

    for _, armName in ipairs(armNames) do
        if part.Name == armName or part.Name:find(armName) then
            return true
        end
    end

    -- Also check for parts with "Arm" or "Hand" in the name
    return part.Name:find("Arm") or part.Name:find("Hand")
end

-- Create default arms if no custom rig
function ViewmodelSystem:createDefaultArms()
    local arms = Instance.new("Model")
    arms.Name = "ViewmodelRig"
    arms.Parent = self.viewmodelContainer

    -- Create basic arm parts
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.BrickColor = BrickColor.new("Light orange")
    rightArm.Material = Enum.Material.SmoothPlastic
    rightArm.TopSurface = Enum.SurfaceType.Smooth
    rightArm.BottomSurface = Enum.SurfaceType.Smooth
    rightArm.Parent = arms

    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.BrickColor = BrickColor.new("Light orange")
    leftArm.Material = Enum.Material.SmoothPlastic
    leftArm.TopSurface = Enum.SurfaceType.Smooth
    leftArm.BottomSurface = Enum.SurfaceType.Smooth
    leftArm.Parent = arms

    -- Set primary part
    arms.PrimaryPart = rightArm

    -- Configure the default arms
    self:configureViewmodelParts(arms)
    self.currentViewmodel = arms

    print("[Viewmodel] Default arms created")
end

-- Verify arm visibility (diagnostic function)
function ViewmodelSystem:verifyArmVisibility()
    if not self.currentViewmodel then
        warn("[Viewmodel] No viewmodel to verify")
        return
    end

    local visibleArmParts = 0
    local totalArmParts = 0

    for _, descendant in ipairs(self.currentViewmodel:GetDescendants()) do
        if descendant:IsA("BasePart") and self:isArmPart(descendant) then
            totalArmParts = totalArmParts + 1

            if descendant.Transparency < 1 then
                visibleArmParts = visibleArmParts + 1
            else
                -- Force fix invisible arms
                warn("[Viewmodel] Found invisible arm part, fixing:", descendant.Name)
                descendant.Transparency = 0
                descendant.LocalTransparencyModifier = 0
            end
        end
    end

    print(string.format("[Viewmodel] Verification: %d/%d arm parts visible", visibleArmParts, totalArmParts))
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
    self.currentViewmodel.Parent = self.viewmodelContainer

    -- Store weapon info
    self.currentWeaponName = weaponName
    self.currentWeaponType = weaponType

    -- Configure viewmodel parts
    self:configureViewmodelParts(self.currentViewmodel)

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

-- Find weapon viewmodel rig
function ViewmodelSystem:findWeaponViewmodel(weaponName, weaponType)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return nil end

    local viewModelsFolder = fpsSystem:FindFirstChild("ViewModels")
    if not viewModelsFolder then return nil end

    -- Try to find specific weapon viewmodel
    local weaponFolder = viewModelsFolder:FindFirstChild(weaponName)
    if weaponFolder then
        local rig = weaponFolder:FindFirstChild("ViewmodelRig")
        if rig then return rig end
    end

    -- Try to find by weapon type
    local typeFolder = viewModelsFolder:FindFirstChild(weaponType)
    if typeFolder then
        local rig = typeFolder:FindFirstChild("ViewmodelRig")
        if rig then return rig end
    end

    -- Default to arms folder
    local armsFolder = viewModelsFolder:FindFirstChild("Arms")
    if armsFolder then
        local rig = armsFolder:FindFirstChild("ViewmodelRig")
        if rig then return rig end
    end

    return nil
end

-- Setup animator for animations
function ViewmodelSystem:setupAnimator()
    if not self.currentViewmodel then return end

    local humanoid = self.currentViewmodel:FindFirstChild("Humanoid")
    if humanoid then
        self.animator = humanoid:FindFirstChild("Animator")
        if not self.animator then
            self.animator = Instance.new("Animator")
            self.animator.Parent = humanoid
        end
    end
end

-- Load weapon animations
function ViewmodelSystem:loadWeaponAnimations(weaponName, weaponType)
    -- Animation loading can be skipped for now as per your requirements
    -- This prevents console spam while animations are being created
    print("[Viewmodel] Animation loading skipped - using default poses")
end

-- Play animation
function ViewmodelSystem:playAnimation(animationName)
    -- Skip animation playing for now to prevent console spam
    print("[Viewmodel] Animation system disabled - using static poses")
end

-- Stop all animations
function ViewmodelSystem:stopAllAnimations()
    for _, track in pairs(self.animationTracks) do
        if track then
            track:Stop()
        end
    end
    self.animationTracks = {}
end

-- Create server-side viewmodel for other players
function ViewmodelSystem:createServerViewmodel(weaponName)
    -- This would typically create a viewmodel that other players can see
    -- For now, we'll skip this to focus on fixing the client-side issues
    print("[Viewmodel] Server viewmodel creation skipped")
end

-- Set aiming state
function ViewmodelSystem:setAiming(aiming)
    self.isAiming = aiming
    print("[Viewmodel] Aiming:", aiming)
end

-- Set sprinting state
function ViewmodelSystem:setSprinting(sprinting)
    self.isSprinting = sprinting
    print("[Viewmodel] Sprinting:", sprinting)
end

-- Start update loop
function ViewmodelSystem:startUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    self.updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:update(deltaTime)
    end)

    print("[Viewmodel] Update loop started")
end

-- Update function
function ViewmodelSystem:update(deltaTime)
    if not self.currentViewmodel then return end

    -- Update weapon sway
    self:updateSway(deltaTime)

    -- Update weapon bob
    self:updateBob(deltaTime)

    -- Update viewmodel position
    self:updatePosition(deltaTime)
end

-- Update weapon sway
function ViewmodelSystem:updateSway(deltaTime)
    if self.lastMouseDelta then
        local swayX = math.clamp(self.lastMouseDelta.X * VIEWMODEL_SETTINGS.SWAY.AMOUNT, 
            -VIEWMODEL_SETTINGS.SWAY.MAX, VIEWMODEL_SETTINGS.SWAY.MAX)
        local swayY = math.clamp(self.lastMouseDelta.Y * VIEWMODEL_SETTINGS.SWAY.AMOUNT, 
            -VIEWMODEL_SETTINGS.SWAY.MAX, VIEWMODEL_SETTINGS.SWAY.MAX)

        self.targetSway = Vector3.new(swayX, swayY, 0)
    end

    -- Smoothly interpolate to target sway
    self.currentSway = self.currentSway:lerp(self.targetSway, VIEWMODEL_SETTINGS.SWAY.SPEED * deltaTime)
end

-- Update weapon bob
function ViewmodelSystem:updateBob(deltaTime)
    if self.character and self.character:FindFirstChild("Humanoid") then
        local humanoid = self.character.Humanoid
        local moveVector = humanoid.MoveDirection

        if moveVector.Magnitude > 0 then
            local bobMultiplier = self.isSprinting and VIEWMODEL_SETTINGS.BOB.SPRINT_MULTIPLIER or 1
            self.bobCycle = self.bobCycle + deltaTime * VIEWMODEL_SETTINGS.BOB.SPEED * bobMultiplier
        else
            self.bobCycle = self.bobCycle * 0.9 -- Slowly reduce bob when not moving
        end
    end
end

-- Update viewmodel position
function ViewmodelSystem:updatePosition(deltaTime)
    if not self.currentViewmodel or not self.currentViewmodel.PrimaryPart then return end

    local targetPosition = VIEWMODEL_SETTINGS.DEFAULT_POSITION

    if self.isAiming then
        targetPosition = VIEWMODEL_SETTINGS.ADS_POSITION
    elseif self.isSprinting then
        targetPosition = VIEWMODEL_SETTINGS.SPRINT_POSITION
    end

    -- Apply sway
    local swayOffset = CFrame.new(self.currentSway.X, self.currentSway.Y, self.currentSway.Z)

    -- Apply bob
    local bobOffset = Vector3.new(
        math.sin(self.bobCycle) * VIEWMODEL_SETTINGS.BOB.AMOUNT,
        math.abs(math.sin(self.bobCycle * 2)) * VIEWMODEL_SETTINGS.BOB.AMOUNT,
        0
    )

    -- Combine transformations
    local finalCFrame = self.camera.CFrame * targetPosition * swayOffset * CFrame.new(bobOffset)

    -- Apply to viewmodel
    if self.currentViewmodel.PrimaryPart then
        self.currentViewmodel:SetPrimaryPartCFrame(finalCFrame)
    end
end

-- Get muzzle attachment for weapon firing
function ViewmodelSystem:getMuzzleAttachment()
    if not self.currentViewmodel then return nil end

    -- Look for muzzle attachment
    local muzzle = self.currentViewmodel:FindFirstChild("Muzzle", true)
    if not muzzle then
        muzzle = self.currentViewmodel:FindFirstChild("MuzzleAttachment", true)
    end
    if not muzzle then
        muzzle = self.currentViewmodel:FindFirstChild("FirePoint", true)
    end

    return muzzle
end

-- Get current weapon info
function ViewmodelSystem:getCurrentWeapon()
    return {
        name = self.currentWeaponName,
        type = self.currentWeaponType,
        model = self.currentViewmodel
    }
end

-- Force arm visibility fix (emergency function)
function ViewmodelSystem:forceArmVisibilityFix()
    if not self.currentViewmodel then
        warn("[Viewmodel] No viewmodel to fix")
        return
    end

    print("[Viewmodel] Forcing arm visibility fix...")

    for _, descendant in ipairs(self.currentViewmodel:GetDescendants()) do
        if descendant:IsA("BasePart") and self:isArmPart(descendant) then
            descendant.Transparency = 0
            descendant.LocalTransparencyModifier = 0
            descendant.CanCollide = false
            descendant.Anchored = true
            print("[Viewmodel] Force-fixed:", descendant.Name)
        end
    end
end

-- Cleanup
function ViewmodelSystem:cleanup()
    print("[Viewmodel] Cleaning up...")

    -- Stop update loop
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end

    -- Stop all animations
    self:stopAllAnimations()

    -- Clean up viewmodel
    if self.viewmodelContainer then
        self.viewmodelContainer:Destroy()
        self.viewmodelContainer = nil
    end

    -- Clean up server viewmodel
    if self.serverViewmodel then
        self.serverViewmodel:Destroy()
        self.serverViewmodel = nil
    end

    -- Clear references
    self.currentViewmodel = nil
    self.animator = nil
    self.character = nil

    print("[Viewmodel] Cleanup complete")
end

-- Export globally for other scripts
_G.ViewmodelSystem = ViewmodelSystem

return ViewmodelSystem