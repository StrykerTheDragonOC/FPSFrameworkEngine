-- ExportUI_ConsoleCommand.lua
-- Run this in Studio Console to export the current UI as .rbxm for reference

local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

print("🔄 UI Export System Starting...")

-- Find the main menu UI
local mainMenu = StarterGui:FindFirstChild("FPSMainMenu")
if not mainMenu then
    print("❌ FPSMainMenu not found! Generate UI first.")
    return
end

print("✅ Found FPSMainMenu")

-- Create a folder to organize the export
local exportFolder = Instance.new("Folder")
exportFolder.Name = "FPS_UI_Export_" .. os.date("%Y%m%d_%H%M%S")

-- Clone the main menu
local menuClone = mainMenu:Clone()
menuClone.Parent = exportFolder

-- Add metadata
local metadata = Instance.new("StringValue")
metadata.Name = "ExportInfo"
metadata.Value = "Exported on " .. os.date("%Y-%m-%d %H:%M:%S") .. " - FPS System UI"
metadata.Parent = exportFolder

-- Add structure documentation
local structure = Instance.new("StringValue")
structure.Name = "UIStructure"
structure.Value = [[
FPSMainMenu Structure:
├── MainContainer
    ├── BackgroundParticles
    └── MenuPanel
        ├── TopBar (PlayerInfo)
        ├── NavigationFrame (DEPLOYButton, ARMORYButton, etc.)
        └── SectionsContainer
            ├── MainSection
            ├── ArmorySection (with AttachmentTabs)
            ├── ShopSection
            ├── LeaderboardSection
            ├── StatisticsSection
            └── SettingsSection
]]
structure.Parent = exportFolder

-- Place in workspace for easy access
exportFolder.Parent = workspace

-- Select it for easy saving
Selection:Set({exportFolder})

print("✅ UI exported to workspace as: " .. exportFolder.Name)
print("📁 Selected in Explorer - Right-click → 'Save to File' to save as .rbxm")
print("📋 Use this .rbxm as reference for future UI updates")

return exportFolder