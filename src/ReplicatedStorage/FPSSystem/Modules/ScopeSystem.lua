-- Advanced Scope System with Model-Based Iron Sights
local ScopeSystem = {}
ScopeSystem.__index = ScopeSystem

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Constants for scope behavior and appearance
local SCOPE_SETTINGS = {
	TRANSITION_TIME = 0.3,
	DEFAULT_FOV = 70,
	ADS_FOV = 50  -- Aim Down Sight Field of View
}

-- Create a new scope system instance
function ScopeSystem.new()
	local self = setmetatable({}, ScopeSystem)

	-- Initialize core components
	self.player = Players.LocalPlayer
	self.camera = workspace.CurrentCamera

	-- Scope state tracking
	self.isScoped = false
	self.currentWeapon = nil

	return self
end

function ScopeSystem:scope(weapon, isScoping)
	print("Scoping weapon:", weapon, "State:", isScoping)

	-- Validate weapon
	if not weapon then
		warn("No weapon provided for scoping")
		return
	end

	self.isScoped = isScoping
	self.currentWeapon = weapon

	if isScoping then
		-- Start scope transition
		self:startScopeTransition()
	else
		-- Reset view
		self:resetScopeView()
	end
end

function ScopeSystem:startScopeTransition()
	if not self.currentWeapon then
		warn("Cannot start scope transition - invalid weapon")
		return
	end

	-- Find sight attachment in the weapon model
	local sightAttachment = self:findSightAttachment()

	-- Change FOV to ADS FOV
	TweenService:Create(
		self.camera,
		TweenInfo.new(SCOPE_SETTINGS.TRANSITION_TIME),
		{FieldOfView = SCOPE_SETTINGS.ADS_FOV}
	):Play()

	-- Optional: Adjust camera to look through iron sights
	if sightAttachment then
		-- Adjust camera to align with sight
		local sightCFrame = sightAttachment.WorldCFrame
		self.camera.CFrame = sightCFrame * CFrame.new(0, 0, -0.5)  -- Offset to simulate looking through sights
	end
end

function ScopeSystem:resetScopeView()
	if not self.currentWeapon then
		warn("Cannot reset scope view - no current weapon")
		return
	end

	-- Reset FOV to default
	TweenService:Create(
		self.camera,
		TweenInfo.new(SCOPE_SETTINGS.TRANSITION_TIME),
		{FieldOfView = SCOPE_SETTINGS.DEFAULT_FOV}
	):Play()

	-- Reset camera position
	self.camera.CFrame = self.camera.CFrame * CFrame.new(0, 0, 0.5)
end

function ScopeSystem:findSightAttachment()
	if not self.currentWeapon or not self.currentWeapon.model then
		return nil
	end

	-- Look for sight-related attachments
	local sightAttachments = {
		"SightPoint",
		"IronSight",
		"Sight",
		"AimPoint"
	}

	for _, attachmentName in ipairs(sightAttachments) do
		local attachment = self.currentWeapon.model:FindFirstChild(attachmentName, true)
		if attachment then
			return attachment
		end
	end

	return nil
end

function ScopeSystem:toggleScopeMode()
	-- For model-based iron sights, this doesn't do anything
	print("Scope mode toggle not applicable for model-based sights")
end

function ScopeSystem:setupInputs()
	-- No special input handling needed for model-based sights
end

return ScopeSystem