-- Updated FPS System Initializer with Main Menu Integration
-- Place in StarterPlayerScripts
local FPSSystemInitializer = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- References
local player = Players.LocalPlayer
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- System modules
local systems = {}

-- Configuration
local SYSTEM_CONFIG = {
    -- Core systems to initialize (cleaned up list)
    CORE_SYSTEMS = {
        "ModernRaycastSystem",
        "AdvancedSoundSystem", 
        "AdvancedUISystem",
        "AdvancedAttachmentSystem",
        "AdvancedBallisticsSystem",
        "WeaponFiringSystem",
        "ViewmodelSystem",
        "AdvancedMovementSystem",
        "WeaponConfig",
        "WeaponManager",
        "FPSFramework", -- Renamed from PhantomForcesFramework
        "GrenadeSystem",
        "MeleeSystem"
    },

    -- Server-only systems
    SERVER_SYSTEMS = {
        "ServerValidationSystem",
        "DamageSystem" -- Server version only
    },

    -- Client menu systems
    MENU_SYSTEMS = {
        "MainMenuSystem",
        "EnhancedLoadoutSelector"
    },

    -- Systems that were removed (for reference)
    REMOVED_SYSTEMS = {
        "CrosshairSystem", -- Replaced by AdvancedUISystem
        "HitMarkersUISystem", -- Replaced by AdvancedUISystem
        "ScopeSystem", -- Replaced by AdvancedAttachmentSystem
        "FPSCamera", -- Replaced by ViewmodelSystem
        "WeaponConverter", -- Not needed
        "WeaponModalHandler", -- Redundant
        "WeaponSetup", -- Replaced by WeaponManager
        "AttachmentTester", -- Testing only
        "DebugTestingSystem", -- Testing only
        "HToUnlockMouse" -- Debug script
    },

    -- Default settings
    SPAWN_IN_MENU = true, -- Players start in menu instead of game
    AUTO_DEPLOY = false, -- Require manual deploy button click

    -- Input bindings (only active after deploy)
    KEY_BINDINGS = {
        FIRE = Enum.UserInputType.MouseButton1,
        AIM = Enum.UserInputType.MouseButton2,
        RELOAD = Enum.KeyCode.R,
        PRIMARY = Enum.KeyCode.One,
        SECONDARY = Enum.KeyCode.Two,
        MELEE = Enum.KeyCode.Three,
        GRENADE = Enum.KeyCode.Four,
        SPRINT = Enum.KeyCode.LeftShift,
        CROUCH = Enum.KeyCode.LeftControl,
        PRONE = Enum.KeyCode.X,
        LEAN_LEFT = Enum.KeyCode.Q,
        LEAN_RIGHT = Enum.KeyCode.E,
        FLASHLIGHT = Enum.KeyCode.T,
        LASER = Enum.KeyCode.B,
        LOADOUT = Enum.KeyCode.L,
        CONSOLE = Enum.KeyCode.F1
    }
}

-- Initialize the complete FPS system
function FPSSystemInitializer.initialize()
    print("=== INITIALIZING TACTICAL FPS SYSTEM ===")

    if isClient then
        print("Initializing client systems...")
        FPSSystemInitializer.initializeClient()
    end

    if isServer then
        print("Initializing server systems...")
        FPSSystemInitializer.initializeServer()
    end

    print("=== FPS SYSTEM INITIALIZATION COMPLETE ===")
end

-- Initialize client-side systems
function FPSSystemInitializer.initializeClient()
    -- Wait for character
    if not player.Character then
        player.CharacterAdded:Wait()
    end

    -- Phase 1: Load core framework systems first
    print("Phase 1: Loading core systems...")
    for _, systemName in ipairs(SYSTEM_CONFIG.CORE_SYSTEMS) do
        local success, system = FPSSystemInitializer.loadSystem(systemName)
        if success then
            systems[systemName] = system
            print("? Loaded:", systemName)
        else
            warn("? Failed to load:", systemName, "-", system)
        end
    end

    -- Phase 2: Load menu systems
    print("Phase 2: Loading menu systems...")
    for _, systemName in ipairs(SYSTEM_CONFIG.MENU_SYSTEMS) do
        local success, system = FPSSystemInitializer.loadSystem(systemName)
        if success then
            systems[systemName] = system
            print("? Loaded:", systemName)
        else
            warn("? Failed to load:", systemName, "-", system)
        end
    end

    -- Phase 3: Initialize main framework (only if not spawning in menu)
    if not SYSTEM_CONFIG.SPAWN_IN_MENU then
        FPSSystemInitializer.initializeGameplay()
    else
        print("Spawning in menu - gameplay systems will initialize after deploy")
    end

    print("Client initialization complete!")
end

-- Initialize server-side systems
function FPSSystemInitializer.initializeServer()
    -- Load server systems
    for _, systemName in ipairs(SYSTEM_CONFIG.SERVER_SYSTEMS) do
        local success, system = FPSSystemInitializer.loadSystem(systemName)
        if success then
            systems[systemName] = system
            print("? Server system loaded:", systemName)
        else
            warn("? Failed to load server system:", systemName, "-", system)
        end
    end

    -- Setup game mode
    FPSSystemInitializer.setupGameMode()

    print("Server initialization complete!")
end

-- Initialize gameplay systems (called after deploy)
function FPSSystemInitializer.initializeGameplay()
    print("Initializing gameplay systems...")

    -- Initialize the main framework
    if systems.FPSFramework then
        _G.FPSFramework = systems.FPSFramework.new()
        systems.Framework = _G.FPSFramework
        print("? Main framework initialized")
    end

    -- Setup systems interconnections
    FPSSystemInitializer.connectSystems()

    -- Setup input handling (only after deploy)
    FPSSystemInitializer.setupInputSystem()

    -- Initialize HUD
    if systems.AdvancedUISystem then
        _G.AdvancedUISystem = systems.AdvancedUISystem.new()
        print("? HUD initialized")
    end

    print("Gameplay systems initialized!")
end

-- Load a system module
function FPSSystemInitializer.loadSystem(systemName)
    local success, result = pcall(function()
        local modulePath = ReplicatedStorage:FindFirstChild("FPSSystem")
        if not modulePath then
            error("FPSSystem folder not found in ReplicatedStorage")
        end

        local modulesFolder = modulePath:FindFirstChild("Modules")
        if not modulesFolder then
            error("Modules folder not found in FPSSystem")
        end

        local moduleScript = modulesFolder:FindFirstChild(systemName)
        if not moduleScript then
            -- Try StarterPlayerScripts for menu systems
            local starterPlayerScripts = player:FindFirstChild("PlayerScripts")
            if starterPlayerScripts then
                moduleScript = starterPlayerScripts:FindFirstChild(systemName)
            end

            if not moduleScript then
                error("Module not found: " .. systemName)
            end
        end

        return require(moduleScript)
    end)

    if success then
        return true, result
    else
        return false, result
    end
end

-- Connect systems together
function FPSSystemInitializer.connectSystems()
    -- Connect firing system to sound system
    if systems.WeaponFiringSystem and systems.AdvancedSoundSystem and _G.FPSFramework then
        local firingSystem = _G.FPSFramework.systems.firing
        local soundSystem = systems.AdvancedSoundSystem.new()

        -- Store sound system globally
        _G.SoundSystem = soundSystem

        print("? Sound system connected to firing system")
    end

    -- Connect UI system to other systems
    if _G.AdvancedUISystem and _G.FPSFramework then
        local uiSystem = _G.AdvancedUISystem

        -- Update UI when systems change
        spawn(function()
            while _G.FPSFramework do
                -- Update ammo display
                if _G.FPSFramework.systems and _G.FPSFramework.systems.firing then
                    local ammoDisplay = _G.FPSFramework.systems.firing:getAmmoDisplay()
                    if ammoDisplay and ammoDisplay ~= "0 / 0" then
                        local current, reserve = ammoDisplay:match("(%d+) / (%d+)")
                        uiSystem:updateAmmo(tonumber(current) or 0, tonumber(reserve) or 0)
                    end
                end
                wait(0.1)
            end
        end)
    end

    print("Systems connected successfully")
end

-- Setup input system (only active after deploy)
function FPSSystemInitializer.setupInputSystem()
    local inputConnections = {}

    -- Only setup game inputs if player has deployed
    if SYSTEM_CONFIG.SPAWN_IN_MENU and _G.MainMenuSystem and _G.MainMenuSystem:isPlayerInMenu() then
        print("Player in menu - skipping game input setup")
        return
    end

    print("Setting up game input controls...")

    -- Input began
    inputConnections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        -- Skip if player is in menu
        if _G.MainMenuSystem and _G.MainMenuSystem:isPlayerInMenu() then
            return
        end

        local keyCode = input.KeyCode
        local inputType = input.UserInputType

        -- Weapon firing
        if inputType == SYSTEM_CONFIG.KEY_BINDINGS.FIRE then
            if _G.FPSFramework then
                _G.FPSFramework:startFiring()
            end

            -- Weapon aiming
        elseif inputType == SYSTEM_CONFIG.KEY_BINDINGS.AIM then
            if _G.FPSFramework then
                _G.FPSFramework:startAiming()
            end

            -- Weapon reloading
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.RELOAD then
            if _G.FPSFramework then
                _G.FPSFramework:reload()
            end

            -- Weapon switching
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.PRIMARY then
            if _G.FPSFramework then
                _G.FPSFramework:switchWeapon("PRIMARY")
            end
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.SECONDARY then
            if _G.FPSFramework then
                _G.FPSFramework:switchWeapon("SECONDARY")
            end
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.MELEE then
            if _G.FPSFramework then
                _G.FPSFramework:switchWeapon("MELEE")
            end
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.GRENADE then
            if _G.FPSFramework then
                _G.FPSFramework:switchWeapon("GRENADE")
            end

            -- Movement
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.SPRINT then
            if systems.AdvancedMovementSystem then
                systems.AdvancedMovementSystem:setSprinting(true)
            end
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.CROUCH then
            if systems.AdvancedMovementSystem then
                systems.AdvancedMovementSystem:toggleCrouch()
            end
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.PRONE then
            if systems.AdvancedMovementSystem then
                systems.AdvancedMovementSystem:toggleProne()
            end

            -- Interface
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.LOADOUT then
            if _G.EnhancedLoadoutSelector then
                if _G.EnhancedLoadoutSelector.isOpen then
                    _G.EnhancedLoadoutSelector:closeMenu()
                else
                    _G.EnhancedLoadoutSelector:openMenu()
                end
            end
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.CONSOLE then
            FPSSystemInitializer.toggleConsole()
        end
    end)

    -- Input ended
    inputConnections.inputEnded = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end

        -- Skip if player is in menu
        if _G.MainMenuSystem and _G.MainMenuSystem:isPlayerInMenu() then
            return
        end

        local keyCode = input.KeyCode
        local inputType = input.UserInputType

        -- Stop firing
        if inputType == SYSTEM_CONFIG.KEY_BINDINGS.FIRE then
            if _G.FPSFramework then
                _G.FPSFramework:stopFiring()
            end

            -- Stop aiming
        elseif inputType == SYSTEM_CONFIG.KEY_BINDINGS.AIM then
            if _G.FPSFramework then
                _G.FPSFramework:stopAiming()
            end

            -- Stop sprinting
        elseif keyCode == SYSTEM_CONFIG.KEY_BINDINGS.SPRINT then
            if systems.AdvancedMovementSystem then
                systems.AdvancedMovementSystem:setSprinting(false)
            end
        end
    end)

    _G.FPSInputConnections = inputConnections
    print("Game input system configured")
end

-- Called when player deploys from menu
function FPSSystemInitializer.onPlayerDeploy()
    print("Player deployed - initializing gameplay systems...")

    -- Initialize gameplay systems
    FPSSystemInitializer.initializeGameplay()

    -- Apply current loadout
    if _G.EnhancedLoadoutSelector and _G.FPSFramework then
        local loadout = _G.EnhancedLoadoutSelector.currentLoadout
        for slot, weapon in pairs(loadout) do
            _G.FPSFramework:loadWeapon(slot, weapon)
        end
        _G.FPSFramework:switchWeapon("PRIMARY")
    end

    print("Player successfully deployed to battlefield!")
end

-- Setup game mode (server-side)
function FPSSystemInitializer.setupGameMode()
    -- Placeholder for game mode setup
    print("Game mode configured")
end

-- Toggle debug console
function FPSSystemInitializer.toggleConsole()
    local existingConsole = player.PlayerGui:FindFirstChild("DebugConsole")

    if existingConsole then
        existingConsole:Destroy()
        return
    end

    -- Create debug console
    local console = Instance.new("ScreenGui")
    console.Name = "DebugConsole"
    console.Parent = player.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0.6, 0)
    frame.Position = UDim2.new(0.1, 0, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.1
    frame.Parent = console

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Console output
    local output = Instance.new("ScrollingFrame")
    output.Size = UDim2.new(1, -20, 0.8, -10)
    output.Position = UDim2.new(0, 10, 0, 10)
    output.BackgroundTransparency = 1
    output.Parent = frame

    local outputText = Instance.new("TextLabel")
    outputText.Size = UDim2.new(1, 0, 1, 0)
    outputText.BackgroundTransparency = 1
    outputText.Text = FPSSystemInitializer.getSystemStatus()
    outputText.TextColor3 = Color3.fromRGB(0, 255, 0)
    outputText.TextScaled = true
    outputText.Font = Enum.Font.Code
    outputText.TextXAlignment = Enum.TextXAlignment.Left
    outputText.TextYAlignment = Enum.TextYAlignment.Top
    outputText.Parent = output

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 30)
    closeButton.Position = UDim2.new(1, -110, 0.8, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "CLOSE"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame

    closeButton.MouseButton1Click:Connect(function()
        console:Destroy()
    end)
end

-- Get system status
function FPSSystemInitializer.getSystemStatus()
    local status = "=== TACTICAL FPS SYSTEM STATUS ===\n\n"

    -- System status
    status = status .. "LOADED SYSTEMS:\n"
    for systemName, system in pairs(systems) do
        if system then
            status = status .. "? " .. systemName .. " - ACTIVE\n"
        else
            status = status .. "? " .. systemName .. " - FAILED\n"
        end
    end

    status = status .. "\nREMOVED SYSTEMS (Cleaned Up):\n"
    for _, systemName in ipairs(SYSTEM_CONFIG.REMOVED_SYSTEMS) do
        status = status .. "??? " .. systemName .. " - REMOVED\n"
    end

    status = status .. "\n=== GLOBAL REFERENCES ===\n"

    -- Global references
    local globals = {
        "FPSFramework",
        "MainMenuSystem",
        "EnhancedLoadoutSelector", 
        "AdvancedUISystem",
        "SoundSystem",
        "ServerValidationSystem"
    }

    for _, globalName in ipairs(globals) do
        if _G[globalName] then
            status = status .. "? _G." .. globalName .. " - AVAILABLE\n"
        else
            status = status .. "? _G." .. globalName .. " - MISSING\n"
        end
    end

    status = status .. "\n=== MENU STATUS ===\n"
    if _G.MainMenuSystem then
        status = status .. "Menu System: " .. (_G.MainMenuSystem:isPlayerInMenu() and "IN MENU" or "DEPLOYED") .. "\n"
    end

    status = status .. "\n=== PERFORMANCE ===\n"
    status = status .. "FPS: " .. math.floor(1/RunService.Heartbeat:Wait()) .. "\n"
    status = status .. "Memory: " .. math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()) .. " MB\n"

    return status
end

-- Cleanup function
function FPSSystemInitializer.cleanup()
    -- Cleanup all systems
    for systemName, system in pairs(systems) do
        if system and system.cleanup then
            system:cleanup()
        end
    end

    -- Disconnect input connections
    if _G.FPSInputConnections then
        for _, connection in pairs(_G.FPSInputConnections) do
            if connection then
                connection:Disconnect()
            end
        end
    end

    -- Clear global references
    _G.FPSFramework = nil
    _G.MainMenuSystem = nil
    _G.EnhancedLoadoutSelector = nil
    _G.AdvancedUISystem = nil
    _G.SoundSystem = nil
    _G.FPSInputConnections = nil

    print("FPS System cleaned up")
end

-- Connect to main menu deploy event
spawn(function()
    -- Wait for main menu system
    while not _G.MainMenuSystem do
        wait(0.1)
    end

    -- Override the deploy function to trigger our initialization
    local originalDeploy = _G.MainMenuSystem.deployToGame
    _G.MainMenuSystem.deployToGame = function(self)
        originalDeploy(self)
        -- Initialize gameplay systems after deploy
        task.delay(1.5, function()
            FPSSystemInitializer.onPlayerDeploy()
        end)
    end

    print("Connected to main menu deploy system")
end)

-- Auto-initialize when script runs
if isClient then
    -- Wait for game to load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    -- Initialize after a short delay
    wait(1)
    FPSSystemInitializer.initialize()

    -- Cleanup on player leaving
    game:BindToClose(function()
        FPSSystemInitializer.cleanup()
    end)
end

if isServer then
    -- Server initialization
    FPSSystemInitializer.initialize()
end

-- Export for manual control
_G.FPSSystemInitializer = FPSSystemInitializer

return FPSSystemInitializer