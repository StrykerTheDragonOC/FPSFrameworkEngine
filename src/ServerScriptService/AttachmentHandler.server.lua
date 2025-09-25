local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsManager = require(ReplicatedStorage.FPSSystem.RemoteEvents.RemoteEventsManager)
local AttachmentManager = require(ReplicatedStorage.FPSSystem.Modules.AttachmentManager)
local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)
local WeaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)

local AttachmentHandler = {}

local playerLoadouts = {}

function AttachmentHandler:Initialize()
	RemoteEventsManager:Initialize()
	DataStoreManager:Initialize()
	
	-- Handle loadout save requests
	local saveLoadoutEvent = RemoteEventsManager:GetEvent("SaveWeaponLoadout")
	if saveLoadoutEvent then
		saveLoadoutEvent.OnServerEvent:Connect(function(player, loadoutData)
			self:HandleSaveLoadout(player, loadoutData)
		end)
	end
	
	-- Handle loadout requests
	local getLoadoutEvent = RemoteEventsManager:GetEvent("GetWeaponLoadout")
	if getLoadoutEvent then
		getLoadoutEvent.OnServerEvent:Connect(function(player, weaponName)
			self:SendWeaponLoadout(player, weaponName)
		end)
	end
	
	-- Player management
	Players.PlayerAdded:Connect(function(player)
		playerLoadouts[player] = {}
		self:LoadPlayerLoadouts(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerLoadouts(player)
		playerLoadouts[player] = nil
	end)
	
	_G.AttachmentHandler = self
	print("AttachmentHandler initialized")
end

function AttachmentHandler:HandleSaveLoadout(player, loadoutData)
	if not player or not loadoutData then
		warn("Invalid loadout data received")
		return
	end
	
	local weaponName = loadoutData.WeaponName
	local attachments = loadoutData.Attachments or {}
	
	-- Validate weapon exists
	if not WeaponConfig:IsValidWeapon(weaponName) then
		self:SendLoadoutResult(player, false, "Invalid weapon: " .. weaponName)
		return
	end
	
	-- Validate attachments
	local valid, errorMessage = AttachmentManager:ValidateLoadout(weaponName, attachments)
	if not valid then
		self:SendLoadoutResult(player, false, errorMessage)
		return
	end
	
	-- Check if player owns all attachments
	for _, attachmentName in pairs(attachments) do
		if not self:PlayerOwnsAttachment(player, weaponName, attachmentName) then
			self:SendLoadoutResult(player, false, "You don't own: " .. attachmentName)
			return
		end
	end
	
	-- Save loadout
	if not playerLoadouts[player] then
		playerLoadouts[player] = {}
	end
	
	playerLoadouts[player][weaponName] = attachments
	
	-- Update player's equipped weapon if it matches
	self:UpdateEquippedWeapon(player, weaponName, attachments)
	
	self:SendLoadoutResult(player, true, "Loadout saved for " .. weaponName)
	
	print(player.Name .. " saved loadout for " .. weaponName .. ": " .. table.concat(attachments, ", "))
end

function AttachmentHandler:PlayerOwnsAttachment(player, weaponName, attachmentName)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.UnlockedAttachments then
		return false
	end
	
	local weaponAttachments = playerData.UnlockedAttachments[weaponName]
	if not weaponAttachments then
		return false
	end
	
	return table.find(weaponAttachments, attachmentName) ~= nil
end

function AttachmentHandler:SendLoadoutResult(player, success, message)
	RemoteEventsManager:FireClient(player, "LoadoutResult", {
		Success = success,
		Message = message
	})
end

function AttachmentHandler:SendWeaponLoadout(player, weaponName)
	local loadout = self:GetPlayerWeaponLoadout(player, weaponName)
	
	RemoteEventsManager:FireClient(player, "WeaponLoadoutData", {
		WeaponName = weaponName,
		Attachments = loadout
	})
end

function AttachmentHandler:GetPlayerWeaponLoadout(player, weaponName)
	if playerLoadouts[player] and playerLoadouts[player][weaponName] then
		return playerLoadouts[player][weaponName]
	end
	return {}
end

function AttachmentHandler:UpdateEquippedWeapon(player, weaponName, attachments)
	-- Update weapon stats for currently equipped weapon
	if not player.Character then return end
	
	for _, tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") and tool.Name == weaponName then
			self:ApplyAttachmentsToWeapon(tool, attachments)
			break
		end
	end
end

function AttachmentHandler:ApplyAttachmentsToWeapon(weaponTool, attachments)
	local config = weaponTool:FindFirstChild("Config")
	if not config then return end
	
	-- Get base weapon config
	local baseConfig = WeaponConfig:GetWeaponConfig(weaponTool.Name)
	if not baseConfig then return end
	
	-- Apply attachment modifications
	local modifiedConfig = AttachmentManager:ApplyAttachmentModifiers(baseConfig, attachments)
	
	-- Update weapon config values
	for statName, value in pairs(modifiedConfig) do
		local statValue = config:FindFirstChild(statName)
		if statValue then
			if statValue:IsA("NumberValue") then
				statValue.Value = value
			elseif statValue:IsA("StringValue") then
				statValue.Value = tostring(value)
			elseif statValue:IsA("BoolValue") then
				statValue.Value = value
			elseif statValue:IsA("Folder") and statName == "Recoil" and type(value) == "table" then
				-- Handle recoil table
				for recoilStat, recoilValue in pairs(value) do
					local recoilStatValue = statValue:FindFirstChild(recoilStat)
					if recoilStatValue and recoilStatValue:IsA("NumberValue") then
						recoilStatValue.Value = recoilValue
					end
				end
			end
		end
	end
	
	-- Store attachment list in weapon
	local attachmentList = weaponTool:FindFirstChild("AttachmentList")
	if not attachmentList then
		attachmentList = Instance.new("StringValue")
		attachmentList.Name = "AttachmentList"
		attachmentList.Parent = weaponTool
	end
	
	attachmentList.Value = table.concat(attachments, ",")
	
	-- Apply visual effects
	self:ApplyVisualEffects(weaponTool, attachments)
end

function AttachmentHandler:ApplyVisualEffects(weaponTool, attachments)
	-- Apply visual effects for attachments
	for _, attachmentName in pairs(attachments) do
		local visualEffects = AttachmentManager:GetAttachmentVisualEffects(attachmentName)
		
		if visualEffects.HasReticle then
			-- Add reticle GUI or modify zoom
			local reticleGui = weaponTool:FindFirstChild("ReticleGui")
			if not reticleGui then
				reticleGui = Instance.new("ScreenGui")
				reticleGui.Name = "ReticleGui"
				reticleGui.Parent = weaponTool
			end
			
			-- Store reticle type
			local reticleType = reticleGui:FindFirstChild("ReticleType")
			if not reticleType then
				reticleType = Instance.new("StringValue")
				reticleType.Name = "ReticleType"
				reticleType.Parent = reticleGui
			end
			reticleType.Value = visualEffects.ReticleType
			
			-- Store zoom factor
			local zoomFactor = reticleGui:FindFirstChild("ZoomFactor")
			if not zoomFactor then
				zoomFactor = Instance.new("NumberValue")
				zoomFactor.Name = "ZoomFactor"
				zoomFactor.Parent = reticleGui
			end
			zoomFactor.Value = visualEffects.ZoomFactor
		end
		
		if visualEffects.HasLaserBeam then
			-- Add laser sight
			local laserPart = weaponTool:FindFirstChild("LaserSight")
			if not laserPart then
				laserPart = Instance.new("Part")
				laserPart.Name = "LaserSight"
				laserPart.Size = Vector3.new(0.1, 0.1, 0.1)
				laserPart.Material = Enum.Material.Neon
				laserPart.BrickColor = BrickColor.new("Really red")
				laserPart.Anchored = true
				laserPart.CanCollide = false
				laserPart.Parent = weaponTool
			end
		end
		
		if visualEffects.HasFlashlight then
			-- Add flashlight
			local spotlight = weaponTool:FindFirstChild("Flashlight")
			if not spotlight then
				spotlight = Instance.new("SpotLight")
				spotlight.Name = "Flashlight"
				spotlight.Brightness = 2
				spotlight.Range = visualEffects.LightRange or 50
				spotlight.Angle = 45
				spotlight.Parent = weaponTool:FindFirstChild("Handle") or weaponTool
			end
		end
	end
end

function AttachmentHandler:LoadPlayerLoadouts(player)
	-- Load attachment loadouts from DataStore
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData then return end
	
	if playerData.WeaponLoadouts then
		playerLoadouts[player] = playerData.WeaponLoadouts
	else
		playerLoadouts[player] = {}
	end
	
	-- Send attachment data to client
	RemoteEventsManager:FireClient(player, "AttachmentDataUpdated", {
		UnlockedAttachments = playerData.UnlockedAttachments or {},
		WeaponLoadouts = playerLoadouts[player]
	})
end

function AttachmentHandler:SavePlayerLoadouts(player)
	-- Save attachment loadouts to DataStore
	local playerData = DataStoreManager:GetPlayerData(player)
	if playerData and playerLoadouts[player] then
		playerData.WeaponLoadouts = playerLoadouts[player]
	end
end

function AttachmentHandler:GetWeaponWithAttachments(player, weaponName)
	-- Return weapon config modified by player's attachments
	local baseConfig = WeaponConfig:GetWeaponConfig(weaponName)
	if not baseConfig then return nil end
	
	local attachments = self:GetPlayerWeaponLoadout(player, weaponName)
	return AttachmentManager:ApplyAttachmentModifiers(baseConfig, attachments)
end

-- Integration with weapon giving system
function AttachmentHandler:OnWeaponGiven(player, weaponTool)
	if not weaponTool or not player then return end
	
	local weaponName = weaponTool.Name
	local attachments = self:GetPlayerWeaponLoadout(player, weaponName)
	
	if #attachments > 0 then
		self:ApplyAttachmentsToWeapon(weaponTool, attachments)
		print("Applied attachments to " .. weaponName .. " for " .. player.Name)
	end
end

-- Console commands for testing
_G.AttachmentCommands = {
	unlockAttachment = function(playerName, weaponName, attachmentName)
		local player = Players:FindFirstChild(playerName)
		if player and AttachmentManager:IsValidAttachment(attachmentName) then
			local playerData = DataStoreManager:GetPlayerData(player)
			if playerData then
				if not playerData.UnlockedAttachments then
					playerData.UnlockedAttachments = {}
				end
				if not playerData.UnlockedAttachments[weaponName] then
					playerData.UnlockedAttachments[weaponName] = {}
				end
				
				table.insert(playerData.UnlockedAttachments[weaponName], attachmentName)
				print("Unlocked " .. attachmentName .. " for " .. weaponName .. " (" .. playerName .. ")")
				
				-- Update client
				RemoteEventsManager:FireClient(player, "AttachmentDataUpdated", {
					UnlockedAttachments = playerData.UnlockedAttachments,
					WeaponLoadouts = playerLoadouts[player] or {}
				})
			end
		end
	end,
	
	unlockAllAttachments = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if player then
			local playerData = DataStoreManager:GetPlayerData(player)
			if playerData then
				playerData.UnlockedAttachments = {
					G36 = {"RedDotSight", "ACOGScope", "Suppressor", "Compensator", "VerticalGrip", "LaserSight", "Flashlight"},
					M9 = {"RedDotSight", "Suppressor", "LaserSight", "ExtendedMag"}
				}
				print("Unlocked all attachments for " .. playerName)
				
				-- Update client  
				RemoteEventsManager:FireClient(player, "AttachmentDataUpdated", {
					UnlockedAttachments = playerData.UnlockedAttachments,
					WeaponLoadouts = playerLoadouts[player] or {}
				})
			end
		end
	end,
	
	getLoadout = function(playerName, weaponName)
		local player = Players:FindFirstChild(playerName)
		if player then
			local loadout = AttachmentHandler:GetPlayerWeaponLoadout(player, weaponName)
			print(playerName .. " loadout for " .. weaponName .. ": " .. table.concat(loadout, ", "))
		end
	end
}

-- Hook into weapon giving system
if _G.WeaponHandler then
	local originalGiveWeapon = _G.WeaponHandler.GiveWeapon
	if originalGiveWeapon then
		_G.WeaponHandler.GiveWeapon = function(self, player, weaponName, ...)
			local weaponTool = originalGiveWeapon(self, player, weaponName, ...)
			if weaponTool then
				AttachmentHandler:OnWeaponGiven(player, weaponTool)
			end
			return weaponTool
		end
	end
end

AttachmentHandler:Initialize()

return AttachmentHandler