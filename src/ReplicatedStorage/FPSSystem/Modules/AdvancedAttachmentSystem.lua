-- AdvancedAttachmentSystem.lua
-- Enhanced attachment system with integrated scope support
-- Place in ReplicatedStorage.FPSSystem.Modules

local AdvancedAttachmentSystem = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants for attachment types and categories
local ATTACHMENT_TYPES = {
    SIGHT = "SIGHT",
    BARREL = "BARREL",
    UNDERBARREL = "UNDERBARREL", 
    OTHER = "OTHER",
    AMMO = "AMMO"
}

-- Dynamic attachment point detection patterns
local ATTACHMENT_POINT_PATTERNS = {
    -- Sight/Optic attachments
    ["Optic"] = ATTACHMENT_TYPES.SIGHT,
    ["Sight"] = ATTACHMENT_TYPES.SIGHT,
    ["Scope"] = ATTACHMENT_TYPES.SIGHT,
    ["AimPoint"] = ATTACHMENT_TYPES.SIGHT,
    ["RedDot"] = ATTACHMENT_TYPES.SIGHT,
    ["ACOG"] = ATTACHMENT_TYPES.SIGHT,

    -- Barrel attachments  
    ["Barrel"] = ATTACHMENT_TYPES.BARREL,
    ["Muzzle"] = ATTACHMENT_TYPES.BARREL,
    ["Suppressor"] = ATTACHMENT_TYPES.BARREL,
    ["Compensator"] = ATTACHMENT_TYPES.BARREL,
    ["FlashHider"] = ATTACHMENT_TYPES.BARREL,

    -- Underbarrel attachments
    ["Underbarrel"] = ATTACHMENT_TYPES.UNDERBARREL,
    ["Grip"] = ATTACHMENT_TYPES.UNDERBARREL,
    ["Foregrip"] = ATTACHMENT_TYPES.UNDERBARREL,
    ["Bipod"] = ATTACHMENT_TYPES.UNDERBARREL,
    ["Laser"] = ATTACHMENT_TYPES.UNDERBARREL,
    ["Tactical"] = ATTACHMENT_TYPES.UNDERBARREL,

    -- Other attachments
    ["Stock"] = ATTACHMENT_TYPES.OTHER,
    ["Magazine"] = ATTACHMENT_TYPES.OTHER,
    ["Mag"] = ATTACHMENT_TYPES.OTHER,
    ["Battery"] = ATTACHMENT_TYPES.OTHER,
    ["Light"] = ATTACHMENT_TYPES.OTHER,

    -- Special points
    ["LeftGrip"] = ATTACHMENT_TYPES.OTHER,
    ["RightGrip"] = ATTACHMENT_TYPES.OTHER
}

-- Cache for attachment asset models
local attachmentModelCache = {}
local weaponAttachmentCache = {}

-- Function to scan weapon model for attachment points
function AdvancedAttachmentSystem.scanWeaponAttachmentPoints(weaponModel)
    if not weaponModel then return {} end

    -- Check cache first
    local weaponName = weaponModel.Name
    if weaponAttachmentCache[weaponName] then
        return weaponAttachmentCache[weaponName]
    end

    local attachmentPoints = {}

    -- Recursively search for attachment points
    local function scanDescendants(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Attachment") then
                -- Determine attachment type based on name patterns
                local attachmentType = AdvancedAttachmentSystem.getAttachmentTypeFromName(child.Name)
                if attachmentType then
                    attachmentPoints[attachmentType] = child
                end
            elseif child:IsA("Model") or child:IsA("Part") then
                scanDescendants(child)
            end
        end
    end

    scanDescendants(weaponModel)

    -- Cache the result
    weaponAttachmentCache[weaponName] = attachmentPoints
    return attachmentPoints
end

-- Function to determine attachment type from attachment point name
function AdvancedAttachmentSystem.getAttachmentTypeFromName(attachmentName)
    for pattern, attachmentType in pairs(ATTACHMENT_POINT_PATTERNS) do
        if string.find(attachmentName:lower(), pattern:lower()) then
            return attachmentType
        end
    end
    return nil
end

-- Get attachment database with integrated scope settings
function AdvancedAttachmentSystem.getAttachmentDatabase()
    return {
        -- Sights with integrated scope system
        ["Red Dot"] = {
            name = "Red Dot Sight",
            description = "Basic red dot for improved accuracy",
            type = ATTACHMENT_TYPES.SIGHT,
            compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol"},
            statModifiers = {
                aimSpeed = 0.95,
                recoil = {
                    vertical = 0.95,
                    horizontal = 0.95
                }
            },
            scopeSettings = {
                fov = 65,
                mode = "MODEL", -- MODEL or GUI
                sensitivity = 0.9,
                zoomLevel = 1.2
            }
        },
        ["ACOG"] = {
            name = "ACOG Sight",
            description = "4x magnification scope for medium range",
            type = ATTACHMENT_TYPES.SIGHT,
            compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
            statModifiers = {
                aimSpeed = 0.8,
                recoil = {
                    vertical = 0.9,
                    horizontal = 0.9
                }
            },
            scopeSettings = {
                fov = 40,
                mode = "MODEL",
                sensitivity = 0.7,
                zoomLevel = 4.0
            }
        },
        ["Sniper Scope"] = {
            name = "Sniper Scope",
            description = "8x magnification scope for long range",
            type = ATTACHMENT_TYPES.SIGHT,
            compatibleWeapons = {"AWP", "M24", "Dragunov", "SCAR-H"},
            statModifiers = {
                aimSpeed = 0.7,
                recoil = {
                    vertical = 0.8,
                    horizontal = 0.8
                }
            },
            scopeSettings = {
                fov = 20,
                mode = "GUI", -- Use GUI overlay for high magnification
                sensitivity = 0.5,
                zoomLevel = 8.0,
                scopeImage = "rbxassetid://7548348960"
            }
        },

        -- Barrels
        ["Suppressor"] = {
            name = "Suppressor",
            description = "Reduces sound and muzzle flash",
            type = ATTACHMENT_TYPES.BARREL,
            compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "AWP"},
            statModifiers = {
                damage = 0.9,
                recoil = {
                    vertical = 0.85,
                    horizontal = 0.9
                },
                sound = 0.3,
                muzzleFlash = 0.2
            }
        },
        ["Compensator"] = {
            name = "Compensator",
            description = "Reduces horizontal recoil",
            type = ATTACHMENT_TYPES.BARREL,
            compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
            statModifiers = {
                recoil = {
                    horizontal = 0.7
                }
            }
        },

        -- Underbarrel
        ["Vertical Grip"] = {
            name = "Vertical Grip",
            description = "Reduces vertical recoil",
            type = ATTACHMENT_TYPES.UNDERBARREL,
            compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "SCAR-H"},
            statModifiers = {
                recoil = {
                    vertical = 0.75
                },
                aimSpeed = 0.95
            }
        },
        ["Angled Grip"] = {
            name = "Angled Grip",
            description = "Faster ADS time",
            type = ATTACHMENT_TYPES.UNDERBARREL,
            compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H"},
            statModifiers = {
                aimSpeed = 1.15,
                recoil = {
                    initial = 0.85
                }
            }
        },
        ["Laser"] = {
            name = "Laser Sight",
            description = "Improves hipfire accuracy",
            type = ATTACHMENT_TYPES.UNDERBARREL,
            compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "SCAR-H"},
            statModifiers = {
                hipfireSpread = 0.7
            },
            hasLaser = true,
            laserColor = Color3.fromRGB(255, 0, 0)
        },

        -- Ammo Types
        ["Hollow Point"] = {
            name = "Hollow Point Rounds",
            description = "More damage to unarmored targets, less penetration",
            type = ATTACHMENT_TYPES.AMMO,
            compatibleWeapons = {"G36", "M4A1", "AK47", "MP5", "Pistol", "SCAR-H"},
            statModifiers = {
                damage = 1.2,
                penetration = 0.6
            }
        },
        ["Armor Piercing"] = {
            name = "Armor Piercing Rounds",
            description = "Better penetration, slightly less damage",
            type = ATTACHMENT_TYPES.AMMO,
            compatibleWeapons = {"G36", "M4A1", "AK47", "SCAR-H", "AWP"},
            statModifiers = {
                damage = 0.9,
                penetration = 1.5,
                armorDamage = 1.4
            }
        }
    }
end

-- Get an attachment by name
function AdvancedAttachmentSystem.getAttachment(attachmentName)
    local attachments = AdvancedAttachmentSystem.getAttachmentDatabase()
    return attachments[attachmentName]
end

-- Check if an attachment is compatible with a weapon
function AdvancedAttachmentSystem.isCompatible(attachmentName, weaponName)
    local attachment = AdvancedAttachmentSystem.getAttachment(attachmentName)
    if not attachment then return false end

    if attachment.compatibleWeapons then
        for _, compatibleWeapon in ipairs(attachment.compatibleWeapons) do
            if compatibleWeapon == weaponName then
                return true
            end
        end
        return false
    end

    return true
end

-- Apply attachment to weapon config with scope integration
function AdvancedAttachmentSystem.applyAttachmentToConfig(weaponConfig, attachmentName)
    local attachment = AdvancedAttachmentSystem.getAttachment(attachmentName)
    if not attachment or not attachment.statModifiers then 
        return weaponConfig 
    end

    local newConfig = table.clone(weaponConfig)

    -- Apply stat modifiers
    for stat, modifier in pairs(attachment.statModifiers) do
        if stat == "recoil" then
            for recoilType, recoilMod in pairs(modifier) do
                if newConfig.recoil and newConfig.recoil[recoilType] then
                    newConfig.recoil[recoilType] = newConfig.recoil[recoilType] * recoilMod
                end
            end
        elseif stat == "mobility" then
            for mobilityType, mobilityMod in pairs(modifier) do
                if newConfig.mobility and newConfig.mobility[mobilityType] then
                    newConfig.mobility[mobilityType] = newConfig.mobility[mobilityType] * mobilityMod
                end
            end
        elseif stat == "magazine" then
            for magType, magMod in pairs(modifier) do
                if newConfig.magazine and newConfig.magazine[magType] then
                    newConfig.magazine[magType] = newConfig.magazine[magType] * magMod
                end
            end
        else
            if type(newConfig[stat]) == "number" then
                newConfig[stat] = newConfig[stat] * modifier
            elseif type(modifier) == "table" and type(newConfig[stat]) == "table" then
                for subStat, subMod in pairs(modifier) do
                    if type(newConfig[stat][subStat]) == "number" then
                        newConfig[stat][subStat] = newConfig[stat][subStat] * subMod
                    end
                end
            end
        end
    end

    -- Integrate scope settings
    if attachment.scopeSettings then
        newConfig.scopeSettings = attachment.scopeSettings
        -- Mark weapon as having a scope attachment
        newConfig.hasScopeAttachment = true
    end

    -- Add laser settings if present
    if attachment.hasLaser then
        newConfig.laser = {
            enabled = true,
            color = attachment.laserColor or Color3.fromRGB(255, 0, 0)
        }
    end

    return newConfig
end

-- Attach an attachment to a weapon model
function AdvancedAttachmentSystem.attachToWeapon(weaponModel, attachmentName)
    if not weaponModel then return nil end

    local attachment = AdvancedAttachmentSystem.getAttachment(attachmentName)
    if not attachment then return nil end

    local attachmentType = attachment.type

    -- Get or create attachment model
    local attachmentModel = AdvancedAttachmentSystem.getAttachmentModel(attachmentName)
    if not attachmentModel then return nil end

    -- Scan weapon for compatible attachment points
    local weaponAttachmentPoints = AdvancedAttachmentSystem.scanWeaponAttachmentPoints(weaponModel)
    local compatiblePoint = weaponAttachmentPoints[attachmentType]

    local mountPosition
    if compatiblePoint and compatiblePoint:IsA("Attachment") then
        mountPosition = compatiblePoint.WorldCFrame
        print("Attached", attachmentName, "to", compatiblePoint.Name, "on", weaponModel.Name)
    else
        -- Fallback to default positions
        local defaultOffsets = {
            [ATTACHMENT_TYPES.SIGHT] = CFrame.new(0, 0.15, 0),
            [ATTACHMENT_TYPES.BARREL] = CFrame.new(0, 0, -0.5), 
            [ATTACHMENT_TYPES.UNDERBARREL] = CFrame.new(0, -0.15, -0.2),
            [ATTACHMENT_TYPES.OTHER] = CFrame.new(0, 0, 0),
            [ATTACHMENT_TYPES.AMMO] = CFrame.new(0, 0, 0)
        }

        local defaultOffset = defaultOffsets[attachmentType] or CFrame.new(0, 0, 0)
        mountPosition = weaponModel.PrimaryPart.CFrame * defaultOffset
        print("Attached", attachmentName, "to default position on", weaponModel.Name)
    end

    -- Position attachment
    attachmentModel:SetPrimaryPartCFrame(mountPosition)
    attachmentModel.Parent = weaponModel

    -- Create special effects (laser, etc.)
    if attachment.hasLaser then
        AdvancedAttachmentSystem.createLaserEffect(attachmentModel, attachment.laserColor)
    end

    return attachmentModel
end

-- Create laser effect for laser attachments
function AdvancedAttachmentSystem.createLaserEffect(attachmentModel, color)
    local laserColor = color or Color3.fromRGB(255, 0, 0)

    -- Create laser emitter
    local emitter = attachmentModel:FindFirstChild("LaserEmitter")
    if not emitter then
        emitter = Instance.new("Attachment")
        emitter.Name = "LaserEmitter"
        emitter.Parent = attachmentModel.PrimaryPart
    end

    -- Create laser beam
    local beam = Instance.new("Beam")
    beam.Name = "LaserBeam"
    beam.Color = ColorSequence.new(laserColor)
    beam.Transparency = NumberSequence.new(0.2)
    beam.Width0 = 0.02
    beam.Width1 = 0.02
    beam.FaceCamera = true
    beam.Attachment0 = emitter

    -- Create endpoint attachment
    local endpoint = Instance.new("Attachment")
    endpoint.Name = "LaserEndpoint"
    endpoint.Parent = workspace.Terrain
    beam.Attachment1 = endpoint

    beam.Parent = emitter

    -- Set up laser update
    local updateFunction
    updateFunction = RunService.RenderStepped:Connect(function()
        if not emitter.Parent then
            updateFunction:Disconnect()
            endpoint:Destroy()
            return
        end

        -- Cast ray to find endpoint
        local origin = emitter.WorldPosition
        local direction = emitter.WorldCFrame.LookVector * 1000

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Include -- Use Include instead of Exclude
        raycastParams.FilterDescendantsInstances = {workspace} -- Include everything in workspace

        local raycastResult = workspace:Raycast(origin, direction, raycastParams)

        if raycastResult then
            endpoint.WorldPosition = raycastResult.Position
        else
            endpoint.WorldPosition = origin + direction
        end
    end)

    return beam
end

-- Get attachment model (placeholder or real model)
function AdvancedAttachmentSystem.getAttachmentModel(attachmentName)
    local attachment = AdvancedAttachmentSystem.getAttachment(attachmentName)
    if not attachment then return nil end

    -- Create placeholder attachment model
    return AdvancedAttachmentSystem.createPlaceholderAttachment(attachmentName, attachment.type)
end

-- Create placeholder attachment model
function AdvancedAttachmentSystem.createPlaceholderAttachment(attachmentName, attachmentType)
    local model = Instance.new("Model")
    model.Name = attachmentName

    local part = Instance.new("Part")
    part.Name = "AttachmentPart"
    part.Anchored = true
    part.CanCollide = false

    -- Configure based on attachment type
    if attachmentType == ATTACHMENT_TYPES.SIGHT then
        part.Size = Vector3.new(0.2, 0.15, 0.3)
        part.Color = Color3.fromRGB(40, 40, 40)

        -- Add sight dot for red dot sights
        if string.find(attachmentName:lower(), "red") or string.find(attachmentName:lower(), "dot") then
            local dot = Instance.new("Part")
            dot.Name = "SightDot"
            dot.Size = Vector3.new(0.05, 0.05, 0.05)
            dot.Shape = Enum.PartType.Ball
            dot.Color = Color3.fromRGB(255, 0, 0)
            dot.Material = Enum.Material.Neon
            dot.Anchored = true
            dot.CanCollide = false
            dot.CFrame = part.CFrame * CFrame.new(0, 0.1, 0)
            dot.Parent = model
        end
    elseif attachmentType == ATTACHMENT_TYPES.BARREL then
        part.Size = Vector3.new(0.15, 0.15, 0.5)
        part.Color = Color3.fromRGB(60, 60, 60)
    elseif attachmentType == ATTACHMENT_TYPES.UNDERBARREL then
        part.Size = Vector3.new(0.15, 0.25, 0.3)
        part.Color = Color3.fromRGB(50, 50, 50)
    else
        part.Size = Vector3.new(0.2, 0.2, 0.2)
        part.Color = Color3.fromRGB(80, 80, 80)
    end

    part.Parent = model
    model.PrimaryPart = part

    return model
end

-- Get available attachments for a weapon
function AdvancedAttachmentSystem.getAvailableAttachments(weaponName)
    local attachments = AdvancedAttachmentSystem.getAttachmentDatabase()
    local available = {}

    for name, attachment in pairs(attachments) do
        if AdvancedAttachmentSystem.isCompatible(name, weaponName) then
            table.insert(available, {
                name = name,
                displayName = attachment.name,
                description = attachment.description,
                type = attachment.type
            })
        end
    end

    -- Sort by type
    table.sort(available, function(a, b)
        return a.type < b.type
    end)

    return available
end

-- Initialize the system
function AdvancedAttachmentSystem.init()
    print("Initializing AdvancedAttachmentSystem...")

    -- Create a folder to hold attachment definitions if it doesn't exist
    local fpsSystem = ReplicatedStorage:FindFirstChild("FPSSystem")
    if not fpsSystem then
        fpsSystem = Instance.new("Folder")
        fpsSystem.Name = "FPSSystem"
        fpsSystem.Parent = ReplicatedStorage
    end

    local configFolder = fpsSystem:FindFirstChild("Config")
    if not configFolder then
        configFolder = Instance.new("Folder")
        configFolder.Name = "Config"
        configFolder.Parent = fpsSystem
    end

    print("AdvancedAttachmentSystem initialized successfully!")
end

-- Initialize the system
AdvancedAttachmentSystem.init()

return AdvancedAttachmentSystem