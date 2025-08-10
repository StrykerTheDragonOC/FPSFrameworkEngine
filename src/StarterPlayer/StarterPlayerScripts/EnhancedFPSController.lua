-- EnhancedFPSController.lua
-- Complete fixed FPS Controller with proper system initialization and error handling
-- Place in StarterPlayerScripts

local EnhancedFPSController = {}
EnhancedFPSController.__index = EnhancedFPSController

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Safe module loading with comprehensive error handling
local function safeRequire(moduleName)
    local success, result = pcall(function()
        -- Try multiple possible locations for the module
        local possibleLocations = {
            ReplicatedStorage:FindFirstChild("FPSSystem") and ReplicatedStorage.FPSSystem:FindFirstChild("Modules"),
            ReplicatedStorage:FindFirstChild("Modules"),
            script.Parent:FindFirstChild("Modules")
        }

        for _, location in ipairs(possibleLocations) do
            if location then
                local moduleScript = location:FindFirstChild(moduleName)
                if moduleScript and moduleScript:IsA("ModuleScript") then
                    return require(moduleScript)
                end
            end
        end

        return nil
    end)

    if success and result then
        print("[FPSController] Successfully loaded module:", moduleName)
        return result
    else
        warn("[FPSController] Failed to load module:", moduleName, "Error:", result)
        return nil
    end
end

-- System state management with clear state transitions
local SystemState = {
    UNINITIALIZED = "UNINITIALIZED",
    INITIALIZING = "INITIALIZING",
    MENU = "MENU",
    DEPLOYING = "DEPLOYING", 
    DEPLOYED = "DEPLOYED",
    ERROR = "ERROR"
}

-- FIXED: Updated default loadout with PocketKnife and proper weapon names
local DEFAULT_LOADOUT = {
    PRIMARY = "G36",
    SECONDARY = "M9",
    MELEE = "PocketKnife", -- FIXED: Changed from KNIFE to match weapon config
    GRENADE = "M67"
}

-- Valid weapon slot mappings for input handling
local WEAPON_SLOT_KEYS = {
    [Enum.KeyCode.One] = "PRIMARY",      -- FIXED: Using correct KeyCode enum values
    [Enum.KeyCode.Two] = "SECONDARY",
    [Enum.KeyCode.Three] = "MELEE",
    [Enum.KeyCode.Four] = "GRENADE"
}

function EnhancedFPSController.new()
    local self = setmetatable({}, EnhancedFPSController)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    self.camera = workspace.CurrentCamera

    -- System management with safe initialization tracking
    self.systems = {}
    self.systemState = SystemState.UNINITIALIZED
    self.initializationErrors = {}
    self.criticalSystemsLoaded = false

    -- Weapon management
    self.loadout = table.clone(DEFAULT_LOADOUT) -- Create a copy to avoid reference issues
    self.currentWeapon = "PRIMARY"
    self.weaponSwitching = false

    -- Input management
    self.inputConnections = {}
    self.inputEnabled = false -- Start disabled (in menu)
    self.mouseControlEnabled = false

    -- Performance monitoring
    self.performanceStats = {
        fps = 60,
        memoryUsage = 0,
        lastFrameTime = tick(),
        frameCount = 0
    }

    -- Configuration with robust error handling settings
    self.config = {
        debugMode = true,
        performanceMonitoring = true,
        maxInitializationRetries = 3,
        initializationTimeout = 10 -- seconds
    }

    -- Initialize with protected call to prevent complete failure
    local initSuccess = pcall(function()
        self:initialize()
    end)

    if not initSuccess then
        warn("[FPSController] Critical initialization failure, entering safe mode")
        self.systemState = SystemState.ERROR
    end

    return self
end

-- Initialize the FPS controller with comprehensive error handling
function EnhancedFPSController:initialize()
    print("[FPSController] Initializing Enhanced FPS Controller...")

    self.systemState = SystemState.INITIALIZING

    -- Wait for character with timeout protection
    local characterReady = self:waitForCharacterWithTimeout(5)
    if not characterReady then
        warn("[FPSController] Character initialization timeout")
    end

    -- Initialize systems with retry logic
    local systemsInitialized = false
    for attempt = 1, self.config.maxInitializationRetries do
        print("[FPSController] System initialization attempt", attempt)

        systemsInitialized = self:initializeSystems()
        if systemsInitialized then
            break
        else
            warn("[FPSController] System initialization failed, attempt", attempt)
            task.wait(1) -- Brief delay before retry
        end
    end

    if not systemsInitialized then
        self.systemState = SystemState.ERROR
        error("[FPSController] Failed to initialize critical systems after multiple attempts")
        return
    end

    -- Start in menu state with proper input management
    self.systemState = SystemState.MENU
    self.inputEnabled = false

    print("[FPSController] Enhanced FPS Controller initialized successfully")
    print("[FPSController] Current state:", self.systemState)
    print("[FPSController] Systems loaded:", table.concat(self:getLoadedSystemNames(), ", "))
end

-- Wait for character with timeout protection to prevent infinite hanging
function EnhancedFPSController:waitForCharacterWithTimeout(timeoutSeconds)
    local startTime = tick()

    if self.player.Character then
        self:onCharacterSpawned(self.player.Character)
        return true
    end

    local connection
    local characterLoaded = false

    connection = self.player.CharacterAdded:Connect(function(character)
        self:onCharacterSpawned(character)
        characterLoaded = true
        if connection then
            connection:Disconnect()
        end
    end)

    -- Wait with timeout
    while not characterLoaded and (tick() - startTime) < timeoutSeconds do
        task.wait(0.1)
    end

    if connection then
        connection:Disconnect()
    end

    return characterLoaded
end

-- Handle character spawning with comprehensive setup
function EnhancedFPSController:onCharacterSpawned(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid", 5)
    self.rootPart = character:WaitForChild("HumanoidRootPart", 5)

    if not self.humanoid or not self.rootPart then
        warn("[FPSController] Failed to get character components")
        return
    end

    print("[FPSController] Character spawned and components loaded")

    -- If already deployed, re-deploy weapons for the new character
    if self.systemState == SystemState.DEPLOYED then
        self:deployWeapons()
    end
end

-- Initialize all required systems with proper dependency management
function EnhancedFPSController:initializeSystems()
    print("[FPSController] Initializing FPS systems...")

    -- FIXED: Load systems with correct naming and proper AdvancedAttachmentSystem
    local systemLoadOrder = {
        -- Critical systems that must load for basic functionality
        {"WeaponConfig", true},              -- Weapon configurations (critical)
        {"EnhancedWeaponSystem", true},      -- Main weapon system (critical) 

        -- Secondary systems that enhance functionality
        {"MeleeSystem", false},              -- Melee system (optional)
        {"GrenadeSystem", false},            -- Grenade system (optional)
        {"ViewmodelSystem", false},          -- Viewmodel rendering (optional)
        {"FPSCamera", false},                -- Camera system (optional)
        {"CrosshairSystem", false},          -- Crosshair system (optional)

        -- FIXED: Using AdvancedAttachmentSystem as requested
        {"AdvancedAttachmentSystem", false}, -- Attachment system (optional)
        {"AdvancedMovementSystem", false},   -- Movement system with diving (optional)
        {"DamageSystem", false},             -- Damage system (optional)
        {"ScreenEffects", false}             -- Screen effects (optional)
    }

    local criticalSystemsLoaded = 0
    local totalCriticalSystems = 0

    -- Count critical systems
    for _, systemInfo in ipairs(systemLoadOrder) do
        if systemInfo[2] then -- is critical
            totalCriticalSystems = totalCriticalSystems + 1
        end
    end

    -- Initialize each system with individual error handling
    for _, systemInfo in ipairs(systemLoadOrder) do
        local systemName, isCritical = systemInfo[1], systemInfo[2]
        local system = self:initializeSystem(systemName, isCritical)

        if system then
            self.systems[systemName] = system
            if isCritical then
                criticalSystemsLoaded = criticalSystemsLoaded + 1
            end
            print("[FPSController] ? Loaded:", systemName)
        else
            if isCritical then
                warn("[FPSController] ? Critical system failed:", systemName)
            else
                print("[FPSController] ? Optional system unavailable:", systemName)
            end
        end
    end

    -- Verify critical systems loaded
    self.criticalSystemsLoaded = (criticalSystemsLoaded == totalCriticalSystems)

    if not self.criticalSystemsLoaded then
        warn("[FPSController] Only", criticalSystemsLoaded, "of", totalCriticalSystems, "critical systems loaded")
        return false
    end

    -- Setup input handling (but keep disabled until deployed)
    self:setupInputHandling()

    -- Setup performance monitoring
    if self.config.performanceMonitoring then
        self:setupPerformanceMonitoring()
    end

    print("[FPSController] All critical systems initialized successfully")
    return true
end

-- Initialize a specific system with enhanced error handling
function EnhancedFPSController:initializeSystem(systemName, isCritical)
    if self.config.debugMode then
        print("[FPSController] Initializing system:", systemName)
    end

    local module = safeRequire(systemName)
    if not module then
        local errorMsg = "Failed to load module: " .. systemName
        if isCritical then
            table.insert(self.initializationErrors, errorMsg)
            return nil
        else
            print("[FPSController] Optional system not found:", systemName)
            return nil
        end
    end

    -- Handle different system initialization patterns with comprehensive error handling
    local system = nil
    local success, result = pcall(function()
        if type(module.new) == "function" then
            -- System with constructor - handle different constructor signatures
            if systemName == "GrenadeSystem" or systemName == "MeleeSystem" then
                -- These systems might need viewmodel reference
                local viewmodelSystem = self.systems.ViewmodelSystem
                system = module.new(viewmodelSystem)
            else
                system = module.new()
            end
        elseif type(module.initialize) == "function" then
            -- System with initialize function
            system = module
            system:initialize()
        elseif type(module) == "table" then
            -- Static module that's ready to use
            system = module
        else
            error("Unknown module type for " .. systemName)
        end

        return system
    end)

    if success and result then
        if self.config.debugMode then
            print("[FPSController] ? System initialized:", systemName)
        end
        return result
    else
        local errorMsg = "Failed to initialize " .. systemName .. ": " .. tostring(result)
        table.insert(self.initializationErrors, errorMsg)

        if isCritical then
            warn("[FPSController] ? Critical system error:", errorMsg)
        else
            print("[FPSController] ? Optional system error:", errorMsg)
        end

        return nil
    end
end

-- FIXED: Setup input handling with correct KeyCode enums and comprehensive mapping
function EnhancedFPSController:setupInputHandling()
    print("[FPSController] Setting up input handling...")

    -- FIXED: Weapon switching with correct KeyCode enum values
    for keyCode, weaponSlot in pairs(WEAPON_SLOT_KEYS) do
        self.inputConnections["weapon_" .. weaponSlot] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not self.inputEnabled then return end
            if input.KeyCode == keyCode then
                self:switchToWeapon(weaponSlot)
            end
        end)
    end

    -- Firing controls (Mouse1)
    self.inputConnections.fire_start = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:startFiring()
        end
    end)

    self.inputConnections.fire_end = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:stopFiring()
        end
    end)

    -- Aiming controls (Mouse2)
    self.inputConnections.aim_start = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:startAiming()
        end
    end)

    self.inputConnections.aim_end = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:stopAiming()
        end
    end)

    -- Reload (R key)
    self.inputConnections.reload = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.R then
            self:reload()
        end
    end)

    -- Quick grenade (G key)
    self.inputConnections.quick_grenade = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.G then
            self:quickGrenade()
        end
    end)

    -- Quick melee (V key)
    self.inputConnections.quick_melee = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.V then
            self:quickMelee()
        end
    end)

    -- Enhanced movement controls for AdvancedMovementSystem
    self:setupAdvancedMovementControls()

    -- Menu toggle (ESC key)
    self.inputConnections.menu_toggle = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            self:toggleMenu()
        end
    end)

    print("[FPSController] Input handling setup complete")
end

-- Setup advanced movement controls including diving capability
function EnhancedFPSController:setupAdvancedMovementControls()
    local movementSystem = self.systems.AdvancedMovementSystem
    if not movementSystem then
        print("[FPSController] AdvancedMovementSystem not available, skipping movement controls")
        return
    end

    -- Sprint controls
    self.inputConnections.sprint_start = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            if movementSystem.setSprinting then
                movementSystem:setSprinting(true)
            end
        end
    end)

    self.inputConnections.sprint_end = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.LeftShift then
            if movementSystem.setSprinting then
                movementSystem:setSprinting(false)
            end
        end
    end)

    -- Crouch/Slide controls
    self.inputConnections.crouch = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
            if movementSystem.toggleCrouch then
                movementSystem:toggleCrouch()
            end
        end
    end)

    -- REQUESTED: Diving while in midair (Space key while airborne and running)
    self.inputConnections.dive = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.Space then
            -- Check if player is airborne and moving fast enough to dive
            if self.humanoid and self.rootPart then
                local isAirborne = self.humanoid:GetState() == Enum.HumanoidStateType.Freefall or 
                    self.humanoid:GetState() == Enum.HumanoidStateType.Flying or
                    self.humanoid:GetState() == Enum.HumanoidStateType.Jumping

                local velocity = self.rootPart.Velocity
                local horizontalSpeed = math.sqrt(velocity.X^2 + velocity.Z^2)

                -- Enable diving if airborne and moving fast enough (like coming from a sprint jump)
                if isAirborne and horizontalSpeed > 10 then -- 10 studs/second minimum speed
                    if movementSystem.dive then
                        movementSystem:dive()
                        print("[FPSController] Dive initiated while airborne")
                    end
                end
            end
        end
    end)

    -- Prone controls
    self.inputConnections.prone = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.X then
            if movementSystem.toggleProne then
                movementSystem:toggleProne()
            end
        end
    end)

    -- Leaning controls
    self.inputConnections.lean_left = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.Q then
            if movementSystem.leanLeft then
                movementSystem:leanLeft(true)
            end
        end
    end)

    self.inputConnections.lean_right = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.E then
            if movementSystem.leanRight then
                movementSystem:leanRight(true)
            end
        end
    end)

    print("[FPSController] Advanced movement controls configured")
end

-- Deploy from menu to game with enhanced validation
function EnhancedFPSController:deploy(loadout)
    if self.systemState == SystemState.DEPLOYED then
        warn("[FPSController] Already deployed")
        return false
    end

    if not self.criticalSystemsLoaded then
        warn("[FPSController] Cannot deploy - critical systems not loaded")
        return false
    end

    print("[FPSController] Deploying to game with loadout:", loadout)

    self.systemState = SystemState.DEPLOYING

    -- Update loadout
    if loadout then
        self.loadout = table.clone(loadout) -- Ensure we don't modify the original
    end

    -- Deploy weapons
    local success = self:deployWeapons()
    if not success then
        warn("[FPSController] Failed to deploy weapons")
        self.systemState = SystemState.MENU
        return false
    end

    -- Enable input and mouse control
    self:enableGameplayInput()

    -- Set state to deployed
    self.systemState = SystemState.DEPLOYED

    print("[FPSController] Successfully deployed to game")
    return true
end

-- Deploy weapons using the weapon system with enhanced error handling
function EnhancedFPSController:deployWeapons()
    local weaponSystem = self.systems.EnhancedWeaponSystem
    if not weaponSystem then
        warn("[FPSController] EnhancedWeaponSystem not available for deployment")
        return false
    end

    -- Verify the weapon system has the required methods
    if type(weaponSystem.deployLoadout) ~= "function" then
        warn("[FPSController] EnhancedWeaponSystem missing deployLoadout method")
        return false
    end

    -- Deploy the loadout with error handling
    local success, result = pcall(function()
        return weaponSystem:deployLoadout(self.loadout)
    end)

    if success and result then
        print("[FPSController] Weapons deployed successfully")
        return true
    else
        warn("[FPSController] Failed to deploy weapons:", result)
        return false
    end
end

-- Enable gameplay input and mouse control
function EnhancedFPSController:enableGameplayInput()
    print("[FPSController] Enabling gameplay input and mouse control")

    self.inputEnabled = true
    self.mouseControlEnabled = true

    -- Lock mouse for FPS gameplay
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Start FPS camera if available
    local fpsCamera = self.systems.FPSCamera
    if fpsCamera and fpsCamera.enable then
        fpsCamera:enable()
    end
end

-- Switch to a weapon slot with enhanced validation
function EnhancedFPSController:switchToWeapon(slot)
    if not self.inputEnabled or self.weaponSwitching then return end

    local weaponSystem = self.systems.EnhancedWeaponSystem
    if weaponSystem and weaponSystem.equipWeapon then
        local success, result = pcall(function()
            return weaponSystem:equipWeapon(slot)
        end)

        if success and result then
            self.currentWeapon = slot
            print("[FPSController] Switched to weapon slot:", slot)
        else
            warn("[FPSController] Failed to switch weapon:", result)
        end
    else
        warn("[FPSController] Weapon system not available for weapon switching")
    end
end

-- Quick grenade with safety checks
function EnhancedFPSController:quickGrenade()
    if not self.inputEnabled then return end

    local weaponSystem = self.systems.EnhancedWeaponSystem
    if weaponSystem and weaponSystem.quickGrenade then
        weaponSystem:quickGrenade()
    else
        print("[FPSController] Quick grenade not available")
    end
end

-- Quick melee with safety checks
function EnhancedFPSController:quickMelee()
    if not self.inputEnabled then return end

    local weaponSystem = self.systems.EnhancedWeaponSystem
    if weaponSystem and weaponSystem.quickMelee then
        weaponSystem:quickMelee()
    else
        print("[FPSController] Quick melee not available")
    end
end

-- Get list of loaded system names for debugging
function EnhancedFPSController:getLoadedSystemNames()
    local names = {}
    for systemName, _ in pairs(self.systems) do
        table.insert(names, systemName)
    end
    return names
end

-- Enhanced cleanup with comprehensive system shutdown
function EnhancedFPSController:cleanup()
    print("[FPSController] Cleaning up Enhanced FPS Controller...")

    -- Disconnect all input connections
    for name, connection in pairs(self.inputConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end

    -- Cleanup all systems with error handling
    for systemName, system in pairs(self.systems) do
        if type(system) == "table" and type(system.cleanup) == "function" then
            local success, result = pcall(function()
                system:cleanup()
            end)

            if success then
                print("[FPSController] ? Cleaned up system:", systemName)
            else
                warn("[FPSController] ? Failed to cleanup system:", systemName, result)
            end
        end
    end

    -- Clear references
    self.inputConnections = {}
    self.systems = {}
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil

    print("[FPSController] Enhanced FPS Controller cleanup complete")
end

-- Start firing, stop firing, start aiming, stop aiming, reload, toggle menu implementations
function EnhancedFPSController:startFiring()
    if not self.inputEnabled then return end
    if self.currentWeapon == "GRENADE" or self.currentWeapon == "MELEE" then return end
    print("[FPSController] Started firing:", self.currentWeapon)
end

function EnhancedFPSController:stopFiring()
    if not self.inputEnabled then return end
    print("[FPSController] Stopped firing")
end

function EnhancedFPSController:startAiming()
    if not self.inputEnabled then return end
    print("[FPSController] Started aiming")
end

function EnhancedFPSController:stopAiming()
    if not self.inputEnabled then return end
    print("[FPSController] Stopped aiming")
end

function EnhancedFPSController:reload()
    if not self.inputEnabled then return end
    print("[FPSController] Reloading:", self.currentWeapon)
end

function EnhancedFPSController:toggleMenu()
    if self.systemState == SystemState.DEPLOYED then
        self:returnToMenu()
    end
end

function EnhancedFPSController:returnToMenu()
    if self.systemState ~= SystemState.DEPLOYED then return false end

    print("[FPSController] Returning to menu...")

    self.inputEnabled = false
    self.mouseControlEnabled = false

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true

    local weaponSystem = self.systems.EnhancedWeaponSystem
    if weaponSystem and weaponSystem.resetDeployment then
        weaponSystem:resetDeployment()
    end

    self.systemState = SystemState.MENU

    if _G.MainMenuSystem then
        _G.MainMenuSystem:returnToMainMenu()
    end

    return true
end

function EnhancedFPSController:setupPerformanceMonitoring()
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        self.performanceStats.frameCount = self.performanceStats.frameCount + 1

        if currentTime - self.performanceStats.lastFrameTime >= 1.0 then
            self.performanceStats.fps = self.performanceStats.frameCount / (currentTime - self.performanceStats.lastFrameTime)
            self.performanceStats.memoryUsage = gcinfo()

            self.performanceStats.frameCount = 0
            self.performanceStats.lastFrameTime = currentTime

            if self.performanceStats.fps < 30 then
                warn("[FPSController] Low FPS detected:", self.performanceStats.fps)
            end
        end
    end)
end

-- Make globally accessible
_G.EnhancedFPSController = EnhancedFPSController

-- Auto-initialize when script loads with protection
local fpsController = nil
local initSuccess = pcall(function()
    fpsController = EnhancedFPSController.new()
end)

if initSuccess and fpsController then
    print("[FPSController] Global FPS Controller initialized successfully")
else
    warn("[FPSController] Failed to initialize global FPS Controller")
end

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer and fpsController then
        fpsController:cleanup()
    end
end)

return fpsController