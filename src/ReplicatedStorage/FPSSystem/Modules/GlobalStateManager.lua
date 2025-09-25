-- GlobalStateManager
-- Centralized state management to replace _G usage
-- Provides a clean, organized way to share data between modules

local GlobalStateManager = {}
GlobalStateManager.__index = GlobalStateManager

-- Private state storage
local globalState = {}
local listeners = {}

-- Initialize the global state manager
function GlobalStateManager:Initialize()
    -- Initialize default state
    globalState = {
        -- Core Systems
        DataStoreManager = nil,
        TeamManager = nil,
        GameConfig = nil,
        HealthSystem = nil,
        WeaponSystem = nil,
        AmmoHandler = nil,
        MovementSystem = nil,
        
        -- Game State
        GameSettings = {
            Sensitivity = 0.5,
            RagdollForce = 0.3,
            FOV = 0.7,
            Volume = 0.8,
            RagdollsEnabled = true,
            BloodEffects = true,
            MuzzleFlash = true,
            BulletTracers = true,
            AutoReload = true,
            DamageNumbers = true
        },
        
        -- Handlers
        SpottingHandler = nil,
        GrenadeHandler = nil,
        AttachmentHandler = nil,
        ClassHandler = nil,
        GamemodeManager = nil,
        TeamSpawnSystem = nil,
        DeployHandler = nil,
        ShopHandler = nil,
        MeleeHandler = nil,
        DayNightHandler = nil,
        PickupHandler = nil,
        KillStreakManager = nil,
        
        -- Client Systems
        ClientSystems = nil,
        SystemEvents = nil,
        HUDController = nil,
        RagdollSystem = nil,
        
        -- Debug
        ClientDebug = nil,
        
        -- Input Events
        onInputBegan = nil,
        onInputEnded = nil,
        onFire = nil
    }
    
    print("GlobalStateManager: Initialized")
end

-- Get a value from global state
function GlobalStateManager:Get(key)
    return globalState[key]
end

-- Set a value in global state
function GlobalStateManager:Set(key, value)
    local oldValue = globalState[key]
    globalState[key] = value
    
    -- Notify listeners
    if listeners[key] then
        for _, callback in pairs(listeners[key]) do
            spawn(function()
                callback(value, oldValue)
            end)
        end
    end
    
    return value
end

-- Update a nested value (e.g., GameSettings.Sensitivity)
function GlobalStateManager:Update(path, value)
    local keys = {}
    for key in path:gmatch("[^%.]+") do
        table.insert(keys, key)
    end
    
    local current = globalState
    for i = 1, #keys - 1 do
        if not current[keys[i]] then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    local oldValue = current[keys[#keys]]
    current[keys[#keys]] = value
    
    -- Notify listeners for the full path
    if listeners[path] then
        for _, callback in pairs(listeners[path]) do
            spawn(function()
                callback(value, oldValue)
            end)
        end
    end
    
    return value
end

-- Get a nested value
function GlobalStateManager:GetNested(path)
    local current = globalState
    for key in path:gmatch("[^%.]+") do
        if current and current[key] then
            current = current[key]
        else
            return nil
        end
    end
    return current
end

-- Listen for changes to a key
function GlobalStateManager:Listen(key, callback)
    if not listeners[key] then
        listeners[key] = {}
    end
    table.insert(listeners[key], callback)
end

-- Remove a listener
function GlobalStateManager:Unlisten(key, callback)
    if listeners[key] then
        for i, listener in pairs(listeners[key]) do
            if listener == callback then
                table.remove(listeners[key], i)
                break
            end
        end
    end
end

-- Get all data (for debugging)
function GlobalStateManager:GetAll()
    return globalState
end

-- Clear all data (for cleanup)
function GlobalStateManager:Clear()
    globalState = {}
    listeners = {}
end

return GlobalStateManager
