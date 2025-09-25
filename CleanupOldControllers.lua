-- CleanupOldControllers.lua
-- Run this ONCE in Studio Console to clean up old controller scripts
-- This removes any conflicting controllers from PlayerScripts

local Players = game:GetService("Players")

print("🧹 Cleaning up old controller scripts...")

local player = Players.LocalPlayer
local playerScripts = player:FindFirstChild("PlayerScripts")

if playerScripts then
    local controllersToRemove = {
        "MainMenuController",
        "DeployController",
        "HUDController",
        "ScopeController",
        "ShopController",
        "LoadoutController",
        "InGameUIController"
    }

    for _, controllerName in ipairs(controllersToRemove) do
        local controller = playerScripts:FindFirstChild(controllerName)
        if controller then
            controller:Destroy()
            print("  ✓ Removed old " .. controllerName)
        end
    end

    print("✅ Controller cleanup complete!")
else
    print("❌ PlayerScripts not found")
end

-- Also clean up any old GUIs in PlayerGui
local playerGui = player:FindFirstChild("PlayerGui")
if playerGui then
    local oldGUIs = {
        "DeployGUI",
        "InGameUI",
        "OldMainMenu",
        "LoadoutMenu",
        "SettingsMenu",
        "ShopMenu",
        "AmmoSystemGUI",
        "ScopeSystemGUI",
        "StatusEffectsGUI",
        "CookingGUI",
        "ClassSystemGUI",
        "PickupGUI",
        "CustomScoreboard" -- Keep this one but check for conflicts
    }

    for _, guiName in ipairs(oldGUIs) do
        local oldGui = playerGui:FindFirstChild(guiName)
        if oldGui then
            if guiName == "CustomScoreboard" then
                print("  ⚠ Found CustomScoreboard - may need adjustment")
            else
                oldGui:Destroy()
                print("  ✓ Removed old " .. guiName)
            end
        end
    end

    print("✅ GUI cleanup complete!")
    print("🎯 Now run MenuUIGenerator to create clean UI")
end