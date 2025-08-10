-- WeaponConverter.lua  
-- Weapon configuration converter for compatibility between formats
-- Place in ReplicatedStorage.FPSSystem.Modules

local WeaponConverter = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Convert weapon configurations between different formats
function WeaponConverter.convertLegacyConfig(legacyConfig)
    -- Convert old weapon configs to new format
    local newConfig = {
        name = legacyConfig.Name or "Unknown Weapon",
        damage = legacyConfig.Damage or 25,
        fireRate = legacyConfig.FireRate or 600,
        recoil = {
            vertical = legacyConfig.VerticalRecoil or 1.2,
            horizontal = legacyConfig.HorizontalRecoil or 0.3,
            recovery = legacyConfig.RecoilRecovery or 0.95
        },
        mobility = {
            adsSpeed = legacyConfig.AimSpeed or 0.3,
            walkSpeed = legacyConfig.WalkSpeed or 14,
            sprintSpeed = legacyConfig.SprintSpeed or 20
        },
        magazine = {
            size = legacyConfig.MagazineSize or 30,
            maxAmmo = legacyConfig.MaxAmmo or 120,
            reloadTime = legacyConfig.ReloadTime or 2.5
        },
        sounds = {
            fire = legacyConfig.FireSound,
            reload = legacyConfig.ReloadSound,
            empty = legacyConfig.EmptySound
        }
    }

    return newConfig
end

-- Convert new config format back to legacy for compatibility
function WeaponConverter.convertToLegacy(newConfig)
    local legacyConfig = {
        Name = newConfig.name,
        Damage = newConfig.damage,
        FireRate = newConfig.fireRate,
        VerticalRecoil = newConfig.recoil and newConfig.recoil.vertical,
        HorizontalRecoil = newConfig.recoil and newConfig.recoil.horizontal,
        RecoilRecovery = newConfig.recoil and newConfig.recoil.recovery,
        AimSpeed = newConfig.mobility and newConfig.mobility.adsSpeed,
        WalkSpeed = newConfig.mobility and newConfig.mobility.walkSpeed,
        SprintSpeed = newConfig.mobility and newConfig.mobility.sprintSpeed,
        MagazineSize = newConfig.magazine and newConfig.magazine.size,
        MaxAmmo = newConfig.magazine and newConfig.magazine.maxAmmo,
        ReloadTime = newConfig.magazine and newConfig.magazine.reloadTime,
        FireSound = newConfig.sounds and newConfig.sounds.fire,
        ReloadSound = newConfig.sounds and newConfig.sounds.reload,
        EmptySound = newConfig.sounds and newConfig.sounds.empty
    }

    return legacyConfig
end

-- Validate weapon configuration
function WeaponConverter.validateConfig(config)
    local errors = {}

    if not config.name then
        table.insert(errors, "Missing weapon name")
    end

    if not config.damage or config.damage <= 0 then
        table.insert(errors, "Invalid damage value")
    end

    if not config.fireRate or config.fireRate <= 0 then
        table.insert(errors, "Invalid fire rate")
    end

    if config.recoil then
        if not config.recoil.vertical or config.recoil.vertical < 0 then
            table.insert(errors, "Invalid vertical recoil")
        end
        if not config.recoil.horizontal or config.recoil.horizontal < 0 then
            table.insert(errors, "Invalid horizontal recoil")
        end
    end

    if config.magazine then
        if not config.magazine.size or config.magazine.size <= 0 then
            table.insert(errors, "Invalid magazine size")
        end
        if not config.magazine.maxAmmo or config.magazine.maxAmmo < 0 then
            table.insert(errors, "Invalid max ammo")
        end
    end

    return #errors == 0, errors
end

-- Normalize weapon stats for balancing
function WeaponConverter.normalizeStats(config)
    local normalized = table.clone(config)

    -- Ensure damage is within reasonable bounds (10-100)
    if normalized.damage then
        normalized.damage = math.clamp(normalized.damage, 10, 100)
    end

    -- Ensure fire rate is within bounds (60-1200 RPM)
    if normalized.fireRate then
        normalized.fireRate = math.clamp(normalized.fireRate, 60, 1200)
    end

    -- Normalize recoil values (0.1-5.0)
    if normalized.recoil then
        if normalized.recoil.vertical then
            normalized.recoil.vertical = math.clamp(normalized.recoil.vertical, 0.1, 5.0)
        end
        if normalized.recoil.horizontal then
            normalized.recoil.horizontal = math.clamp(normalized.recoil.horizontal, 0.1, 5.0)
        end
    end

    return normalized
end

-- Enhanced model conversion functions (keeping existing WeaponConverter functionality)

-- Find weapon model in various possible locations
function WeaponConverter.findWeaponModel(weaponName, category)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild(category),
        ReplicatedStorage:FindFirstChild("FPSSystem") and ReplicatedStorage.FPSSystem:FindFirstChild("Weapons") and ReplicatedStorage.FPSSystem.Weapons:FindFirstChild(category),
        ReplicatedStorage:FindFirstChild("WeaponModels") and ReplicatedStorage.WeaponModels:FindFirstChild(category)
    }

    for _, path in ipairs(searchPaths) do
        if path then
            local weapon = path:FindFirstChild(weaponName)
            if weapon then
                print("WeaponConverter: Found", weaponName, "in", path:GetFullName())
                return weapon
            end
        end
    end

    warn("WeaponConverter: Could not find weapon:", weaponName, "in category:", category)
    return nil
end

-- Ensure model has proper structure for FPS use
function WeaponConverter.ensureModelStructure(model)
    if not model or not model:IsA("Model") then
        warn("WeaponConverter: Invalid model provided")
        return nil
    end

    -- Clone the model to avoid modifying original
    local weaponModel = model:Clone()

    -- Ensure the model has a PrimaryPart (Handle)
    if not weaponModel.PrimaryPart then
        local handle = weaponModel:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            weaponModel.PrimaryPart = handle
        else
            -- Create a new handle if none exists
            local newHandle = Instance.new("Part")
            newHandle.Name = "Handle"
            newHandle.Anchored = false
            newHandle.CanCollide = false
            newHandle.Size = Vector3.new(0.2, 0.2, 1)
            newHandle.Material = Enum.Material.Metal
            newHandle.BrickColor = BrickColor.new("Dark stone grey")

            -- Center the handle in the model
            local modelCenter = Vector3.new(0, 0, 0)
            local partCount = 0

            for _, part in pairs(weaponModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    modelCenter = modelCenter + part.Position
                    partCount = partCount + 1
                end
            end

            if partCount > 0 then
                modelCenter = modelCenter / partCount
            end

            newHandle.Position = modelCenter
            newHandle.Parent = weaponModel
            weaponModel.PrimaryPart = newHandle

            print("WeaponConverter: Created new Handle for", weaponModel.Name)
        end
    end

    -- Create standard attachment points if they don't exist
    local primaryPart = weaponModel.PrimaryPart
    if primaryPart then
        local standardAttachments = {
            MuzzlePoint = CFrame.new(0, 0, -primaryPart.Size.Z/2),
            ShellEjectPoint = CFrame.new(0.1, 0.1, 0),
            AimPoint = CFrame.new(0, 0.15, 0),
            RightGripPoint = CFrame.new(0.2, -0.2, 0),
            LeftGripPoint = CFrame.new(-0.2, -0.2, 0)
        }

        for attachmentName, offset in pairs(standardAttachments) do
            if not primaryPart:FindFirstChild(attachmentName) then
                local attachment = Instance.new("Attachment")
                attachment.Name = attachmentName
                attachment.CFrame = offset
                attachment.Parent = primaryPart
            end
        end
    end

    return weaponModel
end

-- Convert from character model to weapon models
function WeaponConverter.convertFromCharacter(character, weaponName)
    local weapon = character:FindFirstChild(weaponName)
    if not weapon then
        warn("WeaponConverter: Weapon not found in character:", weaponName)
        return nil
    end

    -- Create world model
    local worldModel = WeaponConverter.ensureModelStructure(weapon:Clone())
    if not worldModel then
        return nil
    end

    -- Create viewmodel
    local viewModel = worldModel:Clone()
    viewModel.Name = weaponName .. "Viewmodel"

    return {
        worldModel = worldModel,
        viewModel = viewModel
    }
end

return WeaponConverter