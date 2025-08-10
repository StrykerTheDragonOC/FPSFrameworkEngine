-- EnhancedFPSController.client.lua
-- Main FPS system controller with error handling and modern architecture
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local keyNames = {"One", "Two", "Three", "Four"}
local weaponSlots = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}
local player = Players.LocalPlayer

-- Enhanced FPS Controller
local EnhancedFPSController = {}
EnhancedFPSController.__index = EnhancedFPSController

-- System state management
local SystemState = {
    UNINITIALIZED = "UNINITIALIZED",
    INITIALIZING = "INITIALIZING", 
    READY = "READY",
    ERROR = "ERROR"
}

-- Constructor
function EnhancedFPSController.new()
    local self = setmetatable({}, EnhancedFPSController)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil
    self.camera = workspace.CurrentCamera

    -- System management
    self.systems = {}
    self.systemState = SystemState.UNINITIALIZED
    self.initializationErrors = {}

    -- Weapon management
    self.weapons = {
        PRIMARY = nil,
        SECONDARY = nil,
        MELEE = nil,
        GRENADE = nil
    }
    self.currentWeapon = "PRIMARY"
    self.weaponSwitching = false

    -- Input management
    self.inputConnections = {}
    self.inputEnabled = true

    -- Performance monitoring
    self.lastFrameTime = tick()
    self.frameCount = 0
    self.performanceStats = {
        fps = 60,
        memoryUsage = 0,
        systemLoad = 0
    }

    -- Configuration
    self.config = {
        autoInit = true,
        debugMode = true,
        errorReporting = true,
        performanceMonitoring = true
    }

    return self
end

-- Safely require a module with comprehensive error handling
function EnhancedFPSController:safeRequire(modulePath, isOptional)
    local success, result = pcall(function()
        local moduleScript = ReplicatedStorage.FPSSystem.Modules:FindFirstChild(modulePath)
        if not moduleScript then
            error("Module not found: " .. modulePath)
        end
        return require(moduleScript)
    end)

    if success then
        if self.config.debugMode then
            print("[FPS Controller] Successfully loaded:", modulePath)
        end
        return result
    else
        local errorMsg = "Failed to load " .. modulePath .. ": " .. tostring(result)
        table.insert(self.initializationErrors, errorMsg)

        if not isOptional then
            warn("[FPS Controller] Critical error:", errorMsg)
            self.systemState = SystemState.ERROR
        else
            warn("[FPS Controller] Optional module failed:", errorMsg)
        end

        return nil
    end
end

-- Initialize all FPS systems
function EnhancedFPSController:initialize()
    print("[FPS Controller] Initializing Enhanced FPS System...")
    self.systemState = SystemState.INITIALIZING

    -- Wait for character
    if not self.player.Character then
        self.player.CharacterAdded:Wait()
    end

    self.character = self.player.Character
    self.humanoid = self.character:WaitForChild("Humanoid")
    self.rootPart = self.character:WaitForChild("HumanoidRootPart")

    -- Initialize systems in order of dependency
    local systemInitOrder = {
        {"RaycastUtility", true},           -- Core utility (critical)
        {"WeaponConfig", true},             -- Weapon configurations (critical)
        {"ViewmodelSystem", false},         -- Viewmodel rendering (optional)
        {"EnhancedWeaponSystem", true},             -- Weapon mechanics (critical)
        {"GrenadeSystem", true},   -- Grenade system (optional)
        {"EnhancedMeleeSystem", false},     -- Melee system (optional)
        {"FPSCamera", true},                -- Camera system (critical)
        {"AdvancedMovementSystem", false},  -- Movement system (optional)
        {"AdvancedAttachmentSystem", false},        -- Attachment system (optional)
        {"DamageSystem", false}             -- Damage system (optional)
    }

    -- Initialize each system
    for _, systemInfo in ipairs(systemInitOrder) do
        local systemName, isCritical = systemInfo[1], systemInfo[2]
        local system = self:initializeSystem(systemName, isCritical)

        if system then
            self.systems[systemName] = system
        elseif isCritical then
            self.systemState = SystemState.ERROR
            error("[FPS Controller] Critical system failed to initialize: " .. systemName)
            return false
        end
    end

    -- Setup input handling
    self:setupInputHandling()

    -- Setup performance monitoring
    if self.config.performanceMonitoring then
        self:setupPerformanceMonitoring()
    end

    -- Load default loadout
    self:loadDefaultLoadout()

    self.systemState = SystemState.READY
    print("[FPS Controller] Enhanced FPS System ready!")

    -- Report any non-critical errors
    if #self.initializationErrors > 0 then
        print("[FPS Controller] Non-critical errors during initialization:")
        for _, error in ipairs(self.initializationErrors) do
            print(" - " .. error)
        end
    end

    return true
end

-- Initialize a specific system
function EnhancedFPSController:initializeSystem(systemName, isCritical)
    if self.config.debugMode then
        print("[FPS Controller] Initializing system:", systemName)
    end

    local module = self:safeRequire(systemName, not isCritical)
    if not module then
        return nil
    end

    -- Handle different system initialization patterns
    local system = nil
    local success, result = pcall(function()
        if type(module.new) == "function" then
            -- System with constructor
            if systemName == "EnhancedGrenadeSystem" or systemName == "EnhancedMeleeSystem" then
                system = module.new(self.systems.ViewmodelSystem)
            else
                system = module.new()
            end
        elseif type(module.initialize) == "function" then
            -- System with initialize function
            system = module
            system:initialize()
        else
            -- Static module
            system = module
        end

        return system
    end)

    if success then
        if self.config.debugMode then
            print("[FPS Controller] System initialized:", systemName)
        end
        return result
    else
        local errorMsg = "Failed to initialize " .. systemName .. ": " .. tostring(result)
        table.insert(self.initializationErrors, errorMsg)

        if isCritical then
            warn("[FPS Controller] Critical system error:", errorMsg)
        end

        return nil
    end
end

-- Setup comprehensive input handling
function EnhancedFPSController:setupInputHandling()
    print("[FPS Controller] Setting up input handling...")

    -- Weapon switching (1-4 keys)
    for i = 1, 4 do
        local keyCode = Enum.KeyCode[keyNames[i]]
        local weaponSlot = weaponSlots[i]

        self.inputConnections["weapon_" .. i] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not self.inputEnabled then return end
            if input.KeyCode == keyCode then
                self:switchToWeapon(weaponSlot)
            end
        end)
    end

    -- Firing (Mouse1)
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

    -- Aiming (Mouse2)
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

    -- Grenade (G key)
    self.inputConnections.grenade = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.G then
            self:quickGrenade()
        end
    end)

    -- Melee (V key)
    self.inputConnections.melee = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.V then
            self:quickMelee()
        end
    end)

    -- Sprint (Left Shift)
    self.inputConnections.sprint_start = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            self:setSprint(true)
        end
    end)

    self.inputConnections.sprint_end = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.LeftShift then
            self:setSprint(false)
        end
    end)

    -- Crouch/Slide (C key)
    self.inputConnections.crouch = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.C then
            self:toggleCrouch()
        end
    end)

    -- Prone (X key)
    self.inputConnections.prone = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.X then
            self:toggleProne()
        end
    end)

    -- Lean (Q/E keys)
    self.inputConnections.lean_left = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.Q then
            self:setLean(-1)
        end
    end)

    self.inputConnections.lean_right = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.E then
            self:setLean(1)
        end
    end)

    -- Stop leaning
    self.inputConnections.lean_stop = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
            self:setLean(0)
        end
    end)

    -- Attachment mode (T key)
    self.inputConnections.attachment_mode = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.T then
            self:toggleAttachmentMode()
        end
    end)

    -- Loadout menu (L key)
    self.inputConnections.loadout_menu = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.inputEnabled then return end
        if input.KeyCode == Enum.KeyCode.L then
            self:openLoadoutMenu()
        end
    end)

    print("[FPS Controller] Input handling configured")
end

-- Setup performance monitoring
function EnhancedFPSController:setupPerformanceMonitoring()
    self.performanceConnection = RunService.Heartbeat:Connect(function()
        self.frameCount = self.frameCount + 1
        local currentTime = tick()

        -- Update FPS every second
        if currentTime - self.lastFrameTime >= 1 then
            self.performanceStats.fps = self.frameCount / (currentTime - self.lastFrameTime)
            self.performanceStats.memoryUsage = gcinfo()
            -- Reset counters
            self.frameCount = 0
            self.lastFrameTime = currentTime

            -- Check for performance issues
            if self.performanceStats.fps < 30 then
                warn("[FPS Controller] Low FPS detected:", self.performanceStats.fps)
            end
        end
    end)
end

-- Load default weapon loadout
function EnhancedFPSController:loadDefaultLoadout()
    print("[FPS Controller] Loading default loadout...")

    local defaultLoadout = {
        PRIMARY = "AK74",
        SECONDARY = "M9",
        MELEE = "KNIFE",
        GRENADE = "M67 FRAG"
    }

    for slot, weaponName in pairs(defaultLoadout) do
        self:loadWeapon(slot, weaponName)
    end

    -- Equip primary weapon
    self:switchToWeapon("PRIMARY")
end

-- Load a weapon into a slot
function EnhancedFPSController:loadWeapon(slot, weaponName)
    if not self.systems.EnhancedWeaponSystem then
        warn("[FPS Controller] Cannot load weapon: EnhancedWeaponSystem not available")
        return false
    end

    local success = self.systems.EnhancedWeaponSystem:loadWeapon(slot, weaponName)
    if success then
        self.weapons[slot] = weaponName
        print("[FPS Controller] Loaded", weaponName, "into", slot, "slot")
    else
        warn("[FPS Controller] Failed to load", weaponName, "into", slot, "slot")
    end

    return success
end

-- Switch to a weapon slot
function EnhancedFPSController:switchToWeapon(slot)
    if self.weaponSwitching then return end
    if not self.weapons[slot] then
        warn("[FPS Controller] No weapon in slot:", slot)
        return
    end

    if self.currentWeapon == slot then return end

    self.weaponSwitching = true

    -- Stop any current actions
    self:stopFiring()
    self:stopAiming()

    -- Switch weapon
    local oldWeapon = self.currentWeapon
    self.currentWeapon = slot

    -- Update systems
    if self.systems.EnhancedWeaponSystem then
        self.systems.EnhancedWeaponSystem:equipWeapon(slot)
    end

    if self.systems.ViewmodelSystem then
        self.systems.ViewmodelSystem:switchWeapon(slot, self.weapons[slot])
    end

    -- Play switch sound
    self:playWeaponSwitchSound()

    print("[FPS Controller] Switched from", oldWeapon, "to", slot)

    -- Reset switching flag after animation
    task.delay(0.5, function()
        self.weaponSwitching = false
    end)
end

-- Weapon action methods
function EnhancedFPSController:startFiring()
    if self.weaponSwitching then return end

    if self.currentWeapon == "PRIMARY" or self.currentWeapon == "SECONDARY" then
        if self.systems.EnhancedWeaponSystem then
            self.systems.EnhancedWeaponSystem:startFiring()
        end
    elseif self.currentWeapon == "MELEE" then
        if self.systems.EnhancedMeleeSystem then
            self.systems.EnhancedMeleeSystem:startAttack()
        end
    elseif self.currentWeapon == "GRENADE" then
        if self.systems.EnhancedGrenadeSystem then
            self.systems.EnhancedGrenadeSystem:startCooking()
        end
    end
end

function EnhancedFPSController:stopFiring()
    if self.currentWeapon == "PRIMARY" or self.currentWeapon == "SECONDARY" then
        if self.systems.EnhancedWeaponSystem then
            self.systems.EnhancedWeaponSystem:stopFiring()
        end
    elseif self.currentWeapon == "MELEE" then
        if self.systems.EnhancedMeleeSystem then
            self.systems.EnhancedMeleeSystem:endAttack()
        end
    elseif self.currentWeapon == "GRENADE" then
        if self.systems.EnhancedGrenadeSystem then
            self.systems.EnhancedGrenadeSystem:throwGrenade()
        end
    end
end

function EnhancedFPSController:startAiming()
    if self.weaponSwitching then return end
    if self.currentWeapon ~= "PRIMARY" and self.currentWeapon ~= "SECONDARY" then return end

    if self.systems.EnhancedWeaponSystem then
        self.systems.EnhancedWeaponSystem:startAiming()
    end

    if self.systems.FPSCamera then
        self.systems.FPSCamera:setAiming(true)
    end
end

function EnhancedFPSController:stopAiming()
    if self.systems.EnhancedWeaponSystem then
        self.systems.EnhancedWeaponSystem:stopAiming()
    end

    if self.systems.FPSCamera then
        self.systems.FPSCamera:setAiming(false)
    end
end

function EnhancedFPSController:reload()
    if self.weaponSwitching then return end
    if self.currentWeapon ~= "PRIMARY" and self.currentWeapon ~= "SECONDARY" then return end

    if self.systems.EnhancedWeaponSystem then
        self.systems.EnhancedWeaponSystem:reload()
    end
end

-- Movement methods
function EnhancedFPSController:setSprint(sprinting)
    if self.systems.AdvancedMovementSystem then
        self.systems.AdvancedMovementSystem:setSprinting(sprinting)
    end

    if self.systems.FPSCamera then
        self.systems.FPSCamera:setSprinting(sprinting)
    end
end

function EnhancedFPSController:toggleCrouch()
    if self.systems.AdvancedMovementSystem then
        self.systems.AdvancedMovementSystem:toggleCrouch()
    end
end

function EnhancedFPSController:toggleProne()
    if self.systems.AdvancedMovementSystem then
        self.systems.AdvancedMovementSystem:toggleProne()
    end
end

function EnhancedFPSController:setLean(direction)
    if self.systems.FPSCamera then
        self.systems.FPSCamera:setLean(direction)
    end
end

-- Quick actions
function EnhancedFPSController:quickGrenade()
    local previousWeapon = self.currentWeapon

    self:switchToWeapon("GRENADE")

    -- Auto-throw after delay
    task.delay(0.5, function()
        if self.currentWeapon == "GRENADE" then
            self:startFiring()

            -- Auto-throw and switch back
            task.delay(1.5, function()
                self:stopFiring()
                task.delay(0.5, function()
                    self:switchToWeapon(previousWeapon)
                end)
            end)
        end
    end)
end

function EnhancedFPSController:quickMelee()
    local previousWeapon = self.currentWeapon

    self:switchToWeapon("MELEE")

    -- Auto-attack and switch back
    task.delay(0.3, function()
        if self.currentWeapon == "MELEE" then
            self:startFiring()
            task.delay(0.6, function()
                self:switchToWeapon(previousWeapon)
            end)
        end
    end)
end

-- UI Methods
function EnhancedFPSController:toggleAttachmentMode()
    self.inputEnabled = not self.inputEnabled

    if self.systems.AttachmentSystem then
        -- TODO: Open attachment customization UI
        print("[FPS Controller] Attachment mode toggled:", not self.inputEnabled)
    end

    -- Toggle mouse lock
    if _G.FPSCameraMouseControl then
        if self.inputEnabled then
            _G.FPSCameraMouseControl.lockMouse()
        else
            _G.FPSCameraMouseControl.unlockMouse()
        end
    end
end

function EnhancedFPSController:openLoadoutMenu()
    if _G.ModernLoadout then
        _G.ModernLoadout:openGUI()
    else
        warn("[FPS Controller] Modern Loadout system not available")
    end
end

-- Audio methods
function EnhancedFPSController:playWeaponSwitchSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://131961136"  -- Replace with actual switch sound
    sound.Volume = 0.5
    sound.Parent = self.camera
    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Error handling and recovery
function EnhancedFPSController:handleSystemError(systemName, error)
    warn("[FPS Controller] System error in", systemName, ":", error)

    -- Attempt to restart the system
    if self.systems[systemName] and type(self.systems[systemName].restart) == "function" then
        print("[FPS Controller] Attempting to restart", systemName)
        self.systems[systemName]:restart()
    end
end

-- Cleanup
function EnhancedFPSController:cleanup()
    print("[FPS Controller] Cleaning up Enhanced FPS Controller...")

    -- Disconnect all input connections
    for name, connection in pairs(self.inputConnections) do
        connection:Disconnect()
    end

    -- Disconnect performance monitoring
    if self.performanceConnection then
        self.performanceConnection:Disconnect()
    end

    -- Cleanup all systems
    for systemName, system in pairs(self.systems) do
        if type(system.cleanup) == "function" then
            system:cleanup()
        elseif type(system.destroy) == "function" then
            system:destroy()
        end
    end

    -- Clear references
    self.systems = {}
    self.inputConnections = {}

    print("[FPS Controller] Cleanup complete")
end

-- Get system status
function EnhancedFPSController:getSystemStatus()
    local status = {
        state = self.systemState,
        loadedSystems = {},
        errors = self.initializationErrors,
        performance = self.performanceStats,
        currentWeapon = self.currentWeapon,
        weapons = self.weapons
    }

    for systemName, system in pairs(self.systems) do
        status.loadedSystems[systemName] = system ~= nil
    end

    return status
end

-- Initialize controller
local controller = EnhancedFPSController.new()

-- Character respawn handling
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)  -- Wait for character to fully load
    controller:cleanup()
    controller = EnhancedFPSController.new()
    controller:initialize()
end)

-- Global access
_G.EnhancedFPSController = controller
_G.FPSController = controller  -- Backward compatibility

-- Auto-initialize
if controller.config.autoInit then
    controller:initialize()
end

-- Debug commands
if game:GetService("RunService"):IsStudio() then
    _G.FPSDebug = {
        getStatus = function() return controller:getSystemStatus() end,
        restart = function() 
            controller:cleanup()
            controller:initialize()
        end,
        toggleDebug = function()
            controller.config.debugMode = not controller.config.debugMode
        end
    }
end

return controller