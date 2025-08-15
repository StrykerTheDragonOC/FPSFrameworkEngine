-- SystemFixes.lua
-- Comprehensive fixes for FPS system errors and modernization
-- Place in ReplicatedStorage.FPSSystem.Modules.SystemFixes

local SystemFixes = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

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

-- Apply all essential fixes
function SystemFixes.applyAllFixes()
    print("[System Fixes] Applying comprehensive FPS system fixes...")

    SystemFixes.ensureSystemStructure()
    SystemFixes.fixRaycastFilters()
    SystemFixes.createEssentialModuleStubs()
    SystemFixes.modernizeSoundSystem()
    SystemFixes.fixServerScriptStructure()
    SystemFixes.applyPerformanceOptimizations()
    SystemFixes.setupErrorRecovery()

    print("[System Fixes] All fixes applied successfully!")
end

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
        "MovementEffects",
        "BulletHoles",
        "ShellCasings"
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

    -- Ensure ViewModels has Arms folder
    local viewModels = fpsSystem:FindFirstChild("ViewModels")
    if viewModels then
        local arms = viewModels:FindFirstChild("Arms")
        if not arms then
            arms = Instance.new("Folder")
            arms.Name = "Arms"
            arms.Parent = viewModels
            print("[System Fixes] Created Arms folder in ViewModels")
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
                workspace:FindFirstChild("WeaponEffects"),
                workspace:FindFirstChild("Effects"),
                workspace:FindFirstChild("Particles")
            }
        end

        params.RespectCanCollide = respectCanCollide ~= false
        return params
    end

    -- Export modern raycast function globally
    _G.ModernRaycast = function(origin, direction, maxDistance, includeList, excludeList, respectCanCollide)
        local params = createModernRaycastParams(includeList, excludeList, respectCanCollide)
        local rayDirection = direction.Unit * (maxDistance or 1000)
        return workspace:Raycast(origin, rayDirection, params)
    end

    print("[System Fixes] Modern raycast system available globally as _G.ModernRaycast")
end

-- Fix missing essential modules with stubs
function SystemFixes.createEssentialModuleStubs()
    print("[System Fixes] Creating essential module stubs...")

    local modulesFolder = ReplicatedStorage.FPSSystem.Modules

    -- Essential modules that might be missing
    local essentialModules = {
        "WeaponAttachmentSystem",
        "EnhancedScopeSystem", 
        "GameModeManager",
        "AdvancedMovementSystem",
        "CrosshairSystem",
        "AdvancedUISystem"
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
    if moduleName == "WeaponAttachmentSystem" then
        return [[
-- WeaponAttachmentSystem Stub
local AttachmentSystem = {}

function AttachmentSystem.new()
    local self = {}
    
    function self:attachToWeapon(weapon, attachment)
        print("Attachment system:", attachment, "attached to", weapon)
        return true
    end
    
    function self:removeFromWeapon(weapon, attachment)
        print("Attachment system:", attachment, "removed from", weapon)
        return true
    end
    
    function self:getAttachments(weapon)
        return {}
    end
    
    return self
end

return AttachmentSystem
]]
    elseif moduleName == "EnhancedScopeSystem" then
        return [[
-- EnhancedScopeSystem Stub  
local ScopeSystem = {}

function ScopeSystem.new()
    local self = {}
    
    function self:createScope(scopeType, magnification)
        print("Scope created:", scopeType, "at", magnification .. "x")
        return {type = scopeType, zoom = magnification}
    end
    
    function self:enableScope(scope)
        print("Scope enabled:", scope.type)
    end
    
    function self:disableScope()
        print("Scope disabled")
    end
    
    function self:toggleScopeType()
        print("Scope type toggled")
    end
    
    return self
end

return ScopeSystem
]]
    elseif moduleName == "GameModeManager" then
        return [[
-- GameModeManager Stub
local GameModeManager = {}

function GameModeManager.new()
    local self = {}
    
    self.currentMode = "Team Deathmatch"
    self.availableModes = {
        "Team Deathmatch",
        "King of the Hill", 
        "Kill Confirmed",
        "Capture The Flag",
        "Flare Domination",
        "Gun Game",
        "Duel",
        "Knife Fight"
    }
    
    function self:setGameMode(mode)
        self.currentMode = mode
        print("Game mode set to:", mode)
    end
    
    function self:getCurrentMode()
        return self.currentMode
    end
    
    function self:getAvailableModes()
        return self.availableModes
    end
    
    return self
end

return GameModeManager
]]
    elseif moduleName == "AdvancedMovementSystem" then
        return [[
-- AdvancedMovementSystem Stub
local MovementSystem = {}

function MovementSystem.new()
    local self = {}
    
    self.canSlide = true
    self.canDive = true
    self.canLedgeGrab = true
    
    function self:enableSliding()
        print("Sliding enabled")
    end
    
    function self:enableDolphinDive()
        print("Dolphin dive enabled")
    end
    
    function self:enableLedgeGrabbing()
        print("Ledge grabbing enabled")
    end
    
    function self:update(deltaTime)
        -- Movement update logic
    end
    
    return self
end

return MovementSystem
]]
    elseif moduleName == "CrosshairSystem" then
        return [[
-- CrosshairSystem Stub
local CrosshairSystem = {}

function CrosshairSystem.new()
    local self = {}
    
    function self:createCrosshair()
        print("Crosshair created")
        return true
    end
    
    function self:updateSpread(spreadAmount)
        print("Crosshair spread updated:", spreadAmount)
    end
    
    function self:showHitMarker()
        print("Hit marker shown")
    end
    
    return self
end

return CrosshairSystem
]]
    elseif moduleName == "AdvancedUISystem" then
        return [[
-- AdvancedUISystem Stub
local UISystem = {}

function UISystem.new()
    local self = {}
    
    function self:initialize()
        print("UI System initialized")
    end
    
    function self:createLoadoutMenu()
        print("Loadout menu created")
    end
    
    function self:updateAmmoDisplay(current, reserve)
        print("Ammo display updated:", current, "/", reserve)
    end
    
    function self:showKillFeed(killer, victim, weapon)
        print("Kill feed:", killer, "killed", victim, "with", weapon)
    end
    
    return self
end

return UISystem
]]
    else
        return [[
-- Generated Module Stub for ]] .. moduleName .. [[

local Module = {}

function Module.new()
    local self = {}
    
    function self:init()
        print("]] .. moduleName .. [[ initialized")
        return true
    end
    
    function self:cleanup()
        print("]] .. moduleName .. [[ cleaned up")
    end
    
    return self
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
        "PlayerDataManager",
        "GameModeServer"
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

-- Create RemoteEvents folder if needed
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Handle damage validation
local function handleDamage(player, targetPlayer, damage, weaponType, distance, hitPart)
    -- Validate damage values
    if damage > 200 then damage = 200 end -- Max damage cap
    if damage < 0 then damage = 0 end
    
    -- Distance falloff
    if distance > 1000 then
        damage = damage * 0.5
    end
    
    -- Headshot multiplier
    if hitPart and hitPart:lower():find("head") then
        damage = damage * 1.5
    end
    
    -- Apply damage logic here
    local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
    if targetHumanoid then
        targetHumanoid.Health = targetHumanoid.Health - damage
        print("Damage processed:", damage, "to", targetPlayer.Name, "by", player.Name)
    end
end

-- Set up remote events for damage
local damageEvent = Instance.new("RemoteEvent")
damageEvent.Name = "DamageEvent"
damageEvent.Parent = remoteEvents

damageEvent.OnServerEvent:Connect(handleDamage)
]]
    elseif scriptName == "AntiCheat" then
        return [[
-- Basic AntiCheat Server Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local playerData = {}

local function validatePlayer(player)
    -- Basic validation checks
    if not player.Character then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    return true
end

local function monitorPlayerActions(player)
    local data = playerData[player.UserId]
    if not data then return end
    
    -- Monitor for suspicious activity
    -- This is a basic example
end

-- Monitor player actions
Players.PlayerAdded:Connect(function(player)
    playerData[player.UserId] = {
        joinTime = tick(),
        warnings = 0
    }
    print("Player monitoring started for:", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
end)
]]
    elseif scriptName == "GameModeServer" then
        return [[
-- GameModeServer Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Game mode management
local currentGameMode = "Team Deathmatch"
local gameModeTimer = 1200 -- 20 minutes

local availableGameModes = {
    "Team Deathmatch",
    "King of the Hill",
    "Kill Confirmed", 
    "Capture The Flag",
    "Flare Domination",
    "Gun Game",
    "Duel",
    "Knife Fight"
}

local function changeGameMode()
    local randomIndex = math.random(1, #availableGameModes)
    currentGameMode = availableGameModes[randomIndex]
    
    print("Game mode changed to:", currentGameMode)
    
    -- Notify all players
    for _, player in pairs(Players:GetPlayers()) do
        -- Send game mode update to client
    end
end

-- Change game mode every 20 minutes
spawn(function()
    while true do
        wait(gameModeTimer)
        changeGameMode()
    end
end)

print("GameModeServer loaded - Current mode:", currentGameMode)
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
        groups = {},
        volume = {
            master = 0.8,
            weapon = 0.7,
            effect = 0.6,
            ambient = 0.4,
            ui = 0.5
        }
    }

    function soundManager:playSound(soundId, volume, position, rollOff)
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = (volume or 0.8) * self.volume.master

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

    function soundManager:setVolume(category, volume)
        self.volume[category] = math.clamp(volume, 0, 1)
        SoundService.MasterVolume = self.volume.master
    end

    -- Export globally
    _G.ModernSoundManager = soundManager
    _G.MainVolume = soundManager.volume -- For compatibility

    print("[System Fixes] Modern sound system available as _G.ModernSoundManager")
end

-- Apply performance optimizations
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

            -- Adjust quality based on performance
            if performanceMonitor.avgFPS < 30 then
                -- Reduce quality for better performance
                workspace.StreamingEnabled = true
            end
        end
    end)

    _G.PerformanceMonitor = performanceMonitor
    print("[System Fixes] Performance optimizations applied")
end

-- Setup error recovery system
function SystemFixes.setupErrorRecovery()
    print("[System Fixes] Setting up error recovery system...")

    local errorRecovery = {
        errorCount = 0,
        maxErrors = 10,
        recoveryAttempts = 0
    }

    function errorRecovery:logError(errorMessage, source)
        self.errorCount = self.errorCount + 1
        table.insert(errorLog, {
            message = errorMessage,
            source = source,
            time = tick()
        })

        warn("[Error Recovery] Error logged:", errorMessage, "from", source)

        if self.errorCount > self.maxErrors then
            warn("[Error Recovery] Too many errors, attempting recovery...")
            self:attemptRecovery()
        end
    end

    function errorRecovery:attemptRecovery()
        self.recoveryAttempts = self.recoveryAttempts + 1

        if self.recoveryAttempts > 3 then
            warn("[Error Recovery] Maximum recovery attempts reached")
            return
        end

        -- Attempt to reinitialize systems
        pcall(function()
            SystemFixes.applyAllFixes()
        end)

        self.errorCount = 0
    end

    _G.ErrorRecovery = errorRecovery
    print("[System Fixes] Error recovery system setup complete")
end

-- Initialize default weapons configuration
function SystemFixes.createDefaultWeaponConfig()
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then return end

    local configFolder = fpsSystem:FindFirstChild("Config")
    if not configFolder then return end

    local weaponConfig = configFolder:FindFirstChild("WeaponConfig")
    if not weaponConfig then
        weaponConfig = Instance.new("ModuleScript")
        weaponConfig.Name = "WeaponConfig"
        weaponConfig.Parent = configFolder
        weaponConfig.Source = [[
-- Default Weapon Configuration
local WeaponConfig = {
    -- Default loadout as specified: G36, M9, PocketKnife, M67
    DEFAULT_LOADOUT = {
        PRIMARY = "G36",
        SECONDARY = "M9", 
        MELEE = "PocketKnife",
        GRENADE = "M67"
    },

    -- Weapon categories
    WEAPON_CATEGORIES = {
        ASSAULT_RIFLE = "AssaultRifle",
        SMG = "SMG",
        SNIPER = "Sniper",
        LMG = "LMG",
        SHOTGUN = "Shotgun",
        PISTOL = "Pistol",
        MELEE = "Melee",
        GRENADE = "Grenade"
    },

    -- Weapon definitions
    WEAPONS = {
        -- Primary Weapons
        G36 = {
            name = "G36",
            category = "AssaultRifle",
            damage = 35,
            range = 800,
            fireRate = 750,
            magazineSize = 30,
            reserveAmmo = 120,
            unlockLevel = 1
        },

        -- Secondary Weapons  
        M9 = {
            name = "M9",
            category = "Pistol",
            damage = 45,
            range = 300,
            fireRate = 400,
            magazineSize = 15,
            reserveAmmo = 60,
            unlockLevel = 1
        },

        -- Melee Weapons
        PocketKnife = {
            name = "PocketKnife", 
            category = "Melee",
            damage = 75,
            range = 5,
            unlockLevel = 1
        },

        -- Grenades
        M67 = {
            name = "M67",
            category = "Grenade",
            damage = 150,
            explosionRadius = 15,
            cookTime = 4,
            unlockLevel = 1
        }
    },

    -- Ammo conversion types for shotguns
    AMMO_TYPES = {
        SHOTGUN = {
            "Birdshot",    -- Standard pellets
            "Flechette",   -- Armor piercing
            "Rubber",      -- Non-lethal
            "Slugs"        -- Single projectile
        }
    },

    -- Attachment categories
    ATTACHMENTS = {
        OPTICS = {"Iron Sights", "Red Dot", "Holographic", "ACOG", "Sniper Scope"},
        BARREL = {"Suppressor", "Compensator", "Flash Hider", "Extended Barrel"},
        UNDERBARREL = {"Foregrip", "Bipod", "Laser", "Flashlight"},
        STOCK = {"Standard", "Heavy", "Light", "Adjustable"}
    }
}

return WeaponConfig
]]
        print("[System Fixes] Created default weapon configuration")
    end
end

-- Create FPS system initialization script
function SystemFixes.createInitializationScript()
    local starterPlayerScripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    if not starterPlayerScripts then return end

    local initScript = starterPlayerScripts:FindFirstChild("FPSSystemInitializer")
    if not initScript then
        initScript = Instance.new("LocalScript")
        initScript.Name = "FPSSystemInitializer"
        initScript.Parent = starterPlayerScripts
        initScript.Source = [[
-- FPSSystemInitializer.client.lua
-- Main initialization script for the FPS system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for FPS system to be available
local fpsSystem = ReplicatedStorage:WaitForChild("FPSSystem")
local modules = fpsSystem:WaitForChild("Modules")

-- Load system fixes first
local systemFixes = modules:WaitForChild("SystemFixes")
local SystemFixes = require(systemFixes)

-- Apply all fixes
SystemFixes.applyAllFixes()

-- Initialize core systems
print("[FPS Init] Initializing FPS systems...")

-- Load and initialize viewmodel client
local viewmodelClient = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("ViewmodelClient")
if viewmodelClient then
    require(viewmodelClient)
end

print("[FPS Init] FPS system initialization complete")
]]
        print("[System Fixes] Created FPS initialization script")
    end
end

-- Fix team setup for KFC vs FBI
function SystemFixes.setupTeams()
    local Teams = game:GetService("Teams")

    -- Create KFC team
    local kfcTeam = Teams:FindFirstChild("KFC")
    if not kfcTeam then
        kfcTeam = Instance.new("Team")
        kfcTeam.Name = "KFC"
        kfcTeam.TeamColor = BrickColor.new("Bright red")
        kfcTeam.AutoAssignable = true
        kfcTeam.Parent = Teams
        print("[System Fixes] Created KFC team")
    end

    -- Create FBI team
    local fbiTeam = Teams:FindFirstChild("FBI")
    if not fbiTeam then
        fbiTeam = Instance.new("Team")
        fbiTeam.Name = "FBI"
        fbiTeam.TeamColor = BrickColor.new("Bright blue")
        fbiTeam.AutoAssignable = true
        fbiTeam.Parent = Teams
        print("[System Fixes] Created FBI team")
    end
end

-- Create spawn points for teams
function SystemFixes.createSpawnPoints()
    local kfcSpawns = workspace:FindFirstChild("KFCSpawns")
    if not kfcSpawns then
        kfcSpawns = Instance.new("Folder")
        kfcSpawns.Name = "KFCSpawns"
        kfcSpawns.Parent = workspace

        -- Create example KFC spawn point
        local spawn1 = Instance.new("SpawnLocation")
        spawn1.Name = "KFCSpawn1"
        spawn1.TeamColor = BrickColor.new("Bright red")
        spawn1.Position = Vector3.new(0, 10, 0) -- Adjust position as needed
        spawn1.Parent = kfcSpawns

        print("[System Fixes] Created KFC spawn points")
    end

    local fbiSpawns = workspace:FindFirstChild("FBISpawns")
    if not fbiSpawns then
        fbiSpawns = Instance.new("Folder")
        fbiSpawns.Name = "FBISpawns"
        fbiSpawns.Parent = workspace

        -- Create example FBI spawn point
        local spawn1 = Instance.new("SpawnLocation")
        spawn1.Name = "FBISpawn1"
        spawn1.TeamColor = BrickColor.new("Bright blue")
        spawn1.Position = Vector3.new(100, 10, 0) -- Adjust position as needed
        spawn1.Parent = fbiSpawns

        print("[System Fixes] Created FBI spawn points")
    end
end

-- Initialize all fixes when module is loaded
function SystemFixes.init()
    print("[System Fixes] Initializing comprehensive FPS system fixes...")

    SystemFixes.applyAllFixes()
    SystemFixes.createDefaultWeaponConfig()
    SystemFixes.createInitializationScript()
    SystemFixes.setupTeams()
    SystemFixes.createSpawnPoints()

    print("[System Fixes] FPS system fixes initialization complete!")
end

-- Auto-run fixes if this is being required
if not _G.SystemFixesLoaded then
    _G.SystemFixesLoaded = true
    SystemFixes.init()
end

return SystemFixes