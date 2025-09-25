--[[
	TabScoreboard.client.lua
	Custom Tab scoreboard system for FPS game
	Shows: Rank, Player Name, Kills, Deaths, KDR, Streak, Score, Team
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Wait for FPS System to load
repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hide default playerlist
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local TabScoreboard = {}

-- Scoreboard state
local isScoreboardVisible = false
local scoreboardData = {}
local scoreboardGui = nil

function TabScoreboard:CreateScoreboardUI()
	-- Create ScreenGui
	scoreboardGui = Instance.new("ScreenGui")
	scoreboardGui.Name = "CustomScoreboard"
	scoreboardGui.ResetOnSpawn = false
	scoreboardGui.IgnoreGuiInset = true
	scoreboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main Container
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "ScoreboardContainer"
	mainContainer.Size = UDim2.fromScale(0.8, 0.7)
	mainContainer.Position = UDim2.fromScale(0.1, 0.15)
	mainContainer.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	mainContainer.BackgroundTransparency = 0.1
	mainContainer.BorderSizePixel = 0
	mainContainer.Visible = false
	mainContainer.Parent = scoreboardGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 15)
	containerCorner.Parent = mainContainer

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(80, 120, 200)
	containerStroke.Thickness = 2
	containerStroke.Transparency = 0.3
	containerStroke.Parent = mainContainer

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.Position = UDim2.fromScale(0, 0)
	header.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
	header.BorderSizePixel = 0
	header.Parent = mainContainer

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 15)
	headerCorner.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "ScoreboardTitle"
	title.Size = UDim2.fromScale(0.4, 1)
	title.Position = UDim2.fromScale(0.05, 0)
	title.BackgroundTransparency = 1
	title.Text = "LEADERBOARD"
	title.TextColor3 = Color3.fromRGB(180, 220, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextStrokeTransparency = 0.5
	title.Parent = header

	-- Game Info
	local gameInfo = Instance.new("Frame")
	gameInfo.Name = "GameInfo"
	gameInfo.Size = UDim2.fromScale(0.5, 1)
	gameInfo.Position = UDim2.fromScale(0.45, 0)
	gameInfo.BackgroundTransparency = 1
	gameInfo.Parent = header

	local gamemodeLabel = Instance.new("TextLabel")
	gamemodeLabel.Name = "GamemodeLabel"
	gamemodeLabel.Size = UDim2.fromScale(1, 0.5)
	gamemodeLabel.Position = UDim2.fromScale(0, 0)
	gamemodeLabel.BackgroundTransparency = 1
	gamemodeLabel.Text = "TEAM DEATHMATCH"
	gamemodeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	gamemodeLabel.TextScaled = true
	gamemodeLabel.Font = Enum.Font.GothamBold
	gamemodeLabel.TextXAlignment = Enum.TextXAlignment.Right
	gamemodeLabel.Parent = gameInfo

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.fromScale(1, 0.5)
	timeLabel.Position = UDim2.fromScale(0, 0.5)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "15:30 REMAINING"
	timeLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Parent = gameInfo

	-- Column Headers
	local columnHeaders = Instance.new("Frame")
	columnHeaders.Name = "ColumnHeaders"
	columnHeaders.Size = UDim2.new(1, 0, 0, 40)
	columnHeaders.Position = UDim2.new(0, 0, 0, 60)
	columnHeaders.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
	columnHeaders.BorderSizePixel = 0
	columnHeaders.Parent = mainContainer

	-- Create column header labels
	local headerLabels = {"RANK", "PLAYER", "KILLS", "DEATHS", "K/D", "STREAK", "SCORE", "TEAM"}
	local headerWidths = {0.08, 0.25, 0.12, 0.12, 0.12, 0.12, 0.12, 0.07}
	local xOffset = 0

	for i, label in ipairs(headerLabels) do
		local headerLabel = Instance.new("TextLabel")
		headerLabel.Name = label .. "Header"
		headerLabel.Size = UDim2.fromScale(headerWidths[i], 1)
		headerLabel.Position = UDim2.fromScale(xOffset, 0)
		headerLabel.BackgroundTransparency = 1
		headerLabel.Text = label
		headerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		headerLabel.TextScaled = true
		headerLabel.Font = Enum.Font.GothamBold
		headerLabel.Parent = columnHeaders

		xOffset = xOffset + headerWidths[i]
	end

	-- Scrolling Frame for players
	local playersScroll = Instance.new("ScrollingFrame")
	playersScroll.Name = "PlayersScrollFrame"
	playersScroll.Size = UDim2.new(1, 0, 1, -100)
	playersScroll.Position = UDim2.new(0, 0, 0, 100)
	playersScroll.BackgroundTransparency = 1
	playersScroll.BorderSizePixel = 0
	playersScroll.ScrollBarThickness = 8
	playersScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 200)
	playersScroll.Parent = mainContainer

	local playersLayout = Instance.new("UIListLayout")
	playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playersLayout.Padding = UDim.new(0, 2)
	playersLayout.Parent = playersScroll

	scoreboardGui.Parent = playerGui

	return scoreboardGui
end

function TabScoreboard:CreatePlayerRow(playerData, rank)
	local playerRow = Instance.new("Frame")
	playerRow.Name = playerData.name .. "Row"
	playerRow.Size = UDim2.new(1, 0, 0, 35)
	playerRow.BackgroundColor3 = rank % 2 == 0 and Color3.fromRGB(20, 30, 45) or Color3.fromRGB(25, 35, 50)
	playerRow.BorderSizePixel = 0
	playerRow.LayoutOrder = rank

	-- Team color indicator
	local teamIndicator = Instance.new("Frame")
	teamIndicator.Name = "TeamIndicator"
	teamIndicator.Size = UDim2.new(0, 4, 1, 0)
	teamIndicator.Position = UDim2.fromScale(0, 0)
	teamIndicator.BorderSizePixel = 0
	teamIndicator.BackgroundColor3 = playerData.team == "KFC" and Color3.fromRGB(139, 69, 19) or Color3.fromRGB(0, 0, 139) -- Maroon or NavyBlue
	teamIndicator.Parent = playerRow

	-- Player data labels
	local dataLabels = {
		tostring(rank),
		playerData.name,
		tostring(playerData.kills),
		tostring(playerData.deaths),
		string.format("%.2f", playerData.kdr),
		tostring(playerData.streak),
		tostring(playerData.score),
		playerData.team
	}

	local labelWidths = {0.08, 0.25, 0.12, 0.12, 0.12, 0.12, 0.12, 0.07}
	local xOffset = 0

	for i, text in ipairs(dataLabels) do
		local dataLabel = Instance.new("TextLabel")
		dataLabel.Name = "Data" .. i
		dataLabel.Size = UDim2.fromScale(labelWidths[i], 1)
		dataLabel.Position = UDim2.fromScale(xOffset, 0)
		dataLabel.BackgroundTransparency = 1
		dataLabel.Text = text
		dataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		dataLabel.TextScaled = true
		dataLabel.Font = Enum.Font.Gotham
		dataLabel.Parent = playerRow

		-- Highlight current player
		if playerData.name == player.Name then
			dataLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			dataLabel.Font = Enum.Font.GothamBold
		end

		xOffset = xOffset + labelWidths[i]
	end

	return playerRow
end

function TabScoreboard:UpdateScoreboard()
	if not scoreboardGui then return end

	local mainContainer = scoreboardGui.ScoreboardContainer
	local playersScroll = mainContainer.PlayersScrollFrame

	-- Clear existing player rows
	for _, child in pairs(playersScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get updated scoreboard data from server
	local serverData = RemoteEventsManager:InvokeServer("GetLeaderboard")
	if serverData then
		scoreboardData = serverData
	end

	-- Sort players by score (highest first)
	table.sort(scoreboardData, function(a, b)
		return a.score > b.score
	end)

	-- Create player rows
	for rank, playerData in ipairs(scoreboardData) do
		local playerRow = self:CreatePlayerRow(playerData, rank)
		playerRow.Parent = playersScroll
	end

	-- Update canvas size
	playersScroll.CanvasSize = UDim2.new(0, 0, 0, (#scoreboardData * 37))

	-- Update game info
	local header = mainContainer.Header
	local gameInfo = header.GameInfo

	local currentGamemode = RemoteEventsManager:InvokeServer("GetCurrentGamemode")
	if currentGamemode then
		gameInfo.GamemodeLabel.Text = currentGamemode.name:upper()
	end

	local timeRemaining = RemoteEventsManager:InvokeServer("GetRoundTimeLeft")
	if timeRemaining then
		local minutes = math.floor(timeRemaining / 60)
		local seconds = timeRemaining % 60
		gameInfo.TimeLabel.Text = string.format("%02d:%02d REMAINING", minutes, seconds)
	end
end

function TabScoreboard:ShowScoreboard()
	if not scoreboardGui then
		self:CreateScoreboardUI()
	end

	isScoreboardVisible = true
	local mainContainer = scoreboardGui.ScoreboardContainer

	-- Update data before showing
	self:UpdateScoreboard()

	-- Show with animation
	mainContainer.Visible = true
	mainContainer.Position = UDim2.fromScale(0.1, -0.1)

	local showTween = TweenService:Create(mainContainer,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.fromScale(0.1, 0.15)}
	)
	showTween:Play()

	-- Notify server
	RemoteEventsManager:FireServer("ScoreboardToggled", {visible = true, player = player.Name})
end

function TabScoreboard:HideScoreboard()
	if not scoreboardGui or not isScoreboardVisible then return end

	isScoreboardVisible = false
	local mainContainer = scoreboardGui.ScoreboardContainer

	local hideTween = TweenService:Create(mainContainer,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.fromScale(0.1, -0.8)}
	)

	hideTween:Play()
	hideTween.Completed:Connect(function()
		mainContainer.Visible = false
		mainContainer.Position = UDim2.fromScale(0.1, 0.15)
	end)

	-- Notify server
	RemoteEventsManager:FireServer("ScoreboardToggled", {visible = false, player = player.Name})
end

function TabScoreboard:ToggleScoreboard()
	if isScoreboardVisible then
		self:HideScoreboard()
	else
		self:ShowScoreboard()
	end
end

function TabScoreboard:Initialize()
	-- Set up Tab key input handling
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Tab then
			self:ToggleScoreboard()
		end
	end)

	-- Initialize remote events
	RemoteEventsManager:Initialize()

	-- Listen for scoreboard updates from server
	local tabPressedEvent = RemoteEventsManager:GetEvent("TabPressed")
	if tabPressedEvent then
		tabPressedEvent.OnClientEvent:Connect(function()
			self:UpdateScoreboard()
		end)
	end

	-- Create initial scoreboard data (will be updated from server)
	scoreboardData = {}
	for _, serverPlayer in pairs(Players:GetPlayers()) do
		table.insert(scoreboardData, {
			name = serverPlayer.Name,
			kills = 0,
			deaths = 0,
			kdr = 0,
			streak = 0,
			score = 0,
			team = math.random() > 0.5 and "KFC" or "FBI", -- Random team assignment for now
			rank = 1
		})
	end

	print("TabScoreboard: Initialized")
end

-- Auto-initialize
TabScoreboard:Initialize()

return TabScoreboard