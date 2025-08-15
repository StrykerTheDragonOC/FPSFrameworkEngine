-- Enhanced Weapon Base System with Attachment Support
local WeaponBase = {}
WeaponBase.__index = WeaponBase

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local ATTACHMENT_SLOTS = {
	SIGHT = "SIGHT",
	BARREL = "BARREL",
	UNDERBARREL = "UNDERBARREL",
	OTHER = "OTHER",
	AMMO = "AMMO"
}

local SCOPE_MODES = {
	GUI = "GUI",
	MODEL = "MODEL"
}

function WeaponBase.new(config)
	local self = setmetatable({}, WeaponBase)

	-- Basic weapon stats
	self.config = config or {
		name = "Base Weapon",
		damage = 25,
		fireRate = 600,
		recoil = {
			vertical = 1.2,
			horizontal = 0.3,
			recovery = 0.95
		},
		mobility = {
			adsSpeed = 0.3,
			walkSpeed = 14,
			sprintSpeed = 20
		},
		magazine = {
			size = 30,
			maxAmmo = 120,
			reloadTime = 2.5
		}
	}

	-- State management
	self.state = {
		isEquipped = false,
		isAiming = false,
		isSprinting = false,
		currentAmmo = self.config.magazine.size,
		reserveAmmo = self.config.magazine.maxAmmo,
		scopeMode = SCOPE_MODES.MODEL,
		lastShot = 0
	}

	-- Attachments system
	self.attachments = {
		[ATTACHMENT_SLOTS.SIGHT] = nil,
		[ATTACHMENT_SLOTS.BARREL] = nil,
		[ATTACHMENT_SLOTS.UNDERBARREL] = nil,
		[ATTACHMENT_SLOTS.OTHER] = nil,
		[ATTACHMENT_SLOTS.AMMO] = nil
	}

	-- Initialize systems
	self:setupViewmodel()
	self:setupInputs()

	return self
end

function WeaponBase:setupViewmodel()
	-- Create viewmodel container
	self.viewmodel = Instance.new("Model")
	self.viewmodel.Name = (self.config.name or "Weapon") .. "Viewmodel"

	-- Create a root part for the viewmodel
	local rootPart = Instance.new("Part")
	rootPart.Name = "ViewmodelRoot"
	rootPart.Size = Vector3.new(0.1, 0.1, 0.1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = self.viewmodel
	self.viewmodel.PrimaryPart = rootPart

	-- Create attachment points
	local attachmentTypes = {
		{Name = "MuzzlePoint", CFrame = CFrame.new(0, 0, -0.5)},
		{Name = "SightPoint", CFrame = CFrame.new(0, 0.2, 0)},
		{Name = "RightGripPoint", CFrame = CFrame.new(0.2, -0.1, 0)},
		{Name = "LeftGripPoint", CFrame = CFrame.new(-0.2, -0.1, 0)}
	}

	for _, attachInfo in ipairs(attachmentTypes) do
		local attachment = Instance.new("Attachment")
		attachment.Name = attachInfo.Name
		attachment.CFrame = attachInfo.CFrame
		attachment.Parent = rootPart
	end

	return self.viewmodel
end

function WeaponBase:setupInputs()
	-- Scope mode toggle
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.T then
			self:toggleScopeMode()
		end
	end)
end

function WeaponBase:attachItem(slot, attachment)
	-- Validate attachment slot
	if not ATTACHMENT_SLOTS[slot] then
		warn("Invalid attachment slot:", slot)
		return false
	end

	-- Remove existing attachment if any
	if self.attachments[slot] then
		self:removeAttachment(slot)
	end

	-- Apply attachment
	self.attachments[slot] = attachment

	-- Apply stat modifications
	if attachment.statModifiers then
		for stat, modifier in pairs(attachment.statModifiers) do
			if type(self.config[stat]) == "number" then
				self.config[stat] = self.config[stat] * modifier
			end
		end
	end

	-- Update viewmodel (if attachment has a model)
	if attachment.model then
		local attachPoint = self.viewmodel.PrimaryPart:FindFirstChild(slot .. "Mount")
		if attachPoint then
			local model = attachment.model:Clone()
			model.Parent = self.viewmodel
			model:PivotTo(attachPoint.WorldCFrame)
		end
	end

	return true
end

function WeaponBase:removeAttachment(slot)
	local attachment = self.attachments[slot]
	if not attachment then return end

	-- Revert stat modifications
	if attachment.statModifiers then
		for stat, modifier in pairs(attachment.statModifiers) do
			if type(self.config[stat]) == "number" then
				self.config[stat] = self.config[stat] / modifier
			end
		end
	end

	-- Remove physical model
	local existingModel = self.viewmodel:FindFirstChild(slot .. "Mount")
	if existingModel then
		existingModel:Destroy()
	end

	self.attachments[slot] = nil
end

function WeaponBase:toggleScopeMode()
	-- Toggle between GUI and MODEL scope modes
	self.state.scopeMode = self.state.scopeMode == SCOPE_MODES.GUI 
		and SCOPE_MODES.MODEL 
		or SCOPE_MODES.GUI

	-- Update scope visuals
	self:updateScopeVisuals()
end

function WeaponBase:updateScopeVisuals()
	local sight = self.attachments[ATTACHMENT_SLOTS.SIGHT]
	if not sight then return end

	if self.state.scopeMode == SCOPE_MODES.GUI then
		-- Show GUI scope
		if sight.guiScope then
			sight.guiScope.Visible = true
		end
		-- Hide model scope
		if sight.model then
			sight.model.Transparency = 1
		end
	else
		-- Show model scope
		if sight.model then
			sight.model.Transparency = 0
		end
		-- Hide GUI scope
		if sight.guiScope then
			sight.guiScope.Visible = false
		end
	end
end

-- Additional utility methods
function WeaponBase:setAiming(isAiming)
	self.state.isAiming = isAiming
	-- Additional aiming logic can be added here
end

function WeaponBase:setSprinting(isSprinting)
	self.state.isSprinting = isSprinting
	-- Additional sprinting logic can be added here
end

return WeaponBase