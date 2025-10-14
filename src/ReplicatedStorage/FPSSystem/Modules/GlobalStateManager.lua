-- GlobalStateManager
-- Centralized state management to replace _G usage
-- Provides a clean, organized way to share data between modules
--!nocheck
local GlobalStateManager = {}
GlobalStateManager.__index = GlobalStateManager

-- Private state storage
local globalState = {}
local listeners = {}

-- Initialize the global state manager
function GlobalStateManager:Initialize()
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
        onFire = nil,

        -- Player States
        PlayerStates = {}
    }

    print("? GlobalStateManager: Initialized")
end

-- Initialize player state
function GlobalStateManager:InitializePlayerState(player)
    if not globalState.PlayerStates then
        globalState.PlayerStates = {}
    end

    local userId = player.UserId

    if not globalState.PlayerStates[userId] then
        globalState.PlayerStates[userId] = {
            Player = player,
            IsAiming = false,
            IsMoving = false,
            IsSprinting = false,
            IsCrouching = false,
            IsProne = false,
            ConsecutiveShots = 0,
            LastShotTime = 0,
            CurrentWeapon = nil,
            Velocity = Vector3.new(0, 0, 0),
            LastPosition = nil
        }
    end

    return globalState.PlayerStates[userId]
end

-- Get player state
function GlobalStateManager:GetPlayerState(player)
    if not globalState.PlayerStates then
        globalState.PlayerStates = {}
    end

    local userId = type(player) == "number" and player or player.UserId
    return globalState.PlayerStates[userId]
end

-- Update player state
function GlobalStateManager:UpdatePlayerState(player, key, value)
    if not globalState.PlayerStates then
        globalState.PlayerStates = {}
    end

    local userId = type(player) == "number" and player or player.UserId
    if not globalState.PlayerStates[userId] then
        warn("?? Player state not initialized for userId:", userId)
        return false
    end

    local oldValue = globalState.PlayerStates[userId][key]
    globalState.PlayerStates[userId][key] = value

    -- Notify listeners
    local listenerKey = "PlayerState." .. userId .. "." .. key
    if listeners[listenerKey] then
        for _, callback in pairs(listeners[listenerKey]) do
            task.spawn(function()
                callback(value, oldValue, player)
            end)
        end
    end

    return true
end

-- Remove player state on disconnect
function GlobalStateManager:RemovePlayerState(player)
    if not globalState.PlayerStates then return end
    local userId = type(player) == "number" and player or player.UserId
    globalState.PlayerStates[userId] = nil
end

-- Get a value from global state
function GlobalStateManager:Get(key)
    return globalState[key]
end

-- Set a value in global state
function GlobalStateManager:Set(key, value)
    local oldValue = globalState[key]
    globalState[key] = value

    if listeners[key] then
        for _, callback in pairs(listeners[key]) do
            task.spawn(function()
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

    if listeners[path] then
        for _, callback in pairs(listeners[path]) do
            task.spawn(function()
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

-- Listen for changes
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

-- Debug: Get all state
function GlobalStateManager:GetAll()
    return globalState
end

-- Clear all data
function GlobalStateManager:Clear()
    globalState = {}
    listeners = {}
end

return GlobalStateManager
