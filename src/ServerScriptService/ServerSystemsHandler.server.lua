-- ServerSystemsHandler.server.lua
-- Fixed server systems handler with proper module references
-- Place in ServerScriptService

local ServerSystemsHandler = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local FPS_SYSTEM_PATH = ReplicatedStorage:WaitForChild("FPSSystem")
local MODULES_PATH = FPS_SYSTEM_PATH:WaitForChild("Modules")

-- Module references (ensure these exist)
local requiredModules = {
    "ComprehensiveAttachmentSystem",  -- Fixed: was AdvancedAttachmentSystem
    "DamageSystem", 
    "ComprehensiveGrenadeSystem",
    "AdvancedSoundSystem",
    "MetaSystem"
}

-- Loaded modules storage
local loadedModules = {}
local systemsInitialized = false

-- Safe module loader with error handling
local function safeRequire(moduleScript)
    local success, result = pcall(function()
        return require(moduleScript)
    end)

    if success then
        return result
    else
        warn("Failed to load module " .. moduleScript.Name .. ": " .. tostring(result))
        return nil
    end
end

-- Load all required modules
local function loadModules()
    print("ServerSystemsHandler: Loading modules...")

    for _, moduleName in ipairs(requiredModules) do
        local moduleScript = MODULES_PATH:FindFirstChild(moduleName)

        if moduleScript then
            local module = safeRequire(moduleScript)
            if module then
                loadedModules[moduleName] = module
                print("Loaded server module:", moduleName)
            else
                warn("Failed to load server module:", moduleName)
            end
        else
            -- Only warn for critical modules
            if moduleName == "ComprehensiveAttachmentSystem" or moduleName == "DamageSystem" or moduleName == "ComprehensiveGrenadeSystem" then
                warn("Critical server module not found:", moduleName)
            else
                print("Optional server module not found:", moduleName)
            end
        end
    end

    print("ServerSystemsHandler: Module loading complete")
end

-- Initialize server systems
local function initializeSystems()
    if systemsInitialized then
        return
    end

    print("ServerSystemsHandler: Initializing systems...")

    -- Initialize ComprehensiveAttachmentSystem
    if loadedModules.ComprehensiveAttachmentSystem then
        if loadedModules.ComprehensiveAttachmentSystem.init then
            loadedModules.ComprehensiveAttachmentSystem.init()
            print("ComprehensiveAttachmentSystem initialized")
        end
    end

    -- Initialize DamageSystem
    if loadedModules.DamageSystem then
        if loadedModules.DamageSystem.init then
            loadedModules.DamageSystem.init()
            print("DamageSystem initialized")
        end
    end

    -- Initialize ComprehensiveGrenadeSystem
    if loadedModules.ComprehensiveGrenadeSystem then
        if loadedModules.ComprehensiveGrenadeSystem.init then
            loadedModules.ComprehensiveGrenadeSystem.init()
            print("ComprehensiveGrenadeSystem initialized")
        end
    end

    -- Initialize AdvancedSoundSystem with proper setup
    if loadedModules.AdvancedSoundSystem then
        if loadedModules.AdvancedSoundSystem.initServer then
            loadedModules.AdvancedSoundSystem.initServer()
            print("AdvancedSoundSystem server initialized")
        end
    end

    systemsInitialized = true
    print("ServerSystemsHandler: All systems initialized")
end

-- Handle player joining
local function onPlayerAdded(player)
    print("Player joined:", player.Name)

    -- Initialize player-specific systems
    player.CharacterAdded:Connect(function(character)
        print("Character spawned for:", player.Name)

        -- Initialize character-specific systems here if needed
        if loadedModules.DamageSystem and loadedModules.DamageSystem.initializePlayer then
            loadedModules.DamageSystem.initializePlayer(player, character)
        end
    end)
end

-- Handle player leaving
local function onPlayerRemoving(player)
    print("Player leaving:", player.Name)

    -- Clean up player-specific data
    if loadedModules.DamageSystem and loadedModules.DamageSystem.cleanupPlayer then
        loadedModules.DamageSystem.cleanupPlayer(player)
    end
end

-- Main initialization
local function init()
    print("ServerSystemsHandler: Starting initialization...")

    -- Load all modules first
    loadModules()

    -- Initialize systems
    initializeSystems()

    -- Connect player events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Handle players already in game
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    print("ServerSystemsHandler: Initialization complete")
end

-- Start the handler
init()

-- Export handler for external access
ServerSystemsHandler.getModule = function(moduleName)
    return loadedModules[moduleName]
end

ServerSystemsHandler.isInitialized = function()
    return systemsInitialized
end

return ServerSystemsHandler