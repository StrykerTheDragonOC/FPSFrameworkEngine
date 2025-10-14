# Quick Weapon Fix Guide

**URGENT**: These are immediate fixes for critical weapon errors.

---

## Issue 1: RemoteEventsManager Not Found

**Error**: `RemoteEventsManager is not a valid member of Folder`

**Location**: All weapon LocalScripts (M9, G36, PocketKnife, etc.)

### Fix for M9 (Apply same pattern to all weapons)

**File**: `src/ServerStorage/Weapons/Secondary/Pistols/M9/LocalScript.client.lua`

Replace lines 10 and 49 with this:

```lua
-- OLD (LINE 10 - DELETE THIS):
local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

-- NEW (LINE 10 - USE THIS):
local RemoteEvents = ReplicatedStorage.FPSSystem.RemoteEvents
local WeaponFired = RemoteEvents:WaitForChild("WeaponFired")
local WeaponReloaded = RemoteEvents:WaitForChild("WeaponReloaded")
local WeaponEquipped = RemoteEvents:WaitForChild("WeaponEquipped")
local WeaponUnequipped = RemoteEvents:WaitForChild("WeaponUnequipped")
```

```lua
-- OLD (LINE 49 - DELETE THIS):
RemoteEventsManager:FireServer("WeaponFired", {
	WeaponName = weaponName,
	Origin = Camera.CFrame.Position,
	Direction = rayDirection,
	Hit = rayResult.Hit,
	Distance = rayResult.Distance,
	Damage = weaponStats.Damage
})

-- NEW (LINE 49 - USE THIS):
WeaponFired:FireServer(weaponName, Camera.CFrame.Position, rayDirection, rayResult)
```

---

## Issue 2: Viewmodel Not Showing

**Cause**: ViewmodelSystem now auto-creates viewmodels when tool is equipped, but needs proper WeaponConfig structure.

### Fix: Verify WeaponConfig has correct structure

**File**: `src/ReplicatedStorage/FPSSystem/Modules/WeaponConfig.lua`

Ensure M9 (and all weapons) have these fields:

```lua
Weapons = {
	M9 = {
		Name = "M9",
		Category = "Secondary",  -- REQUIRED: Must be "Primary", "Secondary", "Melee", or "Grenade"
		Type = "Pistols",        -- REQUIRED: Subcategory like "Pistols", "AssaultRifles", etc.

		-- All other stats...
		ClipSize = 15,
		TotalAmmo = 120,
		Damage = 25,
		Range = 250,
		FireRate = 400,
		Recoil = 0.8,
		-- etc...
	},
}
```

### Fix: Ensure viewmodel exists in correct location

**Location**: `ReplicatedStorage/FPSSystem/Viewmodels/Secondary/Pistols/M9`

```
ReplicatedStorage
└─ FPSSystem
   └─ Viewmodels (or ViewModels - both work)
      └─ Secondary
         └─ Pistols
            └─ M9 (Model or folder containing Model)
               ├─ CameraPart (Part) ← REQUIRED for viewmodel to work
               ├─ GunModel (Model)
               │  └─ Handle (Part)
               │     ├─ Muzzle (Attachment)
               │     └─ EjectionPort (Attachment)
               └─ Arms (Model) ← Optional
```

**CRITICAL**: The viewmodel MUST have a part named "CameraPart" or it won't display!

---

## Issue 3: CFrame.Normal Error

**Error**: `Normal is not a valid member of CFrame`

**Location**: M9 LocalScript line ~226 (in bullet impact code)

### Fix:

```lua
-- OLD (WRONG):
local hitCFrame = rayResult.Position
local hitNormal = hitCFrame.Normal  -- ERROR: CFrame doesn't have Normal

-- NEW (CORRECT):
local hitPosition = rayResult.Position
local hitNormal = rayResult.Normal  -- Get Normal from raycast result
```

---

## Complete Fixed M9 LocalScript

Save this as `src/ServerStorage/Weapons/Secondary/Pistols/M9/LocalScript.client.lua`:

```lua
--[[
	M9 Pistol Client Script
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
local currentAmmo = weaponConfig.ClipSize or 15
local reserveAmmo = weaponConfig.TotalAmmo or 120
local isReloading = false
local canFire = true
local lastFireTime = 0
local isEquipped = false

-- Fire weapon
local function FireWeapon()
	if not canFire or isReloading or currentAmmo <= 0 or not isEquipped then
		if currentAmmo <= 0 then
			-- Play dry fire sound
			local drySound = Instance.new("Sound")
			drySound.SoundId = "rbxassetid://2697295462"  -- Dry fire sound
			drySound.Volume = 0.3
			drySound.Parent = Camera
			drySound:Play()
			game:GetService("Debris"):AddItem(drySound, 1)
		end
		return
	end

	local currentTime = tick()
	local fireRate = 60 / (weaponConfig.FireRate or 400)

	if currentTime - lastFireTime < fireRate then return end

	lastFireTime = currentTime
	currentAmmo = currentAmmo - 1

	-- Get camera direction
	local origin = Camera.CFrame.Position
	local direction = (mouse.Hit.Position - origin).Unit

	-- Perform raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = workspace:Raycast(origin, direction * (weaponConfig.Range or 250), raycastParams)

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
	-- Fire sound
	local fireSound = Instance.new("Sound")
	fireSound.SoundId = "rbxassetid://94221465811439"  -- M9 fire sound
	fireSound.Volume = 0.5
	fireSound.Parent = Camera
	fireSound:Play()
	game:GetService("Debris"):AddItem(fireSound, 2)

	-- Camera recoil
	local recoilAmount = weaponConfig.Recoil or 0.8
	local randomX = (math.random() - 0.5) * recoilAmount * 0.08
	local randomY = math.random() * recoilAmount * 0.12
	Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(-randomY), math.rad(randomX), 0)

	-- Viewmodel recoil
	ViewmodelSystem:ApplyRecoil(Vector3.new(randomX, randomY, recoilAmount * 0.1))

	-- Muzzle flash (if viewmodel exists)
	local viewmodel = ViewmodelSystem:GetActiveViewmodel()
	if viewmodel then
		local muzzle = viewmodel:FindFirstChild("Muzzle", true)
		if muzzle and muzzle:IsA("Attachment") then
			-- Create muzzle flash
			local flash = Instance.new("Part")
			flash.Name = "MuzzleFlash"
			flash.Size = Vector3.new(0.3, 0.3, 0.3)
			flash.CFrame = muzzle.WorldCFrame
			flash.Material = Enum.Material.Neon
			flash.Color = Color3.fromRGB(255, 200, 100)
			flash.Transparency = 0.3
			flash.CanCollide = false
			flash.Anchored = true
			flash.Parent = workspace

			local light = Instance.new("PointLight")
			light.Brightness = 3
			light.Range = 8
			light.Color = Color3.fromRGB(255, 200, 100)
			light.Parent = flash

			game:GetService("Debris"):AddItem(flash, 0.05)
		end
	end

	-- Bullet tracer
	if raycastResult then
		local distance = (raycastResult.Position - origin).Magnitude
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

	-- Play reload sound
	local reloadSound = Instance.new("Sound")
	reloadSound.SoundId = "rbxassetid://2697294766"  -- Reload sound
	reloadSound.Volume = 0.4
	reloadSound.Parent = Camera
	reloadSound:Play()
	game:GetService("Debris"):AddItem(reloadSound, 3)

	-- Wait for reload time
	task.wait(weaponConfig.ReloadTime or 2.0)

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

-- Tool equipped
tool.Equipped:Connect(function()
	isEquipped = true
	print("Equipped:", weaponName)

	-- Notify server
	WeaponEquipped:FireServer(weaponName)

	-- ViewmodelSystem automatically creates viewmodel when tool equipped
	-- No manual viewmodel creation needed!
end)

-- Tool unequipped
tool.Unequipped:Connect(function()
	isEquipped = false
	isReloading = false
	print("Unequipped:", weaponName)

	-- Notify server
	WeaponUnequipped:FireServer(weaponName)

	-- ViewmodelSystem automatically removes viewmodel
end)

-- Mouse input
mouse.Button1Down:Connect(function()
	if isEquipped then
		-- For semi-auto pistol, fire once per click
		FireWeapon()
	end
end)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isEquipped then return end

	if input.KeyCode == Enum.KeyCode.R then
		-- Reload
		ReloadWeapon()
	end
end)

print("M9 script loaded ✓")
```

---

## Apply to All Weapons

Use the same pattern for:
- G36: `src/ServerStorage/Weapons/Primary/AssaultRifles/G36/LocalScript.client.lua`
- PocketKnife: `src/ServerStorage/Weapons/Melee/.../PocketKnife/LocalScript.client.lua`
- All other weapons

Key changes:
1. Replace `RemoteEventsManager` with individual remote events
2. Remove manual viewmodel creation (ViewmodelSystem does it automatically)
3. Fix `CFrame.Normal` → `raycastResult.Normal`
4. Ensure WeaponConfig has `Category` and `Type` fields

---

## Test Checklist

After fixing:
- [ ] No RemoteEventsManager errors
- [ ] Viewmodel shows up when equipping weapon
- [ ] Gun fires (click to shoot)
- [ ] Ammo decreases
- [ ] Reloading works (R key)
- [ ] Muzzle flash appears
- [ ] No "Normal is not a valid member of CFrame" errors

---

**Next**: Once M9 works, copy the same pattern to G36, PocketKnife, and all other weapons.
