-- Advanced Sound System with 3D Audio and Dynamic Effects
-- Place in ReplicatedStorage.FPSSystem.Modules.AdvancedSoundSystem
local AdvancedSoundSystem = {}
AdvancedSoundSystem.__index = AdvancedSoundSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Sound Configuration
local SOUND_CONFIG = {
    -- Master audio settings
    MASTER_VOLUME = 1.0,
    SFX_VOLUME = 0.8,
    MUSIC_VOLUME = 0.3,
    VOICE_VOLUME = 0.9,

    -- 3D Audio settings
    ENABLE_3D_AUDIO = true,
    MAX_AUDIO_DISTANCE = 500,
    DOPPLER_SCALE = 1.0,
    ROLLOFF_SCALE = 1.0,

    -- Dynamic range compression
    ENABLE_COMPRESSION = true,
    COMPRESSION_THRESHOLD = 0.8,
    COMPRESSION_RATIO = 4.0,

    -- Environmental audio
    ENABLE_REVERB = true,
    REVERB_TYPE = Enum.ReverbType.Arena,

    -- Bullet audio
    BULLET_WHIZ_DISTANCE = 5.0,
    BULLET_CRACK_DISTANCE = 10.0,
    SUPPRESSOR_VOLUME_REDUCTION = 0.3
}

-- Sound Database
local SOUND_DATABASE = {
    -- Weapon Sounds
    WEAPONS = {
        -- Assault Rifles
        ["G36"] = {
            fire = "rbxassetid://131961136",
            fireSupressed = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            boltAction = "rbxassetid://131961136",
            dryFire = "rbxassetid://131961136",
            switch = "rbxassetid://131961136"
        },
        ["AK74"] = {
            fire = "rbxassetid://131961136",
            fireSupressed = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            boltAction = "rbxassetid://131961136",
            dryFire = "rbxassetid://131961136",
            switch = "rbxassetid://131961136"
        },

        -- Sniper Rifles
        ["AWP"] = {
            fire = "rbxassetid://131961136",
            fireSupressed = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            boltAction = "rbxassetid://131961136",
            dryFire = "rbxassetid://131961136",
            switch = "rbxassetid://131961136"
        },

        -- Pistols
        ["M9"] = {
            fire = "rbxassetid://131961136",
            fireSupressed = "rbxassetid://131961136",
            reload = "rbxassetid://131961136",
            slideAction = "rbxassetid://131961136",
            dryFire = "rbxassetid://131961136",
            switch = "rbxassetid://131961136"
        }
    },

    -- Impact Sounds
    IMPACTS = {
        [Enum.Material.Concrete] = "rbxassetid://131961136",
        [Enum.Material.Metal] = "rbxassetid://131961136",
        [Enum.Material.Wood] = "rbxassetid://131961136",
        [Enum.Material.Glass] = "rbxassetid://131961136",
        [Enum.Material.Plastic] = "rbxassetid://131961136",
        [Enum.Material.Fabric] = "rbxassetid://131961136",
        ["Flesh"] = "rbxassetid://131961136",
        ["Water"] = "rbxassetid://131961136"
    },

    -- Environment Sounds
    ENVIRONMENT = {
        bulletWhiz = "rbxassetid://131961136",
        bulletCrack = "rbxassetid://131961136",
        ricochet = "rbxassetid://131961136",
        shellDrop = "rbxassetid://131961136",
        footstepConcrete = "rbxassetid://131961136",
        footstepMetal = "rbxassetid://131961136",
        footstepGrass = "rbxassetid://131961136"
    },

    -- UI Sounds
    UI = {
        buttonClick = "rbxassetid://131961136",
        buttonHover = "rbxassetid://131961136",
        menuOpen = "rbxassetid://131961136",
        menuClose = "rbxassetid://131961136",
        notification = "rbxassetid://131961136",
        error = "rbxassetid://131961136"
    },

    -- Game Events
    EVENTS = {
        killConfirm = "rbxassetid://131961136",
        hitMarker = "rbxassetid://131961136",
        headshot = "rbxassetid://131961136",
        levelUp = "rbxassetid://131961136",
        matchStart = "rbxassetid://131961136",
        matchEnd = "rbxassetid://131961136"
    }
}

function AdvancedSoundSystem.new()
    local self = setmetatable({}, AdvancedSoundSystem)

    -- References
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera

    -- Sound management
    self.activeSounds = {}
    self.soundCache = {}
    self.soundGroups = {}

    -- 3D Audio tracking
    self.audioSources = {}
    self.listenerPosition = Vector3.new(0, 0, 0)
    self.listenerVelocity = Vector3.new(0, 0, 0)

    -- Dynamic audio effects
    self.reverbSettings = {}
    self.compressionSettings = {}

    -- Initialize system
    self:initialize()

    return self
end

-- Initialize the sound system
function AdvancedSoundSystem:initialize()
    print("Initializing Advanced Sound System...")

    -- Configure SoundService
    self:configureSoundService()

    -- Create sound groups
    self:createSoundGroups()

    -- Setup 3D audio
    if SOUND_CONFIG.ENABLE_3D_AUDIO then
        self:setup3DAudio()
    end

    -- Setup dynamic effects
    self:setupDynamicEffects()

    -- Start update loop
    self:startUpdateLoop()

    print("Advanced Sound System initialized")
end

-- Configure SoundService settings
function AdvancedSoundSystem:configureSoundService()
    SoundService.AmbientReverb = SOUND_CONFIG.REVERB_TYPE
    SoundService.DopplerScale = SOUND_CONFIG.DOPPLER_SCALE
    SoundService.RolloffScale = SOUND_CONFIG.ROLLOFF_SCALE
    SoundService.DistanceFactor = 3.33

    -- Set master volume
    SoundService.MasterVolume = SOUND_CONFIG.MASTER_VOLUME
end

-- Create sound groups for better organization
function AdvancedSoundSystem:createSoundGroups()
    local soundGroups = {"Weapons", "Environment", "UI", "Music", "Voice"}

    for _, groupName in ipairs(soundGroups) do
        local soundGroup = Instance.new("SoundGroup")
        soundGroup.Name = groupName
        soundGroup.Parent = SoundService

        -- Set group volumes
        if groupName == "Weapons" or groupName == "Environment" then
            soundGroup.Volume = SOUND_CONFIG.SFX_VOLUME
        elseif groupName == "Music" then
            soundGroup.Volume = SOUND_CONFIG.MUSIC_VOLUME
        elseif groupName == "Voice" then
            soundGroup.Volume = SOUND_CONFIG.VOICE_VOLUME
        else
            soundGroup.Volume = SOUND_CONFIG.SFX_VOLUME
        end

        self.soundGroups[groupName] = soundGroup
    end
end

-- Setup 3D audio system
function AdvancedSoundSystem:setup3DAudio()
    -- Create audio listener (follows player/camera)
    self.audioListener = {
        position = self.camera.CFrame.Position,
        velocity = Vector3.new(0, 0, 0),
        orientation = self.camera.CFrame.LookVector
    }
end

-- Setup dynamic audio effects
function AdvancedSoundSystem:setupDynamicEffects()
    -- Compression settings
    if SOUND_CONFIG.ENABLE_COMPRESSION then
        self.compressionSettings = {
            threshold = SOUND_CONFIG.COMPRESSION_THRESHOLD,
            ratio = SOUND_CONFIG.COMPRESSION_RATIO,
            enabled = true
        }
    end

    -- Reverb settings
    if SOUND_CONFIG.ENABLE_REVERB then
        self.reverbSettings = {
            type = SOUND_CONFIG.REVERB_TYPE,
            wetLevel = 0.3,
            dryLevel = 0.7,
            enabled = true
        }
    end
end

-- Play weapon sound with 3D positioning
function AdvancedSoundSystem:playWeaponSound(weaponName, soundType, position, isSuppressed)
    local weaponSounds = SOUND_DATABASE.WEAPONS[weaponName]
    if not weaponSounds then
        warn("No sounds found for weapon: " .. weaponName)
        return
    end

    local soundId = isSuppressed and weaponSounds.fireSupressed or weaponSounds[soundType]
    if not soundId then
        warn("Sound not found: " .. soundType .. " for weapon: " .. weaponName)
        return
    end

    -- Create and configure sound
    local sound = self:createSound(soundId, "Weapons")

    -- Apply suppressor effects
    if isSuppressed then
        sound.Volume = sound.Volume * SOUND_CONFIG.SUPPRESSOR_VOLUME_REDUCTION
        sound.Pitch = sound.Pitch * 0.9 -- Slightly lower pitch
    end

    -- Position sound in 3D space
    if position and SOUND_CONFIG.ENABLE_3D_AUDIO then
        self:position3DSound(sound, position)
    end

    -- Apply weapon-specific effects
    self:applyWeaponEffects(sound, weaponName, soundType)

    -- Play sound
    sound:Play()

    -- Track active sound
    table.insert(self.activeSounds, sound)

    return sound
end

-- Play impact sound based on material
function AdvancedSoundSystem:playImpactSound(material, position, intensity)
    local soundId = SOUND_DATABASE.IMPACTS[material] or SOUND_DATABASE.IMPACTS[Enum.Material.Concrete]

    local sound = self:createSound(soundId, "Environment")
    sound.Volume = math.min(intensity or 1.0, 1.0)

    -- Position in 3D space
    if position and SOUND_CONFIG.ENABLE_3D_AUDIO then
        self:position3DSound(sound, position)
    end

    -- Apply material-specific effects
    self:applyMaterialEffects(sound, material)

    sound:Play()
    table.insert(self.activeSounds, sound)

    return sound
end

-- Play bullet whiz/crack sounds
function AdvancedSoundSystem:playBulletAudio(bulletPosition, bulletVelocity, playerPosition)
    if not SOUND_CONFIG.ENABLE_3D_AUDIO then return end

    local distance = (bulletPosition - playerPosition).Magnitude

    -- Bullet whiz (close pass)
    if distance < SOUND_CONFIG.BULLET_WHIZ_DISTANCE then
        local whizSound = self:createSound(SOUND_DATABASE.ENVIRONMENT.bulletWhiz, "Environment")
        whizSound.Volume = 1.0 - (distance / SOUND_CONFIG.BULLET_WHIZ_DISTANCE)
        self:position3DSound(whizSound, bulletPosition)

        -- Apply doppler effect
        self:applyDopplerEffect(whizSound, bulletVelocity)

        whizSound:Play()
        table.insert(self.activeSounds, whizSound)
    end

    -- Bullet crack (supersonic)
    if bulletVelocity.Magnitude > 343 and distance < SOUND_CONFIG.BULLET_CRACK_DISTANCE then
        local crackSound = self:createSound(SOUND_DATABASE.ENVIRONMENT.bulletCrack, "Environment")
        crackSound.Volume = 0.8 - (distance / SOUND_CONFIG.BULLET_CRACK_DISTANCE)
        self:position3DSound(crackSound, bulletPosition)

        crackSound:Play()
        table.insert(self.activeSounds, crackSound)
    end
end

-- Play UI sound
function AdvancedSoundSystem:playUISound(soundType)
    local soundId = SOUND_DATABASE.UI[soundType]
    if not soundId then return end

    local sound = self:createSound(soundId, "UI")
    sound:Play()

    return sound
end

-- Play event sound
function AdvancedSoundSystem:playEventSound(eventType, position)
    local soundId = SOUND_DATABASE.EVENTS[eventType]
    if not soundId then return end

    local sound = self:createSound(soundId, "Environment")

    if position and SOUND_CONFIG.ENABLE_3D_AUDIO then
        self:position3DSound(sound, position)
    end

    sound:Play()
    table.insert(self.activeSounds, sound)

    return sound
end

-- Create a sound object
function AdvancedSoundSystem:createSound(soundId, groupName)
    -- Check cache first
    local cacheKey = soundId .. "_" .. groupName
    if self.soundCache[cacheKey] then
        local cachedSound = self.soundCache[cacheKey]:Clone()
        return cachedSound
    end

    -- Create new sound
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 1.0
    sound.Pitch = 1.0
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.MaxDistance = SOUND_CONFIG.MAX_AUDIO_DISTANCE

    -- Assign to sound group
    if self.soundGroups[groupName] then
        sound.SoundGroup = self.soundGroups[groupName]
    end

    -- Cache the sound
    self.soundCache[cacheKey] = sound:Clone()

    return sound
end

-- Position sound in 3D space
function AdvancedSoundSystem:position3DSound(sound, position)
    if not self.player.Character or not self.player.Character.PrimaryPart then
        return
    end

    -- Create attachment for 3D positioning
    local attachment = Instance.new("Attachment")
    attachment.WorldPosition = position
    attachment.Parent = workspace.Terrain

    sound.Parent = attachment

    -- Calculate 3D audio properties
    local listenerPos = self.camera.CFrame.Position
    local distance = (position - listenerPos).Magnitude

    -- Apply distance attenuation
    local attenuation = math.max(0, 1 - (distance / SOUND_CONFIG.MAX_AUDIO_DISTANCE))
    sound.Volume = sound.Volume * attenuation

    -- Clean up attachment after sound ends
    game:GetService("Debris"):AddItem(attachment, sound.TimeLength + 1)
end

-- Apply weapon-specific effects
function AdvancedSoundSystem:applyWeaponEffects(sound, weaponName, soundType)
    -- Different weapons have different characteristics
    if weaponName:find("Sniper") or weaponName == "AWP" then
        -- Sniper rifles are louder and have more echo
        sound.Volume = sound.Volume * 1.3
        if soundType == "fire" then
            sound.ReverbSoundEffect.Enabled = true
            sound.ReverbSoundEffect.WetLevel = 0.4
        end
    elseif weaponName:find("Pistol") or weaponName == "M9" then
        -- Pistols are sharper, less bass
        sound.Pitch = sound.Pitch * 1.1
        if sound:FindFirstChild("EqualizerSoundEffect") then
            sound.EqualizerSoundEffect.HighGain = 2
            sound.EqualizerSoundEffect.LowGain = -3
        end
    elseif weaponName:find("SMG") or weaponName:find("MP") then
        -- SMGs have higher rate of fire characteristics
        sound.Pitch = sound.Pitch * 1.05
    end
end

-- Apply material-specific effects
function AdvancedSoundSystem:applyMaterialEffects(sound, material)
    if material == Enum.Material.Metal then
        -- Metallic ring
        sound.Pitch = sound.Pitch * 1.2
        if sound:FindFirstChild("ReverbSoundEffect") then
            sound.ReverbSoundEffect.WetLevel = 0.3
        end
    elseif material == Enum.Material.Glass then
        -- Glass shatter
        sound.Pitch = sound.Pitch * 1.4
        sound.Volume = sound.Volume * 0.8
    elseif material == Enum.Material.Wood then
        -- Woody thunk
        sound.Pitch = sound.Pitch * 0.8
    elseif material == Enum.Material.Concrete then
        -- Concrete crack
        if sound:FindFirstChild("ReverbSoundEffect") then
            sound.ReverbSoundEffect.WetLevel = 0.4
            sound.ReverbSoundEffect.DryLevel = 0.6
        end
    end
end

-- Apply doppler effect for moving sounds
function AdvancedSoundSystem:applyDopplerEffect(sound, velocity)
    if not SOUND_CONFIG.ENABLE_3D_AUDIO then return end

    local speedOfSound = 343 -- m/s
    local listenerVel = self.audioListener.velocity or Vector3.new(0, 0, 0)

    -- Calculate relative velocity
    local relativeVelocity = velocity - listenerVel
    local speed = relativeVelocity.Magnitude

    -- Apply doppler shift
    local dopplerFactor = (speedOfSound + listenerVel.Magnitude) / (speedOfSound + speed)
    sound.Pitch = sound.Pitch * math.min(dopplerFactor, 2.0) -- Cap at 2x pitch
end

-- Update audio listener position
function AdvancedSoundSystem:updateAudioListener()
    if not self.camera then return end

    local oldPosition = self.audioListener.position
    local newPosition = self.camera.CFrame.Position

    -- Calculate velocity
    self.audioListener.velocity = (newPosition - oldPosition) / (1/60) -- Assuming 60 FPS
    self.audioListener.position = newPosition
    self.audioListener.orientation = self.camera.CFrame.LookVector
end

-- Apply environmental reverb based on surroundings
function AdvancedSoundSystem:updateEnvironmentalAudio()
    if not self.player.Character or not self.player.Character.PrimaryPart then
        return
    end

    local playerPos = self.player.Character.PrimaryPart.Position

    -- Simple environment detection (could be expanded)
    local reverbType = Enum.ReverbType.NoReverb

    -- Check for enclosed spaces (simplified)
    local rayResults = {}
    local directions = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 1, 0),
        Vector3.new(0, -1, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1)
    }

    for _, direction in ipairs(directions) do
        local rayResult = workspace:Raycast(playerPos, direction * 20)
        if rayResult then
            table.insert(rayResults, rayResult.Distance)
        else
            table.insert(rayResults, 20)
        end
    end

    -- Calculate average distance to walls
    local avgDistance = 0
    for _, distance in ipairs(rayResults) do
        avgDistance = avgDistance + distance
    end
    avgDistance = avgDistance / #rayResults

    -- Set reverb based on space size
    if avgDistance < 5 then
        reverbType = Enum.ReverbType.Room
    elseif avgDistance < 10 then
        reverbType = Enum.ReverbType.Hall
    elseif avgDistance < 15 then
        reverbType = Enum.ReverbType.Arena
    else
        reverbType = Enum.ReverbType.Outdoor
    end

    -- Apply reverb if changed
    if SoundService.AmbientReverb ~= reverbType then
        SoundService.AmbientReverb = reverbType
    end
end

-- Start main update loop
function AdvancedSoundSystem:startUpdateLoop()
    RunService.Heartbeat:Connect(function()
        self:update()
    end)
end

-- Main update function
function AdvancedSoundSystem:update()
    -- Update audio listener
    if SOUND_CONFIG.ENABLE_3D_AUDIO then
        self:updateAudioListener()
    end

    -- Update environmental audio
    if SOUND_CONFIG.ENABLE_REVERB then
        self:updateEnvironmentalAudio()
    end

    -- Clean up finished sounds
    self:cleanupFinishedSounds()
end

-- Clean up finished sounds
function AdvancedSoundSystem:cleanupFinishedSounds()
    for i = #self.activeSounds, 1, -1 do
        local sound = self.activeSounds[i]
        if not sound.IsPlaying then
            -- Clean up sound and its parent
            if sound.Parent and sound.Parent:IsA("Attachment") then
                sound.Parent:Destroy()
            elseif sound.Parent then
                sound:Destroy()
            end
            table.remove(self.activeSounds, i)
        end
    end
end

-- Set master volume
function AdvancedSoundSystem:setMasterVolume(volume)
    SOUND_CONFIG.MASTER_VOLUME = math.clamp(volume, 0, 1)
    SoundService.MasterVolume = SOUND_CONFIG.MASTER_VOLUME
end

-- Set category volume
function AdvancedSoundSystem:setCategoryVolume(category, volume)
    volume = math.clamp(volume, 0, 1)

    if category == "SFX" then
        SOUND_CONFIG.SFX_VOLUME = volume
        if self.soundGroups.Weapons then
            self.soundGroups.Weapons.Volume = volume
        end
        if self.soundGroups.Environment then
            self.soundGroups.Environment.Volume = volume
        end
    elseif category == "Music" then
        SOUND_CONFIG.MUSIC_VOLUME = volume
        if self.soundGroups.Music then
            self.soundGroups.Music.Volume = volume
        end
    elseif category == "Voice" then
        SOUND_CONFIG.VOICE_VOLUME = volume
        if self.soundGroups.Voice then
            self.soundGroups.Voice.Volume = volume
        end
    end
end

-- Enable/disable 3D audio
function AdvancedSoundSystem:set3DAudio(enabled)
    SOUND_CONFIG.ENABLE_3D_AUDIO = enabled

    if not enabled then
        -- Stop all 3D positioned sounds
        for _, sound in ipairs(self.activeSounds) do
            if sound.Parent and sound.Parent:IsA("Attachment") then
                sound.Parent = workspace
            end
        end
    end
end

-- Get current configuration
function AdvancedSoundSystem:getConfiguration()
    return {
        masterVolume = SOUND_CONFIG.MASTER_VOLUME,
        sfxVolume = SOUND_CONFIG.SFX_VOLUME,
        musicVolume = SOUND_CONFIG.MUSIC_VOLUME,
        voiceVolume = SOUND_CONFIG.VOICE_VOLUME,
        enable3DAudio = SOUND_CONFIG.ENABLE_3D_AUDIO,
        enableReverb = SOUND_CONFIG.ENABLE_REVERB
    }
end

-- Cleanup
function AdvancedSoundSystem:cleanup()
    -- Stop all active sounds
    for _, sound in ipairs(self.activeSounds) do
        sound:Stop()
        if sound.Parent and sound.Parent:IsA("Attachment") then
            sound.Parent:Destroy()
        end
    end

    -- Clear caches
    self.activeSounds = {}
    self.soundCache = {}

    -- Reset SoundService
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    SoundService.MasterVolume = 1.0
end

return AdvancedSoundSystem