-- ArmorySystem.lua
-- Comprehensive weapon management system for the FPS game

local ArmorySystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Available weapons (only these 4 are implemented according to Claude.md)
local AVAILABLE_WEAPONS = {
    Primary = {
        AssaultRifles = {
            {
                name = "G36",
                displayName = "G36 Assault Rifle",
                category = "AssaultRifles",
                classes = {"Assault"}, -- Assault exclusive
                level = 0,
                credits = 0,
                stats = {
                    damage = 35,
                    range = 85,
                    accuracy = 75,
                    fireRate = 650,
                    mobility = 60,
                    control = 70
                },
                description = "Versatile assault rifle with balanced stats"
            }
        }
    },
    Secondary = {
        Pistols = {
            {
                name = "M9",
                displayName = "M9 Pistol",
                category = "Pistols",
                classes = {"Assault", "Scout", "Support", "Recon"}, -- Available to all classes
                level = 0,
                credits = 0,
                stats = {
                    damage = 25,
                    range = 45,
                    accuracy = 70,
                    fireRate = 450,
                    mobility = 85,
                    control = 80
                },
                description = "Reliable sidearm with good accuracy"
            }
        }
    },
    Grenade = {
        Explosive = {
            {
                name = "M67",
                displayName = "M67 Frag Grenade",
                category = "Explosive",
                classes = {"Assault", "Scout", "Support", "Recon"}, -- Available to all classes
                level = 0,
                credits = 0,
                stats = {
                    damage = 100,
                    blastRadius = 8,
                    fuseTime = 3.5,
                    throwDistance = 25,
                    mobility = 90
                },
                description = "Standard fragmentation grenade"
            }
        }
    },
    Melee = {
        Blades = {
            {
                name = "PocketKnife",
                displayName = "Pocket Knife",
                category = "Blades",
                classes = {"Assault", "Scout", "Support", "Recon"}, -- Available to all classes
                level = 0,
                credits = 0,
                stats = {
                    damage = 45,
                    range = 2,
                    speed = 85,
                    backstabDamage = 100,
                    mobility = 95
                },
                description = "Quick and silent melee weapon"
            }
        }
    }
}

-- Locked weapons organized by subcategory (will be implemented later)
local LOCKED_WEAPONS = {
    Primary = {
        AssaultRifles = {
            {name = "AK-47", displayName = "AK-47", classes = {"Assault"}, level = 5, credits = 1500},
            {name = "M4A1", displayName = "M4A1", classes = {"Assault"}, level = 8, credits = 2000}
        },
        BattleRifles = {
            {name = "SCAR-H", displayName = "SCAR-H", classes = {"Assault", "Support", "Recon"}, level = 12, credits = 2500}
        },
        SniperRifles = {
            {name = "NTW-20", displayName = "NTW-20", classes = {"Recon"}, level = 30, credits = 8000}
        },
        Carbines = {
            {name = "M4 Carbine", displayName = "M4 Carbine", classes = {"Assault", "Scout", "Support", "Recon"}, level = 10, credits = 2200}
        },
        DMRs = {
            {name = "M110", displayName = "M110 SASS", classes = {"Scout", "Recon"}, level = 15, credits = 3500}
        },
        LMGs = {
            {name = "M240B", displayName = "M240B", classes = {"Support"}, level = 18, credits = 4000}
        },
        PDWs = {
            {name = "MP5", displayName = "MP5", classes = {"Scout"}, level = 7, credits = 1800}
        },
        Shotguns = {
            {name = "M1014", displayName = "M1014", classes = {"Assault", "Scout", "Support"}, level = 13, credits = 2800}
        }
    },
    Secondary = {
        Pistols = {
            {name = "Desert Eagle", displayName = "Desert Eagle", classes = {"Assault", "Scout", "Support", "Recon"}, level = 10, credits = 3000},
            {name = "Glock 17", displayName = "Glock 17", classes = {"Assault", "Scout", "Support", "Recon"}, level = 3, credits = 800}
        },
        Other = {
            {name = "Sawed-Off", displayName = "Sawed-Off Shotgun", classes = {"Assault", "Scout", "Support", "Recon"}, level = 20, credits = 4500}
        }
    },
    Melee = {
        Blades = {
            {name = "Combat Knife", displayName = "Combat Knife", classes = {"Assault", "Scout", "Support", "Recon"}, level = 15, credits = 5000},
            {name = "Katana", displayName = "Katana", classes = {"Assault", "Scout", "Support", "Recon"}, level = 25, credits = 8000}
        },
        Blunt = {
            {name = "Baseball Bat", displayName = "Baseball Bat", classes = {"Assault", "Scout", "Support", "Recon"}, level = 12, credits = 3000}
        }
    },
    Grenade = {
        Explosive = {
            {name = "C4", displayName = "C4 Explosive", classes = {"Assault", "Scout", "Support", "Recon"}, level = 20, credits = 5000}
        },
        Utility = {
            {name = "Smoke Grenade", displayName = "Smoke Grenade", classes = {"Assault", "Scout", "Support", "Recon"}, level = 7, credits = 1200},
            {name = "Flashbang", displayName = "Flashbang", classes = {"Assault", "Scout", "Support", "Recon"}, level = 10, credits = 1800}
        }
    }
}

-- Player data
local playerData = {
    level = 1,
    credits = 200,
    selectedClass = "Assault", -- Current player class
    unlockedWeapons = {},
    selectedWeapons = {
        Primary = "G36",
        Secondary = "M9",
        Grenade = "M67",
        Melee = "PocketKnife"
    },
    attachments = {}
}

-- Class definitions from Claude.md
local PLAYER_CLASSES = {
    Assault = {
        displayName = "Assault",
        description = "Versatile frontline fighter",
        exclusive = {"AssaultRifles"},
        shared = {"BattleRifles", "Carbines", "PDWs", "Shotguns"}
    },
    Scout = {
        displayName = "Scout",
        description = "Fast reconnaissance specialist",
        exclusive = {"PDWs"},
        shared = {"Carbines", "DMRs", "Shotguns"}
    },
    Support = {
        displayName = "Support",
        description = "Heavy weapons specialist",
        exclusive = {"LMGs"},
        shared = {"BattleRifles", "Carbines", "PDWs", "Shotguns"}
    },
    Recon = {
        displayName = "Recon",
        description = "Long-range precision marksman",
        exclusive = {"SniperRifles"},
        shared = {"BattleRifles", "Carbines", "DMRs"}
    }
}

function ArmorySystem:Initialize()
    print("ArmorySystem: Initializing...")

    -- Initialize player unlocks (start with default weapons)
    for category, subcategories in pairs(AVAILABLE_WEAPONS) do
        playerData.unlockedWeapons[category] = {}
        for subcategory, weapons in pairs(subcategories) do
            for _, weapon in pairs(weapons) do
                playerData.unlockedWeapons[category][weapon.name] = true
            end
        end
    end

    print("ArmorySystem: Initialized with", self:GetUnlockedWeaponCount(), "available weapons")
end

function ArmorySystem:GetAvailableWeapons()
    return AVAILABLE_WEAPONS
end

function ArmorySystem:GetLockedWeapons()
    return LOCKED_WEAPONS
end

function ArmorySystem:GetWeaponsByCategory(category, subcategory)
    local weapons = {}
    local currentClass = playerData.selectedClass

    -- Helper function to check if weapon is available to current class
    local function isWeaponAvailableToClass(weapon)
        if not weapon.classes then return true end
        for _, class in pairs(weapon.classes) do
            if class == currentClass then return true end
        end
        return false
    end

    -- Add available weapons
    if AVAILABLE_WEAPONS[category] then
        if subcategory and AVAILABLE_WEAPONS[category][subcategory] then
            -- Specific subcategory requested
            for _, weapon in pairs(AVAILABLE_WEAPONS[category][subcategory]) do
                if isWeaponAvailableToClass(weapon) then
                    table.insert(weapons, {
                        data = weapon,
                        unlocked = true,
                        selected = playerData.selectedWeapons[category] == weapon.name,
                        subcategory = subcategory
                    })
                end
            end
        else
            -- All subcategories
            for subcat, weaponList in pairs(AVAILABLE_WEAPONS[category]) do
                for _, weapon in pairs(weaponList) do
                    if isWeaponAvailableToClass(weapon) then
                        table.insert(weapons, {
                            data = weapon,
                            unlocked = true,
                            selected = playerData.selectedWeapons[category] == weapon.name,
                            subcategory = subcat
                        })
                    end
                end
            end
        end
    end

    -- Add locked weapons
    if LOCKED_WEAPONS[category] then
        if subcategory and LOCKED_WEAPONS[category][subcategory] then
            -- Specific subcategory requested
            for _, weapon in pairs(LOCKED_WEAPONS[category][subcategory]) do
                if isWeaponAvailableToClass(weapon) then
                    table.insert(weapons, {
                        data = weapon,
                        unlocked = false,
                        canUnlock = playerData.level >= weapon.level,
                        selected = false,
                        subcategory = subcategory
                    })
                end
            end
        else
            -- All subcategories
            for subcat, weaponList in pairs(LOCKED_WEAPONS[category]) do
                for _, weapon in pairs(weaponList) do
                    if isWeaponAvailableToClass(weapon) then
                        table.insert(weapons, {
                            data = weapon,
                            unlocked = false,
                            canUnlock = playerData.level >= weapon.level,
                            selected = false,
                            subcategory = subcat
                        })
                    end
                end
            end
        end
    end

    return weapons
end

function ArmorySystem:GetWeaponData(category, weaponName)
    -- Check available weapons first
    if AVAILABLE_WEAPONS[category] then
        for subcategory, weapons in pairs(AVAILABLE_WEAPONS[category]) do
            for _, weapon in pairs(weapons) do
                if weapon.name == weaponName then
                    return weapon, subcategory
                end
            end
        end
    end

    -- Check locked weapons
    if LOCKED_WEAPONS[category] then
        for subcategory, weapons in pairs(LOCKED_WEAPONS[category]) do
            for _, weapon in pairs(weapons) do
                if weapon.name == weaponName then
                    return weapon, subcategory
                end
            end
        end
    end

    return nil, nil
end

function ArmorySystem:IsWeaponUnlocked(category, weaponName)
    return playerData.unlockedWeapons[category] and
           playerData.unlockedWeapons[category][weaponName] == true
end

function ArmorySystem:CanUnlockWeapon(category, weaponName)
    local weapon = self:GetWeaponData(category, weaponName)
    if not weapon then return false end

    return playerData.level >= weapon.level and playerData.credits >= weapon.credits
end

function ArmorySystem:UnlockWeapon(category, weaponName)
    if self:IsWeaponUnlocked(category, weaponName) then
        return false, "Weapon already unlocked"
    end

    local weapon = self:GetWeaponData(category, weaponName)
    if not weapon then
        return false, "Weapon not found"
    end

    if not self:CanUnlockWeapon(category, weaponName) then
        return false, "Requirements not met"
    end

    -- Deduct credits and unlock
    playerData.credits = playerData.credits - weapon.credits
    playerData.unlockedWeapons[category] = playerData.unlockedWeapons[category] or {}
    playerData.unlockedWeapons[category][weaponName] = true

    print("Unlocked weapon:", weaponName, "for", weapon.credits, "credits")
    return true, "Weapon unlocked successfully"
end

function ArmorySystem:SelectWeapon(category, weaponName)
    if not self:IsWeaponUnlocked(category, weaponName) then
        return false, "Weapon not unlocked"
    end

    playerData.selectedWeapons[category] = weaponName
    print("Selected weapon:", category, weaponName)
    return true, "Weapon selected"
end

function ArmorySystem:GetSelectedWeapon(category)
    return playerData.selectedWeapons[category]
end

function ArmorySystem:GetPlayerData()
    return {
        level = playerData.level,
        credits = playerData.credits,
        selectedWeapons = playerData.selectedWeapons,
        unlockedWeapons = playerData.unlockedWeapons
    }
end

function ArmorySystem:GetUnlockedWeaponCount()
    local count = 0
    for category, weapons in pairs(playerData.unlockedWeapons) do
        for weaponName, unlocked in pairs(weapons) do
            if unlocked then count = count + 1 end
        end
    end
    return count
end

function ArmorySystem:GetWeaponModelPath(category, weaponName)
    local weapon, subcategory = self:GetWeaponData(category, weaponName)
    if weapon and subcategory then
        return "ReplicatedStorage.FPSSystem.WeaponModels." .. category .. "." .. subcategory .. "." .. weaponName
    end
    return "ReplicatedStorage.FPSSystem.WeaponModels." .. category .. ".Default." .. weaponName
end

-- New functions for class system
function ArmorySystem:GetPlayerClass()
    return playerData.selectedClass
end

function ArmorySystem:SetPlayerClass(className)
    if PLAYER_CLASSES[className] then
        playerData.selectedClass = className
        print("Player class set to:", className)
        return true
    end
    return false
end

function ArmorySystem:GetAvailableClasses()
    return PLAYER_CLASSES
end

function ArmorySystem:GetWeaponSubcategories(category)
    local subcategories = {}

    -- Get available subcategories
    if AVAILABLE_WEAPONS[category] then
        for subcategory, _ in pairs(AVAILABLE_WEAPONS[category]) do
            subcategories[subcategory] = true
        end
    end

    -- Get locked subcategories
    if LOCKED_WEAPONS[category] then
        for subcategory, _ in pairs(LOCKED_WEAPONS[category]) do
            subcategories[subcategory] = true
        end
    end

    -- Convert to array
    local result = {}
    for subcategory, _ in pairs(subcategories) do
        table.insert(result, subcategory)
    end

    return result
end

function ArmorySystem:CanUseWeapon(category, weaponName)
    local weapon = self:GetWeaponData(category, weaponName)
    if not weapon or not weapon.classes then return true end

    local currentClass = playerData.selectedClass
    for _, class in pairs(weapon.classes) do
        if class == currentClass then return true end
    end
    return false
end

return ArmorySystem