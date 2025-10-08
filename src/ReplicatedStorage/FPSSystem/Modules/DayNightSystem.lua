local DayNightSystem = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

-- Day/Night configuration
local DAY_NIGHT_CONFIG = {
	CycleLength = 36000, -- 10 hours (36000 seconds) for full day/night cycle
	TimeScale = 1, -- Speed multiplier for time
	EnableCycle = true,
	StartTime = 12, -- Start at noon (12:00)
	
	-- Lighting presets
	Presets = {
		Dawn = {
			Time = 6,
			ClockTime = "06:00",
			Brightness = 1,
			Ambient = Color3.new(0.4, 0.4, 0.5),
			ColorShift_Top = Color3.new(1, 0.8, 0.6),
			ColorShift_Bottom = Color3.new(0.8, 0.6, 0.4),
			OutdoorAmbient = Color3.new(0.5, 0.5, 0.6),
			ShadowSoftness = 0.2,
			EnvironmentDiffuseScale = 0.8,
			EnvironmentSpecularScale = 0.8,
			ExposureCompensation = 0.2
		},
		Morning = {
			Time = 9,
			ClockTime = "09:00",
			Brightness = 2,
			Ambient = Color3.new(0.6, 0.6, 0.7),
			ColorShift_Top = Color3.new(1, 1, 0.9),
			ColorShift_Bottom = Color3.new(0.9, 0.9, 0.8),
			OutdoorAmbient = Color3.new(0.7, 0.7, 0.8),
			ShadowSoftness = 0.15,
			EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1,
			ExposureCompensation = 0
		},
		Noon = {
			Time = 12,
			ClockTime = "12:00",
			Brightness = 3,
			Ambient = Color3.new(0.8, 0.8, 0.8),
			ColorShift_Top = Color3.new(1, 1, 1),
			ColorShift_Bottom = Color3.new(1, 1, 1),
			OutdoorAmbient = Color3.new(1, 1, 1),
			ShadowSoftness = 0.1,
			EnvironmentDiffuseScale = 1.2,
			EnvironmentSpecularScale = 1.2,
			ExposureCompensation = -0.1
		},
		Afternoon = {
			Time = 15,
			ClockTime = "15:00",
			Brightness = 2.5,
			Ambient = Color3.new(0.7, 0.7, 0.75),
			ColorShift_Top = Color3.new(1, 0.95, 0.9),
			ColorShift_Bottom = Color3.new(0.95, 0.9, 0.85),
			OutdoorAmbient = Color3.new(0.9, 0.9, 0.95),
			ShadowSoftness = 0.12,
			EnvironmentDiffuseScale = 1.1,
			EnvironmentSpecularScale = 1.1,
			ExposureCompensation = 0
		},
		Dusk = {
			Time = 18,
			ClockTime = "18:00",
			Brightness = 1.2,
			Ambient = Color3.new(0.5, 0.4, 0.6),
			ColorShift_Top = Color3.new(1, 0.6, 0.4),
			ColorShift_Bottom = Color3.new(0.8, 0.4, 0.2),
			OutdoorAmbient = Color3.new(0.6, 0.5, 0.7),
			ShadowSoftness = 0.25,
			EnvironmentDiffuseScale = 0.7,
			EnvironmentSpecularScale = 0.7,
			ExposureCompensation = 0.3
		},
		Night = {
			Time = 21,
			ClockTime = "21:00",
			Brightness = 0.3,
			Ambient = Color3.new(0.1, 0.1, 0.2),
			ColorShift_Top = Color3.new(0.2, 0.2, 0.3),
			ColorShift_Bottom = Color3.new(0.1, 0.1, 0.15),
			OutdoorAmbient = Color3.new(0.15, 0.15, 0.25),
			ShadowSoftness = 0.4,
			EnvironmentDiffuseScale = 0.3,
			EnvironmentSpecularScale = 0.3,
			ExposureCompensation = 0.8
		},
		Midnight = {
			Time = 0,
			ClockTime = "00:00",
			Brightness = 0.1,
			Ambient = Color3.new(0.05, 0.05, 0.1),
			ColorShift_Top = Color3.new(0.1, 0.1, 0.2),
			ColorShift_Bottom = Color3.new(0.05, 0.05, 0.1),
			OutdoorAmbient = Color3.new(0.1, 0.1, 0.15),
			ShadowSoftness = 0.5,
			EnvironmentDiffuseScale = 0.2,
			EnvironmentSpecularScale = 0.2,
			ExposureCompensation = 1.2
		},
		EarlyMorning = {
			Time = 3,
			ClockTime = "03:00",
			Brightness = 0.2,
			Ambient = Color3.new(0.1, 0.1, 0.15),
			ColorShift_Top = Color3.new(0.2, 0.15, 0.25),
			ColorShift_Bottom = Color3.new(0.1, 0.1, 0.15),
			OutdoorAmbient = Color3.new(0.15, 0.15, 0.2),
			ShadowSoftness = 0.45,
			EnvironmentDiffuseScale = 0.25,
			EnvironmentSpecularScale = 0.25,
			ExposureCompensation = 1.0
		}
	}
}

local currentTime = DAY_NIGHT_CONFIG.StartTime
local currentPreset = "Noon"
local timeConnection = nil
local ambientSounds = {}

function DayNightSystem:Initialize()
	-- Set initial lighting
	self:SetTimeOfDay(DAY_NIGHT_CONFIG.StartTime)
	
	-- Setup ambient sounds
	self:SetupAmbientSounds()
	
	-- Start day/night cycle if enabled
	if DAY_NIGHT_CONFIG.EnableCycle then
		self:StartCycle()
	end
	
	-- Setup remote events for server sync
	self:SetupRemoteEvents()
	
	print("DayNightSystem initialized - Time: " .. self:FormatTime(currentTime))
end

function DayNightSystem:SetupAmbientSounds()
	-- Create ambient sound groups
	local ambientFolder = Instance.new("Folder")
	ambientFolder.Name = "AmbientSounds"
	ambientFolder.Parent = SoundService
	
	-- Day sounds
	ambientSounds.Day = Instance.new("SoundGroup")
	ambientSounds.Day.Name = "DaySounds"
	ambientSounds.Day.Parent = ambientFolder
	
	local birdSound = Instance.new("Sound")
	birdSound.Name = "Birds"
    birdSound.SoundId = "rbxassetid://9056670230" -- Bird chirping
	birdSound.Volume = 0.3
	birdSound.Looped = true
	birdSound.SoundGroup = ambientSounds.Day
	birdSound.Parent = ambientFolder
	
	local windSound = Instance.new("Sound")
	windSound.Name = "Wind"
    windSound.SoundId = "rbxassetid://5799870105" -- Wind sound
	windSound.Volume = 0.2
	windSound.Looped = true
	windSound.SoundGroup = ambientSounds.Day
	windSound.Parent = ambientFolder
	
	-- Night sounds
	ambientSounds.Night = Instance.new("SoundGroup")
	ambientSounds.Night.Name = "NightSounds"
	ambientSounds.Night.Parent = ambientFolder
	
	local cricketSound = Instance.new("Sound")
	cricketSound.Name = "Crickets"
    cricketSound.SoundId = "rbxassetid://9112764573" -- Cricket sound
	cricketSound.Volume = 0.4
	cricketSound.Looped = true
	cricketSound.SoundGroup = ambientSounds.Night
	cricketSound.Parent = ambientFolder
	
	local owlSound = Instance.new("Sound")
	owlSound.Name = "Owls"
    owlSound.SoundId = "rbxassetid://1621169776" -- Owl hooting
	owlSound.Volume = 0.2
	owlSound.Looped = true
	owlSound.SoundGroup = ambientSounds.Night
	owlSound.Parent = ambientFolder
	
	-- Start with appropriate sounds
	self:UpdateAmbientSounds()
end

function DayNightSystem:SetupRemoteEvents()
	-- For multiplayer synchronization
	RemoteEventsManager:Initialize()
	
	-- Only setup client event listening on the client
	if RunService:IsClient() then
		local timeUpdateEvent = RemoteEventsManager:GetEvent("TimeUpdate")
		if timeUpdateEvent then
			timeUpdateEvent.OnClientEvent:Connect(function(timeData)
				self:SyncTime(timeData.Time, timeData.Preset)
			end)
		end
	end
end

function DayNightSystem:StartCycle()
	if timeConnection then
		timeConnection:Disconnect()
	end
	
	timeConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:UpdateTime(deltaTime)
	end)
	
	print("Day/Night cycle started")
end

function DayNightSystem:StopCycle()
	if timeConnection then
		timeConnection:Disconnect()
		timeConnection = nil
	end
	
	print("Day/Night cycle stopped")
end

function DayNightSystem:UpdateTime(deltaTime)
	local timeIncrement = (deltaTime * DAY_NIGHT_CONFIG.TimeScale * 24) / DAY_NIGHT_CONFIG.CycleLength
	currentTime = currentTime + timeIncrement
	
	-- Wrap around 24 hours
	if currentTime >= 24 then
		currentTime = currentTime - 24
	end
	
	-- Update lighting
	self:UpdateLighting()
	
	-- Check for preset changes
	local newPreset = self:GetCurrentPreset()
	if newPreset ~= currentPreset then
		currentPreset = newPreset
		self:OnPresetChange(newPreset)
	end
end

function DayNightSystem:UpdateLighting()
	local preset = self:InterpolateLighting(currentTime)
	
	-- Apply lighting settings
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
	
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Brightness = preset.Brightness,
		Ambient = preset.Ambient,
		ColorShift_Top = preset.ColorShift_Top,
		ColorShift_Bottom = preset.ColorShift_Bottom,
		OutdoorAmbient = preset.OutdoorAmbient,
		ShadowSoftness = preset.ShadowSoftness,
		EnvironmentDiffuseScale = preset.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = preset.EnvironmentSpecularScale,
		ExposureCompensation = preset.ExposureCompensation
	})
	
	lightingTween:Play()
	
	-- Update Roblox's built-in time display
	Lighting.ClockTime = currentTime
end

function DayNightSystem:InterpolateLighting(time)
	-- Find the two closest presets for interpolation
	local presets = DAY_NIGHT_CONFIG.Presets
	local sortedTimes = {}
	
	for _, preset in pairs(presets) do
		table.insert(sortedTimes, preset.Time)
	end
	table.sort(sortedTimes)
	
	-- Find surrounding presets
	local beforeTime, afterTime
	for i = 1, #sortedTimes do
		if sortedTimes[i] <= time then
			beforeTime = sortedTimes[i]
		else
			afterTime = sortedTimes[i]
			break
		end
	end
	
	-- Handle wrap around (night to morning)
	if not afterTime then
		afterTime = sortedTimes[1] + 24
		if not beforeTime then
			beforeTime = sortedTimes[#sortedTimes]
		end
	end
	if not beforeTime then
		beforeTime = sortedTimes[#sortedTimes] - 24
	end
	
	-- Get presets
	local beforePreset, afterPreset
	for _, preset in pairs(presets) do
		if preset.Time == beforeTime or preset.Time == beforeTime + 24 or preset.Time == beforeTime - 24 then
			beforePreset = preset
		end
		if preset.Time == afterTime or preset.Time == afterTime - 24 or preset.Time == afterTime + 24 then
			afterPreset = preset
		end
	end
	
	-- Calculate interpolation factor
	local totalTime = afterTime - beforeTime
	local elapsed = time - beforeTime
	local alpha = elapsed / totalTime
	alpha = math.clamp(alpha, 0, 1)
	
	-- Interpolate between presets
	return {
		Brightness = self:LerpNumber(beforePreset.Brightness, afterPreset.Brightness, alpha),
		Ambient = beforePreset.Ambient:lerp(afterPreset.Ambient, alpha),
		ColorShift_Top = beforePreset.ColorShift_Top:lerp(afterPreset.ColorShift_Top, alpha),
		ColorShift_Bottom = beforePreset.ColorShift_Bottom:lerp(afterPreset.ColorShift_Bottom, alpha),
		OutdoorAmbient = beforePreset.OutdoorAmbient:lerp(afterPreset.OutdoorAmbient, alpha),
		ShadowSoftness = self:LerpNumber(beforePreset.ShadowSoftness, afterPreset.ShadowSoftness, alpha),
		EnvironmentDiffuseScale = self:LerpNumber(beforePreset.EnvironmentDiffuseScale, afterPreset.EnvironmentDiffuseScale, alpha),
		EnvironmentSpecularScale = self:LerpNumber(beforePreset.EnvironmentSpecularScale, afterPreset.EnvironmentSpecularScale, alpha),
		ExposureCompensation = self:LerpNumber(beforePreset.ExposureCompensation, afterPreset.ExposureCompensation, alpha)
	}
end

function DayNightSystem:LerpNumber(a, b, t)
	return a + (b - a) * t
end

function DayNightSystem:GetCurrentPreset()
	local presets = DAY_NIGHT_CONFIG.Presets
	local closestPreset = "Noon"
	local closestDistance = math.huge
	
	for name, preset in pairs(presets) do
		local distance = math.abs(currentTime - preset.Time)
		-- Handle wrap around
		if distance > 12 then
			distance = 24 - distance
		end
		
		if distance < closestDistance then
			closestDistance = distance
			closestPreset = name
		end
	end
	
	return closestPreset
end

function DayNightSystem:OnPresetChange(newPreset)
	print("Time of day changed to: " .. newPreset .. " (" .. self:FormatTime(currentTime) .. ")")
	
	-- Update ambient sounds
	self:UpdateAmbientSounds()
	
	-- Trigger effects for specific times
	if newPreset == "Dawn" then
		self:TriggerDawnEffects()
	elseif newPreset == "Dusk" then
		self:TriggerDuskEffects()
	elseif newPreset == "Midnight" then
		self:TriggerMidnightEffects()
	end
end

function DayNightSystem:UpdateAmbientSounds()
	local isNight = currentTime >= 20 or currentTime <= 5
	
	-- Fade day sounds
	if ambientSounds.Day then
		local dayVolume = isNight and 0 or 1
		for _, sound in pairs(ambientSounds.Day:GetChildren()) do
			if sound:IsA("Sound") then
				local volumeTween = TweenService:Create(sound, TweenInfo.new(2), {Volume = sound.Volume * dayVolume})
				volumeTween:Play()
				if not sound.IsPlaying and not isNight then
					sound:Play()
				elseif sound.IsPlaying and isNight then
					spawn(function()
						volumeTween.Completed:Wait()
						sound:Stop()
					end)
				end
			end
		end
	end
	
	-- Fade night sounds
	if ambientSounds.Night then
		local nightVolume = isNight and 1 or 0
		for _, sound in pairs(ambientSounds.Night:GetChildren()) do
			if sound:IsA("Sound") then
				local volumeTween = TweenService:Create(sound, TweenInfo.new(2), {Volume = sound.Volume * nightVolume})
				volumeTween:Play()
				if not sound.IsPlaying and isNight then
					sound:Play()
				elseif sound.IsPlaying and not isNight then
					spawn(function()
						volumeTween.Completed:Wait()
						sound:Stop()
					end)
				end
			end
		end
	end
end

function DayNightSystem:TriggerDawnEffects()
	-- Create sunrise glow effect
	local sunGlow = Instance.new("SunRaysEffect")
	sunGlow.Intensity = 0.3
	sunGlow.Spread = 0.5
	sunGlow.Parent = Lighting
	
	-- Fade in the glow
	local glowTween = TweenService:Create(sunGlow, TweenInfo.new(5), {Intensity = 0.8})
	glowTween:Play()
	
	-- Remove after sunrise
	spawn(function()
		wait(60) -- 1 minute
		local fadeOut = TweenService:Create(sunGlow, TweenInfo.new(5), {Intensity = 0})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		sunGlow:Destroy()
	end)
end

function DayNightSystem:TriggerDuskEffects()
	-- Create sunset glow effect
	local sunsetGlow = Instance.new("SunRaysEffect")
	sunsetGlow.Intensity = 0.5
	sunsetGlow.Spread = 0.7
	sunsetGlow.Parent = Lighting
	
	-- Gradually fade out
	spawn(function()
		wait(30) -- 30 seconds
		local fadeOut = TweenService:Create(sunsetGlow, TweenInfo.new(10), {Intensity = 0})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		sunsetGlow:Destroy()
	end)
end

function DayNightSystem:TriggerMidnightEffects()
	-- Add atmospheric bloom for night sky
	local bloom = Lighting:FindFirstChild("Bloom") or Instance.new("BloomEffect")
	bloom.Name = "Bloom"
	bloom.Intensity = 0.5
	bloom.Size = 8
	bloom.Threshold = 1.2
	bloom.Parent = Lighting
end

function DayNightSystem:SetTimeOfDay(hour)
	currentTime = math.clamp(hour, 0, 23.99)
	self:UpdateLighting()
	currentPreset = self:GetCurrentPreset()
	self:UpdateAmbientSounds()
	
	print("Time set to: " .. self:FormatTime(currentTime) .. " (" .. currentPreset .. ")")
end

function DayNightSystem:SetPreset(presetName)
	local preset = DAY_NIGHT_CONFIG.Presets[presetName]
	if preset then
		self:SetTimeOfDay(preset.Time)
	else
		print("Invalid preset. Available presets:")
		for name, _ in pairs(DAY_NIGHT_CONFIG.Presets) do
			print("- " .. name)
		end
	end
end

function DayNightSystem:SetCycleSpeed(speed)
	DAY_NIGHT_CONFIG.TimeScale = math.max(0.1, speed)
	print("Cycle speed set to: " .. DAY_NIGHT_CONFIG.TimeScale .. "x")
end

function DayNightSystem:ToggleCycle()
	DAY_NIGHT_CONFIG.EnableCycle = not DAY_NIGHT_CONFIG.EnableCycle
	
	if DAY_NIGHT_CONFIG.EnableCycle then
		self:StartCycle()
	else
		self:StopCycle()
	end
	
	print("Day/Night cycle: " .. (DAY_NIGHT_CONFIG.EnableCycle and "Enabled" or "Disabled"))
end

function DayNightSystem:FormatTime(time)
	local hours = math.floor(time)
	local minutes = math.floor((time - hours) * 60)
	return string.format("%02d:%02d", hours, minutes)
end

function DayNightSystem:GetCurrentTime()
	return currentTime
end

function DayNightSystem:GetCurrentPresetName()
	return currentPreset
end

function DayNightSystem:IsNightTime()
	return currentTime >= 20 or currentTime <= 5
end

function DayNightSystem:IsDayTime()
	return currentTime >= 7 and currentTime <= 19
end

function DayNightSystem:SyncTime(serverTime, serverPreset)
	-- For multiplayer synchronization
	currentTime = serverTime
	currentPreset = serverPreset
	self:UpdateLighting()
	self:UpdateAmbientSounds()
end

-- Console commands for testing
_G.TimeCommands = {
	setTime = function(hour)
		local time = tonumber(hour)
		if time and time >= 0 and time <= 24 then
			DayNightSystem:SetTimeOfDay(time)
		else
			print("Usage: setTime(hour) - hour must be between 0-24")
		end
	end,
	
	setPreset = function(presetName)
		DayNightSystem:SetPreset(presetName)
	end,
	
	speed = function(multiplier)
		local speed = tonumber(multiplier)
		if speed then
			DayNightSystem:SetCycleSpeed(speed)
		else
			print("Usage: speed(multiplier) - e.g., speed(5) for 5x faster")
		end
	end,
	
	toggleCycle = function()
		DayNightSystem:ToggleCycle()
	end,
	
	dawn = function() DayNightSystem:SetPreset("Dawn") end,
	noon = function() DayNightSystem:SetPreset("Noon") end,
	dusk = function() DayNightSystem:SetPreset("Dusk") end,
	night = function() DayNightSystem:SetPreset("Night") end,
	midnight = function() DayNightSystem:SetPreset("Midnight") end,
	
	status = function()
		print("Current Time: " .. DayNightSystem:FormatTime(currentTime))
		print("Current Preset: " .. currentPreset)
		print("Cycle Enabled: " .. tostring(DAY_NIGHT_CONFIG.EnableCycle))
		print("Cycle Speed: " .. DAY_NIGHT_CONFIG.TimeScale .. "x")
		print("Is Night: " .. tostring(DayNightSystem:IsNightTime()))
	end,
	
	listPresets = function()
		print("Available time presets:")
		for name, preset in pairs(DAY_NIGHT_CONFIG.Presets) do
			print("- " .. name .. " (" .. preset.ClockTime .. ")")
		end
	end
}

return DayNightSystem