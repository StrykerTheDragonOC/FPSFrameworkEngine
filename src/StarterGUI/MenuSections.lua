--[[
	Menu Sections Module
	Contains all menu section creators:
	- Shop (Weapon Skins)
	- Settings (Sensitivity, FOV, Ragdoll)
	- Leaderboard
]]

local MenuSections = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ========== SHOP SECTION ==========
function MenuSections:CreateShopSection(parent)
	local shopSection = Instance.new("ScrollingFrame")
	shopSection.Name = "ShopSection"
	shopSection.Size = UDim2.new(1, 0, 1, 0)
	shopSection.Position = UDim2.new(0, 0, 0, 0)
	shopSection.BackgroundTransparency = 1
	shopSection.BorderSizePixel = 0
	shopSection.ScrollBarThickness = 8
	shopSection.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	shopSection.CanvasSize = UDim2.new(0, 0, 0, 1000)
	shopSection.Visible = false
	shopSection.Parent = parent

	-- Shop header
	local header = Instance.new("Frame")
	header.Name = "ShopHeader"
	header.Size = UDim2.new(1, -20, 0, 80)
	header.Position = UDim2.new(0, 10, 0, 10)
	header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	header.BackgroundTransparency = 0.3
	header.BorderSizePixel = 0
	header.Parent = shopSection

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header

	-- Shop title
	local shopTitle = Instance.new("TextLabel")
	shopTitle.Name = "Title"
	shopTitle.Size = UDim2.new(0.5, 0, 0, 40)
	shopTitle.Position = UDim2.new(0, 15, 0, 10)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "WEAPON SKINS SHOP"
	shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextSize = 24
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Parent = header

	-- Shop rotation timer
	local rotationTimer = Instance.new("TextLabel")
	rotationTimer.Name = "RotationTimer"
	rotationTimer.Size = UDim2.new(0.4, 0, 0, 25)
	rotationTimer.Position = UDim2.new(0, 15, 0, 50)
	rotationTimer.BackgroundTransparency = 1
	rotationTimer.Text = "Daily Shop Rotates in: 23:45:12"
	rotationTimer.TextColor3 = Color3.fromRGB(255, 200, 50)
	rotationTimer.Font = Enum.Font.Gotham
	rotationTimer.TextSize = 12
	rotationTimer.TextXAlignment = Enum.TextXAlignment.Left
	rotationTimer.Parent = header

	-- Player credits display
	local creditsDisplay = Instance.new("TextLabel")
	creditsDisplay.Name = "CreditsDisplay"
	creditsDisplay.Size = UDim2.new(0.3, 0, 0, 40)
	creditsDisplay.Position = UDim2.new(0.68, 0, 0, 20)
	creditsDisplay.BackgroundTransparency = 1
	creditsDisplay.Text = "YOUR KFCOINS: 1000"
	creditsDisplay.TextColor3 = Color3.fromRGB(255, 200, 50)
	creditsDisplay.Font = Enum.Font.GothamBold
	creditsDisplay.TextSize = 16
	creditsDisplay.TextXAlignment = Enum.TextXAlignment.Right
	creditsDisplay.Parent = header

	-- Featured skins grid
	local skinsGrid = Instance.new("Frame")
	skinsGrid.Name = "SkinsGrid"
	skinsGrid.Size = UDim2.new(1, -20, 0, 850)
	skinsGrid.Position = UDim2.new(0, 10, 0, 100)
	skinsGrid.BackgroundTransparency = 1
	skinsGrid.Parent = shopSection

	-- Create skin items (3x3 grid)
	local skinItems = {
		{Name = "Dragon Breath", Weapon = "G36", Price = 500, Rarity = "Legendary"},
		{Name = "Arctic Camo", Weapon = "M9", Price = 250, Rarity = "Rare"},
		{Name = "Gold Rush", Weapon = "G36", Price = 1000, Rarity = "Epic"},
		{Name = "Neon Striker", Weapon = "M9", Price = 300, Rarity = "Rare"},
		{Name = "Desert Eagle", Weapon = "G36", Price = 150, Rarity = "Common"},
		{Name = "Carbon Fiber", Weapon = "M9", Price = 800, Rarity = "Epic"},
		{Name = "Tiger Stripes", Weapon = "G36", Price = 400, Rarity = "Rare"},
		{Name = "Crimson Web", Weapon = "M9", Price = 600, Rarity = "Epic"},
		{Name = "Urban Camo", Weapon = "G36", Price = 200, Rarity = "Common"}
	}

	local rarityColors = {
		Common = Color3.fromRGB(150, 150, 150),
		Rare = Color3.fromRGB(100, 150, 255),
		Epic = Color3.fromRGB(200, 100, 255),
		Legendary = Color3.fromRGB(255, 180, 50)
	}

	for i, skin in ipairs(skinItems) do
		local row = math.floor((i - 1) / 3)
		local col = (i - 1) % 3

		local skinCard = Instance.new("Frame")
		skinCard.Name = skin.Name:gsub(" ", "") .. "Card"
		skinCard.Size = UDim2.new(0.32, 0, 0, 250)
		skinCard.Position = UDim2.new(col * 0.34, 0, 0, row * 270)
		skinCard.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		skinCard.BackgroundTransparency = 0.2
		skinCard.BorderSizePixel = 0
		skinCard.Parent = skinsGrid

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = skinCard

		-- Rarity indicator
		local rarityBar = Instance.new("Frame")
		rarityBar.Name = "RarityBar"
		rarityBar.Size = UDim2.new(1, 0, 0, 4)
		rarityBar.Position = UDim2.new(0, 0, 0, 0)
		rarityBar.BackgroundColor3 = rarityColors[skin.Rarity] or Color3.fromRGB(100, 100, 100)
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = skinCard

		-- Skin preview (placeholder)
		local skinPreview = Instance.new("Frame")
		skinPreview.Name = "SkinPreview"
		skinPreview.Size = UDim2.new(1, -20, 0, 130)
		skinPreview.Position = UDim2.new(0, 10, 0, 15)
		skinPreview.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		skinPreview.BorderSizePixel = 0
		skinPreview.Parent = skinCard

		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 6)
		previewCorner.Parent = skinPreview

		-- Placeholder text
		local previewText = Instance.new("TextLabel")
		previewText.Size = UDim2.new(1, 0, 1, 0)
		previewText.BackgroundTransparency = 1
		previewText.Text = "SKIN PREVIEW"
		previewText.TextColor3 = Color3.fromRGB(80, 80, 80)
		previewText.Font = Enum.Font.Gotham
		previewText.TextSize = 12
		previewText.Parent = skinPreview

		-- Skin name
		local skinName = Instance.new("TextLabel")
		skinName.Name = "SkinName"
		skinName.Size = UDim2.new(1, -20, 0, 25)
		skinName.Position = UDim2.new(0, 10, 0, 150)
		skinName.BackgroundTransparency = 1
		skinName.Text = skin.Name
		skinName.TextColor3 = Color3.fromRGB(255, 255, 255)
		skinName.Font = Enum.Font.GothamBold
		skinName.TextSize = 16
		skinName.TextXAlignment = Enum.TextXAlignment.Left
		skinName.Parent = skinCard

		-- Weapon type
		local weaponType = Instance.new("TextLabel")
		weaponType.Name = "WeaponType"
		weaponType.Size = UDim2.new(1, -20, 0, 18)
		weaponType.Position = UDim2.new(0, 10, 0, 175)
		weaponType.BackgroundTransparency = 1
		weaponType.Text = skin.Weapon .. " | " .. skin.Rarity
		weaponType.TextColor3 = rarityColors[skin.Rarity]
		weaponType.Font = Enum.Font.Gotham
		weaponType.TextSize = 11
		weaponType.TextXAlignment = Enum.TextXAlignment.Left
		weaponType.Parent = skinCard

		-- Buy button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(1, -20, 0, 40)
		buyButton.Position = UDim2.new(0, 10, 0, 200)
		buyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		buyButton.BorderSizePixel = 0
		buyButton.Text = "BUY - " .. skin.Price .. " KFCOINS"
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextSize = 14
		buyButton.AutoButtonColor = false
		buyButton.Parent = skinCard

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 6)
		buyCorner.Parent = buyButton
	end

	return shopSection
end

-- ========== SETTINGS SECTION ==========
function MenuSections:CreateSettingsSection(parent)
	local settingsSection = Instance.new("ScrollingFrame")
	settingsSection.Name = "SettingsSection"
	settingsSection.Size = UDim2.new(1, 0, 1, 0)
	settingsSection.Position = UDim2.new(0, 0, 0, 0)
	settingsSection.BackgroundTransparency = 1
	settingsSection.BorderSizePixel = 0
	settingsSection.ScrollBarThickness = 8
	settingsSection.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	settingsSection.CanvasSize = UDim2.new(0, 0, 0, 600)
	settingsSection.Visible = false
	settingsSection.Parent = parent

	-- Settings container
	local settingsContainer = Instance.new("Frame")
	settingsContainer.Name = "SettingsContainer"
	settingsContainer.Size = UDim2.new(1, -20, 0, 550)
	settingsContainer.Position = UDim2.new(0, 10, 0, 10)
	settingsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	settingsContainer.BackgroundTransparency = 0.3
	settingsContainer.BorderSizePixel = 0
	settingsContainer.Parent = settingsSection

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = settingsContainer

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "SETTINGS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = settingsContainer

	-- Settings items
	local settings = {
		{Name = "Mouse Sensitivity", Type = "Slider", Min = 0.1, Max = 3, Default = 1, Suffix = "x"},
		{Name = "Weapon FOV", Type = "Slider", Min = 60, Max = 90, Default = 70, Suffix = "°"},
		{Name = "Ragdoll Factor", Type = "Slider", Min = 0, Max = 200, Default = 100, Suffix = "%"},
		{Name = "Master Volume", Type = "Slider", Min = 0, Max = 100, Default = 75, Suffix = "%"},
		{Name = "Effects Volume", Type = "Slider", Min = 0, Max = 100, Default = 80, Suffix = "%"},
		{Name = "Show Killfeed", Type = "Toggle", Default = true},
		{Name = "Show FPS Counter", Type = "Toggle", Default = false},
		{Name = "Motion Blur", Type = "Toggle", Default = true}
	}

	local yOffset = 60

	for i, setting in ipairs(settings) do
		local settingFrame = Instance.new("Frame")
		settingFrame.Name = setting.Name:gsub(" ", "") .. "Frame"
		settingFrame.Size = UDim2.new(1, -40, 0, 60)
		settingFrame.Position = UDim2.new(0, 20, 0, yOffset)
		settingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		settingFrame.BackgroundTransparency = 0.5
		settingFrame.BorderSizePixel = 0
		settingFrame.Parent = settingsContainer

		local frameCorner = Instance.new("UICorner")
		frameCorner.CornerRadius = UDim.new(0, 6)
		frameCorner.Parent = settingFrame

		-- Setting name
		local settingName = Instance.new("TextLabel")
		settingName.Name = "SettingName"
		settingName.Size = UDim2.new(0.4, 0, 1, 0)
		settingName.Position = UDim2.new(0, 15, 0, 0)
		settingName.BackgroundTransparency = 1
		settingName.Text = setting.Name
		settingName.TextColor3 = Color3.fromRGB(220, 220, 220)
		settingName.Font = Enum.Font.GothamBold
		settingName.TextSize = 14
		settingName.TextXAlignment = Enum.TextXAlignment.Left
		settingName.Parent = settingFrame

		if setting.Type == "Slider" then
			-- Value display
			local valueDisplay = Instance.new("TextLabel")
			valueDisplay.Name = "ValueDisplay"
			valueDisplay.Size = UDim2.new(0.15, 0, 1, 0)
			valueDisplay.Position = UDim2.new(0.83, 0, 0, 0)
			valueDisplay.BackgroundTransparency = 1
			valueDisplay.Text = setting.Default .. setting.Suffix
			valueDisplay.TextColor3 = Color3.fromRGB(100, 200, 255)
			valueDisplay.Font = Enum.Font.GothamBold
			valueDisplay.TextSize = 14
			valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
			valueDisplay.Parent = settingFrame

			-- Slider background
			local sliderBg = Instance.new("Frame")
			sliderBg.Name = "SliderBackground"
			sliderBg.Size = UDim2.new(0.38, 0, 0, 8)
			sliderBg.Position = UDim2.new(0.43, 0, 0.5, -4)
			sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			sliderBg.BorderSizePixel = 0
			sliderBg.Parent = settingFrame

			local sliderBgCorner = Instance.new("UICorner")
			sliderBgCorner.CornerRadius = UDim.new(0, 4)
			sliderBgCorner.Parent = sliderBg

			-- Slider fill
			local sliderFill = Instance.new("Frame")
			sliderFill.Name = "SliderFill"
			local fillPercent = (setting.Default - setting.Min) / (setting.Max - setting.Min)
			sliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
			sliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
			sliderFill.BorderSizePixel = 0
			sliderFill.Parent = sliderBg

			local sliderFillCorner = Instance.new("UICorner")
			sliderFillCorner.CornerRadius = UDim.new(0, 4)
			sliderFillCorner.Parent = sliderFill

			-- Slider knob
			local sliderKnob = Instance.new("Frame")
			sliderKnob.Name = "SliderKnob"
			sliderKnob.Size = UDim2.new(0, 18, 0, 18)
			sliderKnob.Position = UDim2.new(fillPercent, -9, 0.5, -9)
			sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			sliderKnob.BorderSizePixel = 0
			sliderKnob.Parent = sliderBg

			local knobCorner = Instance.new("UICorner")
			knobCorner.CornerRadius = UDim.new(1, 0)
			knobCorner.Parent = sliderKnob

		elseif setting.Type == "Toggle" then
			-- Toggle button
			local toggleButton = Instance.new("TextButton")
			toggleButton.Name = "ToggleButton"
			toggleButton.Size = UDim2.new(0, 60, 0, 30)
			toggleButton.Position = UDim2.new(0.88, 0, 0.5, -15)
			toggleButton.BackgroundColor3 = setting.Default and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
			toggleButton.BorderSizePixel = 0
			toggleButton.Text = setting.Default and "ON" or "OFF"
			toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			toggleButton.Font = Enum.Font.GothamBold
			toggleButton.TextSize = 12
			toggleButton.AutoButtonColor = false
			toggleButton.Parent = settingFrame

			local toggleCorner = Instance.new("UICorner")
			toggleCorner.CornerRadius = UDim.new(0, 6)
			toggleCorner.Parent = toggleButton
		end

		yOffset = yOffset + 70
	end

	-- Save settings button
	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.new(0, 200, 0, 50)
	saveButton.Position = UDim2.new(0.5, -100, 0, yOffset)
	saveButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	saveButton.BorderSizePixel = 0
	saveButton.Text = "SAVE SETTINGS"
	saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveButton.Font = Enum.Font.GothamBold
	saveButton.TextSize = 16
	saveButton.AutoButtonColor = false
	saveButton.Parent = settingsContainer

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 8)
	saveCorner.Parent = saveButton

	return settingsSection
end

-- ========== LEADERBOARD SECTION ==========
function MenuSections:CreateLeaderboardSection(parent)
	local leaderboardSection = Instance.new("ScrollingFrame")
	leaderboardSection.Name = "LeaderboardSection"
	leaderboardSection.Size = UDim2.new(1, 0, 1, 0)
	leaderboardSection.Position = UDim2.new(0, 0, 0, 0)
	leaderboardSection.BackgroundTransparency = 1
	leaderboardSection.BorderSizePixel = 0
	leaderboardSection.ScrollBarThickness = 8
	leaderboardSection.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	leaderboardSection.CanvasSize = UDim2.new(0, 0, 0, 800)
	leaderboardSection.Visible = false
	leaderboardSection.Parent = parent

	-- Leaderboard container
	local leaderboardContainer = Instance.new("Frame")
	leaderboardContainer.Name = "LeaderboardContainer"
	leaderboardContainer.Size = UDim2.new(1, -20, 0, 750)
	leaderboardContainer.Position = UDim2.new(0, 10, 0, 10)
	leaderboardContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	leaderboardContainer.BackgroundTransparency = 0.3
	leaderboardContainer.BorderSizePixel = 0
	leaderboardContainer.Parent = leaderboardSection

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = leaderboardContainer

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "LEADERBOARD"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = leaderboardContainer

	-- Leaderboard header row
	local headerRow = Instance.new("Frame")
	headerRow.Name = "HeaderRow"
	headerRow.Size = UDim2.new(1, -40, 0, 35)
	headerRow.Position = UDim2.new(0, 20, 0, 60)
	headerRow.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	headerRow.BorderSizePixel = 0
	headerRow.Parent = leaderboardContainer

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 6)
	headerCorner.Parent = headerRow

	local headerColumns = {"#", "PLAYER", "RANK", "KILLS", "DEATHS", "K/D", "SCORE"}
	local columnWidths = {0.08, 0.3, 0.12, 0.12, 0.12, 0.12, 0.14}

	local xOffset = 0
	for i, column in ipairs(headerColumns) do
		local columnLabel = Instance.new("TextLabel")
		columnLabel.Name = column .. "Column"
		columnLabel.Size = UDim2.new(columnWidths[i], 0, 1, 0)
		columnLabel.Position = UDim2.new(xOffset, 0, 0, 0)
		columnLabel.BackgroundTransparency = 1
		columnLabel.Text = column
		columnLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		columnLabel.Font = Enum.Font.GothamBold
		columnLabel.TextSize = 12
		columnLabel.Parent = headerRow

		xOffset = xOffset + columnWidths[i]
	end

	-- Leaderboard entries
	local leaderboardList = Instance.new("Frame")
	leaderboardList.Name = "LeaderboardList"
	leaderboardList.Size = UDim2.new(1, -40, 0, 630)
	leaderboardList.Position = UDim2.new(0, 20, 0, 105)
	leaderboardList.BackgroundTransparency = 1
	leaderboardList.Parent = leaderboardContainer

	-- Example leaderboard data
	local leaderboardData = {
		{Player = "Player1", Rank = 25, Kills = 1250, Deaths = 890, KD = 1.40, Score = 15600},
		{Player = "Player2", Rank = 18, Kills = 980, Deaths = 720, KD = 1.36, Score = 12400},
		{Player = "Player3", Rank = 32, Kills = 1890, Deaths = 1420, KD = 1.33, Score = 19200},
		{Player = "Player4", Rank = 12, Kills = 650, Deaths = 510, KD = 1.27, Score = 8900},
		{Player = "Player5", Rank = 45, Kills = 3200, Deaths = 2650, KD = 1.21, Score = 34500},
		{Player = "Player6", Rank = 9, Kills = 520, Deaths = 430, KD = 1.21, Score = 6800},
		{Player = "Player7", Rank = 22, Kills = 1120, Deaths = 960, KD = 1.17, Score = 13500},
		{Player = "Player8", Rank = 15, Kills = 780, Deaths = 690, KD = 1.13, Score = 9600},
		{Player = "Player9", Rank = 5, Kills = 290, Deaths = 280, KD = 1.04, Score = 3900},
		{Player = "Player10", Rank = 38, Kills = 2450, Deaths = 2350, KD = 1.04, Score = 28700}
	}

	for i, data in ipairs(leaderboardData) do
		local entryRow = Instance.new("Frame")
		entryRow.Name = "Entry" .. i
		entryRow.Size = UDim2.new(1, 0, 0, 55)
		entryRow.Position = UDim2.new(0, 0, 0, (i - 1) * 62)
		entryRow.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		entryRow.BackgroundTransparency = (data.Player == player.Name) and 0.2 or 0.5
		entryRow.BorderSizePixel = 0
		entryRow.Parent = leaderboardList

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 6)
		entryCorner.Parent = entryRow

		-- Highlight if current player
		if data.Player == player.Name then
			local highlight = Instance.new("UIStroke")
			highlight.Color = Color3.fromRGB(100, 200, 255)
			highlight.Thickness = 2
			highlight.Parent = entryRow
		end

		-- Position number
		local position = Instance.new("TextLabel")
		position.Size = UDim2.new(columnWidths[1], 0, 1, 0)
		position.Position = UDim2.new(0, 0, 0, 0)
		position.BackgroundTransparency = 1
		position.Text = "#" .. i
		position.TextColor3 = Color3.fromRGB(200, 200, 200)
		position.Font = Enum.Font.GothamBold
		position.TextSize = 14
		position.Parent = entryRow

		-- Player name
		local playerName = Instance.new("TextLabel")
		playerName.Size = UDim2.new(columnWidths[2], 0, 1, 0)
		playerName.Position = UDim2.new(columnWidths[1], 0, 0, 0)
		playerName.BackgroundTransparency = 1
		playerName.Text = data.Player
		playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
		playerName.Font = Enum.Font.GothamBold
		playerName.TextSize = 14
		playerName.TextXAlignment = Enum.TextXAlignment.Left
		playerName.Parent = entryRow

		-- Stats columns
		local stats = {data.Rank, data.Kills, data.Deaths, string.format("%.2f", data.KD), data.Score}
		local statsXOffset = columnWidths[1] + columnWidths[2]

		for j, stat in ipairs(stats) do
			local statLabel = Instance.new("TextLabel")
			statLabel.Size = UDim2.new(columnWidths[j + 2], 0, 1, 0)
			statLabel.Position = UDim2.new(statsXOffset, 0, 0, 0)
			statLabel.BackgroundTransparency = 1
			statLabel.Text = tostring(stat)
			statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			statLabel.Font = Enum.Font.Gotham
			statLabel.TextSize = 13
			statLabel.Parent = entryRow

			statsXOffset = statsXOffset + columnWidths[j + 2]
		end
	end

	return leaderboardSection
end

return MenuSections