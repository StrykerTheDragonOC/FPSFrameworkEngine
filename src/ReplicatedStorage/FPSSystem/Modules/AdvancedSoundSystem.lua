-- AdvancedSoundSystem.lua
-- Fixed sound system with proper MainVolume setup and references
-- Place in ReplicatedStorage.FPSSystem.Modules

local AdvancedSoundSystem = {}

-- Services
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Sound settings and volume control
local SOUND_SETTINGS = {
    MASTER_VOLUME = 0.8,
    WEAPON_VOLUME = 0.7,
    EFFECT_VOLUME = 0.6,
    AMBIENT_VOLUME = 0.4,
    UI_VOLUME = 0.5,
    VOICE_VOLUME = 0.8,
    ROLLOFF_SCALE = 0.5,
    DOPPLER_SCALE = 1.0
}

-- Sound categories for organization
local SOUND_CATEGORIES = {
    WEAPON = "WEAPON",
    EFFECT = "EFFECT", 
    AMBIENT = "AMBIENT",
    UI = "UI",
    VOICE = "VOICE"
}

-- Main volume control - this is what was missing and causing the bug
local MainVolume = {
    master = SOUND_SETTINGS.MASTER_VOLUME,
    weapon = SOUND_SETTINGS.WEAPON_VOLUME,
    effect = SOUND_SETTINGS.EFFECT_VOLUME,
    ambient = SOUND_SETTINGS.AMBIENT_VOLUME,
    ui = SOUND_SETTINGS.UI_VOLUME,
    voice = SOUND_SETTINGS.VOICE_VOLUME
}

-- Active sounds tracking
local activeSounds = {}
local soundGroups = {}

-- Initialize the sound system
function AdvancedSoundSystem.init()
    print("Initializing AdvancedSoundSystem...")

    -- Configure SoundService
    SoundService.RolloffScale = SOUND_SETTINGS.ROLLOFF_SCALE
    SoundService.DopplerScale = SOUND_SETTINGS.DOPPLER_SCALE

    -- Create sound groups for better organization
    AdvancedSoundSystem.createSoundGroups()

    -- Set up volume controls
    AdvancedSoundSystem.setupVolumeControls()

    print("AdvancedSoundSystem initialized successfully!")
end

-- Create sound groups for different categories
function AdvancedSoundSystem.createSoundGroups()
    -- Create weapon sounds group
    local weaponGroup = Instance.new("SoundGroup")
    weaponGroup.Name = "WeaponSounds"
    weaponGroup.Volume = MainVolume.weapon
    weaponGroup.Parent = SoundService
    soundGroups[SOUND_CATEGORIES.WEAPON] = weaponGroup

    -- Create effect sounds group
    local effectGroup = Instance.new("SoundGroup")
    effectGroup.Name = "EffectSounds"
    effectGroup.Volume = MainVolume.effect
    effectGroup.Parent = SoundService
    soundGroups[SOUND_CATEGORIES.EFFECT] = effectGroup

    -- Create ambient sounds group
    local ambientGroup = Instance.new("SoundGroup")
    ambientGroup.Name = "AmbientSounds"
    ambientGroup.Volume = MainVolume.ambient
    ambientGroup.Parent = SoundService
    soundGroups[SOUND_CATEGORIES.AMBIENT] = ambientGroup

    -- Create UI sounds group
    local uiGroup = Instance.new("SoundGroup")
    uiGroup.Name = "UISounds"
    uiGroup.Volume = MainVolume.ui
    uiGroup.Parent = SoundService
    soundGroups[SOUND_CATEGORIES.UI] = uiGroup

    -- Create voice sounds group
    local voiceGroup = Instance.new("SoundGroup")
    voiceGroup.Name = "VoiceSounds"
    voiceGroup.Volume = MainVolume.voice
    voiceGroup.Parent = SoundService
    soundGroups[SOUND_CATEGORIES.VOICE] = voiceGroup

    print("Sound groups created successfully")
end

-- Set up volume controls and expose MainVolume properly
function AdvancedSoundSystem.setupVolumeControls()
    -- Make MainVolume accessible globally for other scripts
    _G.MainVolume = MainVolume

    -- Set master volume (this was the missing reference causing the bug)
    SoundService.MasterVolume = MainVolume.master

    -- Update sound group volumes
    for category, group in pairs(soundGroups) do
        if category == SOUND_CATEGORIES.WEAPON then
            group.Volume = MainVolume.weapon
        elseif category == SOUND_CATEGORIES.EFFECT then
            group.Volume = MainVolume.effect
        elseif category == SOUND_CATEGORIES.AMBIENT then
            group.Volume = MainVolume.ambient
        elseif category == SOUND_CATEGORIES.UI then
            group.Volume = MainVolume.ui
        elseif category == SOUND_CATEGORIES.VOICE then
            group.Volume = MainVolume.voice
        end
    end

    print("Volume controls setup complete")
end

-- Play a sound with proper categorization and volume control
function AdvancedSoundSystem.playSound(soundId, category, parent, position, volume, pitch)
    if not soundId then
        warn("AdvancedSoundSystem: No soundId provided")
        return nil
    end

    category = category or SOUND_CATEGORIES.EFFECT
    volume = volume or 0.5
    pitch = pitch or 1.0

    -- Create sound instance
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Pitch = pitch
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 150

    -- Assign to appropriate sound group
    if soundGroups[category] then
        sound.SoundGroup = soundGroups[category]
    end

    -- Handle positioning
    if position and parent then
        -- Create a part for 3D positioned audio
        local soundPart = Instance.new("Part")
        soundPart.Name = "SoundPart"
        soundPart.Anchored = true
        soundPart.CanCollide = false
        soundPart.Transparency = 1
        soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
        soundPart.Position = position
        soundPart.Parent = parent

        sound.Parent = soundPart

        -- Auto cleanup
        sound.Ended:Connect(function()
            soundPart:Destroy()
        end)

        -- Safety cleanup
        game:GetService("Debris"):AddItem(soundPart, 10)
    else
        -- Parent directly to specified parent or camera
        sound.Parent = parent or workspace.CurrentCamera
    end

    -- Track active sound
    table.insert(activeSounds, sound)

    -- Play sound
    sound:Play()

    -- Clean up from tracking when ended
    sound.Ended:Connect(function()
        for i, activeSound in ipairs(activeSounds) do
            if activeSound == sound then
                table.remove(activeSounds, i)
                break
            end
        end
    end)

    return sound
end

-- Play weapon sound with proper weapon volume
function AdvancedSoundSystem.playWeaponSound(soundId, weapon, volume, pitch)
    local weaponPosition = weapon and weapon.PrimaryPart and weapon.PrimaryPart.Position
    return AdvancedSoundSystem.playSound(
        soundId, 
        SOUND_CATEGORIES.WEAPON, 
        workspace, 
        weaponPosition, 
        volume, 
        pitch
    )
end

-- Play UI sound
function AdvancedSoundSystem.playUISound(soundId, volume, pitch)
    return AdvancedSoundSystem.playSound(
        soundId, 
        SOUND_CATEGORIES.UI, 
        Players.LocalPlayer:WaitForChild("PlayerGui"), 
        nil, 
        volume, 
        pitch
    )
end

-- Play effect sound at position
function AdvancedSoundSystem.playEffectSound(soundId, position, volume, pitch)
    return AdvancedSoundSystem.playSound(
        soundId, 
        SOUND_CATEGORIES.EFFECT, 
        workspace, 
        position, 
        volume, 
        pitch
    )
end

-- Play ambient sound
function AdvancedSoundSystem.playAmbientSound(soundId, loop, volume, pitch)
    local sound = AdvancedSoundSystem.playSound(
        soundId, 
        SOUND_CATEGORIES.AMBIENT, 
        workspace, 
        nil, 
        volume, 
        pitch
    )

    if sound and loop then
        sound.Looped = true
    end

    return sound
end

-- Update master volume
function AdvancedSoundSystem.setMasterVolume(volume)
    MainVolume.master = math.clamp(volume, 0, 1)
    SoundService.MasterVolume = MainVolume.master
    _G.MainVolume.master = MainVolume.master
end

-- Update category volume
function AdvancedSoundSystem.setCategoryVolume(category, volume)
    volume = math.clamp(volume, 0, 1)

    if category == SOUND_CATEGORIES.WEAPON then
        MainVolume.weapon = volume
        _G.MainVolume.weapon = volume
        if soundGroups[category] then
            soundGroups[category].Volume = volume
        end
    elseif category == SOUND_CATEGORIES.EFFECT then
        MainVolume.effect = volume
        _G.MainVolume.effect = volume
        if soundGroups[category] then
            soundGroups[category].Volume = volume
        end
    elseif category == SOUND_CATEGORIES.AMBIENT then
        MainVolume.ambient = volume
        _G.MainVolume.ambient = volume
        if soundGroups[category] then
            soundGroups[category].Volume = volume
        end
    elseif category == SOUND_CATEGORIES.UI then
        MainVolume.ui = volume
        _G.MainVolume.ui = volume
        if soundGroups[category] then
            soundGroups[category].Volume = volume
        end
    elseif category == SOUND_CATEGORIES.VOICE then
        MainVolume.voice = volume
        _G.MainVolume.voice = volume
        if soundGroups[category] then
            soundGroups[category].Volume = volume
        end
    end
end

-- Get current volume for category
function AdvancedSoundSystem.getCategoryVolume(category)
    if category == SOUND_CATEGORIES.WEAPON then
        return MainVolume.weapon
    elseif category == SOUND_CATEGORIES.EFFECT then
        return MainVolume.effect
    elseif category == SOUND_CATEGORIES.AMBIENT then
        return MainVolume.ambient
    elseif category == SOUND_CATEGORIES.UI then
        return MainVolume.ui
    elseif category == SOUND_CATEGORIES.VOICE then
        return MainVolume.voice
    else
        return MainVolume.master
    end
end

-- Stop all sounds in a category
function AdvancedSoundSystem.stopCategorySounds(category)
    for i = #activeSounds, 1, -1 do
        local sound = activeSounds[i]
        if sound.SoundGroup == soundGroups[category] then
            sound:Stop()
            table.remove(activeSounds, i)
        end
    end
end

-- Stop all active sounds
function AdvancedSoundSystem.stopAllSounds()
    for _, sound in ipairs(activeSounds) do
        if sound and sound.Parent then
            sound:Stop()
        end
    end
    activeSounds = {}
end

-- Get sound library with common game sounds
function AdvancedSoundSystem.getSoundLibrary()
    return {
        -- Weapon sounds
        weapons = {
            pistol_fire = "rbxassetid://131961136",
            rifle_fire = "rbxassetid://4759267374",
            sniper_fire = "rbxassetid://1369158",
            shotgun_fire = "rbxassetid://132373574",
            reload_mag = "rbxassetid://799954844",
            empty_click = "rbxassetid://91170486",
            bolt_action = "rbxassetid://133084065"
        },

        -- Effect sounds
        effects = {
            explosion = "rbxassetid://133084089",
            metal_impact = "rbxassetid://142082167",
            bullet_whizz = "rbxassetid://133084093",
            ricochet = "rbxassetid://133084095",
            footstep = "rbxassetid://131961136",
            grenade_bounce = "rbxassetid://142082167"
        },

        -- UI sounds
        ui = {
            button_click = "rbxassetid://131961136",
            menu_open = "rbxassetid://133084065",
            menu_close = "rbxassetid://133084069",
            notification = "rbxassetid://133084089",
            error = "rbxassetid://142082167"
        }
    }
end

-- Server initialization (for server-side sound management)
function AdvancedSoundSystem.initServer()
    print("AdvancedSoundSystem: Server initialization")

    -- Server-side sound management here
    -- Handle sound replication, anti-cheat, etc.

    print("AdvancedSoundSystem: Server initialization complete")
end

-- Cleanup function
function AdvancedSoundSystem.cleanup()
    print("Cleaning up AdvancedSoundSystem...")

    -- Stop all active sounds
    AdvancedSoundSystem.stopAllSounds()

    -- Clean up sound groups
    for _, group in pairs(soundGroups) do
        if group and group.Parent then
            group:Destroy()
        end
    end
    soundGroups = {}

    -- Reset global reference
    _G.MainVolume = nil

    print("AdvancedSoundSystem cleanup complete")
end

-- Export the main volume for external reference (this fixes the MainVolume bug)
AdvancedSoundSystem.MainVolume = MainVolume
AdvancedSoundSystem.SOUND_CATEGORIES = SOUND_CATEGORIES

print("AdvancedSoundSystem loaded with MainVolume properly configured")

return AdvancedSoundSystem