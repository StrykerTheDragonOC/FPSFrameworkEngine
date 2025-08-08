-- ViewmodelSystem.lua
-- Comprehensive fix for transparency, positioning, and debugger integration

local ViewmodelSystem = {}
ViewmodelSystem.__index = ViewmodelSystem

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants for fine-tuning viewmodel behavior
local VIEWMODEL_SETTINGS = {
    -- Base position for different states (as Vector3)
    DEFAULT_POSITION = Vector3.new(0.20, 0.10, 0.70),
    ADS_POSITION = Vector3.new(0.10, 0.30, 1.50),
    SPRINT_POSITION = Vector3.new(0.40, -0.30, -0.50),

    -- Weapon positioning offsets
    WEAPON_OFFSETS = {
        DEFAULT = CFrame.new(0,0,0),
        ADS = CFrame.new(0, 0, -0.3),
        SPRINT = CFrame.new(0.5, -0.4, -0.6)
    },

    -- Weapon sway settings
    SWAY = {
        AMOUNT = 0.05,
        SPEED = 1,
        SMOOTHING = 0.3
    },

    -- Weapon bob settings
    BOB = {
        AMOUNT = 0.05,
        SPEED = 1,
        SPRINT_MULTIPLIER = 1.5
    }
}

-- Track existing instances to prevent duplicates
local activeInstances = {}

-- Create a new ViewmodelSystem instance
function ViewmodelSystem.new()
    -- Check for an existing instance and clean it up
    local player = Players.LocalPlayer
    if activeInstances[player] then
        print("Found existing ViewmodelSystem, cleaning up...")
        activeInstances[player]:cleanup()
    end

    local self = setmetatable({}, ViewmodelSystem)

    -- Core components
    self.camera = workspace.CurrentCamera
    self.container = nil -- Will be set in createViewmodelContainer

    -- Create the container
    self:createViewmodelContainer()

    -- State tracking
    self.currentWeapon = nil
    self.viewmodelRig = nil
    self.isAiming = false
    self.isSprinting = false
    self.lastMouseDelta = Vector2.new()
    self.currentSway = Vector3.new()
    self.bobCycle = 0
    self.isMoving = false

    -- Animation tracking
    self.currentAnimations = {}
    self.animationTracks = {}
    self.weaponAnimations = {}

    -- Debug flag - set to false to disable position logging
    self.debugLogging = false

    -- Store this instance as active
    activeInstances[player] = self

    -- Export instance to _G for access by other scripts
    _G.CurrentViewmodelSystem = self

    print("Viewmodel System initialized")
    return self
end

-- Create the container that holds our viewmodel
function ViewmodelSystem:createViewmodelContainer()
    -- Look for an existing container first
    local existingContainer = self.camera:FindFirstChild("ViewmodelContainer")
    if existingContainer then
        print("Using existing ViewmodelContainer")
        self.container = existingContainer
        return existingContainer
    end

    print("Creating new ViewmodelContainer")
    local container = Instance.new("Model")
    container.Name = "ViewmodelContainer"

    -- Create invisible root part for positioning with proper settings
    local root = Instance.new("Part")
    root.Name = "ViewmodelRoot"
    root.Size = Vector3.new(0.1, 0.1, 0.1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true -- Important: Must be anchored
    root.CFrame = self.camera.CFrame * CFrame.new(VIEWMODEL_SETTINGS.DEFAULT_POSITION)

    -- Add attachment for weapon positioning
    local weaponAttachment = Instance.new("Attachment")
    weaponAttachment.Name = "WeaponAttachment"
    weaponAttachment.Position = Vector3.new(0, 0, 0)
    weaponAttachment.Parent = root

    root.Parent = container

    container.PrimaryPart = root
    container.Parent = self.camera
    self.container = container

    return container
end

-- Fix arm and hand part transparency issues
function ViewmodelSystem:fixPartTransparency(part)
    if not part or not part:IsA("BasePart") then return end

    -- Handle HandControl parts - always invisible
    if part.Name == "HandControl" then
        part.Transparency = 1
        part.CanCollide = false
        return
    end

    -- Handle arm and hand parts - always visible
    if part.Name == "LeftArm" or part.Name == "RightArm" or
        part.Name == "LeftHand" or part.Name == "RightHand" or
        part.Name:find("Arm") or part.Name:find("Hand") then

        part.Transparency = 0
        part.LocalTransparencyModifier = 0

        -- Set material and color if default
        if part.Color == Color3.new(1, 1, 1) then
            part.Color = Color3.fromRGB(255, 213, 170) -- Skin tone
        end

        if part.Material == Enum.Material.Plastic then
            part.Material = Enum.Material.SmoothPlastic
        end
    end

    -- Non-visual parts should be invisible
    if part.Name == "HumanoidRootPart" or part.Name == "CameraBone" then
        part.Transparency = 1
    end

    -- Ensure all parts are anchored and non-colliding
    part.Anchored = true
    part.CanCollide = false
end

-- Set up the viewmodel rig (weapon-specific or default)
function ViewmodelSystem:setupArms(weaponName, weaponCategory)
    print("Setting up viewmodel arms for weapon:", weaponName or "default")

    -- Clean up existing viewmodel
    if self.viewmodelRig then
        if self.partAddedConnection then
            self.partAddedConnection:Disconnect()
            self.partAddedConnection = nil
        end
        self.viewmodelRig:Destroy()
        self.viewmodelRig = nil
    end

    -- Ensure container exists
    if not self.container then
        self:createViewmodelContainer()
    end

    local customRig = nil
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")

    -- PRIORITY 1: Look for weapon-specific viewmodel
    if weaponName and fpsSystem then
        customRig = self:findWeaponViewmodel(weaponName, weaponCategory)
        if customRig then
            print("Found weapon-specific viewmodel for", weaponName)
        end
    end

    -- PRIORITY 2: Look for default viewmodel rig in Arms folder
    if not customRig and fpsSystem then
        local viewModels = fpsSystem:FindFirstChild("ViewModels")
        if viewModels then
            local arms = viewModels:FindFirstChild("Arms")
            if arms then
                customRig = arms:FindFirstChild("ViewmodelRig")
                if customRig then
                    print("Found default ViewmodelRig in Arms folder")
                end
            end
        end
    end

    -- PRIORITY 3: Use fallback default arms
    if not customRig then
        print("No custom ViewmodelRig found, creating default arms")
        self:createDefaultArms()
        return self.viewmodelRig
    end

    -- Clone the rig
    local rigClone = customRig:Clone()
    self.viewmodelRig = rigClone
    self.viewmodelRig.Name = "ViewmodelRig"

    -- Fix transparency and visibility issues
    for _, part in ipairs(self.viewmodelRig:GetDescendants()) do
        if part:IsA("BasePart") then
            self:fixPartTransparency(part)
        end
    end

    -- Position and parent the rig
    if self.container and self.container.PrimaryPart then
        pcall(function()
            self.viewmodelRig:PivotTo(self.container.PrimaryPart.CFrame)
        end)
        self.viewmodelRig.Parent = self.container
    else
        warn("Cannot position viewmodel rig: container or primaryPart is nil")
    end

    -- Set up a connection to fix any parts that get added later
    self.partAddedConnection = self.viewmodelRig.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            self:fixPartTransparency(descendant)
        end
    end)

    print("Arms setup complete for:", weaponName or "default")
    return self.viewmodelRig
end

-- Find weapon-specific viewmodel
function ViewmodelSystem:findWeaponViewmodel(weaponName, weaponCategory)
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return nil end
    
    local viewModels = fpsSystem:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    
    -- Search paths for weapon-specific viewmodels
    local searchPaths = {
        -- Primary weapons
        "Primary/AssaultRIfles/" .. weaponName,
        "Primary/BattleRifles/" .. weaponName,
        "Primary/Carbines/" .. weaponName,
        "Primary/DMRS/" .. weaponName,
        "Primary/LMGS/" .. weaponName,
        "Primary/SMGS/" .. weaponName,
        "Primary/Shotguns/" .. weaponName,
        "Primary/SniperRifles/" .. weaponName,
        -- Secondary weapons
        "Secondary/Pistols/" .. weaponName,
        "Secondary/Revolvers/" .. weaponName,
        "Secondary/AutomaticPistols/" .. weaponName,
        "Secondary/Other/" .. weaponName,
        -- Melee weapons
        "Melee/BladeOneHand/" .. weaponName,
        "Melee/BladeTwoHand/" .. weaponName,
        "Melee/BluntOneHand/" .. weaponName,
        "Melee/BluntTwoHand/" .. weaponName,
        -- Grenades
        "Grenades/Explosive/" .. weaponName,
        "Grenades/Impact/" .. weaponName,
        "Grenades/Tactical/" .. weaponName
    }
    
    -- Search for weapon viewmodel in all possible paths
    for _, path in ipairs(searchPaths) do
        local pathParts = path:split("/")
        local currentFolder = viewModels
        
        for _, part in ipairs(pathParts) do
            currentFolder = currentFolder:FindFirstChild(part)
            if not currentFolder then
                break
            end
        end
        
        if currentFolder then
            -- Look for a .rbxm file or Model
            for _, child in ipairs(currentFolder:GetChildren()) do
                if child:IsA("Model") or child.Name:match("%.rbxm$") then
                    print("Found weapon viewmodel at path:", path)
                    return child
                end
            end
        end
    end
    
    return nil
end

-- Create default arms if no model is provided
function ViewmodelSystem:createDefaultArms()
    print("Creating default arms as fallback...")

    local arms = Instance.new("Model")
    arms.Name = "ViewmodelRig"

    -- Create fake camera for positioning
    local fakeCamera = Instance.new("Part")
    fakeCamera.Name = "FakeCamera"
    fakeCamera.Size = Vector3.new(0.1, 0.1, 0.1)
    fakeCamera.Transparency = 1
    fakeCamera.CanCollide = false
    fakeCamera.Anchored = true
    fakeCamera.Parent = arms

    -- Create left arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(0.25, 0.8, 0.25)
    leftArm.Color = Color3.fromRGB(255, 213, 170) -- Skin tone
    leftArm.Transparency = 0
    leftArm.CanCollide = false
    leftArm.Anchored = true
    leftArm.Parent = arms

    -- Create right arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(0.25, 0.8, 0.25)
    rightArm.Color = Color3.fromRGB(255, 213, 170) -- Skin tone
    rightArm.Transparency = 0
    rightArm.CanCollide = false
    rightArm.Anchored = true
    rightArm.Parent = arms

    -- Position the arms
    if self.container and self.container.PrimaryPart then
        local rootCFrame = self.container.PrimaryPart.CFrame
        leftArm.CFrame = rootCFrame * CFrame.new(-0.4, -0.5, -0.2)
        rightArm.CFrame = rootCFrame * CFrame.new(0.4, -0.5, -0.2)
    end

    self.viewmodelRig = arms

    if self.container then
        arms.Parent = self.container
    else
        warn("Cannot parent default arms: container is nil")
    end

    print("Default arms created as fallback!")
    return arms
end

-- Stop all currently playing animations
function ViewmodelSystem:stopAllAnimations()
    for animationName, track in pairs(self.animationTracks) do
        if track and track.IsPlaying then
            track:Stop()
        end
    end
    self.animationTracks = {}
    print("Stopped all viewmodel animations")
end

-- Load weapon animations from ReplicatedStorage Animations folder
function ViewmodelSystem:loadWeaponAnimations(weaponName, weaponCategory)
    self.weaponAnimations = {}

    if not self.viewmodelRig then
        warn("Cannot load animations: no viewmodel rig")
        return
    end

    local humanoid = self.viewmodelRig:FindFirstChild("Humanoid")
    if not humanoid then
        warn("Cannot load animations: no Humanoid in viewmodel rig")
        return
    end

    -- Try to find animations in ReplicatedStorage.FPSSystem.Animations
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        warn("FPSSystem folder not found in ReplicatedStorage")
        return
    end

    local animationsFolder = fpsSystem:FindFirstChild("Animations")
    if not animationsFolder then
        warn("Animations folder not found in FPSSystem")
        return
    end

    -- Determine weapon category and type for animation path
    local animationPaths = {
        -- Primary weapons
        "Primary/AssaultRIfles/" .. weaponName,
        "Primary/BattleRifles/" .. weaponName,
        "Primary/Carbines/" .. weaponName,
        "Primary/DMRS/" .. weaponName,
        "Primary/LMGS/" .. weaponName,
        "Primary/SMGS/" .. weaponName,
        "Primary/Shotguns/" .. weaponName,
        "Primary/SniperRifles/" .. weaponName,
        -- Secondary weapons
        "Secondary/Pistols/" .. weaponName,
        "Secondary/Revolvers/" .. weaponName,
        "Secondary/AutomaticPistols/" .. weaponName,
        "Secondary/Other/" .. weaponName,
        -- Melee weapons
        "Melee/BladeOneHand/" .. weaponName,
        "Melee/BladeTwoHand/" .. weaponName,
        "Melee/BluntOneHand/" .. weaponName,
        "Melee/BluntTwoHand/" .. weaponName,
        -- Grenades
        "Grenades/Explosive/" .. weaponName,
        "Grenades/Impact/" .. weaponName,
        "Grenades/Tactical/" .. weaponName
    }

    local weaponAnimFolder = nil
    
    -- Search for weapon animations in all possible paths
    for _, path in ipairs(animationPaths) do
        local pathParts = path:split("/")
        local currentFolder = animationsFolder
        
        for _, part in ipairs(pathParts) do
            currentFolder = currentFolder:FindFirstChild(part)
            if not currentFolder then
                break
            end
        end
        
        if currentFolder then
            weaponAnimFolder = currentFolder
            print("Found animations for", weaponName, "at path:", path)
            break
        end
    end

    if not weaponAnimFolder then
        print("No animations found for weapon:", weaponName)
        return
    end

    -- Load all animation files from the weapon's animation folder
    for _, animObject in pairs(weaponAnimFolder:GetChildren()) do
        if animObject:IsA("Model") or animObject.Name:match("%.rbxm$") then
            -- This is an animation model file, try to find Animation objects in it
            for _, child in pairs(animObject:GetDescendants()) do
                if child:IsA("Animation") then
                    local track = humanoid:LoadAnimation(child)
                    local animName = animObject.Name:lower():gsub("%.rbxm", "")
                    self.weaponAnimations[animName] = track
                    print("Loaded animation:", animName, "from", animObject.Name)
                end
            end
        elseif animObject:IsA("Animation") then
            -- Direct Animation object
            local track = humanoid:LoadAnimation(animObject)
            local animName = animObject.Name:lower()
            self.weaponAnimations[animName] = track
            print("Loaded animation:", animName)
        end
    end
    
    print("Loaded", #self.weaponAnimations, "animations for", weaponName)
end

-- Play a specific animation
function ViewmodelSystem:playAnimation(animationName, fadeTime, weight, speed)
    fadeTime = fadeTime or 0.1
    weight = weight or 1
    speed = speed or 1

    local track = self.weaponAnimations[animationName:lower()]
    if not track then
        -- Try to find it in current tracks
        track = self.animationTracks[animationName:lower()]
    end

    if track then
        track:Play(fadeTime, weight, speed)
        self.animationTracks[animationName:lower()] = track
        print("Playing animation:", animationName)
        return track
    else
        warn("Animation not found:", animationName)
        return nil
    end
end

-- Setup Motor6Ds for weapon animation
function ViewmodelSystem:setupWeaponMotor6Ds()
    if not self.currentWeapon or not self.viewmodelRig then return end

    -- Find attachment points in both the weapon and the rig
    local weaponHandle = self.currentWeapon:FindFirstChild("Handle") or self.currentWeapon.PrimaryPart
    if not weaponHandle then 
        print("No weapon handle found for Motor6D setup")
        return 
    end

    -- Try to find hand parts in the rig
    local rightHand = self.viewmodelRig:FindFirstChild("RightHand") or 
                      self.viewmodelRig:FindFirstChild("RightArm") or 
                      self.viewmodelRig:FindFirstChild("Right Arm")

    -- Create Motor6D connections for animation support
    if rightHand and weaponHandle then
        -- Remove existing grips first
        local existingMotor = rightHand:FindFirstChild("RightGrip")
        if existingMotor then
            existingMotor:Destroy()
        end
        
        local motor6d = Instance.new("Motor6D")
        motor6d.Name = "RightGrip"
        motor6d.Part0 = rightHand
        motor6d.Part1 = weaponHandle
        
        -- Better default grip positioning
        motor6d.C0 = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        motor6d.C1 = CFrame.new(0, 0, 0)
        motor6d.Parent = rightHand
        
        print("Created RightGrip Motor6D between", rightHand.Name, "and", weaponHandle.Name)
    else
        print("Could not create Motor6D: rightHand =", rightHand and rightHand.Name or "nil", 
              "weaponHandle =", weaponHandle and weaponHandle.Name or "nil")
    end
end

-- Equip a weapon to the viewmodel with animation support
function ViewmodelSystem:equipWeapon(weaponModel, weaponType)
    print("Equipping weapon:", weaponModel and weaponModel.Name or "nil", "Type:", weaponType or "unknown")

    -- Clean up existing weapon
    if self.currentWeapon then
        self.currentWeapon:Destroy()
        self.currentWeapon = nil -- Clear reference
    end

    -- Stop any existing animations
    self:stopAllAnimations()

    -- Determine weapon category for viewmodel selection
    local weaponName = weaponModel and weaponModel.Name or nil
    local weaponCategory = nil
    
    if weaponType then
        if string.find(weaponType:lower(), "primary") then
            weaponCategory = "Primary"
        elseif string.find(weaponType:lower(), "secondary") then
            weaponCategory = "Secondary"
        elseif string.find(weaponType:lower(), "melee") then
            weaponCategory = "Melee"
        elseif string.find(weaponType:lower(), "grenade") then
            weaponCategory = "Grenades"
        end
    end

    -- Set up weapon-specific viewmodel rig BEFORE equipping weapon
    self:setupArms(weaponName, weaponCategory)

    -- If no weapon model provided, create a placeholder
    if not weaponModel then
        self:createPlaceholderWeapon()
        return
    end

    -- Clone and set up new weapon with error handling
    local success, result = pcall(function()
        return weaponModel:Clone()
    end)

    if not success then
        warn("Failed to clone weapon model: " .. tostring(result))
        self:createPlaceholderWeapon()
        return
    end

    self.currentWeapon = result
    self.currentWeaponType = weaponType

    -- Process weapon parts
    for _, part in pairs(self.currentWeapon:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = false -- Important for proper positioning with Motor6D
        end
    end

    -- Parent to viewmodel first
    if self.viewmodelRig then
        self.currentWeapon.Parent = self.viewmodelRig
    else
        warn("Cannot parent weapon: viewmodelRig is nil")
        return
    end

    -- Position weapon properly using existing attachments or create default positioning
    self:positionWeapon()

    -- Find and set up Motor6Ds for animation
    self:setupWeaponMotor6Ds()

    -- Load and play idle animation
    self:loadWeaponAnimations(weaponName, weaponCategory)
    self:playAnimation("idle")

    print("Weapon equipped successfully with weapon-specific viewmodel!")
end

-- Position weapon properly relative to the viewmodel rig
function ViewmodelSystem:positionWeapon()
    if not self.currentWeapon or not self.viewmodelRig then return end
    
    -- Find the right hand in the viewmodel rig
    local rightHand = self.viewmodelRig:FindFirstChild("RightHand") or 
                      self.viewmodelRig:FindFirstChild("RightArm") or 
                      self.viewmodelRig:FindFirstChild("Right Arm")
                      
    -- Find weapon handle
    local weaponHandle = self.currentWeapon:FindFirstChild("Handle") or 
                        self.currentWeapon.PrimaryPart
    
    if not rightHand or not weaponHandle then
        print("Could not find right hand or weapon handle - using default positioning")
        -- Fall back to container attachment positioning
        if self.container and self.container.PrimaryPart then
            local weaponAttachment = self.container.PrimaryPart:FindFirstChild("WeaponAttachment")
            if weaponAttachment and self.currentWeapon.PrimaryPart then
                local offset = CFrame.new(0.2, -0.3, -0.5) -- Default weapon offset
                self.currentWeapon:SetPrimaryPartCFrame(weaponAttachment.WorldCFrame * offset)
                print("Positioned weapon using container attachment")
            end
        end
        return
    end
    
    -- Position weapon in right hand
    if self.currentWeapon.PrimaryPart then
        -- Create a grip offset (adjust as needed)
        local gripOffset = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        local targetCFrame = rightHand.CFrame * gripOffset
        
        self.currentWeapon:SetPrimaryPartCFrame(targetCFrame)
        print("Positioned weapon in right hand")
    end
end

-- Create a placeholder weapon with attachment support
function ViewmodelSystem:createPlaceholderWeapon()
    print("Creating placeholder weapon...")

    local weapon = Instance.new("Model")
    weapon.Name = "PlaceholderWeapon"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.25, 0.25, 1.5)
    handle.Color = Color3.fromRGB(80, 80, 80)
    handle.Transparency = 0
    handle.CanCollide = false
    handle.Anchored = true
    handle.Parent = weapon

    weapon.PrimaryPart = handle

    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(0.15, 0.15, 0.8)
    barrel.Color = Color3.fromRGB(50, 50, 50)
    barrel.Transparency = 0
    barrel.CanCollide = false
    barrel.Anchored = true
    barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - barrel.Size.Z/2)
    barrel.Parent = weapon

    local muzzlePoint = Instance.new("Attachment")
    muzzlePoint.Name = "MuzzlePoint"
    muzzlePoint.Position = Vector3.new(0, 0, -barrel.Size.Z/2)
    muzzlePoint.Parent = barrel

    -- Add grip attachment for positioning
    local gripAttachment = Instance.new("Attachment")
    gripAttachment.Name = "GripAttachment"
    gripAttachment.Position = Vector3.new(0, 0, 0)
    gripAttachment.Parent = handle

    self.currentWeapon = weapon

    if self.viewmodelRig then
        weapon.Parent = self.viewmodelRig

        -- Try to position it based on attachment
        local rootPart = self.container and self.container.PrimaryPart
        if rootPart then
            local weaponAttachment = rootPart:FindFirstChild("WeaponAttachment")
            if weaponAttachment then
                pcall(function()
                    weapon:PivotTo(weaponAttachment.WorldCFrame)
                end)
            end
        end
    else
        warn("Cannot parent placeholder weapon: viewmodelRig is nil")
    end

    print("Placeholder weapon created!")
end

-- Start the update loop for continuous movement
function ViewmodelSystem:startUpdateLoop()
    -- Clean up existing connection if it exists
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end

    self.updateConnection = RunService.RenderStepped:Connect(function(deltaTime)
        self:update(deltaTime)
    end)

    print("Viewmodel update loop started")
end

-- Get target position based on current state - returns Vector3
function ViewmodelSystem:getTargetPosition()
    if self.isAiming then
        return VIEWMODEL_SETTINGS.ADS_POSITION
    elseif self.isSprinting then
        return VIEWMODEL_SETTINGS.SPRINT_POSITION
    else
        return VIEWMODEL_SETTINGS.DEFAULT_POSITION
    end
end

-- Calculate weapon bob offset
function ViewmodelSystem:getBobOffset()
    local amount = VIEWMODEL_SETTINGS.BOB.AMOUNT

    if self.isAiming then
        amount = amount * 0.2 -- Reduce bob while aiming
    end

    return Vector3.new(
        math.sin(self.bobCycle) * amount,
        math.abs(math.cos(self.bobCycle)) * amount,
        0
    )
end

-- Main update function - called every frame
function ViewmodelSystem:update(deltaTime)
    if not self.container or not self.container.PrimaryPart then return end

    -- Update movement effects
    self:updateSway(deltaTime)
    self:updateBob(deltaTime)

    -- Get base position based on state (Vector3)
    local targetPosition = self:getTargetPosition()

    -- IMPORTANT: Ensure targetPosition is Vector3
    if typeof(targetPosition) ~= "Vector3" then
        targetPosition = Vector3.new(0.25, -0.4, -0.8)
    end

    -- Convert sway and bob to CFrame offsets
    local swayCFrame = CFrame.Angles(self.currentSway.Y, self.currentSway.X, 0)
    local bobOffset = self:getBobOffset()
    local bobCFrame = CFrame.new(bobOffset.X, bobOffset.Y, 0)

    -- Create position CFrame separately to avoid errors
    local positionCFrame = CFrame.new(targetPosition)

    -- Calculate final CFrame
    local finalCFrame = self.camera.CFrame * positionCFrame * swayCFrame * bobCFrame

    -- Update container position
    self.container.PrimaryPart.CFrame = finalCFrame

    -- Position viewmodel rig parts
    if self.viewmodelRig then
        -- Position the entire rig
        pcall(function()
            self.viewmodelRig:PivotTo(finalCFrame)
        end)

        -- Position weapon if exists
        if self.currentWeapon and self.currentWeapon.PrimaryPart then
            local weaponOffset = VIEWMODEL_SETTINGS.WEAPON_OFFSETS.DEFAULT

            if self.isAiming then
                weaponOffset = VIEWMODEL_SETTINGS.WEAPON_OFFSETS.ADS
            elseif self.isSprinting then
                weaponOffset = VIEWMODEL_SETTINGS.WEAPON_OFFSETS.SPRINT
            end

            -- Try to position weapon using attachment if available
            local weaponAttachment = self.container.PrimaryPart:FindFirstChild("WeaponAttachment")
            if weaponAttachment then
                pcall(function()
                    self.currentWeapon:PivotTo(weaponAttachment.WorldCFrame)
                end)
            else
                pcall(function()
                    self.currentWeapon:PivotTo(finalCFrame * weaponOffset)
                end)
            end
        end
    end

    -- Only log position if debug logging is enabled
    if self.debugLogging then
        print("Current position:", targetPosition)
    end
end

-- Update weapon sway based on mouse movement
function ViewmodelSystem:updateSway(deltaTime)
    local targetX = -self.lastMouseDelta.X * VIEWMODEL_SETTINGS.SWAY.AMOUNT
    local targetY = -self.lastMouseDelta.Y * VIEWMODEL_SETTINGS.SWAY.AMOUNT

    -- Reset mouse delta after using it
    self.lastMouseDelta = Vector2.new(0, 0)

    -- Smoothly interpolate sway
    self.currentSway = Vector3.new(
        self.currentSway.X + (targetX - self.currentSway.X) * VIEWMODEL_SETTINGS.SWAY.SPEED * deltaTime,
        self.currentSway.Y + (targetY - self.currentSway.Y) * VIEWMODEL_SETTINGS.SWAY.SPEED * deltaTime,
        0
    )
end

-- Update weapon bob cycle
function ViewmodelSystem:updateBob(deltaTime)
    local speed = VIEWMODEL_SETTINGS.BOB.SPEED
    if self.isSprinting then
        speed = speed * VIEWMODEL_SETTINGS.BOB.SPRINT_MULTIPLIER
    end

    self.bobCycle = (self.bobCycle + deltaTime * speed) % (2 * math.pi)
end

-- Add recoil to viewmodel
function ViewmodelSystem:addRecoil(vertical, horizontal)
    vertical = math.clamp(vertical or 0, -0.2, 0.2)
    horizontal = math.clamp(horizontal or 0, -0.1, 0.1)

    -- Apply recoil to sway
    self.currentSway = Vector3.new(
        self.currentSway.X + horizontal,
        self.currentSway.Y + vertical,
        0
    )
end

-- Set aiming state
function ViewmodelSystem:setAiming(isAiming)
    if self.isAiming == isAiming then return end
    self.isAiming = isAiming

    -- Don't sprint while aiming
    if isAiming and self.isSprinting then
        self.isSprinting = false
    end
end

-- Set sprinting state
function ViewmodelSystem:setSprinting(isSprinting)
    if self.isSprinting == isSprinting then return end

    -- Don't sprint while aiming
    if isSprinting and self.isAiming then return end

    self.isSprinting = isSprinting
end

-- Clean up the viewmodel system
function ViewmodelSystem:cleanup()
    print("Cleaning up ViewmodelSystem...")

    -- Stop update loop
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end

    -- Stop part added connection
    if self.partAddedConnection then
        self.partAddedConnection:Disconnect()
        self.partAddedConnection = nil
    end

    -- Stop all animations before cleanup
    self:stopAllAnimations()

    -- Clean up viewmodel parts but don't destroy container
    if self.currentWeapon then
        self.currentWeapon:Destroy()
        self.currentWeapon = nil
    end

    if self.viewmodelRig then
        self.viewmodelRig:Destroy()
        self.viewmodelRig = nil
    end

    -- Remove from active instances
    local player = Players.LocalPlayer
    if activeInstances[player] == self then
        activeInstances[player] = nil
    end

    print("ViewmodelSystem cleanup complete")
end

-- Create a method to handle player removal
function ViewmodelSystem.onPlayerRemoving(player)
    if activeInstances[player] then
        activeInstances[player]:cleanup()
        activeInstances[player] = nil
    end
end

-- Connect to PlayerRemoving event on the client side
Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then
        for _, instance in pairs(activeInstances) do
            instance:cleanup()
        end
    end
end)

return ViewmodelSystem