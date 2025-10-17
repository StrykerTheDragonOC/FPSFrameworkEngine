--[[
	G36 Assault Rifle Client Script
	Fixed version with proper remote events and viewmodel system
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

repeat task.wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

-- Modules
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)

-- Remote Events (NO RemoteEventsManager!)
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFired = RemoteEvents:WaitForChild("WeaponFired")
local WeaponReloaded = RemoteEvents:WaitForChild("WeaponReloaded")
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent
local weaponName = tool.Name

-- Get weapon config
local weaponConfig = WeaponConfig:GetWeaponConfig(weaponName)
if not weaponConfig then
	warn("No weapon config found for:", weaponName)
	return
end

-- Weapon state
local currentAmmo = weaponConfig.ClipSize or 30
local reserveAmmo = weaponConfig.TotalAmmo or 210
local isReloading = false
local canFire = true
local lastFireTime = 0
local isEquipped = false
local isFiring = false
local fireMode = "Auto"  -- "Auto", "Semi", "Burst"

-- Fire weapon
local function FireWeapon()
    if not canFire or isReloading or currentAmmo <= 0 or not isEquipped then
        if currentAmmo <= 0 then
            -- Play dry fire sound via SoundUtils
            local ok, SoundUtils = pcall(function()
                return require(ReplicatedStorage.FPSSystem.Modules.SoundUtils)
            end)
            if ok and SoundUtils then
                SoundUtils:PlayLocalSound("rbxassetid://2697295462", Camera, 0.3)
            else
                local drySound = Instance.new("Sound")
                drySound.SoundId = "rbxassetid://2697295462"  -- Dry fire sound
                drySound.Volume = 0.3
                drySound.Parent = Camera
                drySound:Play()
                game:GetService("Debris"):AddItem(drySound, 1)
            end
        end
        return
    end

	local currentTime = tick()
	local fireRate = 60 / (weaponConfig.FireRate or 750)

	if currentTime - lastFireTime < fireRate then return end

	lastFireTime = currentTime
	currentAmmo = currentAmmo - 1

	-- Get camera direction
	local origin = Camera.CFrame.Position
	local direction = (mouse.Hit.Position - origin).Unit

	-- Perform raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(origin, direction * (weaponConfig.Range or 500), raycastParams)

	-- Fire to server
	WeaponFired:FireServer(weaponName, origin, direction, raycastResult)

	-- Play effects
	PlayFireEffects(raycastResult)

	-- Auto reload if empty
	if currentAmmo <= 0 then
		ReloadWeapon()
	end
end

-- Play fire effects
function PlayFireEffects(raycastResult)
    -- Fire sound via SoundUtils
    local ok, SoundUtils = pcall(function()
        return require(ReplicatedStorage.FPSSystem.Modules.SoundUtils)
    end)
    if ok and SoundUtils then
        SoundUtils:PlayLocalSound("rbxassetid://4759267374", Camera, 0.5)
    else
        local fireSound = Instance.new("Sound")
        fireSound.SoundId = "rbxassetid://4759267374"  -- G36 fire sound
        fireSound.Volume = 0.5
        fireSound.Parent = Camera
        fireSound:Play()
        game:GetService("Debris"):AddItem(fireSound, 2)
    end

	-- Camera recoil
	local recoilAmount = weaponConfig.Recoil or 1.2
	local randomX = (math.random() - 0.5) * recoilAmount * 0.1
	local randomY = math.random() * recoilAmount * 0.15
	Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(-randomY), math.rad(randomX), 0)

	-- Viewmodel recoil
	ViewmodelSystem:ApplyRecoil(Vector3.new(randomX, randomY, recoilAmount * 0.12))

	-- Muzzle flash (if viewmodel exists)
	local viewmodel = ViewmodelSystem:GetActiveViewmodel()
	if viewmodel then
		local muzzle = viewmodel:FindFirstChild("Muzzle", true)
		if muzzle and muzzle:IsA("Attachment") then
			-- Create muzzle flash
			local flash = Instance.new("Part")
			flash.Name = "MuzzleFlash"
			flash.Size = Vector3.new(0.4, 0.4, 0.4)
			flash.CFrame = muzzle.WorldCFrame
			flash.Material = Enum.Material.Neon
			flash.Color = Color3.fromRGB(255, 200, 100)
			flash.Transparency = 0.3
			flash.CanCollide = false
			flash.Anchored = true
			flash.Parent = workspace

			local light = Instance.new("PointLight")
			light.Brightness = 4
			light.Range = 10
			light.Color = Color3.fromRGB(255, 200, 100)
			light.Parent = flash

			game:GetService("Debris"):AddItem(flash, 0.05)
		end
	end

	-- Bullet tracer
	if raycastResult then
        local distance = (raycastResult.Position - (origin or Camera.CFrame.Position)).Magnitude
		if distance > 10 then  -- Only show tracer for distant shots
			local tracer = Instance.new("Part")
			tracer.Size = Vector3.new(0.05, 0.05, distance)
			tracer.CFrame = CFrame.new(origin, raycastResult.Position) * CFrame.new(0, 0, -distance/2)
			tracer.Material = Enum.Material.Neon
			tracer.Color = Color3.fromRGB(255, 200, 100)
			tracer.Transparency = 0.5
			tracer.CanCollide = false
			tracer.Anchored = true
			tracer.Parent = workspace

			game:GetService("Debris"):AddItem(tracer, 0.1)
		end

		-- Bullet impact
		local hitPosition = raycastResult.Position
		local hitNormal = raycastResult.Normal  -- ✓ CORRECT - Get Normal from raycast result

		local impact = Instance.new("Part")
		impact.Size = Vector3.new(0.2, 0.2, 0.1)
		impact.CFrame = CFrame.new(hitPosition, hitPosition + hitNormal)
		impact.Material = Enum.Material.Neon
		impact.Color = Color3.fromRGB(255, 150, 50)
		impact.Transparency = 0.3
		impact.CanCollide = false
		impact.Anchored = true
		impact.Parent = workspace

		game:GetService("Debris"):AddItem(impact, 0.2)
	end
end

-- Reload weapon
function ReloadWeapon()
	if isReloading or currentAmmo >= weaponConfig.ClipSize or reserveAmmo <= 0 then
		return
	end

	isReloading = true
	isFiring = false  -- Stop firing during reload

	-- Play reload sound
	local reloadSound = Instance.new("Sound")
	reloadSound.SoundId = "rbxassetid://138084889"  -- Reload sound
	reloadSound.Volume = 0.4
	reloadSound.Parent = Camera
	reloadSound:Play()
	game:GetService("Debris"):AddItem(reloadSound, 3)

	-- Wait for reload time
	task.wait(weaponConfig.ReloadTime or 2.5)

	-- Calculate ammo
	local ammoNeeded = weaponConfig.ClipSize - currentAmmo
	local ammoToAdd = math.min(ammoNeeded, reserveAmmo)

	currentAmmo = currentAmmo + ammoToAdd
	reserveAmmo = reserveAmmo - ammoToAdd

	isReloading = false

	-- Notify server
	WeaponReloaded:FireServer(weaponName, currentAmmo, reserveAmmo)

	print("Reloaded:", weaponName, "Ammo:", currentAmmo .. "/" .. reserveAmmo)
end

-- Auto-fire loop for assault rifles
local function StartAutoFire()
	isFiring = true
	while isFiring and isEquipped do
		FireWeapon()
		task.wait(0.01)  -- Small delay to prevent overload
	end
end

-- Tool equipped
tool.Equipped:Connect(function()
	isEquipped = true
	print("Equipped:", weaponName)

	-- Notify server (FIXED: send table with WeaponName key, not just string)
	WeaponEquipped:FireServer({WeaponName = weaponName})

	-- ViewmodelSystem automatically creates viewmodel when tool equipped
	-- No manual viewmodel creation needed!
end)

-- Tool unequipped
tool.Unequipped:Connect(function()
	isEquipped = false
	isReloading = false
	isFiring = false
	print("Unequipped:", weaponName)

	-- Notify server (FIXED: send table with WeaponName key, not just string)
	WeaponUnequipped:FireServer({WeaponName = weaponName})

	-- ViewmodelSystem automatically removes viewmodel
end)

-- Mouse input (Full-auto support)
mouse.Button1Down:Connect(function()
	if isEquipped and fireMode == "Auto" then
		-- Start auto-fire
		StartAutoFire()
	elseif isEquipped and fireMode == "Semi" then
		-- Single shot
		FireWeapon()
	end
end)

mouse.Button1Up:Connect(function()
	-- Stop auto-fire
	isFiring = false
end)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isEquipped then return end

	if input.KeyCode == Enum.KeyCode.R then
		-- Reload
		ReloadWeapon()
	elseif input.KeyCode == Enum.KeyCode.V then
		-- Toggle fire mode
		if fireMode == "Auto" then
			fireMode = "Semi"
			print("Fire mode: Semi-Auto")
		else
			fireMode = "Auto"
			print("Fire mode: Full-Auto")
		end
	end
end)

print("G36 script loaded ✓")
