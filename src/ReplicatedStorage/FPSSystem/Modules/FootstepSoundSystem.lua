-- FootstepSoundSystem.lua
-- Material-based footstep sound system for FPS game
-- Place in ReplicatedStorage.FPSSystem.Modules.FootstepSoundSystem

local FootstepSoundSystem = {}
FootstepSoundSystem.__index = FootstepSoundSystem

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Sound configurations for different materials
local MATERIAL_SOUNDS = {
    -- Hard surfaces
    [Enum.Material.Concrete] = {
        soundIds = {
            "rbxasset://sounds/footsteps/concrete_1.mp3",
            "rbxasset://sounds/footsteps/concrete_2.mp3", 
            "rbxasset://sounds/footsteps/concrete_3.mp3",
            "rbxasset://sounds/footsteps/concrete_4.mp3"
        },
        volume = {min = 0.3, max = 0.5},
        pitch = {min = 0.8, max = 1.2},
        rollOff = 50
    },
    
    [Enum.Material.Asphalt] = {
        soundIds = {
            "rbxasset://sounds/footsteps/concrete_1.mp3",
            "rbxasset://sounds/footsteps/concrete_2.mp3",
            "rbxasset://sounds/footsteps/concrete_3.mp3"
        },
        volume = {min = 0.2, max = 0.4},
        pitch = {min = 0.9, max = 1.1},
        rollOff = 45
    },
    
    [Enum.Material.Brick] = {
        soundIds = {
            "rbxasset://sounds/footsteps/concrete_1.mp3",
        },
        volume = {min = 0.35, max = 0.55},
        pitch = {min = 0.7, max = 1.0},
        rollOff = 50
    },
    
    [Enum.Material.Cobblestone] = {
        soundIds = {
            "rbxasset://sounds/footsteps/concrete_1.mp3",
        },
        volume = {min = 0.4, max = 0.6},
        pitch = {min = 0.8, max = 1.3},
        rollOff = 55
    },
    
    -- Metal surfaces
    [Enum.Material.Metal] = {
        soundIds = {
            "rbxassetid://131961136", -- Metal clang 1
        
        },
        volume = {min = 0.4, max = 0.7},
        pitch = {min = 1.0, max = 1.4},
        rollOff = 60
    },
    
    [Enum.Material.CorrodedMetal] = {
        soundIds = {
            "rbxassetid://131961136",
            "rbxassetid://131961140"
        },
        volume = {min = 0.3, max = 0.6},
        pitch = {min = 0.7, max = 1.1},
        rollOff = 55
    },
    
    -- Natural surfaces
    [Enum.Material.Grass] = {
        soundIds = {
            "rbxassetid://2670692779", -- Grass step 1
  
        },
        volume = {min = 0.15, max = 0.3},
        pitch = {min = 0.9, max = 1.2},
        rollOff = 35
    },
    
    [Enum.Material.LeafyGrass] = {
        soundIds = {
            "rbxassetid://2670692779",
      
        },
        volume = {min = 0.2, max = 0.35},
        pitch = {min = 0.8, max = 1.3},
        rollOff = 40
    },
    
    [Enum.Material.Sand] = {
        soundIds = {
            "rbxassetid://2670693564", -- Sand step 1
    
        },
        volume = {min = 0.2, max = 0.4},
        pitch = {min = 0.8, max = 1.1},
        rollOff = 30
    },
    
    [Enum.Material.Rock] = {
        soundIds = {
            "rbxassetid://2670694065",
        },
        volume = {min = 0.3, max = 0.5},
        pitch = {min = 0.7, max = 1.2},
        rollOff = 50
    },
    
    [Enum.Material.Limestone] = {
        soundIds = {
            "rbxassetid://2670694065",
        },
        volume = {min = 0.25, max = 0.45},
        pitch = {min = 0.8, max = 1.1},
        rollOff = 45
    },
    
    -- Wood surfaces
    [Enum.Material.Wood] = {
        soundIds = {
            "rbxassetid://2670694594", -- Wood step 1
    
        },
        volume = {min = 0.3, max = 0.5},
        pitch = {min = 0.9, max = 1.3},
        rollOff = 45
    },
    
    [Enum.Material.WoodPlanks] = {
        soundIds = {
            "rbxassetid://2670694939"
        },
        volume = {min = 0.35, max = 0.55},
        pitch = {min = 1.0, max = 1.4},
        rollOff = 50
    },
    
    -- Water
    [Enum.Material.Water] = {
        soundIds = {
            "rbxassetid://2670695271", -- Water splash 1
            "rbxassetid://2670695435", -- Water splash 2
            "rbxassetid://2670695593"  -- Water splash 3
        },
        volume = {min = 0.4, max = 0.7},
        pitch = {min = 0.8, max = 1.2},
        rollOff = 60
    },
    
    -- Fabric/Soft
    [Enum.Material.Fabric] = {
        soundIds = {
            "rbxassetid://2670695756", -- Soft step 1
        },
        volume = {min = 0.1, max = 0.25},
        pitch = {min = 0.9, max = 1.1},
        rollOff = 25
    },
    
    -- Glass
    [Enum.Material.Glass] = {
        soundIds = {
            "rbxassetid://2670696084", -- Glass step 1
        },
        volume = {min = 0.3, max = 0.5},
        pitch = {min = 1.0, max = 1.5},
        rollOff = 55
    },
    
    -- Default fallback
    [Enum.Material.Plastic] = {
        soundIds = {
            "rbxasset://sounds/footsteps/concrete_1.mp3",
        },
        volume = {min = 0.2, max = 0.4},
        pitch = {min = 0.9, max = 1.1},
        rollOff = 40
    }
}

-- Movement type modifiers
local MOVEMENT_MODIFIERS = {
    Walking = {
        volumeMultiplier = 1.0,
        pitchMultiplier = 1.0,
        stepInterval = 0.5
    },
    Running = {
        volumeMultiplier = 1.3,
        pitchMultiplier = 1.1,
        stepInterval = 0.35
    },
    Sprinting = {
        volumeMultiplier = 1.6,
        pitchMultiplier = 1.2,
        stepInterval = 0.25
    },
    Crouching = {
        volumeMultiplier = 0.4,
        pitchMultiplier = 0.8,
        stepInterval = 0.7
    }
}

function FootstepSoundSystem.new()
    local self = setmetatable({}, FootstepSoundSystem)
    
    -- Player tracking
    self.playerData = {}
    self.connections = {}
    
    return self
end

function FootstepSoundSystem:initialize()
    print("[FootstepSoundSystem] Initializing footstep sound system...")
    
    -- Setup for all players
    self:setupPlayerConnections()
    
    print("[FootstepSoundSystem] Footstep sound system initialized")
    return true
end

function FootstepSoundSystem:setupPlayerConnections()
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:setupPlayerFootsteps(player)
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:setupPlayerFootsteps(player)
    end)
    
    -- Handle leaving players
    Players.PlayerRemoving:Connect(function(player)
        self:cleanupPlayer(player)
    end)
end

function FootstepSoundSystem:setupPlayerFootsteps(player)
    -- Wait for character
    if player.Character then
        self:onCharacterAdded(player, player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        self:onCharacterAdded(player, character)
    end)
    
    player.CharacterRemoving:Connect(function(character)
        self:onCharacterRemoving(player, character)
    end)
end

function FootstepSoundSystem:onCharacterAdded(player, character)
    -- Wait for essential parts
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Initialize player data
    self.playerData[player.UserId] = {
        character = character,
        humanoidRootPart = humanoidRootPart,
        humanoid = humanoid,
        lastStepTime = 0,
        lastPosition = humanoidRootPart.Position,
        isMoving = false,
        movementType = "Walking"
    }
    
    -- Start footstep tracking
    self:startFootstepTracking(player)
    
    print("[FootstepSoundSystem] Setup footsteps for player:", player.Name)
end

function FootstepSoundSystem:onCharacterRemoving(player, character)
    if self.connections[player.UserId] then
        self.connections[player.UserId]:Disconnect()
        self.connections[player.UserId] = nil
    end
    
    self.playerData[player.UserId] = nil
end

function FootstepSoundSystem:startFootstepTracking(player)
    local playerData = self.playerData[player.UserId]
    if not playerData then return end
    
    -- Disconnect existing connection
    if self.connections[player.UserId] then
        self.connections[player.UserId]:Disconnect()
    end
    
    -- Create new tracking connection
    self.connections[player.UserId] = RunService.Heartbeat:Connect(function()
        self:updatePlayerFootsteps(player)
    end)
end

function FootstepSoundSystem:updatePlayerFootsteps(player)
    local playerData = self.playerData[player.UserId]
    if not playerData or not playerData.character.Parent then
        return
    end
    
    local humanoidRootPart = playerData.humanoidRootPart
    local humanoid = playerData.humanoid
    
    -- Check if player is moving
    local currentPosition = humanoidRootPart.Position
    local distance = (currentPosition - playerData.lastPosition).Magnitude
    local isMoving = distance > 0.1 and humanoid.MoveDirection.Magnitude > 0.1
    
    -- Determine movement type
    local movementType = self:getMovementType(humanoid)
    playerData.movementType = movementType
    
    -- Check if we should play a footstep
    if isMoving then
        local currentTime = tick()
        local stepInterval = MOVEMENT_MODIFIERS[movementType].stepInterval
        
        if currentTime - playerData.lastStepTime >= stepInterval then
            self:playFootstepSound(player, currentPosition)
            playerData.lastStepTime = currentTime
        end
    end
    
    -- Update tracking data
    playerData.lastPosition = currentPosition
    playerData.isMoving = isMoving
end

function FootstepSoundSystem:getMovementType(humanoid)
    local walkSpeed = humanoid.WalkSpeed
    local moveVector = humanoid.MoveDirection.Magnitude
    
    if moveVector == 0 then
        return "Standing"
    elseif walkSpeed <= 8 then
        return "Crouching"
    elseif walkSpeed <= 16 then
        return "Walking"
    elseif walkSpeed <= 24 then
        return "Running"
    else
        return "Sprinting"
    end
end

function FootstepSoundSystem:playFootstepSound(player, position)
    -- Raycast downward to detect surface material
    local rayDirection = Vector3.new(0, -10, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local raycastResult = workspace:Raycast(position, rayDirection, raycastParams)
    
    local material = Enum.Material.Plastic -- Default
    if raycastResult and raycastResult.Instance then
        material = raycastResult.Instance.Material
    end
    
    -- Get sound configuration for material
    local soundConfig = MATERIAL_SOUNDS[material] or MATERIAL_SOUNDS[Enum.Material.Plastic]
    local playerData = self.playerData[player.UserId]
    local movementModifier = MOVEMENT_MODIFIERS[playerData.movementType] or MOVEMENT_MODIFIERS.Walking
    
    -- Choose random sound from material pool
    local soundId = soundConfig.soundIds[math.random(1, #soundConfig.soundIds)]
    
    -- Create and configure sound
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = math.random(soundConfig.volume.min * 100, soundConfig.volume.max * 100) / 100
    sound.Volume = sound.Volume * movementModifier.volumeMultiplier
    sound.PlaybackSpeed = math.random(soundConfig.pitch.min * 100, soundConfig.pitch.max * 100) / 100
    sound.PlaybackSpeed = sound.PlaybackSpeed * movementModifier.pitchMultiplier
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.MaxDistance = soundConfig.rollOff
    sound.Parent = playerData.humanoidRootPart
    
    -- Play sound and cleanup
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    -- Cleanup after max duration
    game:GetService("Debris"):AddItem(sound, 3)
    
    -- Debug output (remove in production)
    if game:GetService("RunService"):IsStudio() then
        print(string.format("[FootstepSoundSystem] %s footstep on %s (Vol: %.2f, Pitch: %.2f)", 
            player.Name, material.Name, sound.Volume, sound.PlaybackSpeed))
    end
end

function FootstepSoundSystem:setPlayerMovementType(player, movementType)
    local playerData = self.playerData[player.UserId]
    if playerData then
        playerData.movementType = movementType
    end
end

function FootstepSoundSystem:cleanupPlayer(player)
    if self.connections[player.UserId] then
        self.connections[player.UserId]:Disconnect()
        self.connections[player.UserId] = nil
    end
    
    self.playerData[player.UserId] = nil
    print("[FootstepSoundSystem] Cleaned up footsteps for player:", player.Name)
end

function FootstepSoundSystem:cleanup()
    -- Disconnect all connections
    for userId, connection in pairs(self.connections) do
        connection:Disconnect()
    end
    
    self.connections = {}
    self.playerData = {}
    
    print("[FootstepSoundSystem] Footstep system cleaned up")
end

return FootstepSoundSystem