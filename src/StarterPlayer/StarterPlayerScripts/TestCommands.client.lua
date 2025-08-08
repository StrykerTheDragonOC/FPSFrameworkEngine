-- TestCommands.client.lua
-- Simple testing commands for the FPS system
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for everything to load
task.wait(3)

print("=== FPS System Test Commands ===")
print("Available commands in the console:")
print("LoadoutSelector:openGUI() - Open loadout selector")
print("_G.FPSController:toggleAttachmentMode() - Toggle attachment mode")
print("_G.DamageSystem:createTestRig(Vector3.new(0, 10, 0)) - Create test rig")
print("_G.AdvancedMovementSystem:getCurrentState() - Get movement state")
print("")
print("Controls:")
print("T - Toggle attachment mode")
print("Q - Spot enemies/test rigs")
print("Space+X - Dive")
print("C - Slide/Crouch")
print("X - Prone")
print("1-4 - Switch weapons")
print("================================")

-- Auto-open loadout selector for testing after a delay
task.delay(5, function()
	if _G.LoadoutSelector then
		print("Auto-opening loadout selector for testing...")
		_G.LoadoutSelector:openGUI()
	end
end)