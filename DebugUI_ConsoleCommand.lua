-- DebugUI_ConsoleCommand.lua
-- Run this in Studio Console to debug UI structure

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("=== UI STRUCTURE DEBUG ===")

local mainMenu = playerGui:FindFirstChild("FPSMainMenu")
if not mainMenu then
    print("❌ FPSMainMenu not found! Run MenuUIGenerator_ConsoleCommand.lua first")
    return
end

print("✅ FPSMainMenu found")

local mainContainer = mainMenu:FindFirstChild("MainContainer")
if not mainContainer then
    print("❌ MainContainer not found!")
    return
end
print("✅ MainContainer found")

local menuPanel = mainContainer:FindFirstChild("MenuPanel")
if not menuPanel then
    print("❌ MenuPanel not found!")
    return
end
print("✅ MenuPanel found")

-- Check NavigationFrame
local navFrame = menuPanel:FindFirstChild("NavigationFrame")
if navFrame then
    print("✅ NavigationFrame found")
    local buttons = {"DEPLOYButton", "ARMORYButton", "SHOPButton", "LEADERBOARDButton", "SETTINGSButton"}
    for _, buttonName in ipairs(buttons) do
        local button = navFrame:FindFirstChild(buttonName)
        print("  " .. buttonName .. ":", button and "✅" or "❌")
    end
else
    print("❌ NavigationFrame not found!")
end

-- Check SectionsContainer
local sectionsContainer = menuPanel:FindFirstChild("SectionsContainer")
if sectionsContainer then
    print("✅ SectionsContainer found")
    local sections = {"MainSection", "ArmorySection", "ShopSection", "LeaderboardSection", "StatisticsSection", "SettingsSection"}
    for _, sectionName in ipairs(sections) do
        local section = sectionsContainer:FindFirstChild(sectionName)
        print("  " .. sectionName .. ":", section and "✅" or "❌")

        -- Check ArmorySection specifically
        if sectionName == "ArmorySection" and section then
            local attachmentTabs = section:FindFirstChild("AttachmentTabs")
            print("    AttachmentTabs:", attachmentTabs and "✅" or "❌")
            if attachmentTabs then
                local tabs = {"ATTACHMENTSTab", "PERKSTab", "SKINSTab", "WEAPONSTab"}
                for _, tabName in ipairs(tabs) do
                    local tab = attachmentTabs:FindFirstChild(tabName)
                    print("      " .. tabName .. ":", tab and "✅" or "❌")
                end
            end
        end
    end
else
    print("❌ SectionsContainer not found!")
end

print("=== DEBUG COMPLETE ===")