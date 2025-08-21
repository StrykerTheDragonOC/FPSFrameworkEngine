-- EnhancedWeaponSystem.lua
-- Fixed weapon system with proper naming conventions and deployment mechanics
-- Place in ReplicatedStorage/FPSSystem/Modules

local EnhancedWeaponSystem = {}
EnhancedWeaponSystem.__index = EnhancedWeaponSystem

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Module dependencies (using standard naming, not "Advanced")
local WeaponConfig = require(script.Parent.WeaponConfig)
local MeleeSystem = require(script.Parent.ComprehensiveMeleeSystem) -- Updated to comprehensive version
local GrenadeSystem = require(script.Parent.ComprehensiveGrenadeSystem) -- Updated to comprehensive version

-- Constants
local WEAPON_SLOTS = {"PRIMARY", "SECONDARY", "MELEE", "GRENADE"}

-- Default loadout (FIXED: Changed KNIFE to PocketKnife)
local DEFAULT_LOADOUT = {
    PRIMARY = "G36",
    SECONDARY = "M9",
    MELEE = "PocketKnife", -- FIXED: This was the source of the "Unknown weapon: KNIFE" error
    GRENADE = "M67"
}

function EnhancedWeaponSystem.new()
    local self = setmetatable({}, EnhancedWeaponSystem)

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.rootPart = nil

    -- Weapon management
    self.loadedWeapons = {} -- Weapons available for deployment
    self.deployedWeapons = {} -- Currently deployed/equipped weapons
    self.currentWeapon = nil
    self.currentSlot = "PRIMARY"

    -- Equipment state
    self.isEquipped = false
    self.isSwitching = false
    self.deploymentState = "MENU" -- MENU, DEPLOYING, DEPLOYED

    -- Sub-systems (using standard naming)
    self.meleeSystem = nil
    self.grenadeSystem = nil

    -- Connections
    self.connections = {}

    -- Initialize
    self:initialize()

    return self
end

-- Initialize the weapon system
function EnhancedWeaponSystem:initialize()
    print("[WeaponSystem] Initializing Enhanced Weapon System...")

    -- Wait for character
    self:waitForCharacter()

    -- Initialize sub-systems with proper naming
    self:initializeSubSystems()

    -- Load default loadout into available weapons (not deployed yet)
    self:loadDefaultLoadout()

    print("[WeaponSystem] Enhanced Weapon System initialized successfully")
end

-- Wait for player character
function EnhancedWeaponSystem:waitForCharacter()
    if self.player.Character then
        self:onCharacterSpawned(self.player.Character)
    end

    self.connections.characterAdded = self.player.CharacterAdded:Connect(function(character)
        self:onCharacterSpawned(character)
    end)
end

-- Handle character spawning
function EnhancedWeaponSystem:onCharacterSpawned(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.rootPart = character:WaitForChild("HumanoidRootPart")

    print("[WeaponSystem] Character spawned, weapon system ready")
end

-- Initialize sub-systems with standard naming (not "Advanced")
function EnhancedWeaponSystem:initializeSubSystems()
    print("[WeaponSystem] Initializing sub-systems...")

    -- Initialize ComprehensiveMeleeSystem
    local meleeSuccess, meleeResult = pcall(function()
        self.meleeSystem = MeleeSystem
        if MeleeSystem.init then
            MeleeSystem:init()
        end
        return true
    end)

    if meleeSuccess then
        print("[WeaponSystem] ComprehensiveMeleeSystem initialized successfully")
    else
        warn("[WeaponSystem] Failed to initialize ComprehensiveMeleeSystem:", meleeResult)
    end

    -- Initialize ComprehensiveGrenadeSystem  
    local grenadeSuccess, grenadeResult = pcall(function()
        self.grenadeSystem = GrenadeSystem
        if GrenadeSystem.init then
            GrenadeSystem:init()
        end
        return true
    end)

    if grenadeSuccess then
        print("[WeaponSystem] ComprehensiveGrenadeSystem initialized successfully")
    else
        warn("[WeaponSystem] Failed to initialize ComprehensiveGrenadeSystem:", grenadeResult)
    end
end

-- Load default loadout (makes weapons available, doesn't deploy them)
function EnhancedWeaponSystem:loadDefaultLoadout()
    print("[WeaponSystem] Loading default loadout...")

    for slot, weaponName in pairs(DEFAULT_LOADOUT) do
        local success = self:loadWeapon(slot, weaponName)
        if not success then
            warn("[WeaponSystem] Failed to load default weapon:", weaponName, "in slot:", slot)
        end
    end

    print("[WeaponSystem] Default loadout loaded successfully")
end

-- Load a weapon into a slot (makes it available for deployment)
function EnhancedWeaponSystem:loadWeapon(slot, weaponName)
    if not WEAPON_SLOTS[slot] and not table.find(WEAPON_SLOTS, slot) then
        warn("[WeaponSystem] Invalid weapon slot:", slot)
        return false
    end

    -- Get weapon configuration
    local weaponConfig = self:getWeaponConfig(weaponName)
    if not weaponConfig then
        warn("[WeaponSystem] Unknown weapon:", weaponName)
        return false
    end

    -- Store weapon as available for deployment
    self.loadedWeapons[slot] = {
        name = weaponName,
        config = weaponConfig,
        isDeployed = false
    }

    print("[WeaponSystem] Loaded", weaponName, "into", slot, "slot (ready for deployment)")
    return true
end

-- Deploy weapons from loadout (happens when player deploys from menu)
function EnhancedWeaponSystem:deployLoadout(loadout)
    if self.deploymentState == "DEPLOYED" then
        warn("[WeaponSystem] Weapons already deployed")
        return false
    end

    print("[WeaponSystem] Deploying weapons from loadout...")
    self.deploymentState = "DEPLOYING"

    -- Deploy each weapon from the loadout
    for slot, weaponName in pairs(loadout) do
        if self.loadedWeapons[slot] and self.loadedWeapons[slot].name == weaponName then
            local success = self:deployWeapon(slot)
            if success then
                print("[WeaponSystem] Deployed", weaponName, "to", slot, "slot")
            else
                warn("[WeaponSystem] Failed to deploy", weaponName, "to", slot, "slot")
            end
        else
            -- Load and deploy if not already loaded
            if self:loadWeapon(slot, weaponName) then
                self:deployWeapon(slot)
            end
        end
    end

    self.deploymentState = "DEPLOYED"

    -- Equip primary weapon by default
    self:equipWeapon("PRIMARY")

    print("[WeaponSystem] Loadout deployment complete")
    return true
end

-- Deploy a specific weapon (makes it usable in-game)
function EnhancedWeaponSystem:deployWeapon(slot)
    local weaponData = self.loadedWeapons[slot]
    if not weaponData then
        warn("[WeaponSystem] No weapon loaded in slot:", slot)
        return false
    end

    -- Mark as deployed
    weaponData.isDeployed = true
    self.deployedWeapons[slot] = weaponData

    -- Special handling for grenades and melee
    if slot == "GRENADE" then
        self:deployGrenade(weaponData)
    elseif slot == "MELEE" then
        self:deployMelee(weaponData)
    end

    return true
end

-- Deploy grenade (fixed: proper deployment mechanics)
function EnhancedWeaponSystem:deployGrenade(weaponData)
    if not self.grenadeSystem then
        warn("[WeaponSystem] GrenadeSystem not available")
        return false
    end

    -- Configure grenade system for this grenade type
    local grenadeConfig = weaponData.config
    self.grenadeSystem:setGrenadeType(weaponData.name, grenadeConfig)

    print("[WeaponSystem] Grenade deployed:", weaponData.name)
    return true
end

-- Deploy melee weapon
function EnhancedWeaponSystem:deployMelee(weaponData)
    if not self.meleeSystem then
        warn("[WeaponSystem] MeleeSystem not available")
        return false
    end

    -- Configure melee system for this weapon type
    local meleeConfig = weaponData.config
    self.meleeSystem:setWeapon(weaponData.name, meleeConfig)

    print("[WeaponSystem] Melee weapon deployed:", weaponData.name)
    return true
end

-- Equip a weapon (switch to it)
function EnhancedWeaponSystem:equipWeapon(slot)
    if self.deploymentState ~= "DEPLOYED" then
        warn("[WeaponSystem] Cannot equip weapons - not deployed yet")
        return false
    end

    if self.isSwitching then
        warn("[WeaponSystem] Already switching weapons")
        return false
    end

    local weaponData = self.deployedWeapons[slot]
    if not weaponData or not weaponData.isDeployed then
        warn("[WeaponSystem] No deployed weapon in slot:", slot)
        return false
    end

    if self.currentSlot == slot then
        print("[WeaponSystem] Already equipped:", slot)
        return true
    end

    self.isSwitching = true

    -- Unequip current weapon
    if self.currentWeapon then
        self:unequipCurrentWeapon()
    end

    -- Equip new weapon
    self.currentSlot = slot
    self.currentWeapon = weaponData
    self.isEquipped = true

    -- Handle special weapon types
    if slot == "GRENADE" then
        self:equipGrenade()
    elseif slot == "MELEE" then
        self:equipMelee()
    else
        self:equipFirearm()
    end

    -- Delay to prevent rapid switching
    task.delay(0.5, function()
        self.isSwitching = false
    end)

    print("[WeaponSystem] Equipped weapon:", weaponData.name, "in slot:", slot)
    return true
end

-- Equip grenade (FIXED: Proper deployment mechanics, not spammable in menu)
function EnhancedWeaponSystem:equipGrenade()
    if not self.grenadeSystem then
        warn("[WeaponSystem] GrenadeSystem not available")
        return false
    end

    -- Only allow grenade equipping if properly deployed
    if self.deploymentState ~= "DEPLOYED" then
        warn("[WeaponSystem] Cannot equip grenade - not in deployed state")
        return false
    end

    -- Activate grenade system
    self.grenadeSystem:equip()

    print("[WeaponSystem] Grenade equipped and ready")
    return true
end

-- Equip melee weapon
function EnhancedWeaponSystem:equipMelee()
    if not self.meleeSystem then
        warn("[WeaponSystem] MeleeSystem not available")
        return false
    end

    -- Activate melee system
    self.meleeSystem:equip()

    print("[WeaponSystem] Melee weapon equipped and ready")
    return true
end

-- Equip firearm (primary/secondary)
function EnhancedWeaponSystem:equipFirearm()
    -- Handle firearm equipping
    -- This would integrate with your existing firearm systems
    print("[WeaponSystem] Firearm equipped:", self.currentWeapon.name)
end

-- Unequip current weapon
function EnhancedWeaponSystem:unequipCurrentWeapon()
    if not self.currentWeapon then return end

    local slot = self.currentSlot

    if slot == "GRENADE" and self.grenadeSystem then
        self.grenadeSystem:unequip()
    elseif slot == "MELEE" and self.meleeSystem then
        self.meleeSystem:unequip()
    end

    self.currentWeapon = nil
    self.isEquipped = false

    print("[WeaponSystem] Unequipped weapon from slot:", slot)
end

-- Get weapon configuration
function EnhancedWeaponSystem:getWeaponConfig(weaponName)
    -- Handle the KNIFE ? PocketKnife mapping for backward compatibility
    if weaponName == "KNIFE" then
        weaponName = "PocketKnife"
        print("[WeaponSystem] Mapped KNIFE to PocketKnife for compatibility")
    end

    if WeaponConfig and WeaponConfig.Weapons then
        return WeaponConfig.Weapons[weaponName]
    end

    return nil
end

-- Check if weapon is deployed and ready
function EnhancedWeaponSystem:isWeaponReady(slot)
    local weaponData = self.deployedWeapons[slot]
    return weaponData and weaponData.isDeployed
end

-- Get current weapon info
function EnhancedWeaponSystem:getCurrentWeapon()
    return self.currentWeapon
end

-- Get current weapon slot
function EnhancedWeaponSystem:getCurrentSlot()
    return self.currentSlot
end

-- Check if weapons are deployed
function EnhancedWeaponSystem:isDeployed()
    return self.deploymentState == "DEPLOYED"
end

-- Handle weapon switching input (for hotkeys 1-4)
function EnhancedWeaponSystem:handleWeaponSwitch(slotNumber)
    if not self:isDeployed() then
        warn("[WeaponSystem] Cannot switch weapons - not deployed")
        return false
    end

    local slot = WEAPON_SLOTS[slotNumber]
    if slot then
        return self:equipWeapon(slot)
    end

    return false
end

-- Handle grenade throw input
function EnhancedWeaponSystem:handleGrenadeThrow()
    if self.currentSlot ~= "GRENADE" then
        warn("[WeaponSystem] No grenade equipped")
        return false
    end

    if not self.grenadeSystem then
        warn("[WeaponSystem] GrenadeSystem not available")
        return false
    end

    return self.grenadeSystem:throwGrenade()
end

-- Handle melee attack input
function EnhancedWeaponSystem:handleMeleeAttack()
    if self.currentSlot ~= "MELEE" then
        warn("[WeaponSystem] No melee weapon equipped")
        return false
    end

    if not self.meleeSystem then
        warn("[WeaponSystem] MeleeSystem not available")
        return false
    end

    return self.meleeSystem:attack()
end

-- Quick grenade (G key) - switches to grenade temporarily
function EnhancedWeaponSystem:quickGrenade()
    if not self:isDeployed() then
        warn("[WeaponSystem] Cannot use quick grenade - not deployed")
        return false
    end

    if not self:isWeaponReady("GRENADE") then
        warn("[WeaponSystem] No grenade available")
        return false
    end

    -- Store previous weapon
    local previousSlot = self.currentSlot

    -- Switch to grenade
    if self:equipWeapon("GRENADE") then
        -- Auto-switch back after throw (if implemented in GrenadeSystem)
        if self.grenadeSystem then
            self.grenadeSystem:setReturnSlot(previousSlot)
        end
        return true
    end

    return false
end

-- Quick melee (V key) - switches to melee temporarily  
function EnhancedWeaponSystem:quickMelee()
    if not self:isDeployed() then
        warn("[WeaponSystem] Cannot use quick melee - not deployed")
        return false
    end

    if not self:isWeaponReady("MELEE") then
        warn("[WeaponSystem] No melee weapon available")
        return false
    end

    -- Store previous weapon
    local previousSlot = self.currentSlot

    -- Switch to melee
    if self:equipWeapon("MELEE") then
        -- Auto-switch back after attack (if implemented in MeleeSystem)
        if self.meleeSystem then
            self.meleeSystem:setReturnSlot(previousSlot)
        end
        return true
    end

    return false
end

-- Reset deployment state (for returning to menu)
function EnhancedWeaponSystem:resetDeployment()
    print("[WeaponSystem] Resetting deployment state...")

    -- Unequip current weapon
    self:unequipCurrentWeapon()

    -- Clear deployed weapons
    self.deployedWeapons = {}

    -- Reset state
    self.deploymentState = "MENU"
    self.isEquipped = false
    self.isSwitching = false

    -- Reset sub-systems
    if self.grenadeSystem then
        self.grenadeSystem:reset()
    end

    if self.meleeSystem then
        self.meleeSystem:reset()
    end

    print("[WeaponSystem] Deployment reset complete")
end

-- Cleanup
function EnhancedWeaponSystem:cleanup()
    print("[WeaponSystem] Cleaning up Enhanced Weapon System...")

    -- Disconnect connections
    for name, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    -- Cleanup sub-systems
    if self.meleeSystem and self.meleeSystem.cleanup then
        self.meleeSystem:cleanup()
    end

    if self.grenadeSystem and self.grenadeSystem.cleanup then
        self.grenadeSystem:cleanup()
    end

    -- Clear references
    self.connections = {}
    self.loadedWeapons = {}
    self.deployedWeapons = {}
    self.currentWeapon = nil

    print("[WeaponSystem] Enhanced Weapon System cleanup complete")
end

return EnhancedWeaponSystem