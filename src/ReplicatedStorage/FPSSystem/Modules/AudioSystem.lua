local AudioSystem = {}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Audio configuration
local AUDIO_CONFIG = {
	MasterVolume = 1.0,
	SFXVolume = 0.8,
	MusicVolume = 0.6,
	VoiceVolume = 0.9,
	
	-- 3D Audio settings
	Enable3DAudio = true,
	MaxDistance = 150,
	RollOffMode = Enum.RollOffMode.InverseTapered,
	
	-- Footstep settings
	FootstepVolume = 0.4,
	FootstepMaxDistance = 25,
	MaterialSounds = true,
	
	-- Bullet audio settings
	BulletWhizzDistance = 50,
	BulletWhizzVolume = 0.3,
	
	-- Environment audio
	ReverbEnabled = true,
	OcclusionEnabled = true,
	DopplerEnabled = false
}

-- Sound libraries
local SOUND_LIBRARY = {
	-- Weapon Sounds
	WeaponFire = {
        G36 = "rbxassetid://4759267374",
        M9 = "rbxassetid://94221465811439",
        Reload = "rbxassetid://138084889"
	},
	
	-- Hit Sounds
	Hit = {
        Flesh = "rbxassetid://144884872",
        Headshot = "rbxassetid://5764885315",
        Metal = "rbxassetid://7842407284",
        Wood = "rbxassetid://8394333801"
	},
	
	-- UI Sounds
	UI = {
        Click = "rbxassetid://6895079853",
        Hover = "rbxassetid://10066931761",
        Purchase = "rbxassetid://10066947742",
        Error = "rbxassetid://654933750"
	},
	
	-- Game Sounds
	Game = {
        LevelUp = "rbxassetid://3120909354",
        KillStreak = "rbxassetid://96987276577256",
        Death = "rbxassetid://135021800852257",
        Spawn = "rbxassetid://18218931770",
        MatchStart = "rbxassetid://140419294351439",
        MatchEnd = "rbxassetid://140419294351439"
	},
	
	-- Movement Sounds
	Movement = {
        Footstep = "rbxassetid://18233024046",
        Jump = "rbxassetid://9114890978",
        Land = "rbxassetid://74054153559436",
        Slide = "rbxassetid://97251745910217"
	},
	
	-- Ambient Sounds
	Ambient = {
        Wind = "rbxassetid://5799870105",
        Explosion = "rbxassetid://5801257793"
	},

	Footsteps = {
		Concrete = {
            Walk = {"rbxassetid://5446226292", "rbxassetid://5446226292", "rbxassetid://5446226292"},
            Run = {"rbxassetid://5446226292", "rbxassetid://5446226292", "rbxassetid://5446226292"},
            Crouch = {"rbxassetid://140071470572800",}
		},
		Grass = {
            Walk = {"rbxassetid://18233024046", "rbxassetid://18233035875", "rbxassetid://111728126261614"},
            Run = {"rbxassetid://18233024046", "rbxassetid://18233035875", "rbxassetid://111728126261614"},
            Crouch = {"rbxassetid://140071470572800",}
		},
		Metal = {
            Walk = {"rbxassetid://129120211828684", "rbxassetid://129120211828684", "rbxassetid://129120211828684"},
            Run = {"rbxassetid://129120211828684", "rbxassetid://129120211828684", "rbxassetid://129120211828684"},
            Crouch = {"rbxassetid://140071470572800",}
		},
		Wood = {
            Walk = {"rbxassetid://88495781201377", "rbxassetid://107620456531285", "rbxassetid://8454543187"},
            Run = {"rbxassetid://88495781201377", "rbxassetid://107620456531285", "rbxassetid://8454543187"},
            Crouch = {"rbxassetid://140071470572800",}
		},
		Water = {
            Walk = {"rbxassetid://122684680935247", "rbxassetid://122684680935247"},
            Run = {"rbxassetid://122684680935247", "rbxassetid://122684680935247"},
            Crouch = {"rbxassetid://122684680935247",}
		}
	},
	
	BulletSounds = {
        Whizz = {"rbxassetid://9113634065", "rbxassetid://9114114275", "rbxassetid://9113634194"},
        Crack = {"rbxassetid://103853016737691", "rbxassetid://103853016737691"},
		Impact = {
            Concrete = {"rbxassetid://142082166", "rbxassetid://78578946566141"},
            Metal = {"rbxassetid://7842407959", "rbxassetid://7130144078"},
            Wood = {"rbxassetid://5645899877", "rbxassetid://8542223682"},
            Flesh = {"rbxassetid://255661850", "rbxassetid://17083833030"}
		}
	},
	
	Environment = {
        Wind = "rbxassetid://5799870105",
        Rain = "rbxassetid://9064263922",
        Thunder = "rbxassetid://4961240438",
        Birds = "rbxassetid://9056670230",
        Crickets = "rbxassetid://9112764573"
	},
	
	Weapons = {
		Reload = {
            Pistol = "rbxassetid://5651440920",
            Rifle = "rbxassetid://4502821590",
            Shotgun = "rbxassetid://200289834",
            Sniper = "rbxassetid://7641927705"
		},
		Equip = {
            Primary = "rbxassetid://7405483764",
            Secondary = "rbxassetid://4549835866",
            Melee = "rbxassetid://7804819456",
            Grenade = "rbxassetid://7804819456"
		},
        Safety = "rbxassetid://8553570529",
        DryFire = "rbxassetid://484110242"
	}
}

-- Active sounds tracking
local activeSounds = {}
local footstepConnections = {}
local lastFootstepTime = {}
local audioZones = {}

function AudioSystem:Initialize()
	-- Setup sound groups
	self:SetupSoundGroups()
	
	-- Setup 3D audio
	self:Setup3DAudio()
	
	-- Setup footstep system
	self:SetupFootstepSystem()
	
	-- Setup bullet audio system
	self:SetupBulletAudio()
	
	-- Setup environment audio
	self:SetupEnvironmentAudio()
	
	-- Setup remote events
	self:SetupRemoteEvents()
	
	-- Setup UI controls
	self:SetupAudioUI()
	
	print("AudioSystem initialized")
end

function AudioSystem:SetupSoundGroups()
	-- Create sound groups for volume control
	local soundGroups = {
		"Master", "SFX", "Music", "Voice", "Footsteps", "Weapons", "Environment"
	}
	
	for _, groupName in pairs(soundGroups) do
		local soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = groupName
		soundGroup.Parent = SoundService
		
		-- Set initial volumes
		if groupName == "Master" then
			soundGroup.Volume = AUDIO_CONFIG.MasterVolume
		elseif groupName == "SFX" or groupName == "Footsteps" or groupName == "Weapons" then
			soundGroup.Volume = AUDIO_CONFIG.SFXVolume
		elseif groupName == "Music" then
			soundGroup.Volume = AUDIO_CONFIG.MusicVolume
		elseif groupName == "Voice" then
			soundGroup.Volume = AUDIO_CONFIG.VoiceVolume
		elseif groupName == "Environment" then
			soundGroup.Volume = AUDIO_CONFIG.SFXVolume * 0.7
		end
	end
	
	-- Set master group as parent for all others
	local masterGroup = SoundService:FindFirstChild("Master")
	if masterGroup then
		for _, group in pairs(SoundService:GetChildren()) do
			if group:IsA("SoundGroup") and group ~= masterGroup then
				group.Parent = masterGroup
			end
		end
	end
end

function AudioSystem:Setup3DAudio()
	if not AUDIO_CONFIG.Enable3DAudio then return end
	
	-- Enable listener
	SoundService.AmbientReverb = Enum.ReverbType.City
	SoundService.DistanceFactor = 3.33
	SoundService.DopplerScale = AUDIO_CONFIG.DopplerEnabled and 1 or 0
	SoundService.RolloffScale = 1
	
	print("3D Audio enabled")
end

function AudioSystem:SetupFootstepSystem()
	-- Track all players
	Players.PlayerAdded:Connect(function(newPlayer)
		self:SetupPlayerFootsteps(newPlayer)
	end)
	
	-- Setup existing players
	for _, existingPlayer in pairs(Players:GetPlayers()) do
		self:SetupPlayerFootsteps(existingPlayer)
	end
	
	-- Cleanup on leave
	Players.PlayerRemoving:Connect(function(leavingPlayer)
		self:CleanupPlayerFootsteps(leavingPlayer)
	end)
end

function AudioSystem:SetupPlayerFootsteps(targetPlayer)
	if footstepConnections[targetPlayer] then
		-- Already setup
		return
	end
	
	local function setupCharacterFootsteps(character)
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end
		
		-- Create footstep sound
		local footstepSound = Instance.new("Sound")
		footstepSound.Name = "FootstepSound"
		footstepSound.Volume = AUDIO_CONFIG.FootstepVolume
		footstepSound.RollOffMode = AUDIO_CONFIG.RollOffMode
		footstepSound.EmitterSize = 2
		footstepSound.SoundGroup = SoundService:FindFirstChild("Footsteps")
		footstepSound.Parent = rootPart
		
		-- Setup 3D properties
		if AUDIO_CONFIG.Enable3DAudio then
			footstepSound.RollOffMode = AUDIO_CONFIG.RollOffMode
			if rootPart:FindFirstChild("FootstepEmitter") then
				rootPart.FootstepEmitter:Destroy()
			end
			local emitter = Instance.new("Attachment")
			emitter.Name = "FootstepEmitter"
			emitter.Parent = rootPart
		end
		
		-- Track movement
		local lastPosition = rootPart.Position
		local lastStepTime = 0
		
		footstepConnections[targetPlayer] = RunService.Heartbeat:Connect(function()
			local currentPosition = rootPart.Position
			local velocity = humanoid.RootPart.Velocity
			local speed = velocity.Magnitude
			local movementDirection = velocity.Unit
			
			-- Check if player is moving
			if speed > 2 and humanoid.Health > 0 then
				local currentTime = tick()
				local humanoidState = humanoid:GetState()
				local stepInterval = self:GetStepInterval(speed, humanoidState)
				
				if currentTime - lastStepTime >= stepInterval then
					self:PlayFootstep(targetPlayer, rootPart, speed, humanoidState)
					lastStepTime = currentTime
				end
			end
		end)
	end
	
	-- Setup for current character
	if targetPlayer.Character then
		setupCharacterFootsteps(targetPlayer.Character)
	end
	
	-- Setup for future characters
	targetPlayer.CharacterAdded:Connect(setupCharacterFootsteps)
end

function AudioSystem:GetStepInterval(speed, state)
	-- Calculate step timing based on movement speed and state
	local baseInterval = 0.5
	
	if state == Enum.HumanoidStateType.Running then
		baseInterval = 0.3
	elseif state == Enum.HumanoidStateType.PlatformStanding then -- Crouch
		baseInterval = 0.8
	end
	
	-- Adjust for speed
	local speedFactor = math.clamp(speed / 16, 0.5, 2)
	return baseInterval / speedFactor
end

function AudioSystem:PlayFootstep(targetPlayer, rootPart, speed, state)
	if not rootPart or not rootPart.Parent then return end
	
	-- Determine surface material
	local material = self:GetSurfaceMaterial(rootPart)
	local materialName = self:MaterialToString(material)
	
	-- Get appropriate sound
	local movementType = "Walk"
	if speed > 12 then
		movementType = "Run"
	elseif state == Enum.HumanoidStateType.PlatformStanding then
		movementType = "Crouch"
	end
	
	local soundList = SOUND_LIBRARY.Footsteps[materialName] and SOUND_LIBRARY.Footsteps[materialName][movementType]
	if not soundList or #soundList == 0 then
		soundList = SOUND_LIBRARY.Footsteps.Concrete[movementType]
	end
	
	local soundId = soundList[math.random(1, #soundList)]
	
	-- Play footstep sound
	local footstepSound = rootPart:FindFirstChild("FootstepSound")
	if footstepSound then
		footstepSound.SoundId = soundId
		footstepSound.Pitch = 0.9 + (math.random() * 0.2) -- Random pitch variation
		
		-- Adjust volume based on movement type and distance
		local baseVolume = AUDIO_CONFIG.FootstepVolume
		if movementType == "Crouch" then
			baseVolume = baseVolume * 0.3
		elseif movementType == "Run" then
			baseVolume = baseVolume * 1.2
		end
		
		-- Distance-based volume for own footsteps
		if targetPlayer == player then
			baseVolume = baseVolume * 0.3 -- Quieter for own footsteps
		end
		
		footstepSound.Volume = baseVolume
		footstepSound:Play()
	end
end

function AudioSystem:GetSurfaceMaterial(rootPart)
	-- Raycast down to determine surface material
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {rootPart.Parent}
	
	local rayResult = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), raycastParams)
	
	if rayResult then
		return rayResult.Instance.Material
	end
	
	return Enum.Material.Concrete -- Default
end

function AudioSystem:MaterialToString(material)
	local materialMap = {
		[Enum.Material.Concrete] = "Concrete",
		[Enum.Material.Brick] = "Concrete", 
		[Enum.Material.Cobblestone] = "Concrete",
		[Enum.Material.Grass] = "Grass",
		[Enum.Material.LeafyGrass] = "Grass",
		[Enum.Material.Ground] = "Grass",
		[Enum.Material.Metal] = "Metal",
		[Enum.Material.CorrodedMetal] = "Metal",
		[Enum.Material.DiamondPlate] = "Metal",
		[Enum.Material.Wood] = "Wood",
		[Enum.Material.WoodPlanks] = "Wood",
		[Enum.Material.Water] = "Water"
	}
	
	return materialMap[material] or "Concrete"
end

function AudioSystem:SetupBulletAudio()
	-- Listen for bullet events
	RemoteEventsManager:Initialize()
	
	local bulletWhizzEvent = RemoteEventsManager:GetEvent("BulletWhizz")
	if bulletWhizzEvent then
		bulletWhizzEvent.OnClientEvent:Connect(function(bulletData)
			self:PlayBulletWhizz(bulletData)
		end)
	end
	
	local bulletImpactEvent = RemoteEventsManager:GetEvent("BulletImpact")
	if bulletImpactEvent then
		bulletImpactEvent.OnClientEvent:Connect(function(impactData)
			self:PlayBulletImpact(impactData)
		end)
	end
end

function AudioSystem:PlayBulletWhizz(bulletData)
	if not player.Character or not player.Character:FindFirstChild("Head") then return end
	
	local playerHead = player.Character.Head
	local bulletPosition = bulletData.Position
	local bulletVelocity = bulletData.Velocity
	
	-- Calculate closest point on bullet path to player
	local distance = self:PointToLineDistance(playerHead.Position, bulletPosition, bulletPosition + bulletVelocity)
	
	if distance <= AUDIO_CONFIG.BulletWhizzDistance then
		-- Create whizz sound
		local whizzSound = Instance.new("Sound")
		whizzSound.SoundId = SOUND_LIBRARY.BulletSounds.Whizz[math.random(1, #SOUND_LIBRARY.BulletSounds.Whizz)]
		whizzSound.Volume = AUDIO_CONFIG.BulletWhizzVolume * (1 - distance / AUDIO_CONFIG.BulletWhizzDistance)
		whizzSound.Pitch = 0.8 + (math.random() * 0.4)
		whizzSound.SoundGroup = SoundService:FindFirstChild("SFX")
		whizzSound.Parent = playerHead
		
		whizzSound:Play()
		whizzSound.Ended:Connect(function()
			whizzSound:Destroy()
		end)
		
		-- Create crack sound for supersonic bullets
		if bulletData.Supersonic then
			local crackSound = Instance.new("Sound")
			crackSound.SoundId = SOUND_LIBRARY.BulletSounds.Crack[math.random(1, #SOUND_LIBRARY.BulletSounds.Crack)]
			crackSound.Volume = whizzSound.Volume * 0.7
			crackSound.Pitch = 1.2 + (math.random() * 0.3)
			crackSound.SoundGroup = SoundService:FindFirstChild("SFX")
			crackSound.Parent = playerHead
			
			crackSound:Play()
			crackSound.Ended:Connect(function()
				crackSound:Destroy()
			end)
		end
	end
end

function AudioSystem:PointToLineDistance(point, lineStart, lineEnd)
	local line = lineEnd - lineStart
	local lineLength = line.Magnitude
	if lineLength == 0 then return (point - lineStart).Magnitude end
	
	local t = math.clamp((point - lineStart):Dot(line) / (lineLength * lineLength), 0, 1)
	local projection = lineStart + t * line
	return (point - projection).Magnitude
end

function AudioSystem:PlayBulletImpact(impactData)
	local material = self:MaterialToString(impactData.Material)
	local soundList = SOUND_LIBRARY.BulletSounds.Impact[material]
	if not soundList then
		soundList = SOUND_LIBRARY.BulletSounds.Impact.Concrete
	end
	
	local soundId = soundList[math.random(1, #soundList)]
	
	-- Create impact sound at position
	local impactPart = Instance.new("Part")
	impactPart.Size = Vector3.new(0.1, 0.1, 0.1)
	impactPart.Transparency = 1
	impactPart.CanCollide = false
	impactPart.Anchored = true
	impactPart.Position = impactData.Position
	impactPart.Parent = workspace
	
	local impactSound = Instance.new("Sound")
	impactSound.SoundId = soundId
	impactSound.Volume = 0.6
	impactSound.Pitch = 0.9 + (math.random() * 0.2)
	impactSound.RollOffMode = AUDIO_CONFIG.RollOffMode
	impactSound.SoundGroup = SoundService:FindFirstChild("SFX")
	impactSound.Parent = impactPart
	
	if AUDIO_CONFIG.Enable3DAudio then
		impactSound.RollOffMode = AUDIO_CONFIG.RollOffMode
	end
	
	impactSound:Play()
	impactSound.Ended:Connect(function()
		impactPart:Destroy()
	end)
	
	game:GetService("Debris"):AddItem(impactPart, 3)
end

function AudioSystem:SetupEnvironmentAudio()
	-- Setup ambient environment sounds
	local environmentFolder = Instance.new("Folder")
	environmentFolder.Name = "EnvironmentSounds"
	environmentFolder.Parent = SoundService
	
	-- Create ambient sounds
	for soundName, soundId in pairs(SOUND_LIBRARY.Environment) do
		local ambientSound = Instance.new("Sound")
		ambientSound.Name = soundName
		ambientSound.SoundId = soundId
		ambientSound.Volume = 0.3
		ambientSound.Looped = true
		ambientSound.SoundGroup = SoundService:FindFirstChild("Environment")
		ambientSound.Parent = environmentFolder
	end
end

function AudioSystem:SetupRemoteEvents()
	-- Setup additional remote events for multiplayer audio sync
	local weaponSoundEvent = RemoteEventsManager:GetEvent("WeaponSound")
	if weaponSoundEvent then
		weaponSoundEvent.OnClientEvent:Connect(function(soundData)
			self:PlayWeaponSound(soundData)
		end)
	end
end

function AudioSystem:PlayWeaponSound(soundData)
	local soundType = soundData.Type -- "Reload", "Equip", "Safety", "DryFire"
	local weaponType = soundData.WeaponType -- "Pistol", "Rifle", etc.
	local position = soundData.Position
	local playerObj = soundData.Player
	
	local soundId = SOUND_LIBRARY.Weapons[soundType]
	if type(soundId) == "table" then
		soundId = soundId[weaponType] or soundId.Rifle
	end
	
	if soundId then
		-- Create positioned sound
		local soundPart = Instance.new("Part")
		soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
		soundPart.Transparency = 1
		soundPart.CanCollide = false
		soundPart.Anchored = true
		soundPart.Position = position
		soundPart.Parent = workspace
		
		local weaponSound = Instance.new("Sound")
		weaponSound.SoundId = soundId
		weaponSound.Volume = 0.7
		weaponSound.Pitch = 1 + (math.random() - 0.5) * 0.1
		weaponSound.SoundGroup = SoundService:FindFirstChild("Weapons")
		weaponSound.Parent = soundPart
		
		if AUDIO_CONFIG.Enable3DAudio then
			weaponSound.RollOffMode = AUDIO_CONFIG.RollOffMode
		end
		
		weaponSound:Play()
		weaponSound.Ended:Connect(function()
			soundPart:Destroy()
		end)
		
		game:GetService("Debris"):AddItem(soundPart, 5)
	end
end

function AudioSystem:SetupAudioUI()
	-- Create simple audio settings UI (could be integrated with main UI)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Add keybind to toggle audio settings
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.O then -- O key for audio options
			self:ToggleAudioSettings()
		end
	end)
end

function AudioSystem:ToggleAudioSettings()
	local playerGui = player.PlayerGui
	local audioGUI = playerGui:FindFirstChild("AudioSettingsGUI")
	
	if audioGUI then
		audioGUI:Destroy()
		return
	end
	
	-- Create audio settings GUI
	audioGUI = Instance.new("ScreenGui")
	audioGUI.Name = "AudioSettingsGUI"
	audioGUI.ResetOnSpawn = false
	audioGUI.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 400)
	frame.Position = UDim2.new(0.5, -150, 0.5, -200)
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	frame.BorderSizePixel = 0
	frame.Parent = audioGUI
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Audio Settings"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = frame
	
	-- Volume sliders (simplified implementation)
	local sliders = {"Master", "SFX", "Music", "Voice"}
	for i, sliderName in pairs(sliders) do
		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, -20, 0, 50)
		sliderFrame.Position = UDim2.new(0, 10, 0, 40 + (i * 60))
		sliderFrame.BackgroundTransparency = 1
		sliderFrame.Parent = frame
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.4, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = sliderName .. ":"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.SourceSans
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = sliderFrame
		
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.2, 0, 1, 0)
		valueLabel.Position = UDim2.new(0.8, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = "100%"
		valueLabel.TextColor3 = Color3.new(1, 1, 1)
		valueLabel.TextScaled = true
		valueLabel.Font = Enum.Font.SourceSans
		valueLabel.Parent = sliderFrame
	end
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 60, 0, 30)
	closeButton.Position = UDim2.new(1, -70, 0, 10)
	closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = frame
	
	closeButton.MouseButton1Click:Connect(function()
		audioGUI:Destroy()
	end)
end

function AudioSystem:CleanupPlayerFootsteps(targetPlayer)
	if footstepConnections[targetPlayer] then
		footstepConnections[targetPlayer]:Disconnect()
		footstepConnections[targetPlayer] = nil
	end
	
	lastFootstepTime[targetPlayer] = nil
end

function AudioSystem:SetMasterVolume(volume)
	volume = math.clamp(volume, 0, 1)
	AUDIO_CONFIG.MasterVolume = volume
	
	local masterGroup = SoundService:FindFirstChild("Master")
	if masterGroup then
		masterGroup.Volume = volume
	end
end

function AudioSystem:SetSFXVolume(volume)
	volume = math.clamp(volume, 0, 1)
	AUDIO_CONFIG.SFXVolume = volume
	
	local sfxGroup = SoundService:FindFirstChild("SFX")
	if sfxGroup then
		sfxGroup.Volume = volume
	end
end

function AudioSystem:SetMusicVolume(volume)
	volume = math.clamp(volume, 0, 1)
	AUDIO_CONFIG.MusicVolume = volume
	
	local musicGroup = SoundService:FindFirstChild("Music")
	if musicGroup then
		musicGroup.Volume = volume
	end
end

function AudioSystem:PlayEnvironmentSound(soundName, enabled)
	local environmentFolder = SoundService:FindFirstChild("EnvironmentSounds")
	if not environmentFolder then return end
	
	local sound = environmentFolder:FindFirstChild(soundName)
	if sound then
		if enabled then
			sound:Play()
		else
			sound:Stop()
		end
	end
end

-- Console commands for testing
_G.AudioCommands = {
	setMasterVolume = function(volume)
		AudioSystem:SetMasterVolume(tonumber(volume) or 1)
		print("Master volume set to " .. (tonumber(volume) or 1))
	end,
	
	setSFXVolume = function(volume)
		AudioSystem:SetSFXVolume(tonumber(volume) or 0.8)
		print("SFX volume set to " .. (tonumber(volume) or 0.8))
	end,
	
	setMusicVolume = function(volume)
		AudioSystem:SetMusicVolume(tonumber(volume) or 0.6)
		print("Music volume set to " .. (tonumber(volume) or 0.6))
	end,
	
	toggle3DAudio = function()
		AUDIO_CONFIG.Enable3DAudio = not AUDIO_CONFIG.Enable3DAudio
		print("3D Audio: " .. (AUDIO_CONFIG.Enable3DAudio and "Enabled" or "Disabled"))
	end,
	
	playEnvironmentSound = function(soundName)
		AudioSystem:PlayEnvironmentSound(soundName, true)
		print("Playing environment sound: " .. soundName)
	end,
	
	stopEnvironmentSound = function(soundName)
		AudioSystem:PlayEnvironmentSound(soundName, false)
		print("Stopping environment sound: " .. soundName)
	end,
	
	testBulletWhizz = function()
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local pos = player.Character.HumanoidRootPart.Position
			AudioSystem:PlayBulletWhizz({
				Position = pos + Vector3.new(5, 0, 0),
				Velocity = Vector3.new(-100, 0, 0),
				Supersonic = true
			})
		end
	end,
	
	listSounds = function()
		print("Available environment sounds:")
		for soundName, _ in pairs(SOUND_LIBRARY.Environment) do
			print("- " .. soundName)
		end
	end,
	
	audioSettings = function()
		AudioSystem:ToggleAudioSettings()
	end
}

function AudioSystem:PlayUISound(soundName)
	if not SOUND_LIBRARY.UI[soundName] then
		warn("UI sound not found: " .. soundName)
		return
	end
	
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_LIBRARY.UI[soundName]
	sound.Volume = AUDIO_CONFIG.SFXVolume
	sound.Parent = SoundService
	sound:Play()
	
	-- Clean up after playing
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return AudioSystem