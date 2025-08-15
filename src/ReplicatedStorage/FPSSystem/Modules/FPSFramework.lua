-- FPSFramework.lua  
-- Fixed and modernized FPS Framework with proper coordination
-- Place in ReplicatedStorage.FPSSystem.Modules.FPSFramework

local FPSFramework = {}
FPSFramework.__index = FPSFramework

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Teams = game:GetService("Teams")

-- Framework Configuration
local FRAMEWORK_CONFIG = {
    -- Graphics settings
    GRAPHICS = {
        ENABLE_BLOOM = true,
        ENABLE_MOTION_BLUR = false, -- Disabled for performance
        ENABLE_DEPTH_OF_FIELD = true,
        ENABLE_COLOR_CORRECTION = true,
        ENABLE_ATMOSPHERIC_FOG = true,
        MUZZLE_FLASH_INTENSITY = 2.0,
        PARTICLE_DENSITY = 0.8 -- Reduced for performance
    },

    -- Audio settings
    AUDIO = {
        MASTER_VOLUME = 0.8,
        SFX_VOLUME = 1.0,
        MUSIC_VOLUME = 0.3,
        ENABLE_3D_AUDIO = true,
        BULLET_WHIZ_DISTANCE = 5.0
    },

    -- Performance settings
    PERFORMANCE = {
        MAX_BULLET_HOLES = 50, -- Reduced from 100
        MAX_SHELL_CASINGS = 25, -- Reduced from 50
        MAX_PARTICLES = 100, -- Reduced from 200
        EFFECTS_DISTANCE = 300, -- Reduced from 500
        LOD_DISTANCE = 200 -- Reduced from 300
    },

    -- Gameplay settings
    GAMEPLAY = {
        FRIENDLY_FIRE = false,
        KILL_FEED = true,
        DAMAGE_INDICATORS = true,
        HIT_MARKERS = true,
        ADVANCED_BALLISTICS = true,
        BULLET_DROP = false, -- Simplified for now
        WIND_EFFECTS = false,
        DEFAULT_LOADOUT = {
            PRIMARY = "G36",
            SECONDARY = "M9", 
            MELEE = "PocketKnife",
            GRENADE = "M67"
        }
    }
}

function FPSFramework.new()
    local self = setmetatable({}, FPSFramework)

    -- Prevent multiple instances
    if _G.FPSFramework then
        warn("[FPSFramework] Instance already exists, returning existing")
        return _G.FPSFramework
    end

    -- Core references
    self.player = Players.LocalPlayer
    self.character = nil
    self.humanoid = nil
    self.camera = workspace.CurrentCamera

    -- System modules
    self.systems = {
        raycast = nil,
        firing = nil,
        viewmodel = nil,
        movement = nil,
        ui = nil,
        audio = nil,
        effects = nil,
        networking = nil
    }

    -- Weapon management
    self.currentLoadout = table.clone(FRAMEWORK_CONFIG.GAMEPLAY.DEFAULT_LOADOUT)
    self.equippedWeapon = nil
    self.weaponSlot = "PRIMARY"

    -- Game state
    self.isInGame = false
    self.currentTeam = nil
    self.health = 100
    self.armor = 0

    -- Statistics
    self.stats = {
        kills = 0,
        deaths = 0,
        assists = 0,
        score = 0,
        playtime = 0,
        level = 1,
        xp = 0
    }

    -- Input connections
    self.inputConnections = {}

    -- Main update connection
    self.mainConnection = nil

    -- Store globally
    _G.FPSFramework = self

    return self
end

-- Initialize the framework
function FPSFramework:initialize()
    print("[FPSFramework] Initializing FPS Framework...")

    -- Setup character
    self:setupCharacter()

    -- Initialize systems
    self:initializeSystems()

    -- Setup input handling
    self:setupInputHandling()

    -- Create UI
    self:createUI()

    -- Start main loop
    self:startMainLoop()

    print("[FPSFramework] FPS Framework initialized successfully!")
    return true
end

-- Setup character references
function FPSFramework:setupCharacter()
    local function onCharacterAdded(character)
        self.character = character
        self.humanoid = character:WaitForChild("Humanoid")

        -- Update systems with new character
        if self.systems.raycast then
            self.systems.raycast:updateDefaultExcludes()
        end

        -- Reset health
        self.health = 100
        self.armor = 0

        print("[FPSFramework] Character setup complete")
    end

    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end

    self.player.CharacterAdded:Connect(onCharacterAdded)
end

-- Initialize all core systems with proper error handling
function FPSFramework:initializeSystems()
    print("[FPSFramework] Initializing core systems...")

    -- Load system modules safely
    local function loadModule(name, path)
        local success, module = pcall(function()
            local moduleScript = ReplicatedStorage.FPSSystem.Modules:FindFirstChild(path)
            if moduleScript then
                return require(moduleScript)
            end
            return nil
        end)

        if success and module then
            print("[FPSFramework] Loaded:", name)
            return module
        else
            warn("[FPSFramework] Failed to load " .. name .. ":", tostring(module))
            return nil
        end
    end

    -- Initialize Modern Raycast System
    local ModernRaycastSystem = loadModule("ModernRaycastSystem", "ModernRaycastSystem")
    if ModernRaycastSystem then
        self.systems.raycast = ModernRaycastSystem.new()
    end

    -- Initialize Viewmodel System (use global if available)
    if _G.ViewmodelSystem then
        self.systems.viewmodel = _G.ViewmodelSystem
        print("[FPSFramework] Using global ViewmodelSystem")
    else
        local ViewmodelSystem = loadModule("ViewmodelSystem", "ViewmodelSystem")
        if ViewmodelSystem then
            self.systems.viewmodel = ViewmodelSystem.new()
        end
    end

    -- Initialize Weapon Firing System (use global if available)
    if _G.WeaponFiringSystem then
        self.systems.firing = _G.WeaponFiringSystem
        print("[FPSFramework] Using global WeaponFiringSystem")
    else
        local WeaponFiringSystem = loadModule("WeaponFiringSystem", "WeaponFiringSystem")
        if WeaponFiringSystem and self.systems.viewmodel then
            self.systems.firing = WeaponFiringSystem.new(self.systems.viewmodel)
        end
    end

    -- Initialize Advanced Movement System
    local AdvancedMovementSystem = loadModule("AdvancedMovementSystem", "AdvancedMovementSystem")
    if AdvancedMovementSystem then
        self.systems.movement = AdvancedMovementSystem.new()
    end

    -- Initialize other systems
    self.systems.effects = self:createEffectsSystem()
    self.systems.audio = self:createAudioSystem()
    self.systems.networking = self:createNetworkingSystem()

    print("[FPSFramework] Core systems initialization complete")
end

-- Setup input handling
function FPSFramework:setupInputHandling()
    print("[FPSFramework] Setting up input handling...")

    -- Mouse control for FPS
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Weapon switching
    self.inputConnections.weaponSwitch1 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.One then
            self:equipWeapon("PRIMARY")
        elseif input.KeyCode == Enum.KeyCode.Two then
            self:equipWeapon("SECONDARY")
        elseif input.KeyCode == Enum.KeyCode.Three then
            self:equipWeapon("MELEE")
        elseif input.KeyCode == Enum.KeyCode.Four then
            self:equipWeapon("GRENADE")
        end
    end)

    -- Utility inputs
    self.inputConnections.utilities = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.F then
            self:toggleFlashlight()
        elseif input.KeyCode == Enum.KeyCode.L then
            self:toggleLaser()
        elseif input.KeyCode == Enum.KeyCode.N then
            self:toggleNightVision()
        elseif input.KeyCode == Enum.KeyCode.Tab then
            self:toggleScoreboard()
        elseif input.KeyCode == Enum.KeyCode.M then
            self:toggleMap()
        elseif input.KeyCode == Enum.KeyCode.Q then
            self:spotEnemy()
        end
    end)

    print("[FPSFramework] Input handling setup complete")
end

-- Create basic UI
function FPSFramework:createUI()
    print("[FPSFramework] Creating basic UI...")

    -- Create screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSFrameworkUI"
    screenGui.Parent = self.player:WaitForChild("PlayerGui")

    -- Create crosshair
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 20, 0, 20)
    crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
    crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshair.BorderSizePixel = 0
    crosshair.Parent = screenGui

    -- Create crosshair lines
    local hLine = Instance.new("Frame")
    hLine.Size = UDim2.new(0, 20, 0, 2)
    hLine.Position = UDim2.new(0, 0, 0.5, -1)
    hLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hLine.BorderSizePixel = 0
    hLine.Parent = crosshair

    local vLine = Instance.new("Frame")
    vLine.Size = UDim2.new(0, 2, 0, 20)
    vLine.Position = UDim2.new(0.5, -1, 0, 0)
    vLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    vLine.BorderSizePixel = 0
    vLine.Parent = crosshair

    -- Create ammo counter
    local ammoFrame = Instance.new("Frame")
    ammoFrame.Name = "AmmoCounter"
    ammoFrame.Size = UDim2.new(0, 200, 0, 60)
    ammoFrame.Position = UDim2.new(1, -220, 1, -80)
    ammoFrame.BackgroundTransparency = 1
    ammoFrame.Parent = screenGui

    local ammoLabel = Instance.new("TextLabel")
    ammoLabel.Name = "AmmoText"
    ammoLabel.Size = UDim2.new(1, 0, 1, 0)
    ammoLabel.BackgroundTransparency = 1
    ammoLabel.Text = "30 / 120"
    ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ammoLabel.TextScaled = true
    ammoLabel.Font = Enum.Font.GothamBold
    ammoLabel.TextStrokeTransparency = 0
    ammoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ammoLabel.Parent = ammoFrame

    -- Create health display
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthDisplay"
    healthFrame.Size = UDim2.new(0, 200, 0, 20)
    healthFrame.Position = UDim2.new(0, 20, 1, -40)
    healthFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = screenGui

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthFrame

    -- Store UI references
    self.ui = {
        screenGui = screenGui,
        crosshair = crosshair,
        ammoLabel = ammoLabel,
        healthBar = healthBar
    }

    print("[FPSFramework] Basic UI created")
end

-- Create effects system
function FPSFramework:createEffectsSystem()
    local effects = {
        bulletHoles = {},
        muzzleFlashes = {},
        impacts = {}
    }

    function effects:createMuzzleFlash(position)
        -- TODO: Implement muzzle flash
    end

    function effects:createBulletHole(position, normal, surface)
        -- TODO: Implement bullet holes
    end

    function effects:createImpact(position, material)
        -- TODO: Implement impact effects
    end

    return effects
end

-- Create audio system
function FPSFramework:createAudioSystem()
    local audio = {}

    function audio:playWeaponSound(soundId, volume)
        if _G.ModernSoundManager then
            return _G.ModernSoundManager:playSound(soundId, volume)
        end
    end

    function audio:play3DSound(soundId, position, volume)
        if _G.ModernSoundManager then
            return _G.ModernSoundManager:playSound(soundId, volume, position)
        end
    end

    return audio
end

-- Create networking system
function FPSFramework:createNetworkingSystem()
    local networking = {}

    function networking:sendDamage(targetPlayer, damage, weapon, hitPart)
        -- TODO: Implement damage networking
        print("[FPSFramework] Damage networking:", damage, "to", targetPlayer.Name)
    end

    return networking
end

-- Equip weapon
function FPSFramework:equipWeapon(slot)
    local weaponName = self.currentLoadout[slot]
    if not weaponName then
        warn("[FPSFramework] No weapon in slot:", slot)
        return false
    end

    self.weaponSlot = slot
    self.equippedWeapon = weaponName

    -- Update viewmodel system
    if self.systems.viewmodel then
        self.systems.viewmodel:equipWeapon(weaponName, slot)
    end

    -- Update firing system
    if self.systems.firing then
        -- TODO: Set weapon in firing system
    end

    print("[FPSFramework] Equipped weapon:", weaponName, "in slot:", slot)
    return true
end

-- Load weapon into loadout slot
function FPSFramework:loadWeapon(slot, weaponName)
    self.currentLoadout[slot] = weaponName
    print("[FPSFramework] Loaded weapon:", weaponName, "into slot:", slot)
end

-- Spot enemy (Q key functionality)
function FPSFramework:spotEnemy()
    -- TODO: Implement enemy spotting system
    print("[FPSFramework] Enemy spotting activated")
end

-- Toggle features
function FPSFramework:toggleFlashlight()
    print("[FPSFramework] Flashlight toggled")
end

function FPSFramework:toggleLaser()
    print("[FPSFramework] Laser toggled")
end

function FPSFramework:toggleNightVision()
    print("[FPSFramework] Night vision toggled")
end

function FPSFramework:toggleScoreboard()
    print("[FPSFramework] Scoreboard toggled")
end

function FPSFramework:toggleMap()
    print("[FPSFramework] Map toggled")
end

-- Main update loop
function FPSFramework:startMainLoop()
    if self.mainConnection then
        self.mainConnection:Disconnect()
    end

    self.mainConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:update(deltaTime)
    end)

    print("[FPSFramework] Main loop started")
end

-- Main update function
function FPSFramework:update(deltaTime)
    -- Update systems
    if self.systems.movement then
        self.systems.movement:update(deltaTime)
    end

    if self.systems.viewmodel then
        self.systems.viewmodel:update(deltaTime)
    end

    -- Update UI
    self:updateUI()

    -- Update statistics
    self.stats.playtime = self.stats.playtime + deltaTime
end

-- Update UI
function FPSFramework:updateUI()
    if not self.ui then return end

    -- Update ammo display
    if self.ui.ammoLabel and self.systems.firing then
        local ammoDisplay = self.systems.firing:getAmmoDisplay()
        if ammoDisplay then
            self.ui.ammoLabel.Text = ammoDisplay
        end
    end

    -- Update health bar
    if self.ui.healthBar then
        local healthPercent = self.health / 100
        self.ui.healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    end
end

-- Get current stats
function FPSFramework:getStats()
    return self.stats
end

-- Add XP
function FPSFramework:addXP(amount, reason)
    self.stats.xp = self.stats.xp + amount
    print(string.format("[FPSFramework] +%d XP (%s)", amount, reason or "Unknown"))
end

-- Add kill
function FPSFramework:addKill()
    self.stats.kills = self.stats.kills + 1
    self:addXP(100, "Kill")
end

-- Add death
function FPSFramework:addDeath()
    self.stats.deaths = self.stats.deaths + 1
end

-- Cleanup
function FPSFramework:cleanup()
    print("[FPSFramework] Cleaning up...")

    -- Disconnect connections
    for name, connection in pairs(self.inputConnections) do
        if connection then
            connection:Disconnect()
        end
    end

    if self.mainConnection then
        self.mainConnection:Disconnect()
    end

    -- Cleanup systems
    for _, system in pairs(self.systems) do
        if system and system.cleanup then
            system:cleanup()
        end
    end

    -- Clean up UI
    if self.ui and self.ui.screenGui then
        self.ui.screenGui:Destroy()
    end

    -- Clear global reference
    _G.FPSFramework = nil

    print("[FPSFramework] Cleanup complete")
end

return FPSFramework