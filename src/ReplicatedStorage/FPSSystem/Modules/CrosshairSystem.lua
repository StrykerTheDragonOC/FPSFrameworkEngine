-- CrosshairSystem.lua
-- Dynamic crosshair system that responds to player actions
-- Place in ReplicatedStorage.FPSSystem.Modules

local CrosshairSystem = {}
CrosshairSystem.__index = CrosshairSystem

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Constants for crosshair appearance and behavior
local CROSSHAIR_CONFIG = {
	DEFAULT_SIZE = 5,          -- Base size in pixels
	DEFAULT_THICKNESS = 2,     -- Line thickness
	DEFAULT_COLOR = Color3.fromRGB(255, 255, 255),
	HIT_COLOR = Color3.fromRGB(255, 0, 0),
	CRITICAL_HIT_COLOR = Color3.fromRGB(255, 80, 0),

	-- Spread multipliers for different states
	IDLE_SPREAD = 1.0,
	WALK_SPREAD = 1.5,
	RUN_SPREAD = 2.0,
	JUMP_SPREAD = 2.5,
	CROUCH_SPREAD = 0.7,
	ADS_SPREAD = 0.5,
	FIRE_SPREAD = 2.0,

	-- Animation settings
	SPREAD_SPEED = 0.3,        -- Speed of spread changes
	COLOR_CHANGE_SPEED = 0.2,  -- Speed of color transitions

	-- Hit marker settings
	HITMARKER_DURATION = 0.1,  -- How long the hit marker shows
	HITMARKER_SIZE = 7,

	-- Style settings
	CROSSHAIR_STYLE = {
		DEFAULT = 1,           -- + style crosshair
		DOT = 2,               -- Center dot only
		CIRCLE = 3,            -- Circle with dot
		CORNERS = 4,           -- Corner brackets
		CHEVRON = 5            -- Upward chevron (^)
	},

	-- Visibility settings
	HIDE_WHEN_ADS = true,      -- Hide crosshair when aiming down sights
	SHOW_HITMARKERS = true     -- Show hit confirmation markers
}

-- Create a new crosshair system
function CrosshairSystem.new()
	local self = setmetatable({}, CrosshairSystem)

	-- Initialize properties
	self.player = Players.LocalPlayer
	self.spread = CROSSHAIR_CONFIG.DEFAULT_SIZE
	self.targetSpread = CROSSHAIR_CONFIG.DEFAULT_SIZE
	self.lastShotTime = 0
	self.isFiring = false
	self.isAiming = false
	self.isMoving = false
	self.isCrouching = false
	self.isJumping = false
	self.crosshairStyle = CROSSHAIR_CONFIG.CROSSHAIR_STYLE.DEFAULT
	self.currentWeaponConfig = nil

	-- Create UI elements
	self:createCrosshair()

	-- Start update loop
	RunService.RenderStepped:Connect(function(dt)
		self:update(dt)
	end)

	print("CrosshairSystem initialized")
	return self
end

-- Create the crosshair GUI
function CrosshairSystem:createCrosshair()
	-- Create ScreenGui
	self.gui = Instance.new("ScreenGui")
	self.gui.Name = "CrosshairGui"
	self.gui.ResetOnSpawn = false
	self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Create container frame (centered)
	self.container = Instance.new("Frame")
	self.container.Name = "CrosshairContainer"
	self.container.Size = UDim2.new(0, 100, 0, 100)
	self.container.Position = UDim2.new(0.5, -50, 0.5, -50)
	self.container.BackgroundTransparency = 1
	self.container.Parent = self.gui

	-- Create standard crosshair lines (+ style)
	self.lines = {}
	local directions = {
		Top = {Position = UDim2.new(0.5, 0, 0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE), Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_THICKNESS, 0, CROSSHAIR_CONFIG.DEFAULT_SIZE)},
		Right = {Position = UDim2.new(0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, 0), Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0, CROSSHAIR_CONFIG.DEFAULT_THICKNESS)},
		Bottom = {Position = UDim2.new(0.5, 0, 0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE), Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_THICKNESS, 0, CROSSHAIR_CONFIG.DEFAULT_SIZE)},
		Left = {Position = UDim2.new(0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, 0), Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0, CROSSHAIR_CONFIG.DEFAULT_THICKNESS)}
	}

	for name, info in pairs(directions) do
		local line = Instance.new("Frame")
		line.Name = name
		line.BorderSizePixel = 0
		line.BackgroundColor3 = CROSSHAIR_CONFIG.DEFAULT_COLOR
		line.Size = info.Size
		line.Position = info.Position
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Parent = self.container
		self.lines[name] = line
	end

	-- Create center dot
	self.centerDot = Instance.new("Frame")
	self.centerDot.Name = "CenterDot"
	self.centerDot.BorderSizePixel = 0
	self.centerDot.BackgroundColor3 = CROSSHAIR_CONFIG.DEFAULT_COLOR
	self.centerDot.Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_THICKNESS, 0, CROSSHAIR_CONFIG.DEFAULT_THICKNESS)
	self.centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	self.centerDot.Visible = false -- Hidden in default style
	self.centerDot.Parent = self.container

	-- Create hitmarker lines (X shape)
	self.hitmarker = {}
	local hitmarkerDirections = {
		TopRight = {Start = UDim2.new(0.5, 0, 0.5, 0), End = UDim2.new(0.5, CROSSHAIR_CONFIG.HITMARKER_SIZE, 0.5, -CROSSHAIR_CONFIG.HITMARKER_SIZE)},
		TopLeft = {Start = UDim2.new(0.5, 0, 0.5, 0), End = UDim2.new(0.5, -CROSSHAIR_CONFIG.HITMARKER_SIZE, 0.5, -CROSSHAIR_CONFIG.HITMARKER_SIZE)},
		BottomRight = {Start = UDim2.new(0.5, 0, 0.5, 0), End = UDim2.new(0.5, CROSSHAIR_CONFIG.HITMARKER_SIZE, 0.5, CROSSHAIR_CONFIG.HITMARKER_SIZE)},
		BottomLeft = {Start = UDim2.new(0.5, 0, 0.5, 0), End = UDim2.new(0.5, -CROSSHAIR_CONFIG.HITMARKER_SIZE, 0.5, CROSSHAIR_CONFIG.HITMARKER_SIZE)}
	}

	for name, points in pairs(hitmarkerDirections) do
		local line = Instance.new("Frame")
		line.Name = name
		line.BorderSizePixel = 0
		line.BackgroundColor3 = CROSSHAIR_CONFIG.HIT_COLOR
		line.Size = UDim2.new(0, 1, 0, CROSSHAIR_CONFIG.HITMARKER_SIZE)
		line.Position = points.Start
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Rotation = name:find("TopRight") or name:find("BottomLeft") and 45 or -45
		line.Visible = false
		line.Parent = self.container

		self.hitmarker[name] = line
	end

	-- Create circle (for circle style)
	self.circle = Instance.new("ImageLabel")
	self.circle.Name = "Circle"
	self.circle.BackgroundTransparency = 1
	self.circle.Image = "rbxassetid://3151611793" -- Circle asset
	self.circle.ImageColor3 = CROSSHAIR_CONFIG.DEFAULT_COLOR
	self.circle.Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_SIZE * 2, 0, CROSSHAIR_CONFIG.DEFAULT_SIZE * 2)
	self.circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.circle.AnchorPoint = Vector2.new(0.5, 0.5)
	self.circle.Visible = false
	self.circle.Parent = self.container

	-- Create corner brackets (for corners style)
	self.corners = {}
	local cornerPositions = {
		TopLeft = {Position = UDim2.new(0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE), Rotation = 0},
		TopRight = {Position = UDim2.new(0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE), Rotation = 90},
		BottomRight = {Position = UDim2.new(0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE), Rotation = 180},
		BottomLeft = {Position = UDim2.new(0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE), Rotation = 270}
	}

	for name, info in pairs(cornerPositions) do
		local corner = Instance.new("ImageLabel")
		corner.Name = name
		corner.BackgroundTransparency = 1
		corner.Image = "rbxassetid://3026403129" -- Corner bracket asset
		corner.ImageColor3 = CROSSHAIR_CONFIG.DEFAULT_COLOR
		corner.Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0, CROSSHAIR_CONFIG.DEFAULT_SIZE)
		corner.Position = info.Position
		corner.Rotation = info.Rotation
		corner.AnchorPoint = Vector2.new(0.5, 0.5)
		corner.Visible = false
		corner.Parent = self.container

		self.corners[name] = corner
	end

	-- Create chevron elements
	self.chevrons = {}
	local chevronDirections = {
		Top = {Position = UDim2.new(0.5, 0, 0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE), Rotation = 0},
		Right = {Position = UDim2.new(0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, 0), Rotation = 90},
		Bottom = {Position = UDim2.new(0.5, 0, 0.5, CROSSHAIR_CONFIG.DEFAULT_SIZE), Rotation = 180},
		Left = {Position = UDim2.new(0.5, -CROSSHAIR_CONFIG.DEFAULT_SIZE, 0.5, 0), Rotation = 270}
	}

	for name, info in pairs(chevronDirections) do
		local chevron = Instance.new("ImageLabel")
		chevron.Name = name
		chevron.BackgroundTransparency = 1
		chevron.Image = "rbxassetid://156205234" -- Chevron asset (replace with actual asset ID)
		chevron.ImageColor3 = CROSSHAIR_CONFIG.DEFAULT_COLOR
		chevron.Size = UDim2.new(0, CROSSHAIR_CONFIG.DEFAULT_SIZE, 0, CROSSHAIR_CONFIG.DEFAULT_SIZE)
		chevron.Position = info.Position
		chevron.Rotation = info.Rotation
		chevron.AnchorPoint = Vector2.new(0.5, 0.5)
		chevron.Visible = false
		chevron.Parent = self.container

		self.chevrons[name] = chevron
	end

	-- Parent to player's GUI
	self.gui.Parent = self.player.PlayerGui

	-- Set default style
	self:setCrosshairStyle(CROSSHAIR_CONFIG.CROSSHAIR_STYLE.DEFAULT)
end

-- Update function called every frame
function CrosshairSystem:update(dt)
	-- Smooth spread transition
	self.spread = self.spread + (self.targetSpread - self.spread) * CROSSHAIR_CONFIG.SPREAD_SPEED

	-- Update based on current style
	if self.crosshairStyle == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.DEFAULT then
		self:updateDefaultStyle(self.spread)
	elseif self.crosshairStyle == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.DOT then
		self:updateDotStyle(self.spread)
	elseif self.crosshairStyle == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.CIRCLE then
		self:updateCircleStyle(self.spread)
	elseif self.crosshairStyle == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.CORNERS then
		self:updateCornersStyle(self.spread)
	elseif self.crosshairStyle == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.CHEVRON then
		self:updateChevronStyle(self.spread)
	end

	-- Handle visibility when aiming
	if CROSSHAIR_CONFIG.HIDE_WHEN_ADS and self.isAiming then
		self.container.Visible = false
	else
		self.container.Visible = true
	end

	-- Update firing spread
	if self.isFiring then
		local timeSinceShot = tick() - self.lastShotTime
		if timeSinceShot > 0.5 then
			-- Reset spread when not actively firing
			self.isFiring = false
		end
	end
end

-- Update standard + style crosshair
function CrosshairSystem:updateDefaultStyle(size)
	-- Update line positions
	self.lines.Top.Position = UDim2.new(0.5, 0, 0.5, -size)
	self.lines.Bottom.Position = UDim2.new(0.5, 0, 0.5, size)
	self.lines.Left.Position = UDim2.new(0.5, -size, 0.5, 0)
	self.lines.Right.Position = UDim2.new(0.5, size, 0.5, 0)

	-- Make sure the correct elements are visible
	for _, line in pairs(self.lines) do
		line.Visible = true
	end
	self.centerDot.Visible = false
	self.circle.Visible = false
	for _, corner in pairs(self.corners) do
		corner.Visible = false
	end
	for _, chevron in pairs(self.chevrons) do
		chevron.Visible = false
	end
end

-- Update dot style crosshair
function CrosshairSystem:updateDotStyle(size)
	-- Show only center dot
	for _, line in pairs(self.lines) do
		line.Visible = false
	end
	self.centerDot.Visible = true
	self.circle.Visible = false
	for _, corner in pairs(self.corners) do
		corner.Visible = false
	end
	for _, chevron in pairs(self.chevrons) do
		chevron.Visible = false
	end

	-- Scale dot size based on spread
	local dotSize = math.max(2, math.min(4, 2 + size / 10))
	self.centerDot.Size = UDim2.new(0, dotSize, 0, dotSize)
end

-- Update circle style crosshair
function CrosshairSystem:updateCircleStyle(size)
	-- Show circle and dot
	for _, line in pairs(self.lines) do
		line.Visible = false
	end
	self.centerDot.Visible = true
	self.circle.Visible = true
	for _, corner in pairs(self.corners) do
		corner.Visible = false
	end
	for _, chevron in pairs(self.chevrons) do
		chevron.Visible = false
	end

	-- Scale circle based on spread
	self.circle.Size = UDim2.new(0, size * 2, 0, size * 2)

	-- Scale dot size
	local dotSize = math.max(2, math.min(4, 2 + size / 10))
	self.centerDot.Size = UDim2.new(0, dotSize, 0, dotSize)
end

-- Update corners style crosshair
function CrosshairSystem:updateCornersStyle(size)
	-- Show only corners
	for _, line in pairs(self.lines) do
		line.Visible = false
	end
	self.centerDot.Visible = true
	self.circle.Visible = false
	for _, corner in pairs(self.corners) do
		corner.Visible = true
	end
	for _, chevron in pairs(self.chevrons) do
		chevron.Visible = false
	end

	-- Scale and position corners based on spread
	self.corners.TopLeft.Position = UDim2.new(0.5, -size, 0.5, -size)
	self.corners.TopRight.Position = UDim2.new(0.5, size, 0.5, -size)
	self.corners.BottomRight.Position = UDim2.new(0.5, size, 0.5, size)
	self.corners.BottomLeft.Position = UDim2.new(0.5, -size, 0.5, size)

	-- Scale dot size
	local dotSize = math.max(2, math.min(4, 2 + size / 10))
	self.centerDot.Size = UDim2.new(0, dotSize, 0, dotSize)
end

-- Update chevron style crosshair
function CrosshairSystem:updateChevronStyle(size)
	-- Show only chevrons
	for _, line in pairs(self.lines) do
		line.Visible = false
	end
	self.centerDot.Visible = true
	self.circle.Visible = false
	for _, corner in pairs(self.corners) do
		corner.Visible = false
	end
	for _, chevron in pairs(self.chevrons) do
		chevron.Visible = true
	end

	-- Scale and position chevrons based on spread
	self.chevrons.Top.Position = UDim2.new(0.5, 0, 0.5, -size)
	self.chevrons.Right.Position = UDim2.new(0.5, size, 0.5, 0)
	self.chevrons.Bottom.Position = UDim2.new(0.5, 0, 0.5, size)
	self.chevrons.Left.Position = UDim2.new(0.5, -size, 0.5, 0)

	-- Scale dot size
	local dotSize = math.max(2, math.min(4, 2 + size / 10))
	self.centerDot.Size = UDim2.new(0, dotSize, 0, dotSize)
end

-- Set crosshair style
function CrosshairSystem:setCrosshairStyle(style)
	self.crosshairStyle = style

	if style == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.DEFAULT then
		self:updateDefaultStyle(self.spread)
	elseif style == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.DOT then
		self:updateDotStyle(self.spread)
	elseif style == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.CIRCLE then
		self:updateCircleStyle(self.spread)
	elseif style == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.CORNERS then
		self:updateCornersStyle(self.spread)
	elseif style == CROSSHAIR_CONFIG.CROSSHAIR_STYLE.CHEVRON then
		self:updateChevronStyle(self.spread)
	end
end

-- Set the spread value directly
function CrosshairSystem:setSpread(spread)
	self.targetSpread = spread * CROSSHAIR_CONFIG.DEFAULT_SIZE
end

-- Update crosshair from weapon and character state
function CrosshairSystem:updateFromWeaponState(weaponConfig, isAiming)
	if not weaponConfig then return end

	-- Store current weapon config
	self.currentWeaponConfig = weaponConfig
	self.isAiming = isAiming

	-- Calculate spread multipliers
	local spreadMultiplier = 1

	-- Apply state multipliers
	if self.isJumping then
		spreadMultiplier = spreadMultiplier * CROSSHAIR_CONFIG.JUMP_SPREAD
	elseif self.isMoving and not self.isCrouching then
		spreadMultiplier = spreadMultiplier * CROSSHAIR_CONFIG.WALK_SPREAD
	elseif self.isCrouching then
		spreadMultiplier = spreadMultiplier * CROSSHAIR_CONFIG.CROUCH_SPREAD
	end

	-- Apply aim multiplier
	if isAiming then
		spreadMultiplier = spreadMultiplier * CROSSHAIR_CONFIG.ADS_SPREAD
	end

	-- Apply firing multiplier
	if self.isFiring then
		spreadMultiplier = spreadMultiplier * CROSSHAIR_CONFIG.FIRE_SPREAD
	end

	-- Get base spread from weapon config
	local baseSpread = 1
	if weaponConfig.spread then
		baseSpread = weaponConfig.spread.base or 1
	end

	-- Apply spread
	self:setSpread(baseSpread * spreadMultiplier)

	-- Set crosshair style based on weapon type
	if weaponConfig.crosshairStyle then
		self:setCrosshairStyle(weaponConfig.crosshairStyle)
	end
end

-- Set visibility of the crosshair
function CrosshairSystem:setVisible(visible)
	self.gui.Enabled = visible
end

-- Set the color of the crosshair
function CrosshairSystem:setColor(color)
	-- Tween color change for all elements
	local function tweenColor(element)
		TweenService:Create(
			element,
			TweenInfo.new(CROSSHAIR_CONFIG.COLOR_CHANGE_SPEED),
			{BackgroundColor3 = color}
		):Play()
	end

	-- Apply to standard crosshair lines
	for _, line in pairs(self.lines) do
		tweenColor(line)
	end

	-- Apply to center dot
	tweenColor(self.centerDot)

	-- Apply to circle
	TweenService:Create(
		self.circle,
		TweenInfo.new(CROSSHAIR_CONFIG.COLOR_CHANGE_SPEED),
		{ImageColor3 = color}
	):Play()

	-- Apply to corners
	for _, corner in pairs(self.corners) do
		TweenService:Create(
			corner,
			TweenInfo.new(CROSSHAIR_CONFIG.COLOR_CHANGE_SPEED),
			{ImageColor3 = color}
		):Play()
	end

	-- Apply to chevrons
	for _, chevron in pairs(self.chevrons) do
		TweenService:Create(
			chevron,
			TweenInfo.new(CROSSHAIR_CONFIG.COLOR_CHANGE_SPEED),
			{ImageColor3 = color}
		):Play()
	end
end

-- Show hitmarker when hitting a target
function CrosshairSystem:hitmarker(isCritical)
	if not CROSSHAIR_CONFIG.SHOW_HITMARKERS then return end

	-- Show hitmarker
	for _, line in pairs(self.hitmarker) do
		line.Visible = true
		line.BackgroundColor3 = isCritical and CROSSHAIR_CONFIG.CRITICAL_HIT_COLOR or CROSSHAIR_CONFIG.HIT_COLOR
	end

	-- Hide after duration
	task.delay(CROSSHAIR_CONFIG.HITMARKER_DURATION, function()
		for _, line in pairs(self.hitmarker) do
			line.Visible = false
		end
	end)

	-- Flash crosshair color
	local originalColor = CROSSHAIR_CONFIG.DEFAULT_COLOR
	local hitColor = isCritical and CROSSHAIR_CONFIG.CRITICAL_HIT_COLOR or CROSSHAIR_CONFIG.HIT_COLOR

	self:setColor(hitColor)
	task.delay(CROSSHAIR_CONFIG.HITMARKER_DURATION, function()
		self:setColor(originalColor)
	end)

	-- Play hitmarker sound
	self:playHitmarkerSound(isCritical)
end

-- Play hitmarker sound
function CrosshairSystem:playHitmarkerSound(isCritical)
	local sound = Instance.new("Sound")
	sound.Volume = isCritical and 0.7 or 0.5
	sound.SoundId = isCritical and "rbxassetid://5633695679" or "rbxassetid://160432334"
	sound.Parent = self.gui
	sound:Play()

	-- Auto cleanup
	game:GetService("Debris"):AddItem(sound, 2)
end

-- Record shot fired for spread calculation
function CrosshairSystem:shotFired()
	self.lastShotTime = tick()
	self.isFiring = true

	-- Temporarily increase spread
	local currentSpread = self.targetSpread / CROSSHAIR_CONFIG.DEFAULT_SIZE
	self:setSpread(currentSpread * CROSSHAIR_CONFIG.FIRE_SPREAD)

	-- Reset spread after a delay
	task.delay(0.2, function()
		if not self.isFiring then
			self:updateFromWeaponState(self.currentWeaponConfig, self.isAiming)
		end
	end)
end

-- Set player movement state
function CrosshairSystem:setMovementState(state, value)
	if state == "moving" then
		self.isMoving = value
	elseif state == "jumping" then
		self.isJumping = value
	elseif state == "crouching" then
		self.isCrouching = value
	end

	-- Update crosshair based on new state
	self:updateFromWeaponState(self.currentWeaponConfig, self.isAiming)
end

-- Clean up
function CrosshairSystem:destroy()
	if self.gui then
		self.gui:Destroy()
	end
end

return CrosshairSystem