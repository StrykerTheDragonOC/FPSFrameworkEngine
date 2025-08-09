-- Phantom Forces Style FPS Framework
-- Complete high-tech FPS system with advanced features
-- Place in ReplicatedStorage.FPSSystem.FPSFramework

local FPSFramework = {}
FPSFramework.__index = FPSFramework

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

-- Framework Configuration
local FRAMEWORK_CONFIG = {
    -- Advanced graphics settings
    GRAPHICS = {
        ENABLE_BLOOM = true,
        ENABLE_MOTION_BLUR = true,
        ENABLE_DEPTH_OF_FIELD = true,
        ENABLE_COLOR_CORRECTION = true,
        ENABLE_ATMOSPHERIC_FOG = true,
        MUZZLE_FLASH_INTENSITY = 2.0,
        PARTICLE_DENSITY = 1.0
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
        MAX_BULLET_HOLES = 100,
        MAX_SHELL_CASINGS = 50,
        MAX_PARTICLES = 200,
        EFFECTS_DISTANCE = 500,
        LOD_DISTANCE = 300
    },

    -- Gameplay settings
    GAMEPLAY = {
        FRIENDLY_FIRE = false,
        KILL_FEED = true,
        DAMAGE_INDICATORS = true,
        HIT_MARKERS = true,
        ADVANCED_BALLISTICS = true,
        BULLET_DROP = true,
        WIND_EFFECTS = false
    }
}

function FPSFramework.new()
    local self = setmetatable({}, FPSFramework)

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
    self.currentLoadout = {
        PRIMARY = nil,
        SECONDARY = nil,
        MELEE = nil,
        GRENADE = nil
    }
    self.currentWeapon = nil
    self.currentSlot = "PRIMARY"

    -- Input management
    self.inputConnections = {}
    self.mouseControl = {
        sensitivity = 0.3,
        isLocked = true,
        invertY = false
    }

    -- Statistics tracking
    self.stats = {
        kills = 0,
        deaths = 0,
        accuracy = 0,
        shotsFired = 0,
        shotsHit = 0,
        headshotPercentage = 0,
        favoriteWeapon = "",
        playtime = 0
    }

    -- Initialize framework
    self:initialize()

    return self
end

-- Initialize the complete framework
function FPSFramework:initialize()
    print("Initializing Phantom Forces Framework...")

    -- Setup character references
    self:setupCharacter()

    -- Initialize core systems
    self:initializeSystems()

    -- Setup input handling
    self:setupInputHandling()

    -- Setup UI
    self:setupUI()

    -- Setup graphics
    self:setupGraphics()

    -- Setup audio
    self:setupAudio()

    -- Start main loop
    self:startMainLoop()

    print("Phantom Forces Framework initialized successfully!")
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

        print("Character setup complete")
    end

    if self.player.Character then
        onCharacterAdded(self.player.Character)
    end

    self.player.CharacterAdded:Connect(onCharacterAdded)
end

-- Initialize all core systems
function FPSFramework:initializeSystems()
    -- Load system modules
    local function loadModule(name, path)
        local success, module = pcall(function()
            return require(ReplicatedStorage.FPSSystem.Modules[path])
        end)

        if success then
            return module
        else
            warn("Failed to load " .. name .. ": " .. tostring(module))
            return nil
        end
    end

    -- Initialize Modern Raycast System
    local ModernRaycastSystem = loadModule("ModernRaycastSystem", "ModernRaycastSystem")
    if ModernRaycastSystem then
        self.systems.raycast = ModernRaycastSystem.new()
    end

    -- Initialize Weapon Firing System
    local WeaponFiringSystem = loadModule("WeaponFiringSystem", "WeaponFiringSystem")
    if WeaponFiringSystem then
        self.systems.firing = WeaponFiringSystem.new(self.systems.viewmodel)
    end

    -- Initialize Viewmodel System
    local ViewmodelSystem = loadModule("ViewmodelSystem", "ViewmodelSystem")
    if ViewmodelSystem then
        self.systems.viewmodel = ViewmodelSystem.new()
    end

    -- Initialize Advanced Movement System
    local AdvancedMovementSystem = loadModule("AdvancedMovementSystem", "AdvancedMovementSystem")
    if AdvancedMovementSystem then
        self.systems.movement = AdvancedMovementSystem.new()
    end

    -- Initialize Effects System
    self.systems.effects = self:createEffectsSystem()

    -- Initialize Audio System
    self.systems.audio = self:createAudioSystem()

    -- Initialize Networking System
    self.systems.networking = self:createNetworkingSystem()
end

-- Setup input handling
function FPSFramework:setupInputHandling()
    -- Mouse control
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Input connections
    self.inputConnections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        self:handleInputBegan(input)
    end)

    self.inputConnections.inputEnded = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        self:handleInputEnded(input)
    end)

    self.inputConnections.inputChanged = UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        self:handleInputChanged(input)
    end)
end

-- Handle input began
function FPSFramework:handleInputBegan(input)
    local keyCode = input.KeyCode

    -- Weapon firing
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        self:startFiring()

        -- Weapon switching
    elseif keyCode == Enum.KeyCode.One then
        self:switchWeapon("PRIMARY")
    elseif keyCode == Enum.KeyCode.Two then
        self:switchWeapon("SECONDARY")
    elseif keyCode == Enum.KeyCode.Three then
        self:switchWeapon("MELEE")
    elseif keyCode == Enum.KeyCode.Four or keyCode == Enum.KeyCode.G then
        self:switchWeapon("GRENADE")

        -- Aiming
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        self:startAiming()

        -- Reloading
    elseif keyCode == Enum.KeyCode.R then
        self:reload()

        -- Sprinting
    elseif keyCode == Enum.KeyCode.LeftShift then
        if self.systems.movement then
            self.systems.movement:setSprinting(true)
        end

        -- Crouching
    elseif keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.C then
        if self.systems.movement then
            self.systems.movement:toggleCrouch()
        end

        -- Prone
    elseif keyCode == Enum.KeyCode.X then
        if self.systems.movement then
            self.systems.movement:toggleProne()
        end

        -- Leaning
    elseif keyCode == Enum.KeyCode.Q then
        if self.systems.movement then
            self.systems.movement:leanLeft(true)
        end
    elseif keyCode == Enum.KeyCode.E then
        if self.systems.movement then
            self.systems.movement:leanRight(true)
        end

        -- Tactical features
    elseif keyCode == Enum.KeyCode.T then
        self:toggleFlashlight()
    elseif keyCode == Enum.KeyCode.B then
        self:toggleLaser()
    elseif keyCode == Enum.KeyCode.V then
        self:toggleNightVision()

        -- Interface
    elseif keyCode == Enum.KeyCode.Tab then
        self:toggleScoreboard()
    elseif keyCode == Enum.KeyCode.M then
        self:toggleMap()
    elseif keyCode == Enum.KeyCode.L then
        if _G.LoadoutSelector then
            _G.LoadoutSelector:openGUI()
        end
    end
end

-- Handle input ended
function FPSFramework:handleInputEnded(input)
    -- Stop firing
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        self:stopFiring()

        -- Stop aiming
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        self:stopAiming()

        -- Stop sprinting
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        if self.systems.movement then
            self.systems.movement:setSprinting(false)
        end

        -- Stop leaning
    elseif input.KeyCode == Enum.KeyCode.Q then
        if self.systems.movement then
            self.systems.movement:leanLeft(false)
        end
    elseif input.KeyCode == Enum.KeyCode.E then
        if self.systems.movement then
            self.systems.movement:leanRight(false)
        end
    end
end

-- Handle input changed (mouse movement)
function FPSFramework:handleInputChanged(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        self:handleMouseMovement(input.Delta)
    end
end

-- Handle mouse movement for camera control
function FPSFramework:handleMouseMovement(delta)
    if not self.mouseControl.isLocked then return end

    local sensitivity = self.mouseControl.sensitivity
    local yInvert = self.mouseControl.invertY and -1 or 1

    -- Apply mouse movement to camera
    local rotationX = delta.X * sensitivity
    local rotationY = delta.Y * sensitivity * yInvert

    -- Update camera rotation
    if self.systems.viewmodel and self.systems.viewmodel.updateCameraRotation then
        self.systems.viewmodel:updateCameraRotation(rotationX, rotationY)
    end
end

-- Weapon firing
function FPSFramework:startFiring()
    if self.systems.firing and self.currentWeapon then
        self.systems.firing.isFiring = true
        self:fire()
    end
end

function FPSFramework:stopFiring()
    if self.systems.firing then
        self.systems.firing.isFiring = false
    end
end

function FPSFramework:fire()
    if self.systems.firing and self.systems.firing:fire() then
        -- Update statistics
        self.stats.shotsFired = self.stats.shotsFired + 1

        -- Play audio
        if self.systems.audio then
            self.systems.audio:playWeaponSound("fire", self.currentWeapon)
        end

        -- Create effects
        if self.systems.effects then
            self.systems.effects:createMuzzleFlash(self.currentWeapon)
        end
    end
end

-- Weapon aiming
function FPSFramework:startAiming()
    if self.systems.viewmodel then
        self.systems.viewmodel:setAiming(true)
    end
end

function FPSFramework:stopAiming()
    if self.systems.viewmodel then
        self.systems.viewmodel:setAiming(false)
    end
end

-- Weapon reloading
function FPSFramework:reload()
    if self.systems.firing and self.currentWeapon then
        self.systems.firing:reload()

        -- Play reload audio
        if self.systems.audio then
            self.systems.audio:playWeaponSound("reload", self.currentWeapon)
        end
    end
end

-- Weapon switching
function FPSFramework:switchWeapon(slot)
    if self.currentSlot == slot then return end

    local weapon = self.currentLoadout[slot]
    if not weapon then
        print("No weapon in slot: " .. slot)
        return
    end

    self.currentSlot = slot
    self.currentWeapon = weapon

    -- Update firing system
    if self.systems.firing then
        self.systems.firing:setWeapon(weapon.model, weapon.config)
    end

    -- Update viewmodel
    if self.systems.viewmodel then
        self.systems.viewmodel:equipWeapon(weapon.model, slot)
    end

    -- Play switch audio
    if self.systems.audio then
        self.systems.audio:playWeaponSound("switch", weapon)
    end

    print("Switched to " .. slot .. ": " .. weapon.name)
end

-- Load weapon into loadout slot
function FPSFramework:loadWeapon(slot, weaponName)
    -- Find weapon configuration
    local weaponConfig = self:getWeaponConfig(weaponName)
    if not weaponConfig then
        warn("Weapon config not found: " .. weaponName)
        return false
    end

    -- Load weapon model
    local weaponModel = self:loadWeaponModel(weaponName, slot)
    if not weaponModel then
        warn("Weapon model not found: " .. weaponName)
        return false
    end

    -- Create weapon data
    self.currentLoadout[slot] = {
        name = weaponName,
        model = weaponModel,
        config = weaponConfig,
        slot = slot
    }

    print("Loaded " .. weaponName .. " into " .. slot .. " slot")
    return true
end

-- Get weapon configuration
function FPSFramework:getWeaponConfig(weaponName)
    local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
    return WeaponConfig.getWeapon(weaponName)
end

-- Load weapon model
function FPSFramework:loadWeaponModel(weaponName, slot)
    local WeaponManager = require(ReplicatedStorage.FPSSystem.Modules.WeaponManager)
    return WeaponManager.loadWeapon(weaponName, slot)
end

-- Setup advanced graphics
function FPSFramework:setupGraphics()
    if not FRAMEWORK_CONFIG.GRAPHICS.ENABLE_BLOOM then return end

    -- Create post-processing effects
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.5
    bloom.Size = 24
    bloom.Threshold = 1.2
    bloom.Parent = Lighting

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.05
    colorCorrection.Contrast = 0.1
    colorCorrection.Saturation = 0.2
    colorCorrection.Parent = Lighting

    -- Atmospheric effects
    if FRAMEWORK_CONFIG.GRAPHICS.ENABLE_ATMOSPHERIC_FOG then
        local atmosphere = Instance.new("Atmosphere")
        atmosphere.Density = 0.3
        atmosphere.Offset = 0.25
        atmosphere.Color = Color3.fromRGB(199, 199, 199)
        atmosphere.Decay = Color3.fromRGB(92, 60, 13)
        atmosphere.Glare = 0.02
        atmosphere.Haze = 1.7
        atmosphere.Parent = Lighting
    end
end

-- Setup advanced audio system
function FPSFramework:setupAudio()
    -- Set master audio settings
    game.SoundService.AmbientReverb = Enum.ReverbType.Hangar
    game.SoundService.DistanceFactor = 3.33
    game.SoundService.DopplerScale = 1
    game.SoundService.RolloffScale = 1
end

-- Create effects system
function FPSFramework:createEffectsSystem()
    local effectsSystem = {
        bulletHoles = {},
        muzzleFlashes = {},
        explosions = {}
    }

    function effectsSystem:createMuzzleFlash(weapon)
        -- Advanced muzzle flash with multiple particle systems
        if not weapon or not weapon.PrimaryPart then return end

        local muzzlePoint = weapon.PrimaryPart:FindFirstChild("MuzzlePoint")
        if not muzzlePoint then return end

        -- Create flash effect
        local flash = Instance.new("Explosion")
        flash.Position = muzzlePoint.WorldPosition
        flash.BlastRadius = 0
        flash.BlastPressure = 0
        flash.Visible = false
        flash.Parent = workspace

        -- Create light effect
        local light = Instance.new("PointLight")
        light.Brightness = 5
        light.Range = 10
        light.Color = Color3.fromRGB(255, 200, 100)
        light.Parent = muzzlePoint

        -- Auto cleanup
        game:GetService("Debris"):AddItem(light, 0.05)
    end

    function effectsSystem:createBulletHole(position, normal, material)
        -- Create realistic bullet hole based on material
        local hole = Instance.new("Part")
        hole.Size = Vector3.new(0.1, 0.1, 0.1)
        hole.Shape = Enum.PartType.Cylinder
        hole.Material = Enum.Material.Plastic
        hole.Color = Color3.fromRGB(20, 20, 20)
        hole.Anchored = true
        hole.CanCollide = false
        hole.CFrame = CFrame.lookAt(position, position + normal)
        hole.Parent = workspace

        -- Add to cleanup list
        table.insert(self.bulletHoles, hole)

        -- Cleanup old bullet holes
        if #self.bulletHoles > FRAMEWORK_CONFIG.PERFORMANCE.MAX_BULLET_HOLES then
            local oldHole = table.remove(self.bulletHoles, 1)
            if oldHole and oldHole.Parent then
                oldHole:Destroy()
            end
        end
    end

    return effectsSystem
end

-- Create audio system
function FPSFramework:createAudioSystem()
    local audioSystem = {
        sounds = {},
        musicTracks = {}
    }

    function audioSystem:playWeaponSound(soundType, weapon)
        -- Play appropriate weapon sound
        local soundName = weapon.name .. "_" .. soundType
        local sound = self.sounds[soundName]

        if sound then
            sound:Play()
        else
            -- Create and cache sound if it doesn't exist
            local newSound = self:createWeaponSound(soundType, weapon)
            if newSound then
                self.sounds[soundName] = newSound
                newSound:Play()
            end
        end
    end

    function audioSystem:createWeaponSound(soundType, weapon)
        -- Create weapon sound based on type
        local sound = Instance.new("Sound")
        sound.Volume = FRAMEWORK_CONFIG.AUDIO.SFX_VOLUME

        -- Set sound ID based on weapon and type
        local soundIds = {
            fire = {
                G36 = "rbxassetid://131961136",
                AWP = "rbxassetid://131961136",
                M9 = "rbxassetid://131961136"
            },
            reload = {
                default = "rbxassetid://131961136"
            },
            switch = {
                default = "rbxassetid://131961136"
            }
        }

        local soundId = soundIds[soundType][weapon.name] or soundIds[soundType].default
        if soundId then
            sound.SoundId = soundId
            sound.Parent = self.player.Character and self.player.Character:FindFirstChild("Head")
            return sound
        end

        return nil
    end

    return audioSystem
end

-- Create networking system
function FPSFramework:createNetworkingSystem()
    local networkingSystem = {
        remoteEvents = {},
        remoteFunctions = {}
    }

    function networkingSystem:initialize()
        -- Setup remote events and functions
        local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteFolder then
            self.remoteEvents.weaponFired = remoteFolder:FindFirstChild("WeaponFired")
            self.remoteEvents.weaponHit = remoteFolder:FindFirstChild("WeaponHit")
            self.remoteEvents.weaponReload = remoteFolder:FindFirstChild("WeaponReload")
        end
    end

    networkingSystem:initialize()
    return networkingSystem
end

-- Setup UI
function FPSFramework:setupUI()
    -- Hide default Roblox UI
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    -- Create custom HUD
    self:createHUD()
end

-- Create HUD
function FPSFramework:createHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PhantomForcesHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self.player.PlayerGui

    -- Crosshair
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 20, 0, 20)
    crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
    crosshair.BackgroundTransparency = 1
    crosshair.Parent = screenGui

    -- Crosshair center dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 2, 0, 2)
    dot.Position = UDim2.new(0.5, -1, 0.5, -1)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = crosshair

    -- Ammo counter
    local ammoFrame = Instance.new("Frame")
    ammoFrame.Name = "AmmoCounter"
    ammoFrame.Size = UDim2.new(0, 200, 0, 60)
    ammoFrame.Position = UDim2.new(1, -220, 1, -80)
    ammoFrame.BackgroundTransparency = 1
    ammoFrame.Parent = screenGui

    local ammoLabel = Instance.new("TextLabel")
    ammoLabel.Size = UDim2.new(1, 0, 1, 0)
    ammoLabel.BackgroundTransparency = 1
    ammoLabel.Text = "30 / 120"
    ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ammoLabel.TextScaled = true
    ammoLabel.Font = Enum.Font.GothamBold
    ammoLabel.Parent = ammoFrame

    -- Store UI references
    self.ui = {
        screenGui = screenGui,
        crosshair = crosshair,
        ammoLabel = ammoLabel
    }
end

-- Toggle features
function FPSFramework:toggleFlashlight()
    print("Flashlight toggled")
end

function FPSFramework:toggleLaser()
    print("Laser toggled")
end

function FPSFramework:toggleNightVision()
    print("Night vision toggled")
end

function FPSFramework:toggleScoreboard()
    print("Scoreboard toggled")
end

function FPSFramework:toggleMap()
    print("Map toggled")
end

-- Main update loop
function FPSFramework:startMainLoop()
    self.mainConnection = RunService.Heartbeat:Connect(function(dt)
        self:update(dt)
    end)
end

-- Main update function
function FPSFramework:update(dt)
    -- Update systems
    if self.systems.movement then
        self.systems.movement:update(dt)
    end

    if self.systems.viewmodel then
        self.systems.viewmodel:update(dt)
    end

    -- Update UI
    self:updateUI()

    -- Update statistics
    self.stats.playtime = self.stats.playtime + dt
end

-- Update UI
function FPSFramework:updateUI()
    if self.ui and self.ui.ammoLabel and self.systems.firing then
        local ammoDisplay = self.systems.firing:getAmmoDisplay()
        self.ui.ammoLabel.Text = ammoDisplay
    end
end

-- Cleanup
function FPSFramework:cleanup()
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
end

-- Export framework globally
_G.FPSFramework = FPSFramework

return FPSFramework