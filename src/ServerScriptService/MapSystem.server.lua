-- MapSystem.server.lua
-- Dynamic map generation and management for KFCS FUNNY RANDOMIZER
-- Creates destructible environments, tactical positions, and vehicle integration
-- Advanced map features with environmental storytelling

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

-- Map System Class
local MapSystem = {}
MapSystem.__index = MapSystem

-- Map configurations
MapSystem.MapTemplates = {
    ["Industrial_Complex"] = {
        name = "Industrial Complex",
        size = Vector3.new(500, 100, 500),
        theme = "Urban",
        timeOfDay = 14,
        weather = "Clear",
        structures = {
            "large_warehouse", "office_building", "factory_complex",
            "storage_tanks", "loading_docks", "guard_towers"
        },
        vehicleSpawns = 8,
        destructibleObjects = 150,
        coverPoints = 200,
        description = "Dense industrial facility with multi-level combat"
    },
    
    ["Desert_Outpost"] = {
        name = "Desert Outpost",
        size = Vector3.new(600, 80, 600),
        theme = "Desert",
        timeOfDay = 16,
        weather = "Sandstorm",
        structures = {
            "military_base", "communication_tower", "barracks",
            "vehicle_depot", "supply_bunkers", "observation_posts"
        },
        vehicleSpawns = 6,
        destructibleObjects = 100,
        coverPoints = 120,
        description = "Remote military outpost in harsh desert terrain"
    },
    
    ["Urban_Battlefield"] = {
        name = "Urban Battlefield",
        size = Vector3.new(800, 120, 800),
        theme = "City",
        timeOfDay = 10,
        weather = "Overcast",
        structures = {
            "skyscrapers", "apartment_blocks", "shopping_centers",
            "subway_stations", "bridges", "parking_garages"
        },
        vehicleSpawns = 12,
        destructibleObjects = 300,
        coverPoints = 400,
        description = "Devastated city center with vertical combat"
    },
    
    ["Arctic_Base"] = {
        name = "Arctic Research Base",
        size = Vector3.new(400, 60, 400),
        theme = "Snow",
        timeOfDay = 8,
        weather = "Blizzard",
        structures = {
            "research_facility", "ice_caves", "radar_stations",
            "heated_bunkers", "supply_drops", "emergency_shelters"
        },
        vehicleSpawns = 4,
        destructibleObjects = 80,
        coverPoints = 100,
        description = "Frozen research facility with extreme weather"
    }
}

-- Structure blueprints
MapSystem.StructureBlueprints = {
    ["large_warehouse"] = {
        size = Vector3.new(60, 20, 80),
        materials = {Enum.Material.Metal, Enum.Material.Concrete},
        destructible = true,
        multiLevel = false,
        coverValue = 8,
        strategicValue = 5
    },
    
    ["office_building"] = {
        size = Vector3.new(40, 60, 40),
        materials = {Enum.Material.Concrete, Enum.Material.Glass},
        destructible = true,
        multiLevel = true,
        levels = 4,
        coverValue = 12,
        strategicValue = 9
    },
    
    ["military_base"] = {
        size = Vector3.new(80, 15, 120),
        materials = {Enum.Material.Concrete, Enum.Material.Metal},
        destructible = false,
        multiLevel = false,
        coverValue = 15,
        strategicValue = 10,
        fortified = true
    },
    
    ["communication_tower"] = {
        size = Vector3.new(8, 80, 8),
        materials = {Enum.Material.Metal},
        destructible = true,
        multiLevel = false,
        coverValue = 2,
        strategicValue = 8,
        critical = true
    }
}

-- Environmental hazards
MapSystem.EnvironmentalHazards = {
    ["explosive_barrels"] = {
        damage = 150,
        radius = 15,
        chainReaction = true,
        spawnChance = 0.3
    },
    
    ["fuel_tanks"] = {
        damage = 300,
        radius = 25,
        chainReaction = true,
        spawnChance = 0.15
    },
    
    ["electrical_boxes"] = {
        damage = 80,
        radius = 8,
        stunEffect = true,
        spawnChance = 0.4
    },
    
    ["gas_leaks"] = {
        damage = 5,
        radius = 12,
        damageOverTime = true,
        spawnChance = 0.2
    }
}

-- Initialize Map System
function MapSystem.new()
    local self = setmetatable({}, MapSystem)
    
    self.currentMap = nil
    self.mapObjects = {}
    self.hazards = {}
    self.coverPoints = {}
    self.remoteEvents = {}
    self.weatherEffects = {}
    
    self:setupRemoteEvents()
    self:setupLighting()
    
    print("[MapSystem] ✅ Map system initialized")
    return self
end

-- Setup RemoteEvents
function MapSystem:setupRemoteEvents()
local remoteFolder = ReplicatedStorage.FPSSystem:FindFirstChild("RemoteEvents") or Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
    
    local mapEvents = {
        "LoadMap",
        "UpdateMapObjective",
        "TriggerEnvironmentalHazard",
        "RequestMapInfo"
    }
    
    for _, eventName in pairs(mapEvents) do
        local remoteEvent = remoteFolder:FindFirstChild(eventName) or Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteFolder
        self.remoteEvents[eventName] = remoteEvent
    end
end

-- Setup lighting and atmosphere
function MapSystem:setupLighting()
    -- Configure lighting service
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 500
    Lighting.FogStart = 100
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    
    -- Add atmospheric effects
    if not Lighting:FindFirstChild("Atmosphere") then
        local atmosphere = Instance.new("Atmosphere")
        atmosphere.Density = 0.4
        atmosphere.Offset = 0.2
        atmosphere.Color = Color3.fromRGB(199, 199, 199)
        atmosphere.Decay = Color3.fromRGB(92, 60, 13)
        atmosphere.Glare = 0.2
        atmosphere.Haze = 1.8
        atmosphere.Parent = Lighting
    end
end

-- Generate a complete map
function MapSystem:generateMap(mapName)
    local template = self.MapTemplates[mapName]
    if not template then
        print("[MapSystem] ❌ Unknown map template:", mapName)
        return false
    end
    
    print("[MapSystem] 🏗️ Generating map:", template.name)
    
    -- Clear existing map
    self:clearMap()
    
    -- Create map container
    local mapContainer = Instance.new("Model")
    mapContainer.Name = "GeneratedMap_" .. mapName
    mapContainer.Parent = workspace
    
    -- Generate terrain
    self:generateTerrain(mapContainer, template)
    
    -- Place structures
    self:placeStructures(mapContainer, template)
    
    -- Add environmental hazards
    self:addEnvironmentalHazards(mapContainer, template)
    
    -- Create cover points
    self:generateCoverPoints(mapContainer, template)
    
    -- Setup vehicle spawns
    self:setupVehicleSpawns(mapContainer, template)
    
    -- Apply theme and atmosphere
    self:applyTheme(template)
    
    -- Add ambient elements
    self:addAmbientElements(mapContainer, template)
    
    self.currentMap = {
        name = mapName,
        template = template,
        container = mapContainer
    }
    
    print("[MapSystem] ✅ Map generation complete:", template.name)
    return true
end

-- Generate basic terrain
function MapSystem:generateTerrain(container, template)
    local terrain = workspace.Terrain
    local size = template.size
    
    -- Create base terrain
    local baseRegion = Region3.new(
        Vector3.new(-size.X/2, -10, -size.Z/2),
        Vector3.new(size.X/2, 0, size.Z/2)
    )
    
    -- Set terrain material based on theme
    local terrainMaterial = Enum.Material.Grass
    if template.theme == "Desert" then
        terrainMaterial = Enum.Material.Sand
    elseif template.theme == "Snow" then
        terrainMaterial = Enum.Material.Snow
    elseif template.theme == "Urban" then
        terrainMaterial = Enum.Material.Concrete
    end
    
    -- Generate hills and valleys
    for x = -size.X/2, size.X/2, 20 do
        for z = -size.Z/2, size.Z/2, 20 do
            local height = math.noise(x/50, z/50, 0) * 10
            local position = Vector3.new(x, height/2, z)
            local regionSize = Vector3.new(25, math.abs(height) + 5, 25)
            
            local region = Region3.new(
                position - regionSize/2,
                position + regionSize/2
            )
            
            -- Align region to grid before filling
            region = region:ExpandToGrid(4)
            
            terrain:FillRegion(region, 4, terrainMaterial)
        end
    end
    
    print("[MapSystem] 🌍 Generated terrain with theme:", template.theme)
end

-- Place structures according to template
function MapSystem:placeStructures(container, template)
    local size = template.size
    local placedStructures = 0
    
    for _, structureType in pairs(template.structures) do
        local blueprint = self.StructureBlueprints[structureType]
        if blueprint then
            local count = math.random(2, 5) -- Random count per structure type
            
            for i = 1, count do
                local position = self:findValidStructurePosition(size, blueprint)
                if position then
                    local structure = self:buildStructure(structureType, position, blueprint)
                    structure.Parent = container
                    
                    self.mapObjects[structure] = {
                        type = structureType,
                        blueprint = blueprint,
                        position = position
                    }
                    
                    placedStructures = placedStructures + 1
                end
            end
        end
    end
    
    print("[MapSystem] 🏢 Placed", placedStructures, "structures")
end

-- Find valid position for structure placement
function MapSystem:findValidStructurePosition(mapSize, blueprint)
    local attempts = 0
    local maxAttempts = 50
    
    while attempts < maxAttempts do
        local x = math.random(-mapSize.X/2 + blueprint.size.X, mapSize.X/2 - blueprint.size.X)
        local z = math.random(-mapSize.Z/2 + blueprint.size.Z, mapSize.Z/2 - blueprint.size.Z)
        local y = 5 -- Base height
        
        local position = Vector3.new(x, y, z)
        
        -- Check for overlapping structures
        local isValid = true
        for existingStructure, data in pairs(self.mapObjects) do
            local distance = (position - data.position).Magnitude
            local minDistance = (blueprint.size.Magnitude + data.blueprint.size.Magnitude) / 2 + 10
            
            if distance < minDistance then
                isValid = false
                break
            end
        end
        
        if isValid then
            return position
        end
        
        attempts = attempts + 1
    end
    
    return nil
end

-- Build individual structure
function MapSystem:buildStructure(structureType, position, blueprint)
    local structure = Instance.new("Model")
    structure.Name = structureType .. "_" .. tick()
    
    -- Main building part
    local mainPart = Instance.new("Part")
    mainPart.Name = "MainStructure"
    mainPart.Size = blueprint.size
    mainPart.Position = position
    mainPart.Material = blueprint.materials[1]
    mainPart.BrickColor = self:getThemeColor(blueprint.materials[1])
    mainPart.Anchored = true
    mainPart.CanCollide = true
    mainPart.Parent = structure
    
    -- Multi-level building
    if blueprint.multiLevel and blueprint.levels then
        for level = 1, blueprint.levels do
            local floor = Instance.new("Part")
            floor.Name = "Floor" .. level
            floor.Size = Vector3.new(blueprint.size.X - 2, 1, blueprint.size.Z - 2)
            floor.Position = position + Vector3.new(0, (level * 12) - 6, 0)
            floor.Material = Enum.Material.Concrete
            floor.BrickColor = BrickColor.new("Dark stone grey")
            floor.Anchored = true
            floor.CanCollide = true
            floor.Parent = structure
            
            -- Windows for upper floors
            if blueprint.materials[2] == Enum.Material.Glass then
                self:addWindows(floor, structure)
            end
        end
    end
    
    -- Add details based on structure type
    self:addStructureDetails(structure, structureType, position)
    
    -- Mark as destructible if specified
    if blueprint.destructible then
        self:makeDestructible(structure)
    end
    
    structure.PrimaryPart = mainPart
    return structure
end

-- Add windows to buildings
function MapSystem:addWindows(floor, structure)
    local floorSize = floor.Size
    local windowCount = math.random(3, 6)
    
    for i = 1, windowCount do
        local window = Instance.new("Part")
        window.Name = "Window" .. i
        window.Size = Vector3.new(4, 6, 0.5)
        window.Position = floor.Position + Vector3.new(
            (i - windowCount/2) * 8,
            3,
            floorSize.Z/2
        )
        window.Material = Enum.Material.Glass
        window.BrickColor = BrickColor.new("Institutional white")
        window.Transparency = 0.7
        window.Anchored = true
        window.CanCollide = true
        window.Parent = structure
    end
end

-- Add structure-specific details
function MapSystem:addStructureDetails(structure, structureType, position)
    if structureType == "communication_tower" then
        -- Add antenna
        local antenna = Instance.new("Part")
        antenna.Name = "Antenna"
        antenna.Size = Vector3.new(1, 20, 1)
        antenna.Position = position + Vector3.new(0, 50, 0)
        antenna.Material = Enum.Material.Metal
        antenna.BrickColor = BrickColor.new("Really black")
        antenna.Anchored = true
        antenna.CanCollide = false
        antenna.Parent = structure
        
        -- Blinking light
        local light = Instance.new("PointLight")
        light.Color = Color3.new(1, 0, 0)
        light.Brightness = 2
        light.Range = 100
        light.Parent = antenna
        
        -- Blinking animation
        task.spawn(function()
            while antenna.Parent do
                light.Enabled = not light.Enabled
                task.wait(1)
            end
        end)
        
    elseif structureType == "large_warehouse" then
        -- Add loading dock
        local dock = Instance.new("Part")
        dock.Name = "LoadingDock"
        dock.Size = Vector3.new(15, 8, 5)
        dock.Position = position + Vector3.new(25, 0, 0)
        dock.Material = Enum.Material.Concrete
        dock.BrickColor = BrickColor.new("Medium stone grey")
        dock.Anchored = true
        dock.CanCollide = true
        dock.Parent = structure
        
    elseif structureType == "military_base" then
        -- Add sandbag barriers
        for i = 1, 8 do
            local barrier = Instance.new("Part")
            barrier.Name = "SandbagBarrier" .. i
            barrier.Size = Vector3.new(6, 3, 2)
            barrier.Position = position + Vector3.new(
                math.cos(i * math.pi / 4) * 50,
                0,
                math.sin(i * math.pi / 4) * 50
            )
            barrier.Material = Enum.Material.Sand
            barrier.BrickColor = BrickColor.new("Earth orange")
            barrier.Anchored = true
            barrier.CanCollide = true
            barrier.Parent = structure
        end
    end
end

-- Make structure destructible
function MapSystem:makeDestructible(structure)
    for _, part in pairs(structure:GetChildren()) do
        if part:IsA("BasePart") then
            part:SetAttribute("Destructible", true)
            part:SetAttribute("Health", 300)
            part:SetAttribute("MaxHealth", 300)
        end
    end
end

-- Get theme-appropriate colors
function MapSystem:getThemeColor(material)
    if material == Enum.Material.Concrete then
        return BrickColor.new("Medium stone grey")
    elseif material == Enum.Material.Metal then
        return BrickColor.new("Dark stone grey")
    elseif material == Enum.Material.Brick then
        return BrickColor.new("Brick yellow")
    else
        return BrickColor.new("Light stone grey")
    end
end

-- Add environmental hazards
function MapSystem:addEnvironmentalHazards(container, template)
    local hazardCount = 0
    
    for hazardType, config in pairs(self.EnvironmentalHazards) do
        if math.random() < config.spawnChance then
            local count = math.random(3, 8)
            
            for i = 1, count do
                local position = self:findValidHazardPosition(template.size)
                if position then
                    local hazard = self:createHazard(hazardType, position, config)
                    hazard.Parent = container
                    
                    self.hazards[hazard] = {
                        type = hazardType,
                        config = config,
                        position = position,
                        triggered = false
                    }
                    
                    hazardCount = hazardCount + 1
                end
            end
        end
    end
    
    print("[MapSystem] ⚠️ Added", hazardCount, "environmental hazards")
end

-- Find valid hazard position
function MapSystem:findValidHazardPosition(mapSize)
    local attempts = 0
    local maxAttempts = 30
    
    while attempts < maxAttempts do
        local x = math.random(-mapSize.X/2 + 10, mapSize.X/2 - 10)
        local z = math.random(-mapSize.Z/2 + 10, mapSize.Z/2 - 10)
        local y = 2
        
        local position = Vector3.new(x, y, z)
        
        -- Check distance from structures
        local isValid = true
        for _, data in pairs(self.mapObjects) do
            local distance = (position - data.position).Magnitude
            if distance < 20 then
                isValid = false
                break
            end
        end
        
        if isValid then
            return position
        end
        
        attempts = attempts + 1
    end
    
    return nil
end

-- Create environmental hazard
function MapSystem:createHazard(hazardType, position, config)
    local hazard = Instance.new("Part")
    hazard.Name = hazardType .. "_" .. tick()
    hazard.Position = position
    hazard.Anchored = true
    hazard.CanCollide = true
    
    if hazardType == "explosive_barrels" then
        hazard.Size = Vector3.new(4, 6, 4)
        hazard.Shape = Enum.PartType.Cylinder
        hazard.Material = Enum.Material.Metal
        hazard.BrickColor = BrickColor.new("Bright red")
        
        -- Warning label
        local decal = Instance.new("Decal")
        decal.Texture = "rbxassetid://8560915195" -- Explosion warning
        decal.Face = Enum.NormalId.Front
        decal.Parent = hazard
        
    elseif hazardType == "fuel_tanks" then
        hazard.Size = Vector3.new(8, 12, 8)
        hazard.Shape = Enum.PartType.Cylinder
        hazard.Material = Enum.Material.Metal
        hazard.BrickColor = BrickColor.new("Bright orange")
        
    elseif hazardType == "electrical_boxes" then
        hazard.Size = Vector3.new(3, 4, 2)
        hazard.Material = Enum.Material.Metal
        hazard.BrickColor = BrickColor.new("Bright yellow")
        
        -- Electrical sparks effect
        local sparkEffect = Instance.new("Fire")
        sparkEffect.Size = 2
        sparkEffect.Heat = 5
        sparkEffect.Color = Color3.new(0, 0, 1)
        sparkEffect.SecondaryColor = Color3.new(1, 1, 1)
        sparkEffect.Parent = hazard
        
    elseif hazardType == "gas_leaks" then
        hazard.Size = Vector3.new(2, 1, 2)
        hazard.Material = Enum.Material.Metal
        hazard.BrickColor = BrickColor.new("Bright green")
        hazard.Transparency = 0.5
        
        -- Gas effect
        local gasEffect = Instance.new("Smoke")
        gasEffect.Size = 10
        gasEffect.Opacity = 0.3
        gasEffect.Color = Color3.new(0, 1, 0)
        gasEffect.Parent = hazard
    end
    
    -- Add trigger detection
    hazard.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") or hit.Name == "VehicleProjectile" then
            self:triggerHazard(hazard, position, config)
        end
    end)
    
    return hazard
end

-- Trigger environmental hazard
function MapSystem:triggerHazard(hazard, position, config)
    local hazardData = self.hazards[hazard]
    if not hazardData or hazardData.triggered then return end
    
    hazardData.triggered = true
    
    -- Create explosion
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = config.radius
    explosion.BlastPressure = config.damage * 1000
    explosion.Parent = workspace
    
    -- Chain reaction
    if config.chainReaction then
        task.wait(0.5)
        for otherHazard, otherData in pairs(self.hazards) do
            if not otherData.triggered and otherHazard ~= hazard then
                local distance = (otherData.position - position).Magnitude
                if distance < config.radius * 1.5 then
                    self:triggerHazard(otherHazard, otherData.position, otherData.config)
                end
            end
        end
    end
    
    -- Remove hazard after explosion
    hazard:Destroy()
    self.hazards[hazard] = nil
    
    print("[MapSystem] 💥 Triggered hazard:", hazardData.type)
end

-- Generate tactical cover points
function MapSystem:generateCoverPoints(container, template)
    local coverCount = 0
    local targetCount = template.coverPoints
    
    while coverCount < targetCount do
        local position = self:findValidCoverPosition(template.size)
        if position then
            local cover = self:createCoverPoint(position)
            cover.Parent = container
            
            self.coverPoints[cover] = {
                position = position,
                coverValue = math.random(3, 8),
                occupied = false
            }
            
            coverCount = coverCount + 1
        else
            break -- Prevent infinite loop
        end
    end
    
    print("[MapSystem] 🛡️ Generated", coverCount, "cover points")
end

-- Find valid cover position
function MapSystem:findValidCoverPosition(mapSize)
    local attempts = 0
    local maxAttempts = 100
    
    while attempts < maxAttempts do
        local x = math.random(-mapSize.X/2 + 5, mapSize.X/2 - 5)
        local z = math.random(-mapSize.Z/2 + 5, mapSize.Z/2 - 5)
        local y = 1
        
        local position = Vector3.new(x, y, z)
        
        -- Check distance from other cover points
        local isValid = true
        for _, data in pairs(self.coverPoints) do
            local distance = (position - data.position).Magnitude
            if distance < 15 then
                isValid = false
                break
            end
        end
        
        -- Check distance from structures (should be near but not overlapping)
        if isValid then
            local nearStructure = false
            for _, data in pairs(self.mapObjects) do
                local distance = (position - data.position).Magnitude
                if distance > 10 and distance < 30 then
                    nearStructure = true
                    break
                end
            end
            isValid = nearStructure
        end
        
        if isValid then
            return position
        end
        
        attempts = attempts + 1
    end
    
    return nil
end

-- Create cover point
function MapSystem:createCoverPoint(position)
    local coverType = math.random(1, 4)
    local cover
    
    if coverType == 1 then
        -- Concrete barrier
        cover = Instance.new("Part")
        cover.Name = "ConcreteBarrier"
        cover.Size = Vector3.new(6, 4, 1)
        cover.Material = Enum.Material.Concrete
        cover.BrickColor = BrickColor.new("Medium stone grey")
        
    elseif coverType == 2 then
        -- Metal crate
        cover = Instance.new("Part")
        cover.Name = "MetalCrate"
        cover.Size = Vector3.new(4, 4, 4)
        cover.Material = Enum.Material.Metal
        cover.BrickColor = BrickColor.new("Dark stone grey")
        
    elseif coverType == 3 then
        -- Sandbags
        cover = Instance.new("Part")
        cover.Name = "Sandbags"
        cover.Size = Vector3.new(8, 3, 2)
        cover.Material = Enum.Material.Sand
        cover.BrickColor = BrickColor.new("Earth orange")
        
    else
        -- Rock formation
        cover = Instance.new("Part")
        cover.Name = "RockFormation"
        cover.Size = Vector3.new(5, 6, 3)
        cover.Material = Enum.Material.Rock
        cover.BrickColor = BrickColor.new("Dark stone grey")
        cover.Shape = Enum.PartType.Block
    end
    
    cover.Position = position
    cover.Anchored = true
    cover.CanCollide = true
    
    return cover
end

-- Setup vehicle spawns for map
function MapSystem:setupVehicleSpawns(container, template)
    local spawnCount = template.vehicleSpawns
    local spawnsPerTeam = math.floor(spawnCount / 2)
    
    -- FBI spawns (positive X side)
    for i = 1, spawnsPerTeam do
        local position = Vector3.new(
            template.size.X/2 - 50,
            5,
            (-template.size.Z/2) + (i * 80)
        )
        self:createVehicleSpawnPoint(position, "FBI", container)
    end
    
    -- KFC spawns (negative X side)
    for i = 1, spawnsPerTeam do
        local position = Vector3.new(
            -template.size.X/2 + 50,
            5,
            (-template.size.Z/2) + (i * 80)
        )
        self:createVehicleSpawnPoint(position, "KFC", container)
    end
    
    print("[MapSystem] 🚗 Created", spawnCount, "vehicle spawn points")
end

-- Create vehicle spawn point
function MapSystem:createVehicleSpawnPoint(position, team, container)
    local spawnPad = Instance.new("Part")
    spawnPad.Name = "VehicleSpawn_" .. team .. "_" .. tick()
    spawnPad.Size = Vector3.new(20, 1, 30)
    spawnPad.Position = position
    spawnPad.Anchored = true
    spawnPad.CanCollide = false
    spawnPad.Material = Enum.Material.Neon
    spawnPad.BrickColor = team == "FBI" and BrickColor.new("Bright blue") or BrickColor.new("Bright red")
    spawnPad.Transparency = 0.7
    spawnPad.Parent = container
    
    -- Spawn terminal
    local terminal = Instance.new("Part")
    terminal.Name = "SpawnTerminal"
    terminal.Size = Vector3.new(4, 8, 2)
    terminal.Position = position + Vector3.new(12, 4, 0)
    terminal.Anchored = true
    terminal.Material = Enum.Material.Metal
    terminal.BrickColor = BrickColor.new("Dark stone grey")
    terminal.Parent = container
    
    -- Terminal interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = terminal
end

-- Apply map theme
function MapSystem:applyTheme(template)
    -- Set time of day
    Lighting.ClockTime = template.timeOfDay
    
    -- Apply weather effects
    if template.weather == "Sandstorm" then
        Lighting.FogEnd = 100
        Lighting.FogColor = Color3.fromRGB(194, 154, 108)
        
    elseif template.weather == "Blizzard" then
        Lighting.FogEnd = 50
        Lighting.FogColor = Color3.fromRGB(240, 240, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 120)
        
    elseif template.weather == "Overcast" then
        Lighting.FogEnd = 300
        Lighting.FogColor = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80)
        
    else -- Clear weather
        Lighting.FogEnd = 500
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
    end
    
    print("[MapSystem] 🌤️ Applied theme:", template.theme, "with", template.weather, "weather")
end

-- Add ambient elements
function MapSystem:addAmbientElements(container, template)
    -- Add ambient sounds
    local ambientSound = Instance.new("Sound")
    ambientSound.Name = "AmbientSound"
    ambientSound.SoundId = "rbxassetid://6189453706" -- Wind/ambient
    ambientSound.Volume = 0.3
    ambientSound.Looped = true
    ambientSound.Parent = container
    ambientSound:Play()
    
    -- Add random debris
    for i = 1, 50 do
        local debris = Instance.new("Part")
        debris.Name = "Debris" .. i
        debris.Size = Vector3.new(
            math.random(1, 3),
            math.random(1, 2),
            math.random(1, 3)
        )
        debris.Position = Vector3.new(
            math.random(-template.size.X/2, template.size.X/2),
            math.random(0, 5),
            math.random(-template.size.Z/2, template.size.Z/2)
        )
        debris.Material = Enum.Material.Concrete
        debris.BrickColor = BrickColor.new("Dark stone grey")
        debris.Anchored = true
        debris.CanCollide = false
        debris.Parent = container
    end
    
    print("[MapSystem] 🎵 Added ambient elements")
end

-- Clear existing map
function MapSystem:clearMap()
    if self.currentMap and self.currentMap.container then
        self.currentMap.container:Destroy()
    end
    
    self.mapObjects = {}
    self.hazards = {}
    self.coverPoints = {}
    
    print("[MapSystem] 🗑️ Cleared existing map")
end

-- Get map information
function MapSystem:getMapInfo()
    if not self.currentMap then return nil end
    
    return {
        name = self.currentMap.name,
        template = self.currentMap.template,
        objectCount = #self.mapObjects,
        hazardCount = #self.hazards,
        coverCount = #self.coverPoints
    }
end

-- Initialize the system with default map
local mapSystem = MapSystem.new()

-- Generate default map
mapSystem:generateMap("Industrial_Complex")

print("[MapSystem] 🗺️ ADVANCED MAP SYSTEM FEATURES:")
print("  • Dynamic map generation with multiple themes")
print("  • Destructible buildings and structures")
print("  • Environmental hazards with chain reactions")
print("  • Tactical cover point generation")
print("  • Weather and atmospheric effects")
print("  • Vehicle spawn integration")
print("  • Multi-level building support")
print("  • Performance-optimized object placement")

return mapSystem