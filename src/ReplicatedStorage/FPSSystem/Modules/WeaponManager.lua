-- WeaponManager.lua
-- Place this in ReplicatedStorage.FPSSystem.Modules
local WeaponManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- References
local player = Players.LocalPlayer

-- Find a model in the workspace hierarchy
function WeaponManager.findWeaponModel(weaponName, category)
	print("Searching for weapon: " .. weaponName)

	-- First try to find it in Camera.ViewmodelContainer.ViewmodelRig
	local camera = workspace:FindFirstChild("Camera")
	if camera then
		local container = camera:FindFirstChild("ViewmodelContainer")
		if container then
			local rig = container:FindFirstChild("ViewmodelRig") or 
				container:FindFirstChild("DefaultArms")

			if rig and rig:FindFirstChild(weaponName) then
				print("Found existing " .. weaponName .. " in ViewmodelRig")
				return rig[weaponName]
			end
		end
	end

	-- Try paths from ReplicatedStorage
	local paths = {
		{"FPSSystem", "WeaponModels", "Primary", "AssaultRifles", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "AssaultRifles", weaponName},
		{"FPSSystem", "WeaponModels", "Primary", "Carbines", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "Carbines", weaponName},
		{"FPSSystem", "WeaponModels", "Primary", "SMGS", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "SMGS", weaponName},
		{"FPSSystem", "WeaponModels", "Primary", "DMRS", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "DMRS", weaponName},
		{"FPSSystem", "WeaponModels", "Primary", "Shotguns", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "Shotguns", weaponName},
		{"FPSSystem", "WeaponModels", "Primary", "LMGS", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "LMGS", weaponName},
		{"FPSSystem", "WeaponModels", "Primary", "SniperRifles", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Primary", "SniperRifles", weaponName},
		{"FPSSystem", "WeaponModels", "Secondary", "Pistols", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Secondary", "Pistols", weaponName},
		{"FPSSystem", "WeaponModels", "Secondary", "AutomaticPistols", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Secondary", "AutomaticPistols", weaponName},
		{"FPSSystem", "WeaponModels", "Secondary", "Revolvers", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Secondary", "Revolvers", weaponName},
		{"FPSSystem", "WeaponModels", "Secondary", "Other", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Secondary", "Other", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Grenades", weaponName},
		{"FPSSystem", "WeaponModels", "Grenades",weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Melee", "BladeOneHand", weaponName},
		{"FPSSystem", "WeaponModels", "Melee", "BladeOneHand", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Melee", "BladeTwoHand", weaponName},
		{"FPSSystem", "WeaponModels", "Melee", "BladeTwoHand", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Melee", "BluntOneHand", weaponName},
		{"FPSSystem", "WeaponModels", "Melee", "BluntOneHand", weaponName},
		{"FPSSystem", "ViewModels", "Weapons", "Melee", "BluntTwoHand", weaponName},
		{"FPSSystem", "WeaponModels", "Melee", "BluntTwoHand", weaponName},
	}

	for _, path in ipairs(paths) do
		local current = ReplicatedStorage
		local valid = true

		-- Follow path
		for _, folder in ipairs(path) do
			current = current:FindFirstChild(folder)
			if not current then 
				valid = false
				break 
			end
		end

		if valid then
			print("Found " .. weaponName .. " at path: " .. table.concat(path, "."))
			return current
		end
	end

	print("Could not find " .. weaponName .. " in predefined paths, doing deep search")

	-- Deep search as last resort
	local function deepSearch(parent, depth)
		if depth > 10 then return nil end -- Prevent too deep searches

		for _, child in ipairs(parent:GetChildren()) do
			if child.Name == weaponName and (child:IsA("Model") or child:IsA("BasePart")) then
				print("Found " .. weaponName .. " via deep search at: " .. child:GetFullName())
				return child
			end

			if #child:GetChildren() > 0 then
				local result = deepSearch(child, depth + 1)
				if result then return result end
			end
		end
		return nil
	end

	return deepSearch(ReplicatedStorage, 0)
end

-- Create a default weapon model
function WeaponManager.createWeaponModel(weaponName, weaponType)
	print("Creating default model for: " .. weaponName)

	local model = Instance.new("Model")
	model.Name = weaponName

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = true
	handle.CanCollide = false
	handle.Size = Vector3.new(0.4, 0.3, 2)
	handle.Color = Color3.fromRGB(80, 80, 80)
	handle.Parent = model
	model.PrimaryPart = handle

	if weaponType == "G36" or weaponType == "AssaultRifle" then
		-- Add barrel
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Size = Vector3.new(0.15, 0.15, 0.8)
		barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - barrel.Size.Z/2)
		barrel.Anchored = true
		barrel.CanCollide = false
		barrel.Color = Color3.fromRGB(50, 50, 50)
		barrel.Parent = model

		-- Add magazine
		local mag = Instance.new("Part")
		mag.Name = "Mag"
		mag.Size = Vector3.new(0.25, 0.5, 0.2)
		mag.CFrame = handle.CFrame * CFrame.new(0, -0.3, 0)
		mag.Anchored = true
		mag.CanCollide = false
		mag.Color = Color3.fromRGB(40, 40, 40)
		mag.Parent = model
	elseif weaponType == "Knife" then
		handle.Size = Vector3.new(0.2, 0.8, 0.2)

		-- Add blade
		local blade = Instance.new("Part")
		blade.Name = "Blade"
		blade.Size = Vector3.new(0.05, 0.8, 0.3)
		blade.CFrame = handle.CFrame * CFrame.new(0, 0.8, 0)
		blade.Anchored = true
		blade.CanCollide = false
		blade.Color = Color3.fromRGB(200, 200, 200)
		blade.Parent = model
	elseif weaponType == "Grenade" then
		handle.Size = Vector3.new(0.8, 0.8, 0.8)
		handle.Shape = Enum.PartType.Ball
		handle.Color = Color3.fromRGB(30, 100, 30)
	end

	-- Add attachment points
	local attachPoints = {
		{Name = "MuzzlePoint", Offset = CFrame.new(0, 0, -handle.Size.Z/2)},
		{Name = "RightGripPoint", Offset = CFrame.new(0.15, -0.1, 0)},
		{Name = "LeftGripPoint", Offset = CFrame.new(-0.15, -0.1, 0)},
		{Name = "AimPoint", Offset = CFrame.new(0, 0.1, 0)}
	}

	for _, attachInfo in ipairs(attachPoints) do
		local attachment = Instance.new("Attachment")
		attachment.Name = attachInfo.Name
		attachment.CFrame = attachInfo.Offset
		attachment.Parent = handle
	end

	return model
end

-- Load a weapon by name
function WeaponManager.loadWeapon(weaponName, weaponType)
	-- Try to find existing model
	local model = WeaponManager.findWeaponModel(weaponName)

	-- If not found, create default
	if not model then
		print("Creating default model for: " .. weaponName)
		model = WeaponManager.createWeaponModel(weaponName, weaponType or weaponName)
	else
		-- Clone to avoid modifying original
		model = model:Clone()
	end

	-- Ensure model is properly set up
	if model:IsA("Model") and not model.PrimaryPart then
		-- Try to find a suitable primary part
		local potentialParts = {"Handle", "Body", "Gun", "Main"}
		for _, partName in ipairs(potentialParts) do
			local part = model:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				model.PrimaryPart = part
				break
			end
		end

		-- If still no primary part, use first BasePart
		if not model.PrimaryPart then
			local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
			if firstPart then
				model.PrimaryPart = firstPart
			else
				warn("No suitable parts found for PrimaryPart in: " .. weaponName)

				-- Create a handle part
				local handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Size = Vector3.new(0.5, 0.3, 2)
				handle.Transparency = 0.5
				handle.Anchored = true
				handle.CanCollide = false
				handle.Parent = model
				model.PrimaryPart = handle
			end
		end
	end

	return model
end

-- Get G36 as default primary
function WeaponManager.getG36()
	return WeaponManager.loadWeapon("G36", "G36")
end

return WeaponManager