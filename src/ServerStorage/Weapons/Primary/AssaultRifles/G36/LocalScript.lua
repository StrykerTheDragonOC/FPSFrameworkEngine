local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local SoundService = game:GetService("SoundService")

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
local AttachmentManager = require(ReplicatedStorage.FPSSystem.Modules.AttachmentManager)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local tool = script.Parent
local weaponName = tool.Name

local weaponStats = WeaponConfig:GetWeaponStats(weaponName)
local currentAmmo = weaponStats.ClipSize
local totalAmmo = weaponStats.TotalAmmo
local isReloading = false
local canFire = true
local lastFireTime = 0

local connections = {}

-- Viewmodel handling

function fireWeapon()
	if not canFire or isReloading or currentAmmo <= 0 then return end
	
	local currentTime = tick()
	local fireRate = 60 / weaponStats.FireRate
	
	if currentTime - lastFireTime < fireRate then return end
	
	lastFireTime = currentTime
	currentAmmo = currentAmmo - 1
	
	-- Perform raycast
	local rayDirection = Camera.CFrame.LookVector
	local rayResult = RaycastSystem:FireRay(Camera.CFrame.Position, rayDirection, weaponStats.Range, weaponName, weaponStats.Damage, 1.0, {player.Character})
	
	-- Send to server
	RemoteEventsManager:FireServer("WeaponFired", {
		WeaponName = weaponName,
		Origin = Camera.CFrame.Position,
		Direction = rayDirection,
		Hit = rayResult.Hit,
		Distance = rayResult.Distance,
		Damage = weaponStats.Damage
	})
	
	-- Play effects
	playFireEffects()
	
	-- Check for reload
	if currentAmmo <= 0 then
		reloadWeapon()
	end
end

function playFireEffects()
	-- Muzzle flash
	local viewmodel = ViewmodelSystem:GetActiveViewmodel()
	if viewmodel then
		local muzzle = viewmodel:FindFirstChild("Muzzle")
		if muzzle then
			-- Create muzzle flash effect
			local flash = Instance.new("Explosion")
			flash.Position = muzzle.WorldPosition
			flash.BlastRadius = 0
			flash.BlastPressure = 0
			flash.Visible = false
			flash.Parent = workspace
		end
	end
	
	-- Sound effect
	local fireSound = Instance.new("Sound")
	fireSound.SoundId = "rbxassetid://4759267374" -- G36 fire sound
	fireSound.Volume = 0.3
	fireSound.Parent = Camera
	fireSound:Play()
	
	fireSound.Ended:Connect(function()
		fireSound:Destroy()
	end)
	
	-- Screen shake/recoil
	applyRecoil()
end

function applyRecoil()
	local recoilAmount = weaponStats.Recoil or 1
	local randomX = (math.random() - 0.5) * recoilAmount * 0.1
	local randomY = math.random() * recoilAmount * 0.1
	
	Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(-randomY), math.rad(randomX), 0)
	
	-- Apply viewmodel recoil
	ViewmodelSystem:ApplyRecoil(Vector3.new(randomX, randomY, recoilAmount * 0.1))
end

function reloadWeapon()
	if isReloading or currentAmmo >= weaponStats.ClipSize or totalAmmo <= 0 then return end
	
	isReloading = true
	
	-- Play reload animation/sound
	local reloadSound = Instance.new("Sound")
	reloadSound.SoundId = "rbxassetid://138084889" -- Reload sound
	reloadSound.Volume = 0.4
	reloadSound.Parent = Camera
	reloadSound:Play()
	
	-- Wait for reload time
	wait(weaponStats.ReloadTime)
	
	-- Calculate ammo
	local ammoNeeded = weaponStats.ClipSize - currentAmmo
	local ammoToAdd = math.min(ammoNeeded, totalAmmo)
	
	currentAmmo = currentAmmo + ammoToAdd
	totalAmmo = totalAmmo - ammoToAdd
	
	isReloading = false
	
	-- Notify server
	RemoteEventsManager:FireServer("WeaponReloaded", {
		WeaponName = weaponName,
		CurrentAmmo = currentAmmo,
		TotalAmmo = totalAmmo
	})
end

function onEquipped()
	-- Setup input connections
	connections.mouseButton1 = mouse.Button1Down:Connect(function()
		fireWeapon()
	end)
	
	-- Auto-fire for assault rifles
	connections.autoFire = mouse.Button1Up:Connect(function()
		-- Stop auto-fire logic if implemented
	end)
	
	connections.reload = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.R then
			reloadWeapon()
		end
	end)
	
	-- Setup viewmodel using ViewmodelSystem
	ViewmodelSystem:CreateViewmodel(weaponName, "Primary")
	
	-- Notify server
	RemoteEventsManager:FireServer("WeaponEquipped", {
		WeaponName = weaponName,
		Player = player.Name
	})
end

function onUnequipped()
	-- Disconnect all connections
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	
	-- Clean up viewmodel
	ViewmodelSystem:DestroyViewmodel()
	
	-- Notify server
	RemoteEventsManager:FireServer("WeaponUnequipped", {
		WeaponName = weaponName,
		Player = player.Name
	})
end

-- Tool events
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

-- Initialize
RemoteEventsManager:Initialize()
WeaponConfig:Initialize()
RaycastSystem:Initialize()
AttachmentManager:Initialize()
ViewmodelSystem:Initialize()