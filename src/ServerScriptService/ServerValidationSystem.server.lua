local ServerValidationSystem = {}

-- Missing ANTICHEAT_CONFIG table (this was causing the error)
local ANTICHEAT_CONFIG = {
    FRIENDLY_FIRE = false,
    MAX_WEAPON_DAMAGE = 100,
    MIN_WEAPON_DAMAGE = 1,
    MAX_FIRE_RATE = 1200, -- RPM
    MIN_FIRE_RATE = 60,   -- RPM
    MAX_VELOCITY = 50,    -- For movement validation
    MAX_RANGE = 1000,     -- Maximum weapon range
    DAMAGE_VALIDATION = true,
    SPEED_VALIDATION = true,
    POSITION_VALIDATION = true
}

-- Make it globally accessible
_G.ANTICHEAT_CONFIG = ANTICHEAT_CONFIG

-- Validation functions
function ServerValidationSystem.validateDamage(player, damage, weapon)
    if not ANTICHEAT_CONFIG.DAMAGE_VALIDATION then return true end

    -- Check damage bounds
    if damage < ANTICHEAT_CONFIG.MIN_WEAPON_DAMAGE or damage > ANTICHEAT_CONFIG.MAX_WEAPON_DAMAGE then
        warn("Invalid damage from", player.Name, ":", damage)
        return false
    end

    return true
end

function ServerValidationSystem.validateWeaponStats(weaponConfig)
    if not weaponConfig then return false end

    -- Validate fire rate
    if weaponConfig.fireRate then
        if weaponConfig.fireRate < ANTICHEAT_CONFIG.MIN_FIRE_RATE or 
            weaponConfig.fireRate > ANTICHEAT_CONFIG.MAX_FIRE_RATE then
            return false
        end
    end

    return true
end

function ServerValidationSystem.validatePlayerPosition(player, position)
    if not ANTICHEAT_CONFIG.POSITION_VALIDATION then return true end

    -- Basic position validation (extend as needed)
    if position.Y < -1000 or position.Y > 1000 then
        warn("Invalid position from", player.Name, ":", position)
        return false
    end

    return true
end

return ServerValidationSystem