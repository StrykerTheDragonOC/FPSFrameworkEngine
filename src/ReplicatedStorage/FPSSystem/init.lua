-- FPSSystem init.lua  
-- Main initialization script for the FPS system
-- Creates all necessary folders and files for the system
-- Place in ReplicatedStorage/FPSSystem/init.lua

local FPSSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

-- Create all necessary folders and structure
function FPSSystem:createFolderStructure()
    print("FPSSystem: Creating folder structure...")
    
    -- Create RemoteEvents folder
    local remoteEvents = script:FindFirstChild("RemoteEvents") or Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = script
    
    -- Create essential remote events
    local remoteEventsList = {
        "ScoreUpdate", "PlayerStatsUpdate", "GameModeUpdate", "WeaponFired",
        "WeaponReload", "PlayerDamaged", "PlayerKilled", "LoadoutChanged"
    }
    
    for _, eventName in pairs(remoteEventsList) do
        if not remoteEvents:FindFirstChild(eventName) then
            local remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = remoteEvents
        end
    end
    
    -- Create Config folder
    local configFolder = script:FindFirstChild("Config") or Instance.new("Folder")
    configFolder.Name = "Config"
    configFolder.Parent = script
    
    -- Create Modules folder  
    local modulesFolder = script:FindFirstChild("Modules") or Instance.new("Folder")
    modulesFolder.Name = "Modules"
    modulesFolder.Parent = script
    
    print("FPSSystem: Folder structure created!")
end

-- Module references (with safe loading)
local function safeRequire(module)
    local success, result = pcall(require, module)
    if success then
        return result
    else
        warn("FPSSystem: Could not load module:", module.Name)
        return nil
    end
end

local UnifiedWeaponConfig = script.Config:FindFirstChild("UnifiedWeaponConfig") and safeRequire(script.Config.UnifiedWeaponConfig)
local ConfigMigrationHandler = script.Modules:FindFirstChild("ConfigMigrationHandler") and safeRequire(script.Modules.ConfigMigrationHandler)

-- System state
FPSSystem.Initialized = false
FPSSystem.Version = "5.0.0"

-- Initialize the FPS system
function FPSSystem:init()
    if self.Initialized then
        warn("FPSSystem: Already initialized!")
        return
    end
    
    print("FPSSystem: Initializing version", self.Version)
    
    -- Create folder structure first
    self:createFolderStructure()
    
    -- Create missing weapon config if not exists
    self:createMissingConfigs()
    
    -- Initialize unified weapon config system
    print("FPSSystem: Loading unified weapon configurations...")
    
    -- Setup migration handler for backwards compatibility (if available)
    print("FPSSystem: Setting up migration compatibility layer...")
    if ConfigMigrationHandler then
        ConfigMigrationHandler:init()
    end
    
    -- Initialize sound system if available
    local AdvancedSoundSystem = script.Modules:FindFirstChild("AdvancedSoundSystem")
    if AdvancedSoundSystem then
        local soundSystem = safeRequire(AdvancedSoundSystem)
        if soundSystem then
            if RunService:IsClient() then
                if soundSystem.init then soundSystem.init() end
            else
                if soundSystem.initServer then soundSystem.initServer() end
            end
            print("FPSSystem: Sound system initialized")
        end
    end
    
    -- Expose main APIs
    self:setupAPIs()
    
    self.Initialized = true
    print("FPSSystem: Initialization complete!")
end

-- Create missing configuration files
function FPSSystem:createMissingConfigs()
    print("FPSSystem: Creating missing configuration files...")
    
    -- Create WeaponConfig if missing
    if not script.Modules:FindFirstChild("WeaponConfig") then
        self:createWeaponConfigModule()
    end
    
    -- Create other missing modules
    if not script.Config:FindFirstChild("UnifiedWeaponConfig") then
        self:createUnifiedWeaponConfig()
    end
end

-- Create basic WeaponConfig module
function FPSSystem:createWeaponConfigModule()
    local weaponConfigScript = Instance.new("ModuleScript")
    weaponConfigScript.Name = "WeaponConfig"
    weaponConfigScript.Parent = script.Modules
    
    weaponConfigScript.Source = [[
-- WeaponConfig.lua
-- Basic weapon configuration system
-- Legacy compatibility module

local WeaponConfig = {}

-- Default weapon configurations
WeaponConfig.Weapons = {
    ["M4A1"] = {
        Name = "M4A1",
        Damage = 30,
        Range = 200,
        Recoil = 2,
        FireRate = 650,
        MagSize = 30,
        ReloadTime = 2.5,
        Category = "Primary"
    },
    ["AK47"] = {
        Name = "AK47", 
        Damage = 35,
        Range = 180,
        Recoil = 4,
        FireRate = 600,
        MagSize = 30,
        ReloadTime = 2.8,
        Category = "Primary"
    },
    ["Glock17"] = {
        Name = "Glock17",
        Damage = 25,
        Range = 50,
        Recoil = 1,
        FireRate = 400,
        MagSize = 17,
        ReloadTime = 1.5,
        Category = "Secondary"
    }
}

function WeaponConfig:getWeapon(weaponName)
    return self.Weapons[weaponName]
end

function WeaponConfig:getAllWeapons()
    return self.Weapons
end

return WeaponConfig
]]
    
    print("FPSSystem: Created basic WeaponConfig module")
end

-- Create UnifiedWeaponConfig
function FPSSystem:createUnifiedWeaponConfig()
    local unifiedConfigScript = Instance.new("ModuleScript")
    unifiedConfigScript.Name = "UnifiedWeaponConfig"
    unifiedConfigScript.Parent = script.Config
    
    unifiedConfigScript.Source = [[
-- UnifiedWeaponConfig.lua
-- Unified weapon and attachment configuration system

local UnifiedWeaponConfig = {}

-- Weapon configurations
UnifiedWeaponConfig.Weapons = {
    ["M4A1"] = {
        Name = "M4A1",
        DisplayName = "M4A1 Carbine",
        Damage = 30,
        Range = 200,
        Recoil = 2,
        FireRate = 650,
        MagSize = 30,
        ReloadTime = 2.5,
        Category = "Primary",
        UnlockLevel = 1,
        Attachments = {"RedDot", "Suppressor", "ExtendedMag"}
    },
    ["AK47"] = {
        Name = "AK47",
        DisplayName = "AK-47",
        Damage = 35,
        Range = 180,
        Recoil = 4,
        FireRate = 600,
        MagSize = 30,
        ReloadTime = 2.8,
        Category = "Primary",
        UnlockLevel = 5,
        Attachments = {"RedDot", "Compensator", "ExtendedMag"}
    },
    ["Glock17"] = {
        Name = "Glock17",
        DisplayName = "Glock 17",
        Damage = 25,
        Range = 50,
        Recoil = 1,
        FireRate = 400,
        MagSize = 17,
        ReloadTime = 1.5,
        Category = "Secondary",
        UnlockLevel = 1,
        Attachments = {"LaserSight", "ExtendedMag"}
    }
}

-- Attachment configurations
UnifiedWeaponConfig.Attachments = {
    ["RedDot"] = {
        Name = "RedDot",
        DisplayName = "Red Dot Sight",
        Type = "Optic",
        UnlockLevel = 2,
        Effects = {AimSpeed = 0.1, Accuracy = 0.05}
    },
    ["Suppressor"] = {
        Name = "Suppressor",
        DisplayName = "Sound Suppressor",
        Type = "Barrel",
        UnlockLevel = 8,
        Effects = {Damage = -0.1, Range = 0.15, Sound = -0.8}
    },
    ["ExtendedMag"] = {
        Name = "ExtendedMag",
        DisplayName = "Extended Magazine",
        Type = "Magazine",
        UnlockLevel = 4,
        Effects = {MagSize = 10, ReloadTime = 0.3}
    }
}

function UnifiedWeaponConfig:getWeaponConfig(weaponName)
    return self.Weapons[weaponName]
end

function UnifiedWeaponConfig:getAttachmentConfig(attachmentName)
    return self.Attachments[attachmentName]
end

function UnifiedWeaponConfig:getWeaponsByCategory(category)
    local weapons = {}
    for name, weapon in pairs(self.Weapons) do
        if weapon.Category == category then
            weapons[name] = weapon
        end
    end
    return weapons
end

function UnifiedWeaponConfig:isAttachmentCompatible(weaponName, attachmentName)
    local weapon = self:getWeaponConfig(weaponName)
    if not weapon or not weapon.Attachments then return false end
    
    for _, compatibleAttachment in pairs(weapon.Attachments) do
        if compatibleAttachment == attachmentName then
            return true
        end
    end
    return false
end

return UnifiedWeaponConfig
]]
    
    print("FPSSystem: Created UnifiedWeaponConfig module")
end

-- Setup public APIs
function FPSSystem:setupAPIs()
    -- Reload configs after creation
    UnifiedWeaponConfig = script.Config:FindFirstChild("UnifiedWeaponConfig") and safeRequire(script.Config.UnifiedWeaponConfig)
    
    -- Main weapon configuration API
    FPSSystem.WeaponConfig = UnifiedWeaponConfig
    
    -- Legacy compatibility APIs
    FPSSystem.Migration = ConfigMigrationHandler
    
    -- Utility functions
    FPSSystem.getWeapon = function(weaponName)
        if UnifiedWeaponConfig then
            return UnifiedWeaponConfig:getWeaponConfig(weaponName)
        end
        return nil
    end
    
    FPSSystem.getAttachment = function(attachmentName)
        if UnifiedWeaponConfig then
            return UnifiedWeaponConfig:getAttachmentConfig(attachmentName)
        end
        return nil
    end
    
    FPSSystem.getWeaponsByCategory = function(category)
        if UnifiedWeaponConfig then
            return UnifiedWeaponConfig:getWeaponsByCategory(category)
        end
        return {}
    end
    
    FPSSystem.isAttachmentCompatible = function(weaponName, attachmentName)
        if UnifiedWeaponConfig then
            return UnifiedWeaponConfig:isAttachmentCompatible(weaponName, attachmentName)
        end
        return false
    end
    
    print("FPSSystem: APIs configured")
end

-- Get system status
function FPSSystem:getStatus()
    return {
        initialized = self.Initialized,
        version = self.Version,
        weaponCount = self:getWeaponCount(),
        attachmentCount = self:getAttachmentCount()
    }
end

-- Get weapon count
function FPSSystem:getWeaponCount()
    if not UnifiedWeaponConfig or not UnifiedWeaponConfig.Weapons then
        return 0
    end
    local count = 0
    for _ in pairs(UnifiedWeaponConfig.Weapons) do
        count = count + 1
    end
    return count
end

-- Get attachment count  
function FPSSystem:getAttachmentCount()
    if not UnifiedWeaponConfig or not UnifiedWeaponConfig.Attachments then
        return 0
    end
    local count = 0
    for _ in pairs(UnifiedWeaponConfig.Attachments) do
        count = count + 1
    end
    return count
end

-- Auto-initialize on client and server
task.spawn(function()
    task.wait(1) -- Brief delay to ensure all modules are loaded
    FPSSystem:init()
    
    -- Print system status
    local status = FPSSystem:getStatus()
    print(string.format(
        "FPSSystem: Ready! Version %s with %d weapons and %d attachments", 
        status.version, 
        status.weaponCount, 
        status.attachmentCount
    ))
end)

return FPSSystem