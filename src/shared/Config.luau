--!strict
-- Tuning knobs shared by the server and the client.
-- "Size" is the player's scale: 1 = a normal Roblox character, 12 = sixty studs tall.

local Config = {}

-- What size you must be to smash each tier of stuff.
Config.TIER_NEED = { 1, 2, 3.5, 5.5, 8.5 }
-- How big (longest side, in studs) the stuff in each tier is.
Config.TIER_EXTENT = { 3.5, 7, 13, 24, 42 }

-- The walls between areas, and the water tower itself.
Config.GATE_NEED = { 2.5, 5 }
Config.TOWER_NEED = 12
-- Towers are built about 95 studs tall, then scaled up so they loom over everything.
Config.TOWER_SCALE = 1.4
Config.TOWER_HEIGHT = 95 * Config.TOWER_SCALE

Config.START_SIZE = 1

-- How much you grow per smash. Bigger stuff gives more; tiny stuff gives less once you're huge.
Config.GROWTH = 0.13
function Config.gainFor(need: number, size: number): number
	local falloff = math.clamp(2 * need / size, 0.25, 1)
	return Config.GROWTH * need * falloff
end

function Config.walkSpeedFor(size: number): number
	return 18 * size ^ 0.7
end

function Config.jumpPowerFor(size: number): number
	return 50 * size ^ 0.5
end

function Config.cameraZoomFor(size: number): number
	return 14 * size ^ 0.9
end

-- How far the smash reach goes around the body, as a multiple of size.
Config.REACH = 2.1

-- Seconds a smashed piece flies around before it fades away.
Config.DEBRIS_LIFETIME = 4

-- Free sounds from the Roblox Creator Store (Pro Sound Effects / APM / Distrokid are Roblox-licensed).
Config.Sounds = {
	Pop = "rbxassetid://132948338000932",
	Boing = "rbxassetid://2772396665",
	Crash = "rbxassetid://9120873989",
	TankImpact = "rbxassetid://9116889946",
	Splash = "rbxassetid://9120585252",
	SplashSmall = "rbxasset://sounds/impact_water.mp3",
	Cheer = "rbxassetid://9068897474",
	Magic = "rbxassetid://9125635650",
	Arrive = "rbxassetid://9038313977",
}

Config.Music = {
	Town = "rbxassetid://77622044026107", -- Superhero Kids
	Farm = "rbxassetid://133181348949956", -- Animal Parade
	Snow = "rbxassetid://80903415686925", -- Ice Cream Dream
	Beach = "rbxassetid://140375862183759", -- Rainbow Color Dance
	Candy = "rbxassetid://112315464655241", -- Dinosaur Stomp
}

return Config
