--[[
	Example Sniper Rifle - LocalScript
	Demonstrates proper scope integration with ScopeSystem

	FEATURES:
	- Right-click to aim/scope
	- T key to toggle scope mode (3D/UI)
	- Hold Shift to stabilize when scoped
	- Automatic scope handling
	- Full weapon functionality

	USAGE:
	1. Place this script inside your sniper weapon tool
	2. Ensure your weapon has a proper config in WeaponConfig
	3. Make sure the weapon has a scope attachment configured
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)

-- Load ScopeSystem
local ScopeSystem = nil
pcall(function()
	ScopeSystem = require(ReplicatedStorage.FPSSystem.Modules.ScopeSystem)
end)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local tool = script.Parent
local weaponName = tool.Name

-- Get weapon configuration
local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
if not weaponConfig then
	warn("No weapon config found for:", weaponName)
	return
end

-- Weapon state
local weaponStats = WeaponConfig:GetWeaponStats(weaponName)
local currentAmmo = weaponConfig.MaxAmmo or 10
local totalAmmo = weaponConfig.MaxReserveAmmo or 50
local isReloading = false
local canFire = true
local lastFireTime = 0
local isAiming = false

-- Input connections
local connections = {}

-- Remote events
local remoteEventsFolder = ReplicatedStorage.FPSSystem.RemoteEvents

--========================================
-- WEAPON FUNCTIONS
--========================================

function fireWeapon()
	if not canFire or isReloading or currentAmmo <= 0 then return end

	local currentTime = tick()
	local fireRate = 60 / (weaponStats.FireRate or 60)

	if currentTime - lastFireTime < fireRate then return end

	lastFireTime = currentTime
	currentAmmo = currentAmmo - 1

	-- Apply zoom factor for accuracy (snipers are more accurate when scoped)
	local spreadModifier = isAiming and 0.1 or 1.0

	-- Perform raycast
	local rayDirection = Camera.CFrame.LookVector
	local rayResult = RaycastSystem:FireRay(
		Camera.CFrame.Position,
		rayDirection,
		weaponStats.Range or 5000,
		weaponName,
		weaponStats.Damage or 100,
		spreadModifier,
		{player.Character}
	)

	-- Send to server
	local weaponFiredEvent = remoteEventsFolder:FindFirstChild("WeaponFired")
	if weaponFiredEvent then
		weaponFiredEvent:FireServer({
			WeaponName = weaponName,
			Origin = Camera.CFrame.Position,
			Direction = rayDirection,
			Hit = rayResult.Hit,
			Distance = rayResult.Distance,
			Damage = weaponStats.Damage
		})
	end

	-- Play effects
	playFireEffects()

	-- Apply recoil
	applyRecoil()

	-- Update UI
	updateAmmoUI()

	-- Check for reload
	if currentAmmo <= 0 then
		reloadWeapon()
	end
end

function playFireEffects()
	-- Play muzzle flash, sound, etc.
	local viewmodel = ViewmodelSystem:GetActiveViewmodel()
	if viewmodel then
		local muzzle = viewmodel:FindFirstChild("Muzzle", true)
		if muzzle then
			-- Create muzzle flash
			local flash = Instance.new("PointLight")
			flash.Brightness = 10
			flash.Range = 20
			flash.Color = Color3.fromRGB(255, 200, 100)
			flash.Parent = muzzle

			game:GetService("Debris"):AddItem(flash, 0.1)
		end
	end

	-- Play fire sound
	local weaponSoundEvent = remoteEventsFolder:FindFirstChild("WeaponSound")
	if weaponSoundEvent then
		weaponSoundEvent:FireServer({
			SoundType = "Fire",
			WeaponName = weaponName,
			Position = Camera.CFrame.Position
		})
	end
end

function applyRecoil()
	if not weaponStats.Recoil then return end

	-- Calculate recoil based on weapon stats and aiming state
	local recoilMultiplier = isAiming and 0.5 or 1.0
	local verticalRecoil = (weaponStats.Recoil.Vertical or 2) * recoilMultiplier
	local horizontalRecoil = (weaponStats.Recoil.Horizontal or 0.5) * recoilMultiplier

	-- Apply to camera
	local recoilX = (math.random() - 0.5) * horizontalRecoil
	local recoilY = verticalRecoil

	-- Smooth recoil application
	local currentCFrame = Camera.CFrame
	Camera.CFrame = currentCFrame * CFrame.Angles(math.rad(-recoilY), math.rad(recoilX), 0)

	-- Apply to viewmodel if available
	if ViewmodelSystem.ApplyRecoil then
		ViewmodelSystem:ApplyRecoil(Vector3.new(recoilX, recoilY, 0))
	end
end

function reloadWeapon()
	if isReloading or currentAmmo >= weaponConfig.MaxAmmo or totalAmmo <= 0 then return end

	isReloading = true
	canFire = false

	print("Reloading " .. weaponName .. "...")

	-- Play reload animation
	local reloadTime = weaponStats.ReloadTime or 3.0

	-- Send reload event to server
	local weaponReloadedEvent = remoteEventsFolder:FindFirstChild("WeaponReloaded")
	if weaponReloadedEvent then
		weaponReloadedEvent:FireServer({
			WeaponName = weaponName
		})
	end

	wait(reloadTime)

	-- Calculate ammo to reload
	local ammoNeeded = weaponConfig.MaxAmmo - currentAmmo
	local ammoToReload = math.min(ammoNeeded, totalAmmo)

	currentAmmo = currentAmmo + ammoToReload
	totalAmmo = totalAmmo - ammoToReload

	isReloading = false
	canFire = true

	updateAmmoUI()

	print("Reload complete!")
end

function updateAmmoUI()
	-- Update ammo display
	local ammoUpdateEvent = remoteEventsFolder:FindFirstChild("AmmoUpdate")
	if ammoUpdateEvent then
		ammoUpdateEvent:FireServer({
			WeaponName = weaponName,
			CurrentAmmo = currentAmmo,
			TotalAmmo = totalAmmo
		})
	end
end

--========================================
-- AIMING/SCOPING FUNCTIONS
--========================================

function startAiming()
	if isAiming or isReloading then return end

	isAiming = true

	-- Notify ViewmodelSystem (which will notify ScopeSystem)
	if ViewmodelSystem.SetAiming then
		ViewmodelSystem:SetAiming(true)
	end

	print("Aiming started")
end

function stopAiming()
	if not isAiming then return end

	isAiming = false

	-- Notify ViewmodelSystem (which will notify ScopeSystem)
	if ViewmodelSystem.SetAiming then
		ViewmodelSystem:SetAiming(false)
	end

	print("Aiming stopped")
end

--========================================
-- INPUT HANDLING
--========================================

function setupInputHandling()
	-- Right-click to aim/scope
	connections.MouseButton2Down = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			startAiming()
		end
	end)

	connections.MouseButton2Up = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			stopAiming()
		end
	end)

	-- Left-click to fire
	connections.MouseButton1Down = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			fireWeapon()
		end
	end)

	-- R to reload
	connections.ReloadKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.R then
			reloadWeapon()
		end
	end)

	-- V to toggle fire mode (if applicable)
	connections.FireModeKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.V then
			-- Sniper rifles typically don't have fire modes, but this is here for reference
			print("Fire mode toggle (not applicable for sniper)")
		end
	end)

	-- H to inspect
	connections.InspectKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.H then
			print("Inspecting weapon...")
			-- Play inspect animation if available
		end
	end)

	print("✓ Input handling setup complete")
end

function cleanupInputHandling()
	for name, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}

	print("✓ Input handling cleaned up")
end

--========================================
-- TOOL EVENTS
--========================================

function onEquipped()
	print("Equipped " .. weaponName)

	-- Setup input
	setupInputHandling()

	-- Update ammo UI
	updateAmmoUI()

	-- ViewmodelSystem handles viewmodel creation automatically via tool detection
	-- ScopeSystem is automatically notified via ViewmodelSystem integration
end

function onUnequipped()
	print("Unequipped " .. weaponName)

	-- Stop aiming if currently aiming
	if isAiming then
		stopAiming()
	end

	-- Cleanup input
	cleanupInputHandling()

	-- ViewmodelSystem handles cleanup automatically
	-- ScopeSystem is automatically notified via ViewmodelSystem integration
end

--========================================
-- INITIALIZATION
--========================================

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

print("✓ " .. weaponName .. " client script loaded")
print("=== SNIPER CONTROLS ===")
print("Left-Click: Fire")
print("Right-Click: Aim/Scope")
print("T: Toggle scope mode (3D/UI)")
print("Shift: Stabilize (when scoped)")
print("R: Reload")
print("H: Inspect")
print("=======================")
