local WeaponBase = {}
WeaponBase.__index = WeaponBase

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function WeaponBase.new(tool, config)
	local self = setmetatable({}, WeaponBase)
	
	self.tool = tool
	self.config = config
	self.player = Players.LocalPlayer
	self.character = self.player.Character
	self.humanoid = self.character and self.character:FindFirstChild("Humanoid")
	
	self.currentAmmo = config.MaxAmmo or 30
	self.reserveAmmo = config.MaxReserveAmmo or 120
	self.isReloading = false
	self.lastFireTime = 0
	
	-- Initialize weapon systems
	self:InitializeWeapon()
	
	return self
end

function WeaponBase:InitializeWeapon()
	-- Setup weapon events
	self:SetupWeaponEvents()
	
	print("WeaponBase initialized for " .. self.tool.Name)
end

function WeaponBase:SetupWeaponEvents()
	-- This would setup weapon-specific events
	-- For now, just a placeholder
end

function WeaponBase:Fire()
	local currentTime = tick()
	local fireRate = self.config.FireRate or 600
	local fireInterval = 60 / fireRate
	
	if currentTime - self.lastFireTime < fireInterval then
		return false
	end
	
	if self.currentAmmo <= 0 then
		-- Play dry fire sound
		self:PlayDryFireSound()
		return false
	end
	
	if self.isReloading then
		return false
	end
	
	-- Consume ammo
	self.currentAmmo = self.currentAmmo - 1
	self.lastFireTime = currentTime

	-- Send fire event to server
	local weaponFireEvent = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("WeaponFire")
	if weaponFireEvent then
		weaponFireEvent:FireServer({
			WeaponName = self.tool.Name,
			FirePosition = self.character.Head.Position,
			FireDirection = self.character.Head.CFrame.LookVector
		})
	end
	
	-- Apply recoil
	self:ApplyRecoil()
	
	return true
end

function WeaponBase:Reload()
	if self.isReloading then return false end
	if self.reserveAmmo <= 0 then return false end
	if self.currentAmmo >= self.config.MaxAmmo then return false end
	
	self.isReloading = true
	
	-- Calculate reload time
	local reloadTime = self.config.ReloadTime or 2.5
	
	-- Play reload animation/sound
	self:PlayReloadEffects()
	
	-- Wait for reload
	spawn(function()
		wait(reloadTime)
		
		-- Calculate ammo to reload
		local ammoNeeded = self.config.MaxAmmo - self.currentAmmo
		local ammoToReload = math.min(ammoNeeded, self.reserveAmmo)
		
		self.currentAmmo = self.currentAmmo + ammoToReload
		self.reserveAmmo = self.reserveAmmo - ammoToReload
		self.isReloading = false
		
		print("Reloaded: " .. self.currentAmmo .. "/" .. self.reserveAmmo)
	end)
	
	return true
end

function WeaponBase:ApplyRecoil()
	if not self.config.Recoil then return end
	
	local recoil = self.config.Recoil
	local camera = workspace.CurrentCamera
	
	-- Simple recoil implementation
	local recoilX = (math.random() - 0.5) * recoil.Horizontal
	local recoilY = recoil.Vertical * (math.random() * 0.5 + 0.75)
	
	-- Apply recoil to camera
	local currentCFrame = camera.CFrame
	local recoilCFrame = CFrame.Angles(math.rad(-recoilY), math.rad(recoilX), 0)
	
	camera.CFrame = currentCFrame * recoilCFrame
end

function WeaponBase:PlayReloadEffects()
	-- Play reload sound
	local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://138084889" -- Placeholder reload sound
	sound.Volume = 0.5
	sound.Parent = self.tool
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function WeaponBase:PlayDryFireSound()
	local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://88242783225642" -- Placeholder dry fire sound
	sound.Volume = 0.3
	sound.Pitch = 1.5
	sound.Parent = self.tool
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function WeaponBase:GetAmmoCount()
	return self.currentAmmo, self.reserveAmmo
end

function WeaponBase:SetAmmoCount(current, reserve)
	self.currentAmmo = current or self.currentAmmo
	self.reserveAmmo = reserve or self.reserveAmmo
end

function WeaponBase:IsReloading()
	return self.isReloading
end

function WeaponBase:CanFire()
	return not self.isReloading and self.currentAmmo > 0
end

function WeaponBase:SwitchFireMode()
	if not self.config.FireModes or #self.config.FireModes <= 1 then
		return false
	end
	
	-- Cycle through fire modes
	local currentIndex = 1
	for i, mode in pairs(self.config.FireModes) do
		if mode == self.currentFireMode then
			currentIndex = i
			break
		end
	end
	
	currentIndex = currentIndex + 1
	if currentIndex > #self.config.FireModes then
		currentIndex = 1
	end
	
	self.currentFireMode = self.config.FireModes[currentIndex]
	print("Fire mode: " .. self.currentFireMode)
	
	return true
end

function WeaponBase:GetFireMode()
	return self.currentFireMode or (self.config.FireModes and self.config.FireModes[1]) or "Semi"
end

function WeaponBase:Update(deltaTime)
	-- Update weapon systems
	-- Called from the main weapon script
end

function WeaponBase:Cleanup()
	-- Clean up weapon resources
	if self.connections then
		for _, connection in pairs(self.connections) do
			connection:Disconnect()
		end
		self.connections = {}
	end
	
	print("WeaponBase cleaned up for " .. self.tool.Name)
end

return WeaponBase