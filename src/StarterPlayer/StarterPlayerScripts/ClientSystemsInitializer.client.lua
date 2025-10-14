local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ClientSystemsInitializer = {}

local player = Players.LocalPlayer
local character = nil

-- System references
local systems = {}

repeat wait() until ReplicatedStorage:FindFirstChild("FPSSystem")

function ClientSystemsInitializer:Initialize()
	print("=== CLIENT SYSTEMS INITIALIZER ===")
	print("Starting comprehensive FPS system client initialization...")
	
	-- Wait for character
	if player.Character then
		character = player.Character
	else
		character = player.CharacterAdded:Wait()
	end
	
	-- Initialize all client systems in correct order
	self:InitializeCore()
	self:InitializeUI()
	self:InitializeGameplay()
	self:InitializeIntegrations()
	
	-- Setup global access
	_G.ClientSystems = systems
	
	print("=== CLIENT SYSTEMS READY ===")
	print("All systems initialized successfully")
end

function ClientSystemsInitializer:InitializeCore()
	print("Initializing core systems...")

	-- Game Config
	local GameConfig = require(ReplicatedStorage.FPSSystem.Modules.GameConfig)
	GameConfig:Initialize()
	systems.GameConfig = GameConfig
	print("✓ Game Config initialized")
	
	-- XP System
	local XPSystem = require(ReplicatedStorage.FPSSystem.Modules.XPSystem)
	XPSystem:Initialize()
	systems.XP = XPSystem
	print("✓ XP System initialized")
	
	-- Raycast System
	local RaycastSystem = require(ReplicatedStorage.FPSSystem.Modules.RaycastSystem)
	RaycastSystem:Initialize()
	systems.Raycast = RaycastSystem
	print("✓ Raycast System initialized")
	
	-- Damage System
	local DamageSystem = require(ReplicatedStorage.FPSSystem.Modules.DamageSystem)
	DamageSystem:Initialize()
	systems.Damage = DamageSystem
	print("✓ Damage System initialized")
	
	-- Attachment Manager
	local AttachmentManager = require(ReplicatedStorage.FPSSystem.Modules.AttachmentManager)
	AttachmentManager:Initialize()
	systems.Attachments = AttachmentManager
	print("✓ Attachment Manager initialized")
	
	-- Note: DataStore is server-side only, client gets data through RemoteEvents
	print("✓ Data persistence handled server-side")
end

function ClientSystemsInitializer:InitializeUI()
	print("Initializing UI systems...")
	
	-- Wait for PlayerGui to be ready
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Hide default Roblox UI elements
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	
	-- UI Coordinator removed - now using MenuController in StarterGui
	print("✓ UI managed by MenuController (UICoordinator removed)")
	
	-- Main Menu Controller (in StarterGui per Claude.md guidelines)
	local starterGui = game:GetService("StarterGui")
	if starterGui:FindFirstChild("MenuController") then
		print("✓ Menu Controller found in StarterGui - will initialize automatically")
	else
		print("⚠ Menu Controller not found in StarterGui")
	end

	-- In-Game UI Controllers are handled by individual client scripts
	print("✓ In-Game UI systems handled by individual client controllers")
end

function ClientSystemsInitializer:InitializeGameplay()
	print("Initializing gameplay systems...")
	
	-- Movement System (LocalScript - runs automatically)
	if script.Parent:FindFirstChild("MovementSystem") then
		print("✓ Movement System found - will initialize automatically")
	else
		print("⚠ Movement System not found")
	end
	
	-- Viewmodel System
	local ViewmodelSystem = require(ReplicatedStorage.FPSSystem.Modules.ViewmodelSystem)
	ViewmodelSystem:Initialize()
	systems.Viewmodel = ViewmodelSystem
	print("✓ Viewmodel System initialized")

	-- Scope System (for sniper scopes and optics)
	local ScopeSystem = require(ReplicatedStorage.FPSSystem.Modules.ScopeSystem)
	ScopeSystem:Initialize()
	systems.Scope = ScopeSystem
	print("✓ Scope System initialized")

	-- Audio System (if exists)
	if ReplicatedStorage.FPSSystem.Modules:FindFirstChild("AudioSystem") then
		local AudioSystem = require(ReplicatedStorage.FPSSystem.Modules.AudioSystem)
		AudioSystem:Initialize()
		systems.Audio = AudioSystem
		print("✓ Audio System initialized")
	end
end

function ClientSystemsInitializer:InitializeIntegrations()
	print("Setting up system integrations...")
	
	-- Character respawn handling
	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		self:OnCharacterAdded(newCharacter)
	end)
	
	-- Setup cross-system communication
	self:SetupSystemCommunication()
	
	-- Setup event connections
	self:SetupEventConnections()
	
	print("✓ System integrations setup complete")
end

function ClientSystemsInitializer:OnCharacterAdded(newCharacter)
	print("Character respawned - reinitializing systems...")
	
	-- Reinitialize character-dependent systems
	-- Movement and InGameUI are LocalScripts that handle their own initialization
	
	if systems.Viewmodel and systems.Viewmodel.Initialize then
		systems.Viewmodel:Initialize()
	end
end

function ClientSystemsInitializer:SetupSystemCommunication()
	-- Create event system for inter-system communication
	local SystemEvents = {}
	
	-- Health updates
	SystemEvents.HealthChanged = function(health, maxHealth)
		-- UI updates handled by FPSHUD directly
		print("Health changed:", health, "/", maxHealth)
	end
	
	-- Ammo updates
	SystemEvents.AmmoChanged = function(current, reserve)
		-- UI updates handled by FPSHUD directly
		print("Ammo changed:", current, "/", reserve)
	end
	
	-- Weapon equipped
	SystemEvents.WeaponEquipped = function(weaponData)
		if systems.Viewmodel and systems.Viewmodel.OnWeaponEquipped then
			systems.Viewmodel:OnWeaponEquipped(weaponData)
		end
	end
	
	-- Movement state changes
	SystemEvents.MovementStateChanged = function(state)
		-- Coordinate between movement and other systems
		if systems.Viewmodel and systems.Viewmodel.OnMovementStateChanged then
			systems.Viewmodel:OnMovementStateChanged(state)
		end
	end
	
	_G.SystemEvents = SystemEvents
	print("✓ Cross-system communication setup")
end

function ClientSystemsInitializer:SetupEventConnections()
	local remoteEventsFolder = ReplicatedStorage.FPSSystem.RemoteEvents
	if not remoteEventsFolder then return end

	-- Level up notifications
	local levelUpEvent = remoteEventsFolder:FindFirstChild("LevelUp")
	if levelUpEvent then
		levelUpEvent.OnClientEvent:Connect(function(levelData)
			print("LEVEL UP! New Level: " .. levelData.NewLevel .. " | Credits Earned: " .. levelData.CreditsEarned)

			-- Show UI notification if available
			-- InGameUI handles level up notifications automatically
		end)
	end

	-- XP awards
	local xpAwardedEvent = remoteEventsFolder:FindFirstChild("XPAwarded")
	if xpAwardedEvent then
		xpAwardedEvent.OnClientEvent:Connect(function(xpData)
			print("XP Gained: +" .. xpData.Amount .. " (" .. xpData.Reason .. ")")

			-- InGameUI handles XP notifications automatically
		end)
	end

	-- Kill feed
	local playerKilledEvent = remoteEventsFolder:FindFirstChild("PlayerKilled")
	if playerKilledEvent then
		playerKilledEvent.OnClientEvent:Connect(function(killData)
			local message = killData.Killer .. " killed " .. killData.Victim
			if killData.IsHeadshot then
				message = message .. " (HEADSHOT)"
			end
			if killData.KillStreak > 1 then
				message = message .. " (Streak: " .. killData.KillStreak .. ")"
			end
			print(message)

			-- Add to kill feed if available
			-- InGameUI handles kill feed automatically
		end)
	end

	print("✓ Event connections established")
end

-- Console commands for debugging
function ClientSystemsInitializer:SetupDebugCommands()
	_G.ClientDebug = {
		listSystems = function()
			print("=== CLIENT SYSTEMS STATUS ===")
			for name, system in pairs(systems) do
				print(name .. ": " .. (system and "✓ Loaded" or "✗ Failed"))
			end
		end,
		
		reloadSystem = function(systemName)
			if systems[systemName] and systems[systemName].Initialize then
				systems[systemName]:Initialize()
				print("Reloaded system: " .. systemName)
			else
				print("System not found or not reloadable: " .. systemName)
			end
		end,
		
		getMovementState = function()
			if systems.Movement and systems.Movement.GetAdvancedMovementState then
				local state = systems.Movement:GetAdvancedMovementState()
				print("Movement State:")
				for key, value in pairs(state) do
					print("  " .. key .. ": " .. tostring(value))
				end
			end
		end,
		
		testViewmodel = function(weaponName)
			if systems.Viewmodel and systems.Viewmodel.CreateViewmodel then
				local weaponConfig = require(ReplicatedStorage.FPSSystem.Modules.WeaponConfig)
				local config = weaponConfig:GetWeaponConfig(weaponName or "G36")
				if config then
					systems.Viewmodel:CreateViewmodel(weaponName or "G36", config)
					print("Created viewmodel for: " .. (weaponName or "G36"))
				end
			end
		end,
		
		simulateHealth = function(health)
			health = health or 50
			-- InGameUI handles health updates automatically
			print("Simulated health: " .. health)
		end,
		
		testMovement = function()
			-- Movement system is a LocalScript that runs automatically
			print("Testing movement system...")
		end
	}
	
	print("✓ Debug commands setup")
end

-- Initialize everything
ClientSystemsInitializer:Initialize()
ClientSystemsInitializer:SetupDebugCommands()

print("=== Client FPS System Fully Initialized ===")
print("Advanced Controls:")
print("- C (tap): Crouch/Uncrouch")
print("- C (hold): Slide")
print("- Z: Prone/Unprone")
print("- X (in air): Dolphin Dive")
print("- Space (while ledge grabbing): Climb up")
print("- S (while ledge grabbing): Drop down")
print("- ESC: Toggle menu")
print("- Tab: Show leaderboard")
print("Console Commands:")
print("- _G.ClientDebug.listSystems() - Show system status")
print("- _G.ClientDebug.getMovementState() - Show movement state")
print("- _G.ClientDebug.testViewmodel('WeaponName') - Test viewmodel")
print("Ready for action!")

return ClientSystemsInitializer