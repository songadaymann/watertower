--!nonstrict
-- Each biome says what the ground looks like, which things show up at each tier,
-- what kind of wall blocks the next area, and which water tower styles can appear.

local rgb = Color3.fromRGB
local M = Enum.Material

local Biomes = {}

Biomes.Town = {
	ground = rgb(110, 190, 90),
	groundMat = M.Grass,
	path = rgb(75, 75, 82),
	pathMat = M.Asphalt,
	stripe = rgb(255, 215, 60),
	cliff = { rgb(135, 125, 115), rgb(120, 110, 100), rgb(150, 140, 125) },
	cliffMat = M.Rock,
	gate = "Town",
	tiers = {
		{ "cone", "hydrant", "mailbox", "trashcan", "flowerpot" },
		{ "bench", "bush", "lamppost", "picnic" },
		{ "car", "tree", "pine" },
		{ "house", "bus", "shop" },
		{ "apartment" },
	},
	towers = { "Classic", "Classic", "Stripes", "Pillar", "Sphere" },
	names = { "Splashville", "Dripton", "Puddletown", "Bubbleburg", "Sprinkleton", "Gurgle City", "Drizzleton" },
	lighting = { clock = 14, atmosphere = rgb(200, 220, 255), decay = rgb(110, 120, 140) },
}

Biomes.Farm = {
	ground = rgb(150, 200, 80),
	groundMat = M.LeafyGrass,
	path = rgb(160, 115, 75),
	pathMat = M.Ground,
	cliff = { rgb(150, 120, 90), rgb(135, 105, 80), rgb(165, 135, 100) },
	cliffMat = M.Sandstone,
	gate = "Farm",
	tiers = {
		{ "pumpkin", "hayroll", "crate", "sunflower" },
		{ "scarecrow", "fence", "haystack", "bush" },
		{ "tractor", "tree", "tree" },
		{ "barn", "house" },
		{ "silo", "windmill" },
	},
	towers = { "Classic", "Peach", "Sphere", "Stripes" },
	names = { "Mooville", "Hayfield", "Cornbury", "Pumpkin Hill", "Oinkton", "Haybale" },
	lighting = { clock = 16.3, atmosphere = rgb(255, 230, 190), decay = rgb(150, 120, 100) },
}

Biomes.Snow = {
	ground = rgb(240, 245, 252),
	groundMat = M.Snow,
	path = rgb(185, 220, 245),
	pathMat = M.Ice,
	cliff = { rgb(230, 238, 248), rgb(210, 222, 238), rgb(245, 248, 255) },
	cliffMat = M.Glacier,
	gate = "Snow",
	tiers = {
		{ "snowman", "present", "candycane", "sled" },
		{ "snowman", "snowpine", "present", "bench" },
		{ "snowpine", "car", "igloo" },
		{ "cabin", "igloo", "bus" },
		{ "icecastle" },
	},
	towers = { "Pillar", "Sphere", "Classic" },
	names = { "Snowdrop", "Frosty", "Icicle", "Brrrton", "Snowflake", "Chilly" },
	lighting = { clock = 12.5, atmosphere = rgb(220, 235, 255), decay = rgb(160, 180, 210) },
	snowing = true,
}

Biomes.Beach = {
	ground = rgb(240, 220, 160),
	groundMat = M.Sand,
	path = rgb(170, 125, 80),
	pathMat = M.WoodPlanks,
	cliff = { rgb(215, 185, 130), rgb(200, 170, 120), rgb(225, 200, 145) },
	cliffMat = M.Sandstone,
	gate = "Beach",
	tiers = {
		{ "beachball", "bucket", "sandcastle" },
		{ "umbrella", "sandcastle", "bench" },
		{ "palm", "boat", "lifeguard" },
		{ "beachhut", "bus" },
		{ "lighthouse" },
	},
	towers = { "Stripes", "Sphere", "Pillar" },
	names = { "Seashell", "Sandy", "Wavetown", "Splashy", "Coconut", "Seagull" },
	lighting = { clock = 13, atmosphere = rgb(190, 230, 255), decay = rgb(110, 150, 190) },
}

Biomes.Candy = {
	ground = rgb(255, 190, 220),
	groundMat = M.SmoothPlastic,
	path = rgb(255, 250, 250),
	pathMat = M.SmoothPlastic,
	stripe = rgb(255, 90, 140),
	cliff = { rgb(190, 150, 255), rgb(150, 220, 255), rgb(255, 220, 140) },
	cliffMat = M.SmoothPlastic,
	gate = "Candy",
	tiers = {
		{ "lollipop", "gumdrop", "cupcake", "donut" },
		{ "candycane", "icecream", "donut", "lollipop" },
		{ "cake", "lollipop", "icecream" },
		{ "gingerbread", "cake" },
		{ "bigcake" },
	},
	towers = { "Stripes", "Peach", "Sphere" },
	names = { "Sugartown", "Gumdrop", "Lollipop", "Sprinkles", "Cupcake", "Jellybean" },
	lighting = { clock = 15, atmosphere = rgb(255, 205, 235), decay = rgb(190, 130, 170) },
}

Biomes.ORDER = { "Town", "Farm", "Snow", "Beach", "Candy" }

return Biomes
