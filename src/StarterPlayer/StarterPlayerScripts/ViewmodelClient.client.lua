-- ViewmodelClient.client.lua
-- Fixed client script with proper error handling and coordination
-- Place in StarterPlayer/StarterPlayerScripts/ViewmodelClient.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Prevent multiple instances
if _G.ViewmodelClientLoaded then
    warn("ViewmodelClient already loaded, skipping duplicate")
    return
end
_G.ViewmodelClientLoaded = true

-- Helper function to safely require modules
local function safeRequire(modulePath)
    local success, result = pcall(function()
        return require(modulePath)
    end)

    if success then
        print("[ViewmodelClient] Loaded module:", modulePath.Name)
        return result
    else
        warn("[ViewmodelClient] Failed to require module:", modulePath:GetFullName(), "-", tostring(result))
        return nil
    end
end

-- Ensure folders are properly set up
local function ensureFPSFolders()
    print("[ViewmodelClient] Ensuring FPS folders exist...")

    -- Check for FPSSystem folder
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        fpsSystem = Instance.new("Folder")
        fpsSystem.Name = "FPSSystem"
        fpsSystem.Parent = ReplicatedStorage
        print("[ViewmodelClient] Created FPSSystem folder in ReplicatedStorage")
    end

    -- Check for Modules folder
    local modulesFolder = fpsSystem:FindFirstChild("Modules")
    if not modulesFolder then
        modulesFolder = Instance.new("Folder")
        modulesFolder.Name = "Modules"
        modulesFolder.Parent = fpsSystem
        print("[ViewmodelClient] Created Modules folder in FPSSystem")
    end

    -- Check for ViewModels folder
    local viewModels = fpsSystem:FindFirstChild("ViewModels")
    if not viewModels then
        viewModels = Instance.new("Folder")
        viewModels.Name = "ViewModels"
        viewModels.Parent = fpsSystem
        print("[ViewmodelClient] Created ViewModels folder")
    end

    -- Check for Arms folder
    local arms = viewModels:FindFirstChild("Arms")
    if not arms then
        arms = Instance.new("Folder")
        arms.Name = "Arms"
        arms.Parent = viewModels
        print("[ViewmodelClient] Created Arms folder")
    end

    return {
        fpsSystem = fpsSystem,
        modulesFolder = modulesFolder,
        viewModels = viewModels,
        arms = arms
    }
end

-- Find your custom ViewmodelRig
local function findCustomViewmodelRig()
    local folders = ensureFPSFolders()

    -- Look for existing ViewmodelRig in FPSSystem.ViewModels.Arms
    local customRig = folders.arms:FindFirstChild("ViewmodelRig")

    if customRig then
        print("[ViewmodelClient] Found custom ViewmodelRig in correct path")
        return customRig
    end

    print("[ViewmodelClient] Custom ViewmodelRig not found in expected path")
    return nil
end

-- Check for FPS system coordinator to prevent conflicts
local function checkCoordinator()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return false end

    local modulesFolder = fpsSystem:FindFirstChild("Modules")
    if not modulesFolder then return false end

    local coordinator = modulesFolder:FindFirstChild("FPSSystemCoordinator")
    if coordinator then
        local success, coordinatorModule = pcall(function()
            return require(coordinator)
        end)

        if success and coordinatorModule then
            print("[ViewmodelClient] Found FPS coordinator, registering script")
            coordinatorModule.registerScript("ViewmodelClient")
            return coordinatorModule
        end
    end

    return false
end

-- Load essential modules with enhanced error handling
local function loadEssentialModules()
    print("[ViewmodelClient] Loading essential FPS modules...")

    local folders = ensureFPSFolders()
    local modulesFolder = folders.modulesFolder

    local modules = {}

    -- Essential modules list
    local essentialModules = {
        "ViewmodelSystem",
        "ModernRaycastSystem",
        "WeaponFiringSystem"
    }

    -- Optional modules (won't prevent initialization if missing)
    local optionalModules = {
        "CrosshairSystem",
        "FPSCamera",
        "AdvancedSoundSystem",
        "SystemFixes"
    }

    -- Load essential modules first
    local essentialLoaded = true
    for _, moduleName in ipairs(essentialModules) do
        local moduleScript = modulesFolder:FindFirstChild(moduleName)
        if moduleScript then
            modules[moduleName] = safeRequire(moduleScript)
            if not modules[moduleName] then
                warn("[ViewmodelClient] CRITICAL: Failed to load essential module:", moduleName)
                essentialLoaded = false
            end
        else
            warn("[ViewmodelClient] CRITICAL: Essential module not found:", moduleName)
            essentialLoaded = false
        end
    end

    if not essentialLoaded then
        error("[ViewmodelClient] Critical modules missing, cannot initialize FPS system")
        return nil
    end

    -- Load optional modules
    for _, moduleName in ipairs(optionalModules) do
        local moduleScript = modulesFolder:FindFirstChild(moduleName)
        if moduleScript then
            modules[moduleName] = safeRequire(moduleScript)
            if modules[moduleName] then
                print("[ViewmodelClient] Loaded optional module:", moduleName)
            else
                warn("[ViewmodelClient] Failed to load optional module:", moduleName)
            end
        else
            print("[ViewmodelClient] Optional module not found (skipping):", moduleName)
        end
    end

    return modules
end

-- Apply system fixes if available
local function applySystemFixes(modules)
    if modules.SystemFixes then
        print("[ViewmodelClient] Applying system fixes...")

        local fixes = modules.SystemFixes

        -- Apply essential fixes
        if fixes.ensureSystemStructure then
            fixes.ensureSystemStructure()
        end

        if fixes.fixRaycastFilters then
            fixes.fixRaycastFilters()
        end

        if fixes.modernizeSoundSystem then
            fixes.modernizeSoundSystem()
        end

        print("[ViewmodelClient] System fixes applied")
    end
end

-- Initialize viewmodel systems
local function initViewmodel()
    print("[ViewmodelClient] Initializing viewmodel system...")

    -- Check for coordinator
    local coordinator = checkCoordinator()

    -- Load modules
    local modules = loadEssentialModules()
    if not modules then
        error("Failed to load essential modules")
        return nil
    end

    -- Apply system fixes
    applySystemFixes(modules)

    -- Exit if critical modules are missing
    if not modules.ViewmodelSystem then
        error("Critical module ViewmodelSystem is missing!")
        return nil
    end

    -- Create viewmodel instance
    local viewmodel = modules.ViewmodelSystem.new()

    -- Get the custom viewmodel rig
    local customRig = findCustomViewmodelRig()

    -- Set up arms with custom rig
    if customRig then
        print("[ViewmodelClient] Using custom ViewmodelRig from ReplicatedStorage path")
        viewmodel:setupArms(customRig)
    else
        print("[ViewmodelClient] No custom ViewmodelRig found, using default arms")
        viewmodel:setupArms()
    end

    -- Start the update loop
    viewmodel:startUpdateLoop()

    -- Initialize weapon firing system if available
    local weaponFiring = nil
    if modules.WeaponFiringSystem then
        weaponFiring = modules.WeaponFiringSystem.new(viewmodel)
        print("[ViewmodelClient] Weapon firing system initialized")
    end

    -- Setup input handlers for movement states
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.LeftShift then
            viewmodel:setSprinting(true)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            viewmodel:setAiming(true)
        elseif input.KeyCode == Enum.KeyCode.V then
            -- Emergency arm visibility fix
            viewmodel:forceArmVisibilityFix()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.LeftShift then
            viewmodel:setSprinting(false)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            viewmodel:setAiming(false)
        end
    end)

    -- Mouse movement for weapon sway
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            viewmodel.lastMouseDelta = input.Delta
        end
    end)

    print("[ViewmodelClient] Viewmodel system initialized successfully!")

    -- Store systems globally
    _G.ViewmodelSystem = viewmodel
    if weaponFiring then
        _G.WeaponFiringSystem = weaponFiring
    end

    return {
        viewmodel = viewmodel,
        weaponFiring = weaponFiring,
        modules = modules
    }
end

-- Verification function to check viewmodel rig visibility
local function verifyViewmodelRigVisibility()
    task.delay(2, function()
        local camera = workspace.CurrentCamera
        if not camera then return end

        local container = camera:FindFirstChild("ViewmodelContainer")
        if not container then
            print("[ViewmodelClient] ViewmodelContainer not found in verification")
            return
        end

        local rig = container:FindFirstChild("ViewmodelRig")
        if not rig then
            print("[ViewmodelClient] ViewmodelRig not found in verification")
            return
        end

        -- Check arm parts
        local foundArmParts = false
        local visibleArmParts = 0

        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("BasePart") and 
                (descendant.Name == "LeftArm" or 
                    descendant.Name == "RightArm" or
                    descendant.Name:find("Arm") or
                    descendant.Name:find("Hand")) then

                foundArmParts = true

                if descendant.Transparency < 1 then
                    visibleArmParts = visibleArmParts + 1
                else
                    -- Force visibility on invisible arm parts
                    print("[ViewmodelClient] Fixing invisible arm part:", descendant.Name)
                    descendant.Transparency = 0
                    descendant.LocalTransparencyModifier = 0
                    descendant.CanCollide = false
                    descendant.Anchored = true
                end
            end
        end

        if foundArmParts then
            if visibleArmParts > 0 then
                print(string.format("[ViewmodelClient] Verification: %d visible arm parts found", visibleArmParts))
            else
                print("[ViewmodelClient] Verification: Found arm parts but they're all invisible")
            end
        else
            print("[ViewmodelClient] Verification: No arm parts found at all")
        end
    end)
end

-- Main initialization with comprehensive error handling
local function init()
    print("[ViewmodelClient] Starting FPS viewmodel initialization...")

    -- Wait for character
    local function waitForCharacter()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            return player.Character
        end

        return player.CharacterAdded:Wait()
    end

    local character = waitForCharacter()
    print("[ViewmodelClient] Character loaded, initializing viewmodel")

    -- Initialize viewmodel with error handling
    local success, result = pcall(initViewmodel)

    if success and result then
        print("[ViewmodelClient] Viewmodel initialization complete")

        -- Run visibility verification
        verifyViewmodelRigVisibility()

        -- Additional arm visibility fix that runs after a delay
        task.delay(3, function()
            if _G.ViewmodelSystem and _G.ViewmodelSystem.forceArmVisibilityFix then
                _G.ViewmodelSystem:forceArmVisibilityFix()
            end
        end)

        return result
    else
        warn("[ViewmodelClient] Failed to initialize viewmodel:", tostring(result))

        -- Try again after a delay if it failed
        task.delay(2, function()
            print("[ViewmodelClient] Retrying viewmodel initialization...")
            pcall(init)
        end)

        return nil
    end
end

-- Cleanup function for when player leaves
local function cleanup()
    print("[ViewmodelClient] Cleaning up viewmodel systems...")

    if _G.ViewmodelSystem and _G.ViewmodelSystem.cleanup then
        _G.ViewmodelSystem:cleanup()
    end

    if _G.WeaponFiringSystem and _G.WeaponFiringSystem.cleanup then
        _G.WeaponFiringSystem:cleanup()
    end

    _G.ViewmodelClientLoaded = nil
    print("[ViewmodelClient] Cleanup complete")
end

-- Connect cleanup to player removing
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        cleanup()
    end
end)

-- Run initialization
local initResult = init()

-- Debug commands (remove in production)
if game:GetService("RunService"):IsStudio() then
    _G.DebugViewmodel = {
        reinit = init,
        cleanup = cleanup,
        forceVisibilityFix = function()
            if _G.ViewmodelSystem then
                _G.ViewmodelSystem:forceArmVisibilityFix()
            end
        end,
        getInfo = function()
            return {
                loaded = _G.ViewmodelClientLoaded,
                viewmodel = _G.ViewmodelSystem ~= nil,
                weaponFiring = _G.WeaponFiringSystem ~= nil,
                result = initResult
            }
        end
    }

    print("[ViewmodelClient] Debug commands available in _G.DebugViewmodel")
end

return initResult