-- ConfigMigrationHandler.lua
-- Handles migration from old weapon configs to UnifiedWeaponConfig
-- Place in ReplicatedStorage/FPSSystem/Modules/ConfigMigrationHandler.lua

local ConfigMigrationHandler = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the new unified config
local UnifiedWeaponConfig = require(ReplicatedStorage.FPSSystem.Config.UnifiedWeaponConfig)

-- Migration mappings for old systems
local WEAPON_NAME_MAPPINGS = {
    -- Handle any weapon name differences between old and new systems
    ["PocketKnife"] = "Knife",
    ["FragGrenade"] = "M67 Frag",
    ["M67"] = "M67 Frag",
    ["NTW20"] = "NTW-20",
    ["NTW20_Chaos"] = "NTW-20" -- Map chaos variant to standard for now
}

-- Legacy compatibility layer
function ConfigMigrationHandler:getWeaponConfig(weaponName)
    -- Handle weapon name mapping
    local mappedName = WEAPON_NAME_MAPPINGS[weaponName] or weaponName
    
    -- Get from unified config
    local config = UnifiedWeaponConfig:getWeaponConfig(mappedName)
    if config then
        return self:convertToLegacyFormat(config)
    end
    
    warn("ConfigMigrationHandler: Weapon not found:", weaponName)
    return nil
end

-- Convert unified config to legacy format for backwards compatibility
function ConfigMigrationHandler:convertToLegacyFormat(unifiedConfig)
    local legacyConfig = {}
    
    -- Copy all base properties
    for key, value in pairs(unifiedConfig) do
        legacyConfig[key] = value
    end
    
    -- Handle specific legacy format requirements
    if unifiedConfig.damage and unifiedConfig.damage.base then
        legacyConfig.damage = unifiedConfig.damage.base -- Legacy systems expect single damage value
        legacyConfig.damageRanges = unifiedConfig.damage.ranges
        legacyConfig.headshotMultiplier = unifiedConfig.damage.headshotMultiplier
    end
    
    if unifiedConfig.fireRate then
        legacyConfig.firerate = unifiedConfig.fireRate -- Legacy naming
    end
    
    -- Ensure compatibility with old sound system
    if unifiedConfig.sounds then
        legacyConfig.sounds = {}
        for soundType, soundId in pairs(unifiedConfig.sounds) do
            legacyConfig.sounds[soundType] = soundId
        end
    end
    
    return legacyConfig
end

-- Get attachment config with legacy compatibility
function ConfigMigrationHandler:getAttachmentConfig(attachmentName)
    return UnifiedWeaponConfig:getAttachmentConfig(attachmentName)
end

-- Apply attachment to weapon with legacy support
function ConfigMigrationHandler:applyAttachment(weaponConfig, attachmentName)
    return UnifiedWeaponConfig:applyAttachment(weaponConfig, attachmentName)
end

-- Check attachment compatibility
function ConfigMigrationHandler:isAttachmentCompatible(weaponName, attachmentName)
    local mappedName = WEAPON_NAME_MAPPINGS[weaponName] or weaponName
    return UnifiedWeaponConfig:isAttachmentCompatible(mappedName, attachmentName)
end

-- Get compatible attachments for weapon
function ConfigMigrationHandler:getCompatibleAttachments(weaponName)
    local mappedName = WEAPON_NAME_MAPPINGS[weaponName] or weaponName
    return UnifiedWeaponConfig:getCompatibleAttachments(mappedName)
end

-- Get weapons by category
function ConfigMigrationHandler:getWeaponsByCategory(category)
    return UnifiedWeaponConfig:getWeaponsByCategory(category)
end

-- Legacy WeaponConfig compatibility functions
function ConfigMigrationHandler.getWeapon(weaponName)
    return ConfigMigrationHandler:getWeaponConfig(weaponName)
end

function ConfigMigrationHandler.getAttachment(attachmentName)
    return ConfigMigrationHandler:getAttachmentConfig(attachmentName)
end

-- Legacy WeaponConfigManager compatibility
ConfigMigrationHandler.Weapons = setmetatable({}, {
    __index = function(self, weaponName)
        return ConfigMigrationHandler:getWeaponConfig(weaponName)
    end
})

ConfigMigrationHandler.Attachments = setmetatable({}, {
    __index = function(self, attachmentName)
        return ConfigMigrationHandler:getAttachmentConfig(attachmentName)
    end
})

-- Create compatibility globals for old systems
function ConfigMigrationHandler:setupGlobalCompatibility()
    -- Set up WeaponConfig compatibility
    _G.WeaponConfig = {
        getWeapon = ConfigMigrationHandler.getWeapon,
        getAttachment = ConfigMigrationHandler.getAttachment,
        Weapons = ConfigMigrationHandler.Weapons,
        Attachments = ConfigMigrationHandler.Attachments,
        Categories = UnifiedWeaponConfig.Categories,
        Types = UnifiedWeaponConfig.Types,
        FiringModes = UnifiedWeaponConfig.FiringModes
    }
    
    -- Set up WeaponConfigManager compatibility  
    _G.WeaponConfigManager = {
        getWeaponConfig = function(self, weaponName)
            return ConfigMigrationHandler:getWeaponConfig(weaponName)
        end,
        getAttachmentConfig = function(self, attachmentName)
            return ConfigMigrationHandler:getAttachmentConfig(attachmentName)
        end,
        applyAttachment = function(self, weaponConfig, attachmentName)
            return ConfigMigrationHandler:applyAttachment(weaponConfig, attachmentName)
        end,
        isAttachmentCompatible = function(self, weaponName, attachmentName)
            return ConfigMigrationHandler:isAttachmentCompatible(weaponName, attachmentName)
        end,
        getCompatibleAttachments = function(self, weaponName)
            return ConfigMigrationHandler:getCompatibleAttachments(weaponName)
        end,
        Weapons = ConfigMigrationHandler.Weapons,
        Attachments = ConfigMigrationHandler.Attachments
    }
    
    print("ConfigMigrationHandler: Global compatibility layer established")
end

-- Initialize migration system
function ConfigMigrationHandler:init()
    print("ConfigMigrationHandler: Initializing weapon config migration...")
    
    -- Setup global compatibility
    self:setupGlobalCompatibility()
    
    -- Validate migration
    self:validateMigration()
    
    print("ConfigMigrationHandler: Migration complete!")
end

-- Validate that migration is working correctly
function ConfigMigrationHandler:validateMigration()
    local testWeapons = {"G36", "M4A1", "AWP", "M9", "Knife"}
    local passCount = 0
    
    for _, weaponName in ipairs(testWeapons) do
        local config = self:getWeaponConfig(weaponName)
        if config then
            passCount = passCount + 1
            print("✓ Migration validated for:", weaponName)
        else
            warn("✗ Migration failed for:", weaponName)
        end
    end
    
    print(string.format("ConfigMigrationHandler: Validation complete (%d/%d passed)", passCount, #testWeapons))
end

-- Cleanup old references (call this after all systems are migrated)
function ConfigMigrationHandler:cleanupLegacyReferences()
    print("ConfigMigrationHandler: Cleaning up legacy references...")
    
    -- List of deprecated config files that can be removed after migration
    local deprecatedFiles = {
        "WeaponConfigManager",
        "WeaponConfig" -- Keep this one for now in case of issues
    }
    
    print("ConfigMigrationHandler: Legacy cleanup recommendations:")
    for _, fileName in ipairs(deprecatedFiles) do
        print(string.format("  - Consider removing: %s.lua (replaced by UnifiedWeaponConfig)", fileName))
    end
end

-- Export the handler
return ConfigMigrationHandler