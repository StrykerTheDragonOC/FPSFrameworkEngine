-- WeaponConfig.lua
-- Core weapon configuration module for FPS System
-- Provides weapon stats and configuration data

local WeaponConfig = {}

-- Default weapon configurations
WeaponConfig.Weapons = {
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
        UnlockLevel = 1
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
        UnlockLevel = 5
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
        UnlockLevel = 1
    },
    ["SCAR-H"] = {
        Name = "SCAR-H",
        DisplayName = "SCAR-H",
        Damage = 40,
        Range = 220,
        Recoil = 3,
        FireRate = 550,
        MagSize = 20,
        ReloadTime = 3.0,
        Category = "Primary",
        UnlockLevel = 10
    }
}

-- Get weapon configuration
function WeaponConfig:getWeapon(weaponName)
    return self.Weapons[weaponName]
end

-- Get all weapons
function WeaponConfig:getAllWeapons()
    return self.Weapons
end

-- Get weapons by category
function WeaponConfig:getWeaponsByCategory(category)
    local weapons = {}
    for name, weapon in pairs(self.Weapons) do
        if weapon.Category == category then
            weapons[name] = weapon
        end
    end
    return weapons
end

-- Check if weapon exists
function WeaponConfig:weaponExists(weaponName)
    return self.Weapons[weaponName] ~= nil
end

-- Get weapon damage
function WeaponConfig:getWeaponDamage(weaponName)
    local weapon = self:getWeapon(weaponName)
    return weapon and weapon.Damage or 0
end

-- Get weapon range
function WeaponConfig:getWeaponRange(weaponName)
    local weapon = self:getWeapon(weaponName)
    return weapon and weapon.Range or 0
end

return WeaponConfig