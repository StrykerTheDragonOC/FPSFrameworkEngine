-- LoadoutSystem.lua
-- Comprehensive loadout and armory system for KFCS FUNNY RANDOMIZER
-- Manages weapon unlocks, attachments, loadout customization, and progression
-- Updated to use UnifiedWeaponConfig for consolidated configuration
-- Place in ReplicatedStorage.FPSSystem.Modules.LoadoutSystem

local LoadoutSystem = {}
LoadoutSystem.__index = LoadoutSystem

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get unified weapon configuration
local UnifiedWeaponConfig = require(ReplicatedStorage.FPSSystem.Config.UnifiedWeaponConfig)

-- Comprehensive weapon categories and unlock system matching original request
local WEAPON_CATEGORIES = {
    PRIMARY = {
        ["Assault Rifles"] = {
            "G36", "AK74", "M4A1", "SCAR-L", "AUG", "F2000", "TAR-21", "AN-94"
        },
        ["SMGs"] = {
            "MP5", "UMP45", "P90", "MP7", "Vector", "Skorpion", "PPSh-41", "MP40"
        },
        ["LMGs"] = {
            "M249", "PKM", "MG3", "L86A2", "HAMR", "AWS", "M60", "RPK"
        },
        ["Sniper Rifles"] = {
            "AWM", "M98B", "DSR-1", "Intervention", "TRG-42", "SV-98", "WA2000", "BFG-50"
        },
        ["Shotguns"] = {
            "M870", "KSG", "SPAS-12", "AA-12", "Saiga-12", "M1014", "Serbu", "DBV12"
        },
        ["DMRs"] = {
            "MK11", "SKS", "VSS", "SCAR-SSR", "Dragunov", "Henry", "Mosin", "BEOWULF TCR"
        },
        ["Carbines"] = {
            "M4", "AKU12", "Honey Badger", "SR-3M", "AS VAL", "Groza-1", "X95R", "K2C1"
        },
        ["Battle Rifles"] = {
            "SCAR-H", "G3", "FAL", "AG-3", "Henry .45-70", "AK103", "HK417", "BEOWULF ECR"
        }
    },
    SECONDARY = {
        ["Pistols"] = {
            "M9", "M1911", "Deagle 44", "Five seveN", "ZIP 22", "M45A1", "USP45", "1858 New Army"
        },
        ["Machine Pistols"] = {
            "G18", "M93R", "TEC-9", "MP1911", "Micro Uzi", "CZ75 Auto", "M712", "AUTO MAG III"
        },
        ["Revolvers"] = {
            "MP412 REX", "Mateba 6", "Judge", "Executioner", "Python", "REDHAWK 44", "1858 Carbine", "JUDGE JURY"
        },
        ["Others"] = {
            "Serbu Shotgun", "SFG 50", "Obrez", "Sawed Off", "AWS", "Zip .22", "Thumper M79", "MARS"
        }
    },
    MELEE = {
        ["Knives"] = {
            "Knife", "Tactical Knife", "Bayonet", "Karambit", "Butterfly Knife", "Machete", "Cleaver", "Ice Pick"
        },
        ["Blunt"] = {
            "Baseball Bat", "Crowbar", "Sledgehammer", "Frying Pan", "Golf Club", "Wrench", "Hammer", "Shovel"
        },
        ["Swords"] = {
            "Katana", "Broadsword", "Rapier", "Scimitar", "Claymore", "Wakizashi", "Zweihander", "Cutlass"
        }
    },
    GRENADES = {
        ["Lethal"] = {
            "M67 Frag", "Impact Grenade", "Semtex", "RGO Impact", "Molotov", "Thermite", "C4", "Claymore"
        },
        ["Tactical"] = {
            "Smoke Grenade", "Flashbang", "Stun Grenade", "Flare", "EMP", "Tear Gas", "Decoy", "Heartbeat Sensor"
        }
    }
}

-- Weapon unlock requirements (based on total kills as requested)
local WEAPON_UNLOCKS = {
    -- Primary weapons unlock progression
    ["G36"] = 0,        -- Starting weapon
    ["M4A1"] = 50,      -- 50 total kills 
    ["AK74"] = 100,
    ["SCAR-L"] = 200,
    ["AUG"] = 350,
    ["F2000"] = 500,
    ["TAR-21"] = 750,
    ["AN-94"] = 1000,
    
    -- SMGs
    ["MP5"] = 0,        -- Starting SMG
    ["UMP45"] = 75,
    ["P90"] = 150,
    ["MP7"] = 300,
    ["Vector"] = 450,
    ["Skorpion"] = 600,
    ["PPSh-41"] = 800,
    ["MP40"] = 1200,
    
    -- LMGs
    ["M249"] = 400,
    ["PKM"] = 600,
    ["MG3"] = 900,
    ["L86A2"] = 1100,
    
    -- Sniper Rifles  
    ["AWM"] = 300,
    ["M98B"] = 500,
    ["DSR-1"] = 700,
    ["Intervention"] = 900,
    
    -- Shotguns
    ["M870"] = 150,
    ["KSG"] = 250,
    ["SPAS-12"] = 400,
    ["AA-12"] = 650,
    
    -- Secondary weapons
    ["M9"] = 0,         -- Starting pistol
    ["M1911"] = 25,
    ["Deagle 44"] = 100,
    ["Five seveN"] = 200,
    ["G18"] = 350,
    ["MP412 REX"] = 500,
    
    -- Melee
    ["Knife"] = 0,      -- Starting melee
    ["Baseball Bat"] = 50,
    ["Katana"] = 200,
    ["Sledgehammer"] = 400,
    
    -- Grenades
    ["M67 Frag"] = 0,   -- Starting grenade
    ["Smoke Grenade"] = 25,
    ["Flashbang"] = 75,
    ["Semtex"] = 150,
    ["C4"] = 500
}

-- Attachment unlock system (5-3000 kills with specific weapon as requested)
local ATTACHMENT_UNLOCKS = {
    -- Optics (unlock with weapon-specific kills)
    ["Red Dot Sight"] = 5,
    ["Holographic Sight"] = 15,
    ["ACOG Scope"] = 35,
    ["Sniper Scope"] = 50,
    ["Thermal Scope"] = 100,
    ["Night Vision"] = 150,
    ["Coyote Sight"] = 200,
    ["PK-A"] = 300,
    ["Kobra Sight"] = 400,
    ["PSO-1"] = 500,
    
    -- Barrels
    ["Suppressor"] = 25,
    ["Heavy Barrel"] = 40,
    ["Flash Hider"] = 60,
    ["Compensator"] = 80,
    ["Long Barrel"] = 120,
    ["Muzzle Brake"] = 180,
    ["Loudener"] = 250,
    
    -- Grips
    ["Vertical Grip"] = 10,
    ["Angled Grip"] = 30,
    ["Bipod"] = 75,
    ["Stubby Grip"] = 90,
    ["Folding Grip"] = 150,
    ["Potato Grip"] = 300,
    
    -- Lasers/Lights  
    ["Laser Sight"] = 20,
    ["Flashlight"] = 35,
    ["IR Laser"] = 85,
    ["Green Laser"] = 120,
    
    -- Ammunition
    ["Hollow Point"] = 100,
    ["Armor Piercing"] = 150,
    ["Tracer"] = 75,
    ["Subsonic"] = 200,
    ["Plus P"] = 400,
    ["API"] = 800,
    
    -- High-end attachments requiring 1000+ kills
    ["FLIR 3.4x"] = 1200,
    ["Global Offensive"] = 1500,
    ["Anti Sight"] = 2000,
    ["Furro Sight"] = 2500,
    ["SUPER SCOPE"] = 3000
}

-- Perk system as requested
local PERKS = {
    TIER1 = {
        ["Double Time"] = {
            name = "Double Time",
            description = "Increased sprint speed and duration",
            effect = "movement_speed",
            unlock_rank = 5
        },
        ["Quick Fix"] = {
            name = "Quick Fix", 
            description = "Faster health regeneration",
            effect = "health_regen",
            unlock_rank = 10
        },
        ["Tactical Reload"] = {
            name = "Tactical Reload",
            description = "Faster reload speed",
            effect = "reload_speed", 
            unlock_rank = 15
        }
    },
    TIER2 = {
        ["Eagle Eye"] = {
            name = "Eagle Eye",
            description = "Reduced scope sway and faster ADS",
            effect = "weapon_handling",
            unlock_rank = 8
        },
        ["Stealth"] = {
            name = "Stealth",
            description = "Quieter movement and delayed detection",
            effect = "stealth",
            unlock_rank = 12
        },
        ["Explosive Resistance"] = {
            name = "Explosive Resistance", 
            description = "Reduced explosive damage",
            effect = "explosive_resist",
            unlock_rank = 18
        }
    },
    TIER3 = {
        ["Double Jump"] = {
            name = "Double Jump",
            description = "Ability to jump twice in mid-air",
            effect = "double_jump",
            unlock_rank = 20
        },
        ["Speed Boost"] = {
            name = "Speed Boost",
            description = "Permanent movement speed increase",
            effect = "speed_boost", 
            unlock_rank = 22
        },
        ["Sixth Sense"] = {
            name = "Sixth Sense",
            description = "See enemies through walls for short time",
            effect = "wallhack",
            unlock_rank = 25
        },
        ["Last Stand"] = {
            name = "Last Stand",
            description = "Continue fighting with pistol when downed",
            effect = "last_stand",
            unlock_rank = 30
        }
    }
}

-- Constructor
function LoadoutSystem.new()
    local self = setmetatable({}, LoadoutSystem)
    
    -- Player data storage
    self.playerLoadouts = {}      -- 3 loadout slots per player
    self.playerStats = {}         -- Kill/XP/rank tracking
    self.playerUnlocks = {}       -- Weapon/attachment unlocks
    self.playerPreferences = {}   -- UI preferences, weapon preview settings
    
    return self
end

-- Initialize the loadout system
function LoadoutSystem:initialize()
    print("[LoadoutSystem] Initializing comprehensive loadout/armory system...")
    
    -- Setup player connections
    game.Players.PlayerAdded:Connect(function(player)
        self:initializePlayer(player)
    end)
    
    -- Initialize existing players
    for _, player in pairs(game.Players:GetPlayers()) do
        self:initializePlayer(player)
    end
    
    print("[LoadoutSystem] Comprehensive loadout system initialized with", 
          "weapon unlocks, attachments, and 3-slot loadout customization")
    
    return true
end

-- Initialize player data with comprehensive loadout system
function LoadoutSystem:initializePlayer(player)
    local userId = player.UserId
    
    -- 3-slot loadout system as requested
    self.playerLoadouts[userId] = {
        slot1 = {
            primary = "G36",
            primary_attachments = {},
            secondary = "M9", 
            secondary_attachments = {},
            melee = "Knife",
            lethal = "M67 Frag",
            tactical = "Smoke Grenade",
            perk1 = nil,
            perk2 = nil,
            perk3 = nil
        },
        slot2 = {
            primary = "MP5",
            primary_attachments = {},
            secondary = "M1911",
            secondary_attachments = {},
            melee = "Baseball Bat", 
            lethal = "M67 Frag",
            tactical = "Flashbang",
            perk1 = nil,
            perk2 = nil,
            perk3 = nil
        },
        slot3 = {
            primary = "AWM",
            primary_attachments = {},
            secondary = "Deagle 44",
            secondary_attachments = {},
            melee = "Knife",
            lethal = "C4",
            tactical = "Smoke Grenade",
            perk1 = nil,
            perk2 = nil,
            perk3 = nil
        },
        active_slot = 1
    }
    
    -- Player progression tracking
    self.playerStats[userId] = {
        total_kills = 0,
        weapon_kills = {},          -- Kills per weapon for attachment unlocks
        attachment_unlocks = {},    -- Unlocked attachments per weapon
        rank = 1,
        xp = 0,
        credits = 200,
        deaths = 0
    }
    
    -- Weapon unlock tracking
    self.playerUnlocks[userId] = {
        weapons = {"G36", "MP5", "AWM", "M9", "M1911", "Deagle 44", "Knife", "Baseball Bat", "M67 Frag", "Smoke Grenade", "Flashbang", "C4"},
        perks = {}
    }
    
    -- UI preferences
    self.playerPreferences[userId] = {
        preview_mode = "inspect",   -- inspect, stats, attachments
        auto_preview = true,
        show_unlock_requirements = true
    }
    
    print("[LoadoutSystem] Initialized comprehensive loadout for player:", player.Name)
end

function LoadoutSystem:generateRandomLoadout(player)
    local playerData = self:getPlayerData(player)
    local availableWeapons = self:getAvailableWeaponsForPlayer(player)
    
    local loadout = {}
    
    -- Randomize each category
    for category, weapons in pairs(availableWeapons) do
        if #weapons > 0 then
            local randomIndex = math.random(1, #weapons)
            loadout[category] = weapons[randomIndex]
        else
            -- Fallback to defaults
            loadout[category] = self:getDefaultUnlocks()[category][1]
        end
    end
    
    self.currentLoadouts[player.UserId] = loadout
    
    print(string.format("[LoadoutSystem] Generated random loadout for %s: Primary=%s, Secondary=%s, Melee=%s, Grenade=%s", 
        player.Name, loadout.Primary, loadout.Secondary, loadout.Melee, loadout.Grenade))
    
    return loadout
end

function LoadoutSystem:getAvailableWeaponsForPlayer(player)
    local playerData = self:getPlayerData(player)
    local rank = playerData.rank
    
    -- Get weapons from pool + purchased weapons
    local available = {
        Primary = {},
        Secondary = {},  
        Melee = {},
        Grenade = {}
    }
    
    -- Add unlocked weapons from rank progression
    local rankPool = self.weaponPools[rank] or self.weaponPools[0]
    for category, weapons in pairs(rankPool) do
        for _, weapon in pairs(weapons) do
            if not table.find(available[category], weapon) then
                table.insert(available[category], weapon)
            end
        end
    end
    
    -- Add purchased weapons
    for category, weapons in pairs(playerData.purchasedWeapons) do
        for _, weapon in pairs(weapons) do
            if not table.find(available[category], weapon) then
                table.insert(available[category], weapon)
            end
        end
    end
    
    return available
end

function LoadoutSystem:canPlayerUnlockWeapon(player, weaponName, weaponConfig)
    local playerData = self:getPlayerData(player)
    
    -- Check if already unlocked
    for category, weapons in pairs(playerData.unlockedWeapons) do
        if table.find(weapons, weaponName) then
            return false, "Already unlocked"
        end
    end
    
    -- Check rank requirement
    local requiredRank = weaponConfig.unlockRank or 0
    if playerData.rank < requiredRank then
        return false, string.format("Requires rank %d (current: %d)", requiredRank, playerData.rank)
    end
    
    return true, "Can unlock"
end

function LoadoutSystem:purchaseWeapon(player, weaponName, weaponConfig)
    local playerData = self:getPlayerData(player)
    
    -- Check if can unlock
    local canUnlock, reason = self:canPlayerUnlockWeapon(player, weaponName, weaponConfig)
    if not canUnlock then
        return false, reason
    end
    
    -- Calculate cost (inflated price for early unlock)
    local baseCost = 1000
    local requiredRank = weaponConfig.unlockRank or 0
    local rankDiff = math.max(0, requiredRank - playerData.rank)
    local inflationMultiplier = 1 + (rankDiff * 0.5) -- 50% inflation per rank difference
    local cost = math.floor(baseCost * inflationMultiplier)
    
    -- Check credits
    if playerData.credits < cost then
        return false, string.format("Insufficient credits (need %d, have %d)", cost, playerData.credits)
    end
    
    -- Purchase weapon
    playerData.credits = playerData.credits - cost
    local category = weaponConfig.category
    
    if not playerData.purchasedWeapons[category] then
        playerData.purchasedWeapons[category] = {}
    end
    
    table.insert(playerData.purchasedWeapons[category], weaponName)
    
    print(string.format("[LoadoutSystem] %s purchased %s for %d credits", player.Name, weaponName, cost))
    
    return true, string.format("Purchased %s for %d credits", weaponName, cost)
end

function LoadoutSystem:addXP(player, amount, reason)
    local playerData = self:getPlayerData(player)
    
    playerData.xp = playerData.xp + amount
    
    -- Check for rank up
    local newRank = self:calculateRankFromXP(playerData.xp)
    if newRank > playerData.rank then
        self:rankUp(player, newRank)
    end
    
    print(string.format("[LoadoutSystem] %s gained %d XP (%s) - Total: %d", player.Name, amount, reason or "Unknown", playerData.xp))
end

function LoadoutSystem:calculateRankFromXP(xp)
    -- XP = 1000 × ((rank² + rank) ÷ 2)
    -- Solve for rank: rank = (-1 + sqrt(1 + 8*xp/1000)) / 2
    local rank = math.floor((-1 + math.sqrt(1 + 8 * xp / 1000)) / 2)
    return math.max(0, rank)
end

function LoadoutSystem:getXPForRank(rank)
    -- XP = 1000 × ((rank² + rank) ÷ 2)
    return 1000 * ((rank * rank + rank) / 2)
end

function LoadoutSystem:rankUp(player, newRank)
    local playerData = self:getPlayerData(player)
    local oldRank = playerData.rank
    
    playerData.rank = newRank
    
    -- Calculate credit reward
    local credits
    if newRank <= 20 then
        credits = ((newRank - 1) * 5) + 200
    else
        credits = (newRank * 5) + 200
    end
    
    playerData.credits = playerData.credits + credits
    
    print(string.format("[LoadoutSystem] %s ranked up! %d -> %d (+%d credits)", player.Name, oldRank, newRank, credits))
    
    -- TODO: Show rank up popup to player
    return credits
end

function LoadoutSystem:addKill(player, weapon)
    local playerData = self:getPlayerData(player)
    
    playerData.kills = playerData.kills + 1
    
    -- Track weapon kills for attachment unlocks
    if weapon then
        if not playerData.weaponProgression[weapon] then
            playerData.weaponProgression[weapon] = {kills = 0, attachmentsUnlocked = {}}
        end
        
        playerData.weaponProgression[weapon].kills = playerData.weaponProgression[weapon].kills + 1
    end
    
    -- Award XP
    self:addXP(player, 100, "Kill")
end

function LoadoutSystem:addDeath(player)
    local playerData = self:getPlayerData(player)
    playerData.deaths = playerData.deaths + 1
end

function LoadoutSystem:getKDR(player)
    local playerData = self:getPlayerData(player)
    if playerData.deaths == 0 then
        return playerData.kills
    end
    return playerData.kills / playerData.deaths
end

function LoadoutSystem:getCurrentLoadout(player)
    return self.currentLoadouts[player.UserId]
end

function LoadoutSystem:setCustomLoadout(player, loadout)
    -- Validate loadout weapons are available to player
    local available = self:getAvailableWeaponsForPlayer(player)
    
    for category, weaponName in pairs(loadout) do
        if not table.find(available[category] or {}, weaponName) then
            return false, string.format("Weapon %s not available in category %s", weaponName, category)
        end
    end
    
    self.currentLoadouts[player.UserId] = loadout
    
    print(string.format("[LoadoutSystem] Set custom loadout for %s", player.Name))
    return true, "Loadout set successfully"
end

-- Get player stats for UI display
function LoadoutSystem:getPlayerStats(player)
    local playerData = self:getPlayerData(player)
    
    return {
        rank = playerData.rank,
        xp = playerData.xp,
        xpForNext = self:getXPForRank(playerData.rank + 1),
        credits = playerData.credits,
        kills = playerData.kills,
        deaths = playerData.deaths,
        kdr = self:getKDR(player)
    }
end

-- Admin function to create special NTW variant
function LoadoutSystem:createAdminNTWVariant()
    return {
        name = "NTW-Admin",
        category = "Primary",
        subcategory = "SniperRifles", 
        damage = 200, -- Instant kill
        headMultiplier = 1.0,
        fireRate = 30,
        recoilPattern = {8.0, 7.5, 6.8, 7.2}, -- High recoil
        penetration = 500,
        range = 2000,
        velocity = 1500,
        spread = {min = 0.05, max = 0.3, increase = 0.1},
        ammo = {magazine = 3, reserve = 12, total = 15},
        reloadTime = {tactical = 4.0, empty = 5.0},
        aimTime = 1.2,
        walkSpeed = 8, -- Very slow
        firemodes = {"Semi"},
        special = "admin_orbital", -- Special orbital effect
        attachments = {
            optics = true,
            barrel = false, -- Cannot remove suppressor
            underbarrel = true,
            other = true
        },
        defaultAttachments = {
            barrel = "AdminSuppressor" -- Pre-equipped suppressor
        }
    }
end

function LoadoutSystem:cleanup()
    print("[LoadoutSystem] Cleaning up...")
    
    self.playerData = {}
    self.currentLoadouts = {}
    
    print("[LoadoutSystem] Cleanup complete")
end

return LoadoutSystem