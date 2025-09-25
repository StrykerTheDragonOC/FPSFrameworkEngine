-- Run this in Studio Command Bar to debug mesh properties
-- This will show you what MeshID/TextureID properties are currently set

local function checkMeshProperties()
    print("=== ROJO MESH DEBUG ===")

    -- Check weapon model G36
    local weaponModel = game.ReplicatedStorage.FPSSystem.WeaponModels.Primary.AssaultRifles:FindFirstChild("G36")
    if weaponModel then
        print("Weapon Model G36 found:")
        for _, child in pairs(weaponModel:GetChildren()) do
            if child:IsA("MeshPart") then
                print("  " .. child.Name .. " - MeshID: " .. tostring(child.MeshID) .. ", TextureID: " .. tostring(child.TextureID))
            end
        end
    else
        print("Weapon Model G36 NOT FOUND")
    end

    -- Check viewmodel G36
    local viewModel = game.ReplicatedStorage.FPSSystem.ViewModels.Primary.AssaultRifles:FindFirstChild("G36")
    if viewModel then
        print("View Model G36 found:")
        for _, child in pairs(viewModel:GetChildren()) do
            if child:IsA("MeshPart") then
                print("  " .. child.Name .. " - MeshID: " .. tostring(child.MeshID) .. ", TextureID: " .. tostring(child.TextureID))
            end
        end
    else
        print("View Model G36 NOT FOUND")
    end

    -- Check test mesh
    local testMesh = game.Workspace:FindFirstChild("TestMesh")
    if testMesh then
        print("Test Mesh found - MeshID: " .. tostring(testMesh.MeshID))
    else
        print("Test Mesh NOT FOUND")
    end

    print("=== END DEBUG ===")
end

checkMeshProperties()