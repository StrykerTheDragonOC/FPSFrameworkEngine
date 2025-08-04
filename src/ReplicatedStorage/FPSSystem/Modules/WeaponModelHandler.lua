-- Weapon Model Handler
-- This system ensures proper structure for weapon models
local WeaponModelHandler = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function WeaponModelHandler.processWeaponModel(weaponPart)
	-- Create a Model to contain the weapon parts if not already in one
	local weaponModel = (weaponPart:IsA("Model") and weaponPart) or Instance.new("Model")
	weaponModel.Name = weaponPart.Name

	if not weaponPart:IsA("Model") then
		-- If we're starting with just a part, set it up properly
		local mainPart = weaponPart:Clone()
		mainPart.Name = "Handle"  -- Rename to standard name
		mainPart.Parent = weaponModel
		weaponModel.PrimaryPart = mainPart

		-- Create necessary attachments
		local attachments = {
			MuzzlePoint = CFrame.new(0, 0, -mainPart.Size.Z/2),
			RightGripPoint = CFrame.new(0.2, -0.2, 0),
			LeftGripPoint = CFrame.new(-0.2, -0.2, 0),
			AimPoint = CFrame.new(0, 0.15, 0),
			ShellEjectPoint = CFrame.new(0.1, 0.1, 0)
		}

		for name, offset in pairs(attachments) do
			if not mainPart:FindFirstChild(name) then
				local attachment = Instance.new("Attachment")
				attachment.Name = name
				attachment.CFrame = offset
				attachment.Parent = mainPart
			end
		end
	end

	-- Validate model structure
	if not weaponModel.PrimaryPart then
		local mainPart = weaponModel:FindFirstChild("Handle") or
			weaponModel:FindFirstChild("Gun") or
			weaponModel:FindFirstChildWhichIsA("BasePart")

		if mainPart then
			weaponModel.PrimaryPart = mainPart
		else
			error("Weapon model must have a primary part")
		end
	end

	return weaponModel
end

function WeaponModelHandler.loadWeaponFromPath(category, subcategory, weaponName)
	-- Construct path to weapon
	local weaponsFolder = ReplicatedStorage.FPSSystem.ViewModels.Weapons
	local weaponPath = weaponsFolder

	if category then
		weaponPath = weaponPath[category]
		if subcategory then
			weaponPath = weaponPath[subcategory]
		end
	end

	local weaponModel = weaponPath:FindFirstChild(weaponName)
	if not weaponModel then
		warn(string.format("Could not find weapon: %s in %s/%s", 
			weaponName, category or "", subcategory or ""))
		return nil
	end

	-- Process and validate the weapon model
	local processedModel = WeaponModelHandler.processWeaponModel(weaponModel)
	return processedModel
end

-- Example usage:

local weaponModel = WeaponModelHandler.loadWeaponFromPath(
    "Primary", 
    "AssaultRifles", 
    "G36"
)


return WeaponModelHandler