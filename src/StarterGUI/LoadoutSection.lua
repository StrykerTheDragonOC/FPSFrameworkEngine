--[[
	Loadout Section Generator
	Creates the loadout customization UI with:
	- Class selection (Assault, Scout, Support, Recon)
	- Weapon slots (Primary, Secondary, Melee, Grenade, Special)
	- Weapon preview with stats
	- Attachment customization
]]

local LoadoutSection = {}

local TweenService = game:GetService("TweenService")

-- Create loadout section
function LoadoutSection:Create(parent)
	local loadoutSection = Instance.new("ScrollingFrame")
	loadoutSection.Name = "LoadoutSection"
	loadoutSection.Size = UDim2.new(1, 0, 1, 0)
	loadoutSection.Position = UDim2.new(0, 0, 0, 0)
	loadoutSection.BackgroundTransparency = 1
	loadoutSection.BorderSizePixel = 0
	loadoutSection.ScrollBarThickness = 8
	loadoutSection.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	loadoutSection.CanvasSize = UDim2.new(0, 0, 0, 1200)
	loadoutSection.Visible = false
	loadoutSection.Parent = parent

	-- Class selection header
	self:CreateClassSelection(loadoutSection)

	-- Weapon slots
	self:CreateWeaponSlots(loadoutSection)

	-- Weapon preview and stats
	self:CreateWeaponPreview(loadoutSection)

	-- Attachment customization
	self:CreateAttachmentPanel(loadoutSection)

	return loadoutSection
end

-- Create class selection
function LoadoutSection:CreateClassSelection(parent)
	local classContainer = Instance.new("Frame")
	classContainer.Name = "ClassSelection"
	classContainer.Size = UDim2.new(1, -20, 0, 120)
	classContainer.Position = UDim2.new(0, 10, 0, 10)
	classContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	classContainer.BackgroundTransparency = 0.3
	classContainer.BorderSizePixel = 0
	classContainer.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = classContainer

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "SELECT CLASS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = classContainer

	-- Class buttons
	local classes = {
		{Name = "ASSAULT", Color = Color3.fromRGB(200, 50, 50), Desc = "Assault Rifles, Shotguns"},
		{Name = "SCOUT", Color = Color3.fromRGB(50, 200, 50), Desc = "DMRs, Carbines"},
		{Name = "SUPPORT", Color = Color3.fromRGB(200, 200, 50), Desc = "LMGs, PDWs"},
		{Name = "RECON", Color = Color3.fromRGB(50, 150, 255), Desc = "Sniper Rifles, DMRs"}
	}

	for i, class in ipairs(classes) do
		local classButton = Instance.new("TextButton")
		classButton.Name = class.Name .. "Button"
		classButton.Size = UDim2.new(0.23, 0, 0, 55)
		classButton.Position = UDim2.new((i - 1) * 0.25 + 0.01, 0, 0, 50)
		classButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		classButton.BorderSizePixel = 0
		classButton.AutoButtonColor = false
		classButton.Text = ""
		classButton.Parent = classContainer

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = classButton

		-- Class indicator bar
		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(1, 0, 0, 3)
		indicator.Position = UDim2.new(0, 0, 0, 0)
		indicator.BackgroundColor3 = class.Color
		indicator.BorderSizePixel = 0
		indicator.Parent = classButton

		local indCorner = Instance.new("UICorner")
		indCorner.CornerRadius = UDim.new(0, 6)
		indCorner.Parent = indicator

		-- Class name
		local className = Instance.new("TextLabel")
		className.Name = "ClassName"
		className.Size = UDim2.new(1, -10, 0, 25)
		className.Position = UDim2.new(0, 5, 0, 8)
		className.BackgroundTransparency = 1
		className.Text = class.Name
		className.TextColor3 = Color3.fromRGB(255, 255, 255)
		className.Font = Enum.Font.GothamBold
		className.TextSize = 14
		className.Parent = classButton

		-- Class description
		local classDesc = Instance.new("TextLabel")
		classDesc.Name = "ClassDesc"
		classDesc.Size = UDim2.new(1, -10, 0, 18)
		classDesc.Position = UDim2.new(0, 5, 0, 32)
		classDesc.BackgroundTransparency = 1
		classDesc.Text = class.Desc
		classDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
		classDesc.Font = Enum.Font.Gotham
		classDesc.TextSize = 10
		classDesc.TextWrapped = true
		classDesc.Parent = classButton
	end
end

-- Create weapon slots
function LoadoutSection:CreateWeaponSlots(parent)
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "WeaponSlots"
	slotsContainer.Size = UDim2.new(0.35, 0, 0, 500)
	slotsContainer.Position = UDim2.new(0, 10, 0, 145)
	slotsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	slotsContainer.BackgroundTransparency = 0.3
	slotsContainer.BorderSizePixel = 0
	slotsContainer.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = slotsContainer

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "LOADOUT"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = slotsContainer

	-- Weapon slot types
	local slots = {
		{Name = "PRIMARY", Icon = "🔫", Current = "G36"},
		{Name = "SECONDARY", Icon = "🔫", Current = "M9"},
		{Name = "MELEE", Icon = "🔪", Current = "Pocket Knife"},
		{Name = "GRENADE", Icon = "💣", Current = "M67"},
		{Name = "SPECIAL", Icon = "⚡", Current = "None"}
	}

	for i, slot in ipairs(slots) do
		local slotButton = Instance.new("TextButton")
		slotButton.Name = slot.Name .. "Slot"
		slotButton.Size = UDim2.new(1, -20, 0, 75)
		slotButton.Position = UDim2.new(0, 10, 0, 45 + (i - 1) * 85)
		slotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		slotButton.BorderSizePixel = 0
		slotButton.AutoButtonColor = false
		slotButton.Text = ""
		slotButton.Parent = slotsContainer

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slotButton

		-- Slot icon/type
		local slotType = Instance.new("TextLabel")
		slotType.Name = "SlotType"
		slotType.Size = UDim2.new(1, -10, 0, 20)
		slotType.Position = UDim2.new(0, 5, 0, 5)
		slotType.BackgroundTransparency = 1
		slotType.Text = slot.Name
		slotType.TextColor3 = Color3.fromRGB(150, 150, 150)
		slotType.Font = Enum.Font.Gotham
		slotType.TextSize = 11
		slotType.TextXAlignment = Enum.TextXAlignment.Left
		slotType.Parent = slotButton

		-- Current weapon
		local currentWeapon = Instance.new("TextLabel")
		currentWeapon.Name = "CurrentWeapon"
		currentWeapon.Size = UDim2.new(1, -10, 0, 28)
		currentWeapon.Position = UDim2.new(0, 5, 0, 28)
		currentWeapon.BackgroundTransparency = 1
		currentWeapon.Text = slot.Current
		currentWeapon.TextColor3 = Color3.fromRGB(255, 255, 255)
		currentWeapon.Font = Enum.Font.GothamBold
		currentWeapon.TextSize = 16
		currentWeapon.TextXAlignment = Enum.TextXAlignment.Left
		currentWeapon.Parent = slotButton

		-- Change button
		local changeButton = Instance.new("TextButton")
		changeButton.Name = "ChangeButton"
		changeButton.Size = UDim2.new(0, 60, 0, 25)
		changeButton.Position = UDim2.new(1, -70, 0.5, -12)
		changeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		changeButton.BorderSizePixel = 0
		changeButton.Text = "CHANGE"
		changeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		changeButton.Font = Enum.Font.GothamBold
		changeButton.TextSize = 10
		changeButton.AutoButtonColor = false
		changeButton.Parent = slotButton

		local changeCorner = Instance.new("UICorner")
		changeCorner.CornerRadius = UDim.new(0, 4)
		changeCorner.Parent = changeButton
	end
end

-- Create weapon preview
function LoadoutSection:CreateWeaponPreview(parent)
	local previewContainer = Instance.new("Frame")
	previewContainer.Name = "WeaponPreview"
	previewContainer.Size = UDim2.new(0.63, 0, 0, 280)
	previewContainer.Position = UDim2.new(0.36, 0, 0, 145)
	previewContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	previewContainer.BackgroundTransparency = 0.3
	previewContainer.BorderSizePixel = 0
	previewContainer.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = previewContainer

	-- Weapon name
	local weaponName = Instance.new("TextLabel")
	weaponName.Name = "WeaponName"
	weaponName.Size = UDim2.new(1, -20, 0, 35)
	weaponName.Position = UDim2.new(0, 10, 0, 10)
	weaponName.BackgroundTransparency = 1
	weaponName.Text = "G36 ASSAULT RIFLE"
	weaponName.TextColor3 = Color3.fromRGB(255, 255, 255)
	weaponName.Font = Enum.Font.GothamBold
	weaponName.TextSize = 20
	weaponName.TextXAlignment = Enum.TextXAlignment.Left
	weaponName.Parent = previewContainer

	-- Weapon 3D preview area (placeholder)
	local previewViewport = Instance.new("Frame")
	previewViewport.Name = "PreviewViewport"
	previewViewport.Size = UDim2.new(0.5, 0, 0, 150)
	previewViewport.Position = UDim2.new(0, 10, 0, 50)
	previewViewport.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	previewViewport.BorderSizePixel = 0
	previewViewport.Parent = previewContainer

	local viewportCorner = Instance.new("UICorner")
	viewportCorner.CornerRadius = UDim.new(0, 6)
	viewportCorner.Parent = previewViewport

	-- Placeholder text
	local placeholderText = Instance.new("TextLabel")
	placeholderText.Name = "PlaceholderText"
	placeholderText.Size = UDim2.new(1, 0, 1, 0)
	placeholderText.BackgroundTransparency = 1
	placeholderText.Text = "3D PREVIEW"
	placeholderText.TextColor3 = Color3.fromRGB(100, 100, 100)
	placeholderText.Font = Enum.Font.Gotham
	placeholderText.TextSize = 14
	placeholderText.Parent = previewViewport

	-- Weapon stats
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "WeaponStats"
	statsFrame.Size = UDim2.new(0.48, 0, 0, 150)
	statsFrame.Position = UDim2.new(0.52, 0, 0, 50)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = previewContainer

	local stats = {
		{Name = "Damage", Value = "30", Max = 100},
		{Name = "Range", Value = "250", Max = 500},
		{Name = "Fire Rate", Value = "750", Max = 1200},
		{Name = "Recoil", Value = "35", Max = 100},
		{Name = "Accuracy", Value = "75", Max = 100}
	}

	for i, stat in ipairs(stats) do
		local statLabel = Instance.new("TextLabel")
		statLabel.Name = stat.Name
		statLabel.Size = UDim2.new(0.4, 0, 0, 20)
		statLabel.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
		statLabel.BackgroundTransparency = 1
		statLabel.Text = stat.Name
		statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		statLabel.Font = Enum.Font.Gotham
		statLabel.TextSize = 12
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = statsFrame

		-- Stat bar background
		local statBarBg = Instance.new("Frame")
		statBarBg.Name = stat.Name .. "BarBg"
		statBarBg.Size = UDim2.new(0.55, 0, 0, 12)
		statBarBg.Position = UDim2.new(0.43, 0, 0, (i - 1) * 28 + 4)
		statBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		statBarBg.BorderSizePixel = 0
		statBarBg.Parent = statsFrame

		local statBarCorner = Instance.new("UICorner")
		statBarCorner.CornerRadius = UDim.new(0, 3)
		statBarCorner.Parent = statBarBg

		-- Stat bar fill
		local statPercent = tonumber(stat.Value) / stat.Max
		local statBar = Instance.new("Frame")
		statBar.Name = stat.Name .. "Bar"
		statBar.Size = UDim2.new(statPercent, 0, 1, 0)
		statBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		statBar.BorderSizePixel = 0
		statBar.Parent = statBarBg

		local statFillCorner = Instance.new("UICorner")
		statFillCorner.CornerRadius = UDim.new(0, 3)
		statFillCorner.Parent = statBar
	end

	-- Weapon info
	local weaponInfo = Instance.new("TextLabel")
	weaponInfo.Name = "WeaponInfo"
	weaponInfo.Size = UDim2.new(1, -20, 0, 60)
	weaponInfo.Position = UDim2.new(0, 10, 0, 210)
	weaponInfo.BackgroundTransparency = 1
	weaponInfo.Text = "Unlock: Rank 0 | Kills: 0 / 100 | Cost: FREE"
	weaponInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
	weaponInfo.Font = Enum.Font.Gotham
	weaponInfo.TextSize = 11
	weaponInfo.TextXAlignment = Enum.TextXAlignment.Left
	weaponInfo.TextYAlignment = Enum.TextYAlignment.Top
	weaponInfo.TextWrapped = true
	weaponInfo.Parent = previewContainer
end

-- Create attachment panel
function LoadoutSection:CreateAttachmentPanel(parent)
	local attachmentContainer = Instance.new("Frame")
	attachmentContainer.Name = "AttachmentPanel"
	attachmentContainer.Size = UDim2.new(0.63, 0, 0, 205)
	attachmentContainer.Position = UDim2.new(0.36, 0, 0, 435)
	attachmentContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	attachmentContainer.BackgroundTransparency = 0.3
	attachmentContainer.BorderSizePixel = 0
	attachmentContainer.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = attachmentContainer

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ATTACHMENTS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = attachmentContainer

	-- Attachment categories
	local categories = {
		{Name = "OPTIC", Current = "Iron Sights"},
		{Name = "BARREL", Current = "None"},
		{Name = "UNDERBARREL", Current = "None"},
		{Name = "AMMO", Current = "Standard"}
	}

	for i, category in ipairs(categories) do
		local categoryFrame = Instance.new("Frame")
		categoryFrame.Name = category.Name .. "Category"
		categoryFrame.Size = UDim2.new(0.48, 0, 0, 35)
		categoryFrame.Position = UDim2.new((i - 1) % 2 * 0.51 + 0.01, 0, 0, 45 + math.floor((i - 1) / 2) * 45)
		categoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		categoryFrame.BorderSizePixel = 0
		categoryFrame.Parent = attachmentContainer

		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 6)
		catCorner.Parent = categoryFrame

		-- Category name
		local catName = Instance.new("TextLabel")
		catName.Name = "CategoryName"
		catName.Size = UDim2.new(0.35, 0, 1, 0)
		catName.Position = UDim2.new(0, 8, 0, 0)
		catName.BackgroundTransparency = 1
		catName.Text = category.Name
		catName.TextColor3 = Color3.fromRGB(150, 150, 150)
		catName.Font = Enum.Font.Gotham
		catName.TextSize = 11
		catName.TextXAlignment = Enum.TextXAlignment.Left
		catName.Parent = categoryFrame

		-- Current attachment
		local currentAttachment = Instance.new("TextLabel")
		currentAttachment.Name = "CurrentAttachment"
		currentAttachment.Size = UDim2.new(0.45, 0, 1, 0)
		currentAttachment.Position = UDim2.new(0.35, 0, 0, 0)
		currentAttachment.BackgroundTransparency = 1
		currentAttachment.Text = category.Current
		currentAttachment.TextColor3 = Color3.fromRGB(255, 255, 255)
		currentAttachment.Font = Enum.Font.GothamBold
		currentAttachment.TextSize = 12
		currentAttachment.TextXAlignment = Enum.TextXAlignment.Left
		currentAttachment.Parent = categoryFrame

		-- Edit button
		local editButton = Instance.new("TextButton")
		editButton.Name = "EditButton"
		editButton.Size = UDim2.new(0.18, 0, 0, 25)
		editButton.Position = UDim2.new(0.80, 0, 0, 5)
		editButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		editButton.BorderSizePixel = 0
		editButton.Text = "EDIT"
		editButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		editButton.Font = Enum.Font.GothamBold
		editButton.TextSize = 10
		editButton.AutoButtonColor = false
		editButton.Parent = categoryFrame

		local editCorner = Instance.new("UICorner")
		editCorner.CornerRadius = UDim.new(0, 4)
		editCorner.Parent = editButton
	end

	-- Save loadout button
	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.new(0.3, 0, 0, 40)
	saveButton.Position = UDim2.new(0.35, 0, 0, 155)
	saveButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	saveButton.BorderSizePixel = 0
	saveButton.Text = "SAVE LOADOUT"
	saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveButton.Font = Enum.Font.GothamBold
	saveButton.TextSize = 14
	saveButton.AutoButtonColor = false
	saveButton.Parent = attachmentContainer

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 6)
	saveCorner.Parent = saveButton
end

return LoadoutSection