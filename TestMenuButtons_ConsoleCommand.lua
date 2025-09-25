-- TestMenuButtons_ConsoleCommand.lua
-- Run this in Studio Console to test menu button functionality

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("=== MENU BUTTON TEST ===")

-- Check if main menu exists
local mainMenu = playerGui:FindFirstChild("FPSMainMenu")
if not mainMenu then
    print("❌ FPSMainMenu not found in PlayerGui!")
    print("Available GUIs in PlayerGui:")
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            print("  - " .. gui.Name)
        end
    end
    return
end

print("✅ FPSMainMenu found")

-- Navigate to navigation frame
local mainContainer = mainMenu:FindFirstChild("MainContainer")
if not mainContainer then
    print("❌ MainContainer not found!")
    return
end

local menuPanel = mainContainer:FindFirstChild("MenuPanel")
if not menuPanel then
    print("❌ MenuPanel not found!")
    return
end

local navigationFrame = menuPanel:FindFirstChild("NavigationFrame")
if not navigationFrame then
    print("❌ NavigationFrame not found!")
    return
end

print("✅ NavigationFrame found")

-- Test each button
local buttons = {"DEPLOYButton", "ARMORYButton", "SHOPButton", "LEADERBOARDButton", "SETTINGSButton"}

for _, buttonName in ipairs(buttons) do
    local button = navigationFrame:FindFirstChild(buttonName)
    if button then
        print("✅ " .. buttonName .. " found")

        -- Test if it's clickable
        if button:IsA("TextButton") or button:IsA("ImageButton") then
            print("  ✅ Button is clickable (" .. button.ClassName .. ")")

            -- Check if it has connections
            local connections = getconnections(button.MouseButton1Click)
            if #connections > 0 then
                print("  ✅ Button has " .. #connections .. " connection(s)")
            else
                print("  ❌ Button has no connections!")
            end
        else
            print("  ❌ Element is not a clickable button (" .. button.ClassName .. ")")
        end
    else
        print("❌ " .. buttonName .. " not found!")
    end
end

-- Test sections container
local sectionsContainer = menuPanel:FindFirstChild("SectionsContainer")
if sectionsContainer then
    print("✅ SectionsContainer found")

    local sections = {"MainSection", "ArmorySection", "ShopSection", "LeaderboardSection", "StatisticsSection", "SettingsSection"}
    for _, sectionName in ipairs(sections) do
        local section = sectionsContainer:FindFirstChild(sectionName)
        print("  " .. sectionName .. ":", section and "✅" or "❌")
    end
else
    print("❌ SectionsContainer not found!")
end

-- Check if MenuController script exists
local menuController = StarterGui:FindFirstChild("MenuController")
if menuController then
    print("✅ MenuController script found in StarterGui")
    if menuController.Enabled then
        print("  ✅ MenuController is enabled")
    else
        print("  ❌ MenuController is disabled!")
    end
else
    print("❌ MenuController script not found in StarterGui!")
    print("Available scripts in StarterGui:")
    for _, child in pairs(StarterGui:GetChildren()) do
        if child:IsA("LocalScript") then
            print("  - " .. child.Name .. " (enabled: " .. tostring(child.Enabled) .. ")")
        end
    end
end

print("=== TEST COMPLETE ===")

-- Try to manually trigger armory button for testing
local armoryButton = navigationFrame:FindFirstChild("ARMORYButton")
if armoryButton then
    print("🔍 Testing ARMORY button manually...")
    local success, result = pcall(function()
        -- Simulate button click
        for _, connection in pairs(getconnections(armoryButton.MouseButton1Click)) do
            connection:Fire()
        end
    end)

    if success then
        print("✅ ARMORY button test completed")
    else
        print("❌ ARMORY button test failed:", result)
    end
end