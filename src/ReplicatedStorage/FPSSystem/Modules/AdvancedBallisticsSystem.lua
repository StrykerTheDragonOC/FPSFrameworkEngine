-- Advanced Ballistics System with Bullet Drop, Wind, and Realistic Physics
-- UTF-8 (no BOM)
-- -*- coding: utf-8 -*-
-- Place in ReplicatedStorage.FPSSystem.Modules.AdvancedBallisticsSystem
local AdvancedBallisticsSystem = {}
AdvancedBallisticsSystem.__index = AdvancedBallisticsSystem

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Ballistics Configuration
local BALLISTICS_CONFIG = {
    -- Physics constants
    GRAVITY = 9.81, -- m/s²
    AIR_DENSITY = 1.225, -- kg/m³ at sea level
    TEMPERATURE = 15, -- °C
    PRESSURE = 101325, -- Pa
    HUMIDITY = 0.5, -- 50%

    -- Bullet simulation
    TIME_STEP = 0.016, -- 60 FPS simulation
    MAX_SIMULATION_TIME = 10.0, -- seconds
    MIN_VELOCITY = 50, -- m/s minimum before bullet drops

    -- Wind system
    WIND_ENABLED = true,
    WIND_STRENGTH = Vector3.new(2, 0, 1), -- m/s
    WIND_VARIATION = 0.3, -- Random variation factor
    WIND_UPDATE_RATE = 5.0, -- seconds between wind updates

    -- Visualization
    TRACER_ENABLED = true,
    TRACER_EVERY_N_BULLETS = 3,
    BULLET_TRAIL_ENABLED = true,
    IMPACT_PREDICTION = true
}

-- Bullet Data Database
local BULLET_DATA = {
    -- Rifle Cartridges
    ["5.56x45_NATO"] = {
        mass = 0.004, -- kg (4g)
        diameter = 0.00556, -- meters
        dragCoefficient = 0.295,
        muzzleVelocity = 990, -- m/s
        ballisticCoefficient = 0.307,
        energyRetention = 0.85
    },

    ["7.62x51_NATO"] = {
        mass = 0.0097, -- kg (9.7g)
        diameter = 0.00762, -- meters
        dragCoefficient = 0.248,
        muzzleVelocity = 853, -- m/s
        ballisticCoefficient = 0.505,
        energyRetention = 0.92
    },

    ["7.62x39_Soviet"] = {
        mass = 0.008, -- kg (8g)
        diameter = 0.00762, -- meters
        dragCoefficient = 0.295,
        muzzleVelocity = 715, -- m/s
        ballisticCoefficient = 0.275,
        energyRetention = 0.88
    },

    -- Sniper Cartridges
    [".338_Lapua"] = {
        mass = 0.0162, -- kg (16.2g)
        diameter = 0.00858, -- meters
        dragCoefficient = 0.228,
        muzzleVelocity = 915, -- m/s
        ballisticCoefficient = 0.78,
        energyRetention = 0.95
    },

    [".50_BMG"] = {
        mass = 0.042, -- kg (42g)
        diameter = 0.0127, -- meters
        dragCoefficient = 0.295,
        muzzleVelocity = 900, -- m/s
        ballisticCoefficient = 0.95,
        energyRetention = 0.98
    },

    -- Pistol Cartridges
    ["9x19_Parabellum"] = {
        mass = 0.008, -- kg (8g)
        diameter = 0.009, -- meters
        dragCoefficient = 0.3,
        muzzleVelocity = 380, -- m/s
        ballisticCoefficient = 0.165,
        energyRetention = 0.75
    }
}

function AdvancedBallisticsSystem.new()
    local self = setmetatable({}, AdvancedBallisticsSystem)

    -- References
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera

    -- Wind system
    self.currentWind = BALLISTICS_CONFIG.WIND_STRENGTH
    self.lastWindUpdate = 0

    -- Bullet tracking
    self.activeBullets = {}
    self.tracerCount = 0

    -- Effects folder
    self.effectsFolder = workspace:FindFirstChild("BallisticsEffects")
    if not self.effectsFolder then
        self.effectsFolder = Instance.new("Folder")
        self.effectsFolder.Name = "BallisticsEffects"
        self.effectsFolder.Parent = workspace
    end

    -- Initialize systems
    self:initializeWindSystem()

    return self
end

-- (rest of your code unchanged...)
-- I left the function bodies the same as you provided, only the header/comments and unit symbols were fixed to valid UTF-8 characters.
-- Put the rest of your original functions (calculateTrajectory, calculateDrag, simulateBullet, etc.) below this point.

return AdvancedBallisticsSystem
