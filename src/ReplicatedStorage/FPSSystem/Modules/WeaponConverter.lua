-- Enhanced WeaponConverter with better PrimaryPart handling
local WeaponConverter = {}

-- Helper function to safely find the most suitable primary part
local function findBestPrimaryPart(model)
	-- Try to find these parts in order of preference
	local partNames = {"Handle", "Gun", "Receiver", "Body", "Main", "Base"}

	for _, name in ipairs(partNames) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	-- Fall back to any BasePart
	return model:FindFirstChildWhichIsA("BasePart", true)
end

-- Helper function to ensure proper model structure
function WeaponConverter.ensureModelStructure(weapon)
	if not weapon then
		warn("WeaponConverter: No weapon provided")
		return nil
	end

	local model

	-- If we got a Part instead of a Model, create a proper Model
	if weapon:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = weapon.Name
		local clone = weapon:Clone()
		clone.Name = "Handle" -- Rename the part to be more descriptive
		clone.Parent = model
		model.PrimaryPart = clone
		print("WeaponConverter: Created model from part: " .. weapon.Name)
	elseif weapon:IsA("Model") then
		model = weapon:Clone()

		-- Ensure it has a PrimaryPart
		if not model.PrimaryPart then
			local mainPart = findBestPrimaryPart(model)

			if mainPart then
				model.PrimaryPart = mainPart
				print("WeaponConverter: Assigned PrimaryPart for " .. model.Name .. ": " .. mainPart.Name)
			else
				warn("WeaponConverter: Failed to find suitable PrimaryPart for " .. model.Name)

				-- Create a new handle if no suitable part found
				local newHandle = Instance.new("Part")
				newHandle.Name = "Handle"
				newHandle.Size = Vector3.new(0.5, 0.5, 2)
				newHandle.Transparency = 0.5
				newHandle.CanCollide = false

				-- Position at center of model
				local modelCenter = Vector3.new(0, 0, 0)
				local partCount = 0

				for _, part in pairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						modelCenter = modelCenter + part.Position
						partCount = partCount + 1
					end
				end

				if partCount > 0 then
					modelCenter = modelCenter / partCount
				end

				newHandle.Position = modelCenter
				newHandle.Parent = model
				model.PrimaryPart = newHandle

				print("WeaponConverter: Created new Handle part for " .. model.Name)
			end
		end
	else
		warn("WeaponConverter: Invalid weapon type: " .. weapon.ClassName)
		return nil
	end

	-- Validate model has BaseParts
	local hasParts = false
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			hasParts = true
			break
		end
	end

	if not hasParts then
		warn("WeaponConverter: Model has no parts: " .. model.Name)
		return nil
	end

	-- Create attachments if they don't exist
	local primaryPart = model.PrimaryPart
	local attachments = {
		MuzzlePoint = CFrame.new(0, 0, -primaryPart.Size.Z/2),
		ShellEjectPoint = CFrame.new(0.1, 0.1, 0),
		AimPoint = CFrame.new(0, 0.15, 0),
		RightGripPoint = CFrame.new(0.2, -0.2, 0),
		LeftGripPoint = CFrame.new(-0.2, -0.2, 0)
	}

	for name, offset in pairs(attachments) do
		if not primaryPart:FindFirstChild(name) then
			local attachment = Instance.new("Attachment")
			attachment.Name = name
			attachment.CFrame = offset
			attachment.Parent = primaryPart
		end
	end

	return model
end


-- Convert from an existing model
function WeaponConverter.convertFromModel(model)
	if not model then
		warn("WeaponConverter: No model provided")
		return nil
	end

	-- Ensure proper model structure
	local worldModel = WeaponConverter.ensureModelStructure(model)
	if not worldModel then
		warn("WeaponConverter: Failed to create proper model structure from model")
		return nil
	end

	-- Create viewmodel version
	local viewModel = worldModel:Clone()
	viewModel.Name = model.Name .. "Viewmodel"

	return {
		worldModel = worldModel,
		viewModel = viewModel
	}
end
-- Add this helper function to your WeaponConverter module

-- Enhanced path finding for different folder structures
-- Replace the findWeaponModel function in WeaponConverter with this safer version

function WeaponConverter.findWeaponModel(weaponName, category)
	-- Get standard locations
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- Safe access function to avoid nil errors
	local function safeFind(parent, childName)
		if parent and typeof(parent) == "Instance" then
			return parent:FindFirstChild(childName)
		end
		return nil
	end

	-- Chain of safe lookups for deeper paths
	local function safePath(...)
		local args = {...}
		local current = args[1]

		for i = 2, #args do
			if current then
				current = safeFind(current, args[i])
			else
				return nil
			end
		end

		return current
	end

	-- Check direct weapon name match
	local directMatch = safeFind(ReplicatedStorage, weaponName)
	if directMatch then
		return directMatch
	end

	-- Check in AssaultRifles (based on your folder structure screenshot)
	local inAssaultRifles = safePath(ReplicatedStorage, "AssaultRifles", weaponName)
	if inAssaultRifles then
		print("WeaponConverter: Found " .. weaponName .. " in AssaultRifles")
		return inAssaultRifles
	end

	-- Check in FPSSystem paths
	local inFPSSystem = safePath(ReplicatedStorage, "FPSSystem", "Weapons", category, weaponName)
	if inFPSSystem then
		return inFPSSystem
	end

	-- Check in plain Weapons folder if it exists
	local weaponsFolder = safeFind(ReplicatedStorage, "Weapons")
	if weaponsFolder then
		-- Try direct in Weapons
		local inWeapons = safeFind(weaponsFolder, weaponName)
		if inWeapons then
			return inWeapons
		end

		-- Try in category subfolder
		if category then
			local categoryFolder = safeFind(weaponsFolder, category)
			if categoryFolder then
				local inCategory = safeFind(categoryFolder, weaponName)
				if inCategory then
					return inCategory
				end
			end
		end

		-- Try in common weapon type folders
		local commonFolders = {"Primary", "Secondary", "AssaultRifles", "SMGs", "Snipers", "Pistols"}
		for _, folderName in ipairs(commonFolders) do
			local folder = safeFind(weaponsFolder, folderName)
			if folder then
				local inFolder = safeFind(folder, weaponName)
				if inFolder then
					return inFolder
				end
			end
		end
	end

	-- If all else fails, search the entire ReplicatedStorage
	print("WeaponConverter: Deep searching for " .. weaponName .. "...")

	local function deepSearch(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if child.Name == weaponName then
				print("WeaponConverter: Found " .. weaponName .. " via deep search in " .. child:GetFullName())
				return child
			end

			if #child:GetChildren() > 0 then
				local result = deepSearch(child)
				if result then
					return result
				end
			end
		end
		return nil
	end

	local deepResult = deepSearch(ReplicatedStorage)
	if deepResult then
		return deepResult
	end

	-- Not found anywhere
	warn("WeaponConverter: Could not find weapon: " .. weaponName)
	return nil
end
-- Updated version of convertFromCharacter
function WeaponConverter.convertFromCharacter(character, weaponName, category)
	-- Find the weapon
	local weapon = character:FindFirstChild(weaponName)
	if not weapon then
		-- If not found in character, try to find in ReplicatedStorage
		weapon = WeaponConverter.findWeaponModel(weaponName, category)
		if not weapon then
			warn("WeaponConverter: Could not find weapon:", weaponName)
			return nil
		end
	end

	-- Ensure proper model structure
	local worldModel = WeaponConverter.ensureModelStructure(weapon:Clone())
	if not worldModel then
		warn("WeaponConverter: Failed to create proper model structure")
		return nil
	end

	-- Create viewmodel version
	local viewModel = worldModel:Clone()
	viewModel.Name = weaponName .. "Viewmodel"

	return {
		worldModel = worldModel,
		viewModel = viewModel
	}
end

-- New direct model conversion function
function WeaponConverter.convertG36Direct()
	print("WeaponConverter: Attempting direct G36 conversion...")

	-- Try to find the G36 model directly 
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local model = nil

	-- Look for specifically the G36 model in AssaultRifles
	if ReplicatedStorage:FindFirstChild("SMGS") and 
		ReplicatedStorage.SMGS:FindFirstChild("G36") then
		model = ReplicatedStorage.SMGS.G36
		print("WeaponConverter: Found G36 directly in ReplicatedStorage.SMGS")
	end

	-- Check for it in specific FPS folders
	if not model and ReplicatedStorage:FindFirstChild("FPSSystem") and
		ReplicatedStorage.FPSSystem:FindFirstChild("Weapons") and
		ReplicatedStorage.FPSSystem.Weapons:FindFirstChild("AssaultRifles") and
		ReplicatedStorage.FPSSystem.Weapons.SMGS:FindFirstChild("G36") then
		model = ReplicatedStorage.FPSSystem.Weapons.SMGS.G36
		print("WeaponConverter: Found G36 in FPSSystem.Weapons.AssaultRifles")
	end

	-- If still not found, do a deep search
	if not model then
		print("WeaponConverter: G36 not found in expected locations, performing deep search...")
		model = WeaponConverter.findWeaponModel("G36", "SMGS")
	end

	-- If we found it, convert it
	if model then
		local worldModel = WeaponConverter.ensureModelStructure(model:Clone())
		if worldModel then
			local viewModel = worldModel:Clone()
			viewModel.Name = "G36"

			print("WeaponConverter: G36 conversion successful!")
			return {
				worldModel = worldModel,
				viewModel = viewModel
			}
		end
	end

	warn("WeaponConverter: Failed to find or convert G36 model")
	return nil
end
return WeaponConverter