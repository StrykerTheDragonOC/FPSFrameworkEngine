-- Camera Shake Presets
-- Predefined camera shake effects for different scenarios

local CameraShakePresets = {
    -- Weapon-related shakes
    ["WeaponFire"] = {
        magnitude = 0.5,
        roughness = 8,
        duration = 0.1,
        positionInfluence = Vector3.new(0.2, 0.2, 0.1),
        rotationInfluence = Vector3.new(0.3, 0.3, 0.1),
        fadeOutTime = 0.05
    },

    ["WeaponReload"] = {
        magnitude = 0.3,
        roughness = 4,
        duration = 0.2,
        positionInfluence = Vector3.new(0.1, 0.1, 0.1),
        rotationInfluence = Vector3.new(0.2, 0.1, 0.1),
        fadeOutTime = 0.1
    },

    ["SniperShot"] = {
        magnitude = 1.2,
        roughness = 6,
        duration = 0.3,
        positionInfluence = Vector3.new(0.3, 0.3, 0.2),
        rotationInfluence = Vector3.new(0.5, 0.3, 0.2),
        fadeOutTime = 0.15
    },

    -- Impact and damage shakes
    ["Impact"] = {
        magnitude = 1.0,
        roughness = 10,
        duration = 0.4,
        positionInfluence = Vector3.new(0.8, 0.8, 0.3),
        rotationInfluence = Vector3.new(0.5, 0.5, 0.3),
        fadeOutTime = 0.2
    },

    ["TakeDamage"] = {
        magnitude = 0.8,
        roughness = 12,
        duration = 0.3,
        positionInfluence = Vector3.new(0.4, 0.4, 0.2),
        rotationInfluence = Vector3.new(0.3, 0.3, 0.2),
        fadeOutTime = 0.15
    },

    ["Death"] = {
        magnitude = 2.0,
        roughness = 8,
        duration = 1.0,
        positionInfluence = Vector3.new(1.0, 1.0, 0.5),
        rotationInfluence = Vector3.new(0.8, 0.8, 0.5),
        fadeOutTime = 0.5
    },

    -- Explosion shakes
    ["Explosion"] = {
        magnitude = 1.5,
        roughness = 10,
        duration = 0.4,
        positionInfluence = Vector3.new(0.4, 0.4, 0.3),
        rotationInfluence = Vector3.new(0.6, 0.4, 0.3),
        fadeOutTime = 0.2
    },

    ["SmallExplosion"] = {
        magnitude = 1.5,
        roughness = 15,
        duration = 0.6,
        positionInfluence = Vector3.new(0.7, 0.7, 0.4),
        rotationInfluence = Vector3.new(0.4, 0.4, 0.3),
        fadeOutTime = 0.3
    },

    ["LargeExplosion"] = {
        magnitude = 3.0,
        roughness = 12,
        duration = 1.2,
        positionInfluence = Vector3.new(1.2, 1.2, 0.8),
        rotationInfluence = Vector3.new(0.8, 0.8, 0.6),
        fadeOutTime = 0.6
    },

    ["Earthquake"] = {
        magnitude = 2.5,
        roughness = 6,
        duration = 3.0,
        positionInfluence = Vector3.new(1.0, 1.5, 0.5),
        rotationInfluence = Vector3.new(0.3, 0.3, 0.2),
        fadeOutTime = 1.0
    },

    -- Vehicle shakes
    ["VehicleEngine"] = {
        magnitude = 0.3,
        roughness = 20,
        duration = 999, -- Continuous until stopped
        positionInfluence = Vector3.new(0.1, 0.2, 0.1),
        rotationInfluence = Vector3.new(0.1, 0.1, 0.05),
        fadeOutTime = 0.1
    },

    ["VehicleCrash"] = {
        magnitude = 2.5,
        roughness = 15,
        duration = 0.8,
        positionInfluence = Vector3.new(1.0, 0.8, 1.2),
        rotationInfluence = Vector3.new(0.6, 0.6, 0.8),
        fadeOutTime = 0.4
    },

    -- ViciousStinger specific shakes
    ["ViciousStrike"] = {
        magnitude = 0.8,
        roughness = 12,
        duration = 0.25,
        positionInfluence = Vector3.new(0.3, 0.3, 0.2),
        rotationInfluence = Vector3.new(0.4, 0.2, 0.3),
        fadeOutTime = 0.1
    },

    ["ViciousOverdrive"] = {
        magnitude = 1.5,
        roughness = 8,
        duration = 0.5,
        positionInfluence = Vector3.new(0.5, 0.5, 0.3),
        rotationInfluence = Vector3.new(0.6, 0.4, 0.4),
        fadeOutTime = 0.2
    },

    ["ViciousEarthquake"] = {
        magnitude = 2.0,
        roughness = 6,
        duration = 2.0,
        positionInfluence = Vector3.new(0.8, 1.2, 0.4),
        rotationInfluence = Vector3.new(0.3, 0.3, 0.2),
        fadeOutTime = 0.8
    },

    -- Movement shakes
    ["Landing"] = {
        magnitude = 0.6,
        roughness = 20,
        duration = 0.2,
        positionInfluence = Vector3.new(0.2, 0.4, 0.1),
        rotationInfluence = Vector3.new(0.1, 0.1, 0.1),
        fadeOutTime = 0.1
    },

    ["Sliding"] = {
        magnitude = 0.4,
        roughness = 15,
        duration = 999, -- Continuous
        positionInfluence = Vector3.new(0.1, 0.1, 0.2),
        rotationInfluence = Vector3.new(0.05, 0.05, 0.1),
        fadeOutTime = 0.1
    },

    -- Environmental shakes
    ["Thunder"] = {
        magnitude = 1.2,
        roughness = 4,
        duration = 0.8,
        positionInfluence = Vector3.new(0.3, 0.3, 0.2),
        rotationInfluence = Vector3.new(0.2, 0.2, 0.1),
        fadeOutTime = 0.4
    },

    ["Flashbang"] = {
        magnitude = 2.5,
        roughness = 20,
        duration = 1.5,
        positionInfluence = Vector3.new(0.8, 0.8, 0.4),
        rotationInfluence = Vector3.new(1.0, 1.0, 0.6),
        fadeOutTime = 0.8
    }
}

return CameraShakePresets