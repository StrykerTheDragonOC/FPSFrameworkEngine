-- SystemErrorFixes.lua
-- Comprehensive fixes for FPS system errors and modernization
-- Place in ReplicatedStorage.FPSSystem.Modules

local SystemFixes = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Error tracking
local errorLog = {}
local fixApplied = {}

-- Modern system configuration
local MODERN_CONFIG = {
    -- Use Include/Exclude instead of deprecated Whitelist/Blacklist
    RAYCAST_FILTER_MODERNIZATION = true,

    -- Enhanced scope system instead of deprecated methods
    SCOPE_SYSTEM_V2 = true,

    -- Modern sound system
    SOUND_SYSTEM_V3 = true,

    -- Performance optimizations
    PERFORMANCE_MODE = true,

    -- Error recovery
    AUTO_ERROR_RECOVERY = true
}

-- Create missing essential folders and modules
function SystemFixes.ensureSystemStructure()
    print("[System Fixes] Ensuring proper FPS system structure...")

    -- Create main FPS system folder
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        fpsSystem = Instance.new("Folder")
        fpsSystem.Name = "FPSSystem"
        fpsSystem.Parent = ReplicatedStorage
        print("[System Fixes] Created FPSSystem folder")
    end

    -- Create essential subfolders
    local essentialFolders = {
        "Modules",
        "ViewModels", 
        "Weapons",
        "Attachments",
        "Effects",
        "Sounds",
        "Config"
    }

    for _, folderName in ipairs(essentialFolders) do
        local folder = fpsSystem:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = fpsSystem
            print("[System Fixes] Created", folderName, "folder")
        end
    end

    -- Create workspace effect folders
    local workspaceFolders = {
        "WeaponEffects",
        "GrenadeEffects", 
        "MeleeEffects",
        "MovementEffects"
    }

    for _, folderName in ipairs(workspaceFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = workspace
            print("[System Fixes] Created workspace", folderName, "folder")
        end
    end
end

-- Fix deprecated raycast filter methods
function SystemFixes.fixRaycastFilters()
    print("[System Fixes] Modernizing raycast filter methods...")

    -- Create modern raycast parameter generator
    local function createModernRaycastParams(includeList, excludeList, respectCanCollide)
        local params = RaycastParams.new()

        if includeList and #includeList > 0 then
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = includeList
        elseif excludeList and #excludeList > 0 then
            params.FilterType = Enum.RaycastFilterType.Exclude  
            params.FilterDescendantsInstances = excludeList
        else
            -- Default exclude player and effects
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {
                Players.LocalPlayer.Character,
                workspace:FindFirstChild("Effects"),
                workspace:FindFirstChild("WeaponEffects")
            }
        end

        params.RespectCanCollide = respectCanCollide ~= false
        return params
    end

    -- Export modern raycast function globally
    _G.ModernRaycast = function(origin, direction, includeList, excludeList, respectCanCollide)
        local params = createModernRaycastParams(includeList, excludeList, respectCanCollide)
        return workspace:Raycast(origin, direction, params)
    end

    print("[System Fixes] Modern raycast system available globally as _G.ModernRaycast")
end

-- Fix missing essential modules with stubs
function SystemFixes.createEssentialModuleStubs()
    print("[System Fixes] Creating essential module stubs...")

    local modulesFolder = ReplicatedStorage.FPSSystem.Modules

    -- Essential modules that might be missing
    local essentialModules = {
        "WeaponAttachmentIntegration",
        "EnhancedScopeSystem", 
        "MapGameModeSystem",
        "ServerAntiCheat",
        "StarterPlayerStarterPlayerScripts"
    }

    for _, moduleName in ipairs(essentialModules) do
        local module = modulesFolder:FindFirstChild(moduleName)
        if not module then
            module = Instance.new("ModuleScript")
            module.Name = moduleName
            module.Source = SystemFixes.generateModuleStub(moduleName)
            module.Parent = modulesFolder
            print("[System Fixes] Created stub for", moduleName)
        end
    end
end

-- Generate module stub source code
function SystemFixes.generateModuleStub(moduleName)
    if moduleName == "WeaponAttachmentIntegration" then
        return [[
-- WeaponAttachmentIntegration Stub
local Integration = {}

function Integration.attachToWeapon(weapon, attachment)
    print("Attachment integration:", attachment, "->", weapon)
    return true
end

function Integration.removeFromWeapon(weapon, attachment)
    print("Attachment removal:", attachment, "from", weapon)
    return true
end

return Integration
]]
    elseif moduleName == "EnhancedScopeSystem" then
        return [[
-- EnhancedScopeSystem Stub  
local ScopeSystem = {}

function ScopeSystem.createScope(scopeType, magnification)
    print("Scope created:", scopeType, "at", magnification .. "x")
    return {type = scopeType, zoom = magnification}
end

function ScopeSystem.enableScope(scope)
    print("Scope enabled:", scope.type)
end

function ScopeSystem.disableScope()
    print("Scope disabled")
end

return ScopeSystem
]]
    elseif moduleName == "MapGameModeSystem" then
        return [[
-- MapGameModeSystem Stub
local GameModeSystem = {}

function GameModeSystem.createSpawnPoints(mapName)
    print("Spawn points created for map:", mapName)
    return {}
end

function GameModeSystem.createDesertMap()
    print("Desert map created")
    return true
end

function GameModeSystem.createObjectives()
    print("Objectives created")
    return {}
end

return GameModeSystem
]]
    else
        return [[
-- Generated Module Stub for ]] .. moduleName .. [[

local Module = {}

function Module.init()
    print("]] .. moduleName .. [[ initialized")
    return true
end

function Module.cleanup()
    print("]] .. moduleName .. [[ cleaned up")
end

return Module
]]
    end
end

-- Fix server script service organization
function SystemFixes.fixServerScriptStructure()
    print("[System Fixes] Organizing server scripts...")

    -- Create server script service folder if needed
    local serverFolder = ServerScriptService:FindFirstChild("FPSSystem")
    if not serverFolder then
        serverFolder = Instance.new("Folder")
        serverFolder.Name = "FPSSystem"
        serverFolder.Parent = ServerScriptService
        print("[System Fixes] Created server FPSSystem folder")
    end

    -- Create essential server scripts
    local serverScripts = {
        "DamageHandler",
        "WeaponValidation", 
        "AntiCheat",
        "PlayerDataManager"
    }

    for _, scriptName in ipairs(serverScripts) do
        local script = serverFolder:FindFirstChild(scriptName)
        if not script then
            script = Instance.new("Script")
            script.Name = scriptName
            script.Source = SystemFixes.generateServerScript(scriptName)
            script.Parent = serverFolder
            print("[System Fixes] Created server script:", scriptName)
        end
    end
end

-- Generate server script templates
function SystemFixes.generateServerScript(scriptName)
    if scriptName == "DamageHandler" then
        return [[
-- DamageHandler Server Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Handle damage validation
local function handleDamage(player, targetPlayer, damage, weaponType, distance)
    -- Validate damage values
    if damage > 200 then damage = 200 end -- Max damage cap
    if damage < 0 then damage = 0 end
    
    -- Apply damage logic here
    print("Damage processed:", damage, "to", targetPlayer.Name, "by", player.Name)
end

-- Set up remote events for damage
local damageEvent = Instance.new("RemoteEvent")
damageEvent.Name = "DamageEvent"
damageEvent.Parent = ReplicatedStorage

damageEvent.OnServerEvent:Connect(handleDamage)
]]
    elseif scriptName == "AntiCheat" then
        return [[
-- Basic AntiCheat Server Script
local Players = game:GetService("Players")

local function validatePlayer(player)
    -- Basic validation checks
    if not player.Character then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    return true
end

-- Monitor player actions
Players.PlayerAdded:Connect(function(player)
    print("Player monitoring started for:", player.Name)
end)
]]
    else
        return [[
-- ]] .. scriptName .. [[ Server Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("]] .. scriptName .. [[ server script loaded")

-- Add your server logic here
]]
    end
end

-- Fix sound system modernization
function SystemFixes.modernizeSoundSystem()
    print("[System Fixes] Modernizing sound system...")

    -- Create modern sound manager
    local soundManager = {
        sounds = {},
        groups = {}
    }

    function soundManager:playSound(soundId, volume, position, rollOff)
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.8

        if position then
            -- 3D positioned sound
            sound.RollOffMode = rollOff or Enum.RollOffMode.InverseTapered
            sound.RollOffMinDistance = 10
            sound.RollOffMaxDistance = 100

            local soundPart = Instance.new("Part")
            soundPart.Transparency = 1
            soundPart.Anchored = true
            soundPart.CanCollide = false
            soundPart.Position = position
            soundPart.Parent = workspace

            sound.Parent = soundPart
            sound:Play()

            game:GetService("Debris"):AddItem(soundPart, sound.TimeLength + 1)
        else
            -- 2D sound
            sound.Parent = workspace.CurrentCamera
            sound:Play()

            game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.5)
        end

        return sound
    end

    -- Export globally
    _G.ModernSoundManager = soundManager
    print("[System Fixes] Modern sound system available as _G.ModernSoundManager")
end

-- Fix performance issues
function SystemFixes.applyPerformanceOptimizations()
    print("[System Fixes] Applying performance optimizations...")

    -- Optimize rendering
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = 80  -- Optimize FOV
    end

    -- Optimize physics
    workspace.Gravity = 196.2  -- Standard gravity

    -- Create performance monitor
    local performanceMonitor = {
        lastCheck = tick(),
        frameCount = 0,
        avgFPS = 60
    }

    local connection = RunService.Heartbeat:Connect(function()
        performanceMonitor.frameCount = performanceMonitor.frameCount + 1
        local currentTime = tick()

        if currentTime - performanceMonitor.lastCheck >= 1 then
            performanceMonitor.avgFPS = performanceMonitor.frameCount / (currentTime - performanceMonitor.lastCheck)
            performanceMonitor.frameCount = 0
            performanceMonitor.lastCheck = currentTime

            -- Warn about low FPS
            if performanceMonitor.avgFPS < 30 then
                warn("[Performance] Low FPS detected:", math.floor(performanceMonitor.avgFPS))
            end
        end
    end)

    _G.PerformanceMonitor = performanceMonitor
    print("[System Fixes] Performance monitor active")
end

-- Error recovery system
function SystemFixes.setupErrorRecovery()
    print("[System Fixes] Setting up error recovery system...")

    local errorRecovery = {
        maxRetries = 3,
        retryDelay = 2,
        failedSystems = {}
    }

    function errorRecovery:retrySystem(systemName, initFunction)
        local retries = self.failedSystems[systemName] or 0

        if retries >= self.maxRetries then
            warn("[Error Recovery] Max retries exceeded for:", systemName)
            return false
        end

        local success = pcall(initFunction)
        if success then
            self.failedSystems[systemName] = nil
            print("[Error Recovery] Successfully recovered:", systemName)
            return true
        else
            self.failedSystems[systemName] = retries + 1
            warn("[Error Recovery] Retry", retries + 1, "failed for:", systemName)

            -- Schedule another retry
            task.delay(self.retryDelay, function()
                self:retrySystem(systemName, initFunction)
            end)

            return false
        end
    end

    _G.ErrorRecovery = errorRecovery
    print("[Error Recovery] System ready")
end

-- Character connection fixes
function SystemFixes.fixCharacterConnections()
    print("[System Fixes] Fixing character connection issues...")

    local player = Players.LocalPlayer

    -- Ensure character exists
    local function waitForCharacter()
        if not player.Character then
            player.CharacterAdded:Wait()
        end
        return player.Character
    end

    -- Enhanced character ready check
    local function isCharacterReady(character)
        return character and 
            character:FindFirstChild("Humanoid") and
            character:FindFirstChild("HumanoidRootPart") and
            character.Parent == workspace
    end

    -- Character connection manager
    local characterManager = {
        character = nil,
        connections = {},
        onCharacterReady = {}
    }

    function characterManager:waitForReady()
        local character = waitForCharacter()

        -- Wait for all essential parts
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)

        if humanoid and rootPart then
            self.character = character

            -- Fire ready callbacks
            for _, callback in ipairs(self.onCharacterReady) do
                task.spawn(callback, character)
            end

            return character
        else
            warn("[Character Manager] Character parts not found, retrying...")
            task.wait(1)
            return self:waitForReady()
        end
    end

    function characterManager:onReady(callback)
        table.insert(self.onCharacterReady, callback)

        -- If character is already ready, call immediately
        if self.character and isCharacterReady(self.character) then
            task.spawn(callback, self.character)
        end
    end

    -- Handle respawning
    player.CharacterAdded:Connect(function(character)
        characterManager.character = nil
        characterManager:waitForReady()
    end)

    -- Initial setup
    if player.Character then
        characterManager:waitForReady()
    end

    _G.CharacterManager = characterManager
    print("[System Fixes] Character connection manager ready")
end

-- Apply all fixes
function SystemFixes.applyAllFixes()
    print("[System Fixes] Applying comprehensive system fixes...")

    -- Core structure fixes
    SystemFixes.ensureSystemStructure()

    -- Modernization fixes
    if MODERN_CONFIG.RAYCAST_FILTER_MODERNIZATION then
        SystemFixes.fixRaycastFilters()
    end

    if MODERN_CONFIG.SOUND_SYSTEM_V3 then
        SystemFixes.modernizeSoundSystem()
    end

    -- Module and script fixes
    SystemFixes.createEssentialModuleStubs()
    SystemFixes.fixServerScriptStructure()

    -- Performance and reliability
    if MODERN_CONFIG.PERFORMANCE_MODE then
        SystemFixes.applyPerformanceOptimizations()
    end

    if MODERN_CONFIG.AUTO_ERROR_RECOVERY then
        SystemFixes.setupErrorRecovery()
    end

    -- Character connection fixes
    SystemFixes.fixCharacterConnections()

    print("[System Fixes] All fixes applied successfully!")

    -- Set flag to prevent re-running
    _G.SystemFixesApplied = true
end

-- Cleanup function
function SystemFixes.cleanup()
    print("[System Fixes] Cleaning up system fixes...")

    -- Clear global references
    _G.ModernRaycast = nil
    _G.ModernSoundManager = nil
    _G.PerformanceMonitor = nil
    _G.ErrorRecovery = nil
    _G.CharacterManager = nil

    print("[System Fixes] Cleanup complete")
end

-- Auto-apply fixes if not already applied
if not _G.SystemFixesApplied then
    task.defer(function()
        SystemFixes.applyAllFixes()
    end)
end

return SystemFixes