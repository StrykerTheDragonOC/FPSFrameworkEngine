-- ===========================
-- ACTUAL FIX 1: WeaponAttachmentIntegration.lua
-- The real issue: ScopeSystem doesn't exist, and it's AdvancedAttachmentSystem
-- ===========================

-- WeaponAttachmentIntegration.lua (REAL FIX)
local WeaponAttachmentIntegration = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- CORRECT module name - it's AdvancedAttachmentSystem, not AttachmentSystem
local AdvancedAttachmentSystem = require(ReplicatedStorage.FPSSystem.Modules.AdvancedAttachmentSystem)

-- DON'T try to load ScopeSystem since it doesn't exist
-- Remove this line entirely: local ScopeSystem = require(...)

-- Integration functions WITHOUT ScopeSystem
function WeaponAttachmentIntegration.integrateScope(weapon, scopeAttachment)
    if not weapon or not scopeAttachment then return false end

    -- Apply scope settings to weapon config only
    if scopeAttachment.scopeSettings then
        weapon.config.scopeSettings = scopeAttachment.scopeSettings
        print("Applied scope settings to weapon:", weapon.config.name)
    end

    -- NO ScopeSystem integration since it doesn't exist
    return true
end

-- Use AdvancedAttachmentSystem instead of AttachmentSystem
function WeaponAttachmentIntegration.attachToWeapon(weapon, attachmentName)
    if not weapon or not weapon.model then
        warn("Invalid weapon provided to attachToWeapon")
        return false
    end

    -- Use AdvancedAttachmentSystem (the correct name)
    local success = AdvancedAttachmentSystem.attachToWeapon(weapon.model, attachmentName)
    if success then
        -- Apply attachment effects using AdvancedAttachmentSystem
        weapon.config = AdvancedAttachmentSystem.applyAttachmentToConfig(weapon.config, attachmentName)

        -- Handle scope integration for sight attachments
        local attachment = AdvancedAttachmentSystem.getAttachment(attachmentName)
        if attachment and attachment.type == "SIGHT" then
            WeaponAttachmentIntegration.integrateScope(weapon, attachment)
        end

        print("Successfully attached", attachmentName, "to", weapon.config.name)
    else
        warn("Failed to attach", attachmentName, "to", weapon.config.name)
    end

    return success
end

-- Use AdvancedAttachmentSystem for compatibility checks
function WeaponAttachmentIntegration.isCompatible(weapon, attachmentName)
    if not weapon or not weapon.config then return false end

    return AdvancedAttachmentSystem.isCompatible(attachmentName, weapon.config.name)
end

-- Use AdvancedAttachmentSystem for available attachments
function WeaponAttachmentIntegration.getAvailableAttachments(weapon)
    if not weapon or not weapon.config then return {} end

    return AdvancedAttachmentSystem.getAvailableAttachments(weapon.config.name)
end

return WeaponAttachmentIntegration