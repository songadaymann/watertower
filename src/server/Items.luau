--!nonstrict
-- Every smashable thing, built from primitive parts.
-- Each builder draws at its natural proportions around the origin; Land scales it to fit its tier.

local Kit = require(script.Parent.Kit)

local V = Vector3.new
local rgb = Color3.fromRGB

local C = {
	white = rgb(245, 245, 240),
	black = rgb(30, 30, 35),
	dark = rgb(60, 62, 70),
	gray = rgb(150, 155, 160),
	silver = rgb(200, 205, 210),
	red = rgb(230, 57, 70),
	orange = rgb(255, 130, 40),
	yellow = rgb(255, 205, 50),
	green = rgb(110, 190, 70),
	darkGreen = rgb(50, 130, 60),
	blue = rgb(40, 120, 220),
	sky = rgb(120, 200, 245),
	purple = rgb(150, 90, 200),
	pink = rgb(255, 130, 190),
	brown = rgb(125, 85, 55),
	wood = rgb(170, 120, 75),
	hay = rgb(235, 200, 90),
	sand = rgb(235, 210, 150),
	glass = rgb(150, 210, 240),
	terracotta = rgb(200, 100, 60),
	brick = rgb(170, 70, 55),
	snow = rgb(250, 252, 255),
	ice = rgb(170, 225, 255),
}

local BRIGHTS = { C.red, C.orange, C.yellow, C.green, C.blue, C.purple, C.pink, rgb(30, 190, 180) }
local PASTELS = {
	rgb(255, 180, 200),
	rgb(255, 225, 150),
	rgb(180, 230, 190),
	rgb(170, 210, 255),
	rgb(215, 185, 255),
	rgb(255, 200, 160),
}
local LEAVES = { rgb(90, 180, 70), rgb(60, 150, 60), rgb(120, 200, 80), rgb(70, 165, 95) }
local HOUSE_WALLS = {
	rgb(255, 235, 180),
	rgb(180, 220, 255),
	rgb(255, 200, 200),
	rgb(200, 240, 200),
	rgb(245, 245, 240),
	rgb(255, 215, 150),
}
local ROOFS = { rgb(170, 60, 50), rgb(70, 80, 110), rgb(90, 140, 90), rgb(120, 80, 60) }

local function pick(r: Random, list)
	return list[r:NextInteger(1, #list)]
end

local function shade(c: Color3, f: number)
	return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

local NEON = { material = Enum.Material.Neon }

local B = {}

---------------------------------------------------------------- Town

function B.cone(k, r)
	k:block(V(2.4, 0.3, 2.4), V(0, 0.15, 0), C.orange)
	k:cone(1.7, 0.35, 3.2, V(0, 0.3, 0), C.orange, 7)
	k:cyl(1.2, 0.45, V(0, 1.5, 0), C.white)
end

function B.hydrant(k, r)
	local c = pick(r, { C.red, C.yellow, C.red })
	k:cyl(1.7, 0.3, V(0, 0.15, 0), c)
	k:cyl(1.15, 2.1, V(0, 1.35, 0), c)
	k:ball(1.2, V(0, 2.4, 0), c)
	k:cyl(0.5, 0.45, V(0, 3.0, 0), C.silver)
	k:hcyl(0.55, 1.9, V(0, 1.8, 0), c)
	k:zcyl(0.75, 0.5, V(0, 1.6, -0.7), C.silver)
end

function B.mailbox(k, r)
	local c = pick(r, { C.blue, C.dark, C.red, C.green })
	k:block(V(0.4, 2.6, 0.4), V(0, 1.3, 0), C.wood)
	k:block(V(1.1, 0.7, 2), V(0, 2.95, 0), c)
	k:zcyl(1.1, 2, V(0, 3.3, 0), c)
	k:block(V(0.1, 1.0, 0.2), V(0.6, 3.4, 0.6), C.red)
	k:block(V(0.1, 0.4, 0.55), V(0.6, 3.75, 0.8), C.red)
end

function B.trashcan(k, r)
	local c = pick(r, { C.green, C.gray, C.blue })
	k:cyl(1.6, 2.4, V(0, 1.2, 0), c)
	k:cyl(1.8, 0.25, V(0, 2.5, 0), shade(c, 0.8))
	k:block(V(0.7, 0.25, 0.25), V(0, 2.75, 0), shade(c, 0.6))
	for i = 1, 3 do
		k:cyl(1.65, 0.12, V(0, i * 0.6, 0), shade(c, 0.85))
	end
end

function B.flowerpot(k, r)
	k:cone(1.2, 1.8, 1.4, V(0, 0, 0), C.terracotta, 3)
	k:ball(1.6, V(0, 1.75, 0), pick(r, LEAVES))
	local fc = pick(r, BRIGHTS)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		k:ball(0.55, V(math.cos(a) * 0.55, 2.35, math.sin(a) * 0.55), fc)
	end
	k:ball(0.45, V(0, 2.5, 0), C.yellow)
end

function B.bench(k, r)
	local wood = pick(r, { C.wood, C.red, C.green, C.blue })
	k:block(V(5, 0.25, 1.6), V(0, 1.4, 0), wood)
	k:block(V(5, 0.9, 0.25), V(0, 2.25, 0.8), wood)
	k:block(V(5, 0.4, 0.25), V(0, 2.95, 0.8), wood)
	for _, x in { -2.1, 2.1 } do
		k:block(V(0.3, 1.3, 1.5), V(x, 0.65, 0), C.dark)
		k:block(V(0.3, 1.8, 0.3), V(x, 2.2, 0.8), C.dark)
	end
end

function B.bush(k, r)
	local g = pick(r, LEAVES)
	local g2 = shade(g, 1.12)
	k:ball(3, V(0, 1.4, 0), g)
	k:ball(2.4, V(1.3, 1.1, 0.4), g2)
	k:ball(2.2, V(-1.2, 1.0, -0.3), g)
	k:ball(2, V(0.2, 1.0, 1.1), g2)
	if r:NextNumber() < 0.6 then
		local berry = pick(r, { C.red, C.pink, C.purple, C.yellow, C.white })
		for _ = 1, 6 do
			local a = r:NextNumber() * math.pi * 2
			k:ball(0.45, V(math.cos(a) * 1.5, 1 + r:NextNumber() * 1.6, math.sin(a) * 1.5), berry)
		end
	end
end

function B.lamppost(k, r)
	k:cyl(1.1, 0.5, V(0, 0.25, 0), C.dark)
	k:cyl(0.35, 7, V(0, 3.9, 0), C.dark)
	k:cyl(1.0, 0.3, V(0, 7.45, 0), C.dark)
	k:ball(1.3, V(0, 8.1, 0), rgb(255, 240, 170), NEON)
	k:cone(1.4, 0.4, 0.8, V(0, 8.6, 0), C.dark, 3)
end

function B.picnic(k, r)
	local c = pick(r, { C.wood, C.red, C.blue })
	k:block(V(6, 0.3, 2.6), V(0, 2.4, 0), c)
	for _, z in { -2, 2 } do
		k:block(V(6, 0.25, 0.9), V(0, 1.3, z), c)
	end
	for _, x in { -2.3, 2.3 } do
		k:beam(0.3, 0.3, V(x, 0, -2.2), V(x, 2.3, 0), c)
		k:beam(0.3, 0.3, V(x, 0, 2.2), V(x, 2.3, 0), c)
	end
end

function B.car(k, r)
	local c = pick(r, BRIGHTS)
	k:block(V(5.2, 1.8, 11), V(0, 1.75, 0), c)
	k:block(V(4.6, 1.7, 5.6), V(0, 3.5, 0.4), c)
	k:block(V(4.1, 1.2, 0.1), V(0, 3.5, -2.42), C.glass)
	k:block(V(4.1, 1.2, 0.1), V(0, 3.5, 3.22), C.glass)
	for _, x in { -2.32, 2.32 } do
		k:block(V(0.1, 1.15, 2.3), V(x, 3.5, -0.9), C.glass)
		k:block(V(0.1, 1.15, 2.3), V(x, 3.5, 1.7), C.glass)
	end
	for _, x in { -2.45, 2.45 } do
		for _, z in { -3.4, 3.4 } do
			k:hcyl(2.3, 0.9, V(x, 1.15, z), C.black)
			k:hcyl(1.1, 0.95, V(x, 1.15, z), C.silver)
		end
	end
	for _, x in { -1.7, 1.7 } do
		k:ball(0.75, V(x, 2.0, -5.45), rgb(255, 250, 200), NEON)
		k:block(V(0.9, 0.5, 0.1), V(x, 2.1, 5.52), C.red, NEON)
	end
	k:block(V(5.3, 0.4, 0.4), V(0, 0.95, -5.6), C.silver)
	k:block(V(5.3, 0.4, 0.4), V(0, 0.95, 5.6), C.silver)
end

function B.tree(k, r)
	local h = r:NextNumber(5, 7)
	k:cyl(1.4, h, V(0, h / 2, 0), C.brown)
	local g = pick(r, LEAVES)
	local g2 = shade(g, 1.15)
	k:ball(6, V(0, h + 1.5, 0), g)
	k:ball(4.5, V(1.9, h + 0.4, 0.8), g2)
	k:ball(4.5, V(-1.7, h + 0.7, -0.9), g2)
	k:ball(4.2, V(0.3, h + 3.6, 0.3), g)
	if r:NextNumber() < 0.35 then
		local fruit = pick(r, { C.red, C.orange, C.yellow })
		for _ = 1, 7 do
			local a = r:NextNumber() * math.pi * 2
			k:ball(0.8, V(math.cos(a) * 2.9, h + r:NextNumber(0, 3), math.sin(a) * 2.9), fruit)
		end
	end
end

local function pine(k, r, snowy)
	local g = pick(r, { rgb(40, 120, 70), rgb(30, 100, 60), rgb(50, 135, 80) })
	k:cyl(1.2, 2.5, V(0, 1.25, 0), C.brown)
	local layers = { { 6.5, 2.0, 1.5 }, { 5.2, 4.2, 4.0 }, { 3.8, 6.2, 6.4 }, { 2.4, 7.8, 8.6 } }
	for i, l in layers do
		local colors = { g, g, g }
		if snowy then
			colors = { g, g, C.snow }
		end
		k:cone(l[1], l[1] * 0.25, l[3] - l[2] + 2.4, V(0, l[2], 0), colors, 3)
		if i == #layers then
			k:ball(0.9, V(0, l[3] + 2.6, 0), snowy and C.snow or C.yellow, snowy and nil or NEON)
		end
	end
end

function B.pine(k, r)
	pine(k, r, false)
end

function B.snowpine(k, r)
	pine(k, r, true)
end

function B.bus(k, r)
	local y = rgb(255, 196, 0)
	k:block(V(6, 5, 20), V(0, 3.4, 1), y)
	k:block(V(6, 3, 4), V(0, 2.4, -10.5), y)
	k:block(V(6.1, 0.3, 20), V(0, 3.4, 1), C.black)
	k:block(V(6.1, 0.3, 24), V(0, 2.2, -1), C.black)
	for i = 0, 6 do
		k:block(V(6.1, 1.6, 1.9), V(0, 4.8, -6.6 + i * 2.6), C.glass)
	end
	k:block(V(5.4, 2.0, 0.1), V(0, 4.7, -9.05), C.glass)
	for _, x in { -3.0, 3.0 } do
		for _, z in { -8.6, 7 } do
			k:hcyl(2.6, 1, V(x, 1.3, z), C.black)
			k:hcyl(1.2, 1.05, V(x, 1.3, z), C.silver)
		end
		k:ball(0.8, V(x * 0.7, 2.8, -12.5), rgb(255, 250, 200), NEON)
	end
	local stop = k:hcyl(1.6, 0.15, V(-3.2, 4, -5), C.red)
	stop.Name = "StopSign"
end

local function house(k, r, opts)
	local W, D, H = 14, 12, 8
	local wall = opts.wall or pick(r, HOUSE_WALLS)
	local roofC = opts.roof or pick(r, ROOFS)
	local trim = opts.trim or C.white
	k:block(V(W, H, D), V(0, H / 2, 0), wall, opts.wallMat and { material = opts.wallMat } or nil)
	k:roof(W + 1.6, D + 1.6, 5, V(0, H, 0), roofC, opts.roofMat and { material = opts.roofMat } or nil)
	k:block(V(2.4, 4.2, 0.3), V(0, 2.1, -D / 2 - 0.1), opts.door or pick(r, { C.red, C.blue, C.green, C.wood }))
	k:ball(0.35, V(0.8, 2.1, -D / 2 - 0.3), C.yellow)
	for _, x in { -4, 4 } do
		k:block(V(3, 3, 0.2), V(x, 4.6, -D / 2 - 0.05), trim)
		k:block(V(2.5, 2.5, 0.3), V(x, 4.6, -D / 2 - 0.12), C.glass)
	end
	for _, x in { -W / 2 - 0.1, W / 2 + 0.1 } do
		k:block(V(0.3, 2.5, 2.5), V(x, 4.6, 0), C.glass)
	end
	k:block(V(1.6, 5, 1.6), V(W / 2 - 3, H + 3, 2), opts.chimney or C.brick)
	if opts.extra then
		opts.extra(k, W, D, H)
	end
end

function B.house(k, r)
	house(k, r, {})
end

function B.cabin(k, r)
	house(k, r, {
		wall = rgb(140, 90, 55),
		wallMat = Enum.Material.WoodPlanks,
		roof = C.snow,
		trim = rgb(230, 230, 230),
		door = C.red,
		chimney = C.gray,
	})
end

function B.beachhut(k, r)
	house(k, r, {
		wall = pick(r, PASTELS),
		roof = pick(r, { C.white, C.sky, C.pink }),
		trim = C.white,
		chimney = pick(r, PASTELS),
	})
end

function B.gingerbread(k, r)
	house(k, r, {
		wall = rgb(165, 100, 50),
		roof = rgb(255, 245, 250),
		trim = rgb(255, 255, 255),
		door = rgb(255, 100, 160),
		chimney = rgb(255, 120, 170),
		extra = function(k2, W, D, H)
			for i = -2, 2 do
				k2:ball(1.1, V(i * 2.6, H - 0.4, -D / 2 - 0.3), pick(r, BRIGHTS))
			end
			for i = -1, 1, 2 do
				k2:cyl(0.6, 6, V(i * 1.9, 3, -D / 2 - 0.4), C.white)
			end
		end,
	})
end

function B.apartment(k, r)
	local W, D = 12, 12
	local H = r:NextNumber(30, 40)
	local wall = pick(r, { rgb(200, 120, 90), rgb(230, 220, 200), rgb(150, 170, 200), rgb(240, 200, 120) })
	k:block(V(W, H, D), V(0, H / 2, 0), wall)
	local floor = 4
	local y = 5
	while y < H - 2 do
		k:block(V(W + 0.2, 1.8, D + 0.2), V(0, y, 0), C.glass)
		y += floor
	end
	for _, x in { -W / 2, W / 2 } do
		for _, z in { -D / 2, D / 2 } do
			k:block(V(1.2, H, 1.2), V(x, H / 2, z), shade(wall, 0.8))
		end
	end
	k:block(V(W + 0.8, 0.8, D + 0.8), V(0, H + 0.4, 0), shade(wall, 0.7))
	k:block(V(3, 3.6, 0.3), V(0, 1.8, -D / 2 - 0.1), C.glass)
	-- A little wooden water tank on the roof, like in the big city.
	for _, x in { 1.2, 3.8 } do
		for _, z in { 1.2, 3.8 } do
			k:block(V(0.3, 2, 0.3), V(x, H + 1.8, z), C.dark)
		end
	end
	k:cyl(3.4, 3, V(2.5, H + 4.3, 2.5), C.wood, { material = Enum.Material.WoodPlanks })
	k:cone(3.6, 0.4, 1.4, V(2.5, H + 5.8, 2.5), C.dark, 3)
end

function B.shop(k, r)
	local W, D, H = 16, 10, 9
	local wall = pick(r, HOUSE_WALLS)
	k:block(V(W, H, D), V(0, H / 2, 0), wall)
	k:block(V(W + 0.6, 1, D + 0.6), V(0, H + 0.5, 0), shade(wall, 0.75))
	k:block(V(W - 4, 4, 0.3), V(0, 3, -D / 2 - 0.1), C.glass)
	local a, b = pick(r, BRIGHTS), C.white
	for i = 0, 7 do
		k:wedge(V(W / 8, 1.2, 2.2), CFrame.new(-W / 2 + W / 16 + i * W / 8, 5.9, -D / 2 - 1.1), i % 2 == 0 and a or b)
	end
	local sign = k:block(V(W - 2, 2.4, 0.3), V(0, 7.6, -D / 2 - 0.1), C.white)
	k:label(sign, Enum.NormalId.Front, pick(r, { "TOYS", "ICE CREAM", "PIZZA", "BAKERY", "BOOKS", "PETS" }), a)
end

---------------------------------------------------------------- Farm

function B.pumpkin(k, r)
	local o = pick(r, { C.orange, rgb(255, 150, 50), rgb(240, 115, 30) })
	k:blob(V(2.6, 1.9, 2.6), V(0, 0.95, 0), o)
	k:blob(V(1.4, 1.95, 2.7), V(0, 0.95, 0), shade(o, 0.92))
	k:blob(V(2.7, 1.95, 1.4), V(0, 0.95, 0), shade(o, 0.92))
	k:cyl(0.35, 0.7, V(0, 2.1, 0), C.darkGreen)
	k:blob(V(0.9, 0.2, 0.5), CFrame.new(0.4, 1.95, 0) * CFrame.Angles(0, 0, -0.4), C.green)
end

function B.hayroll(k, r)
	k:hcyl(2.4, 2.6, V(0, 1.2, 0), C.hay)
	k:hcyl(1.6, 2.65, V(0, 1.2, 0), shade(C.hay, 0.9))
	for _, x in { -0.7, 0.7 } do
		k:hcyl(2.45, 0.15, V(x, 1.2, 0), shade(C.hay, 0.7))
	end
end

function B.crate(k, r)
	local w = pick(r, { C.wood, rgb(190, 140, 90) })
	k:block(V(2.5, 2.5, 2.5), V(0, 1.25, 0), w, { material = Enum.Material.WoodPlanks })
	for _, y in { 0.25, 2.25 } do
		k:block(V(2.6, 0.4, 2.6), V(0, y, 0), shade(w, 0.75))
	end
	local fruit = pick(r, { C.red, C.orange, C.green, C.yellow })
	for _ = 1, 5 do
		k:ball(0.8, V(r:NextNumber(-0.8, 0.8), 2.6, r:NextNumber(-0.8, 0.8)), fruit)
	end
end

function B.sunflower(k, r)
	local h = r:NextNumber(4, 5)
	k:cyl(0.3, h, V(0, h / 2, 0), C.darkGreen)
	k:blob(V(1.4, 0.15, 0.6), CFrame.new(0.6, h * 0.5, 0) * CFrame.Angles(0, 0, 0.4), C.green)
	k:blob(V(1.4, 0.15, 0.6), CFrame.new(-0.6, h * 0.65, 0) * CFrame.Angles(0, 0, -0.4), C.green)
	local head = CFrame.new(0, h + 0.6, -0.1) * CFrame.Angles(math.rad(-15), 0, 0)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		k:blob(V(0.7, 1.2, 0.2), head * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.0, 0), C.yellow)
	end
	k:zcyl(1.4, 0.35, head, C.brown)
end

function B.scarecrow(k, r)
	k:block(V(0.45, 6, 0.45), V(0, 3, 0), C.wood)
	k:block(V(5, 0.4, 0.4), V(0, 4.6, 0), C.wood)
	local shirt = pick(r, { C.red, C.blue, rgb(200, 80, 60) })
	k:block(V(2, 2.4, 1), V(0, 4.1, 0), shirt)
	k:block(V(2.2, 0.8, 1.1), V(0, 2.7, 0), rgb(70, 110, 170))
	k:ball(1.6, V(0, 5.9, 0), rgb(225, 195, 140))
	k:cyl(2.6, 0.2, V(0, 6.6, 0), C.wood)
	k:cyl(1.3, 1.1, V(0, 7.2, 0), C.wood)
	for _, x in { -2.6, 2.6 } do
		k:block(V(0.5, 0.6, 0.5), V(x, 4.4, 0), C.hay)
	end
	for _, x in { -0.35, 0.35 } do
		k:ball(0.25, V(x, 6.1, -0.75), C.black)
	end
end

function B.fence(k, r)
	local c = pick(r, { C.white, C.wood })
	for _, x in { -3.5, 0, 3.5 } do
		k:block(V(0.5, 3.2, 0.5), V(x, 1.6, 0), c)
	end
	for _, y in { 1.1, 2.4 } do
		k:block(V(7.6, 0.45, 0.25), V(0, y, -0.3), c)
	end
end

function B.haystack(k, r)
	k:cone(5.5, 1.2, 4.5, V(0, 0, 0), { C.hay, shade(C.hay, 0.92) }, 6)
	k:cyl(0.25, 2, V(1.4, 4, 0.3), C.wood)
end

function B.tractor(k, r)
	local c = pick(r, { rgb(60, 160, 60), C.red, rgb(60, 160, 60) })
	local rim = C.yellow
	k:block(V(3.4, 2.4, 6.5), V(0, 2.8, 0.2), c)
	k:block(V(2.8, 2.2, 3), V(0, 2.8, -3.9), c)
	for _, x in { -2.3, 2.3 } do
		k:hcyl(4.4, 1.3, V(x, 2.2, 1.9), C.black)
		k:hcyl(2.4, 1.35, V(x, 2.2, 1.9), rim)
		k:hcyl(2.4, 0.9, V(x * 0.8, 1.2, -3.8), C.black)
		k:hcyl(1.2, 0.95, V(x * 0.8, 1.2, -3.8), rim)
	end
	k:block(V(3.8, 0.3, 3.4), V(0, 7.2, 1.6), c)
	for _, x in { -1.75, 1.75 } do
		for _, z in { 0.1, 3.1 } do
			k:block(V(0.2, 3.2, 0.2), V(x, 5.5, z), C.dark)
		end
	end
	k:block(V(1.6, 0.4, 1.4), V(0, 4.2, 2.1), C.black)
	k:cyl(0.4, 2.6, V(0.8, 5.2, -3.6), C.dark)
	k:ball(0.6, V(-1, 3.2, -5.45), rgb(255, 250, 200), NEON)
	k:ball(0.6, V(1, 3.2, -5.45), rgb(255, 250, 200), NEON)
end

function B.barn(k, r)
	local W, D, H = 20, 16, 10
	local red = pick(r, { rgb(190, 45, 45), rgb(170, 40, 40), rgb(200, 60, 50) })
	k:block(V(W, H, D), V(0, H / 2, 0), red, { material = Enum.Material.WoodPlanks })
	k:roof(W + 1.6, D + 1.6, 7, V(0, H, 0), rgb(80, 80, 90))
	local gx = -(W + 1.6) / 2 - 0.1
	k:block(V(0.3, 7.2, 7.2), V(-W / 2 - 0.1, 3.6, 0), C.white)
	k:block(V(0.35, 6.4, 6.4), V(-W / 2 - 0.15, 3.6, 0), shade(red, 0.85))
	for _, a in { math.rad(45), math.rad(-45) } do
		k:block(V(0.2, 8.6, 0.5), CFrame.new(-W / 2 - 0.3, 3.6, 0) * CFrame.Angles(a, 0, 0), C.white)
	end
	k:block(V(0.3, 2.6, 2.6), V(gx, 12.2, 0), C.white)
	k:block(V(0.35, 2, 2), V(gx - 0.05, 12.2, 0), C.dark)
	for _, x in { -W / 2, W / 2 } do
		for _, z in { -D / 2, D / 2 } do
			k:block(V(0.6, H, 0.6), V(x, H / 2, z), C.white)
		end
	end
	k:ball(1.2, V(0, H + 7.6, 0), C.yellow)
end

function B.silo(k, r)
	local c = pick(r, { rgb(40, 70, 140), C.silver, rgb(200, 200, 205), rgb(150, 60, 50) })
	local H = 26
	k:cyl(8, H, V(0, H / 2, 0), c, { material = c == C.silver and Enum.Material.Metal or nil })
	k:ball(8, V(0, H, 0), c == rgb(40, 70, 140) and C.white or C.silver)
	for y = 4, H - 2, 5 do
		k:cyl(8.2, 0.4, V(0, y, 0), shade(c, 0.8))
	end
	for _, x in { -0.6, 0.6 } do
		k:block(V(0.2, H, 0.2), V(x, H / 2, -4.15), C.dark)
	end
	for y = 1, H, 2 do
		k:block(V(1.4, 0.15, 0.15), V(0, y, -4.15), C.dark)
	end
end

function B.windmill(k, r)
	local body = pick(r, { C.white, rgb(200, 90, 70), rgb(240, 230, 210) })
	k:cone(11, 6.5, 22, V(0, 0, 0), body, 8)
	k:cone(7.5, 1, 4, V(0, 22, 0), rgb(90, 70, 60), 4)
	k:block(V(2.6, 4, 0.3), V(0, 2, -5.4), C.wood)
	k:block(V(1.6, 1.6, 0.3), V(0, 12, -4.3), C.glass)
	local hub = CFrame.new(0, 21, -4.6)
	k:zcyl(1.4, 1.2, hub, C.dark)
	local spin = r:NextNumber() * math.pi
	for i = 0, 3 do
		local arm = hub * CFrame.Angles(0, 0, spin + i * math.pi / 2)
		k:block(V(0.4, 9, 0.3), arm * CFrame.new(0, 4.5, -0.5), C.wood)
		k:block(V(2.2, 7.5, 0.15), arm * CFrame.new(1.2, 5.5, -0.6), C.white)
	end
end

---------------------------------------------------------------- Snow

function B.snowman(k, r)
	k:ball(2.4, V(0, 1.1, 0), C.snow)
	k:ball(1.8, V(0, 2.8, 0), C.snow)
	k:ball(1.35, V(0, 4.1, 0), C.snow)
	k:hcyl(0.25, 0.8, CFrame.new(0, 4.1, -0.9) * CFrame.Angles(0, math.pi / 2, 0), C.orange)
	for _, x in { -0.3, 0.3 } do
		k:ball(0.2, V(x, 4.35, -0.58), C.black)
	end
	for _, y in { 2.6, 3.1 } do
		k:ball(0.2, V(0, y, -0.9), C.black)
	end
	local scarf = pick(r, BRIGHTS)
	k:cyl(1.55, 0.35, V(0, 3.55, 0), scarf)
	k:block(V(0.4, 1, 0.15), V(0.4, 3.1, -0.75), scarf)
	if r:NextNumber() < 0.6 then
		k:cyl(1.6, 0.15, V(0, 4.7, 0), C.black)
		k:cyl(1.0, 1.0, V(0, 5.2, 0), C.black)
	end
end

function B.present(k, r)
	local box, ribbon = pick(r, BRIGHTS), pick(r, { C.white, C.yellow, C.red, C.green })
	if box == ribbon then
		ribbon = C.white
	end
	k:block(V(2.4, 2, 2.4), V(0, 1, 0), box)
	k:block(V(2.5, 2.05, 0.5), V(0, 1, 0), ribbon)
	k:block(V(0.5, 2.05, 2.5), V(0, 1, 0), ribbon)
	k:ball(0.8, V(-0.35, 2.2, 0), ribbon)
	k:ball(0.8, V(0.35, 2.2, 0), ribbon)
end

function B.candycane(k, r)
	local stripe = pick(r, { C.red, C.red, C.green })
	for i = 0, 9 do
		k:cyl(0.7, 0.5, V(0, 0.25 + i * 0.5, 0), i % 2 == 0 and stripe or C.white)
	end
	for i = 0, 6 do
		local a = i / 6 * math.pi
		k:ball(0.72, V(0.7 - math.cos(a) * 0.7, 5 + math.sin(a) * 0.7, 0), i % 2 == 0 and C.white or stripe)
	end
end

function B.sled(k, r)
	local c = pick(r, { C.red, C.blue, C.wood })
	for _, x in { -0.9, 0.9 } do
		k:block(V(0.2, 0.2, 4.4), V(x, 0.1, 0), C.silver)
		k:zcyl(0.7, 0.2, V(x, 0.5, -2.2), C.silver)
		k:block(V(0.2, 0.6, 0.2), V(x, 0.4, -1), C.dark)
		k:block(V(0.2, 0.6, 0.2), V(x, 0.4, 1.2), C.dark)
	end
	k:block(V(2.2, 0.25, 3.6), V(0, 0.8, 0.2), c, { material = Enum.Material.WoodPlanks })
end

function B.igloo(k, r)
	k:ball(12, V(0, 0, 0), C.snow, { material = Enum.Material.Snow })
	k:zcyl(5, 4, V(0, 0.8, -6.2), C.snow, { material = Enum.Material.Snow })
	k:block(V(2.6, 2.8, 0.2), V(0, 1.4, -8.25), rgb(60, 70, 90))
	for y = 1, 4 do
		k:cyl(math.sqrt(36 - (y * 1.2) ^ 2) * 2 + 0.1, 0.12, V(0, y * 1.2, 0), C.ice)
	end
end

function B.icecastle(k, r)
	local ice = { material = Enum.Material.Ice }
	local glassy = rgb(190, 230, 255)
	k:block(V(20, 12, 20), V(0, 6, 0), C.ice, ice)
	for _, x in { -10, 10 } do
		for _, z in { -10, 10 } do
			k:cyl(6, 22, V(x, 11, z), glassy, ice)
			k:cone(7, 0.8, 8, V(x, 22, z), rgb(120, 170, 255), 5)
		end
	end
	k:cyl(9, 30, V(0, 15, 0), glassy, ice)
	k:cone(10.5, 1, 12, V(0, 30, 0), rgb(120, 170, 255), 6)
	k:ball(1.6, V(0, 42.5, 0), rgb(200, 240, 255), NEON)
	for i = -4, 4, 2 do
		k:block(V(2, 2, 2), V(i * 2, 13, -10), C.ice, ice)
		k:block(V(2, 2, 2), V(i * 2, 13, 10), C.ice, ice)
	end
	k:block(V(5, 7, 0.4), V(0, 3.5, -10.1), rgb(90, 130, 200))
end

---------------------------------------------------------------- Beach

function B.beachball(k, r)
	k:ball(2.4, V(0, 1.2, 0), C.white)
	local colors = { C.red, C.yellow, C.blue }
	for i = 1, 3 do
		k:hcyl(2.42, 0.45, CFrame.new(0, 1.2, 0) * CFrame.Angles(0, i * math.pi / 3, 0), colors[i])
	end
	k:ball(0.5, V(0, 2.4, 0), C.white)
end

function B.bucket(k, r)
	local c = pick(r, BRIGHTS)
	k:cone(1.5, 2, 1.8, V(0, 0, 0), c, 3)
	k:cyl(1.6, 0.2, V(0, 1.7, 0), C.sand)
	k:beam(0.12, 0.12, V(-1, 1.8, 0), V(0, 2.6, 0), shade(c, 0.7))
	k:beam(0.12, 0.12, V(1, 1.8, 0), V(0, 2.6, 0), shade(c, 0.7))
	k:block(V(0.3, 0.1, 1.6), CFrame.new(1.6, 0.4, 0) * CFrame.Angles(0, 0, 0.6), pick(r, BRIGHTS))
end

function B.sandcastle(k, r)
	local sand = { material = Enum.Material.Sand }
	k:block(V(5, 2, 5), V(0, 1, 0), C.sand, sand)
	for _, x in { -2.5, 2.5 } do
		for _, z in { -2.5, 2.5 } do
			k:cyl(1.6, 3.2, V(x, 1.6, z), C.sand, sand)
			k:cone(1.7, 0.4, 0.8, V(x, 3.2, z), shade(C.sand, 0.92), 3)
		end
	end
	k:cyl(2.4, 4.5, V(0, 2.25, 0), C.sand, sand)
	k:cyl(0.12, 2, V(0, 5.5, 0), C.wood)
	k:block(V(0.1, 0.7, 1.1), V(0, 6.1, -0.55), pick(r, BRIGHTS))
	k:block(V(1.4, 1.4, 0.2), V(0, 0.7, -2.55), shade(C.sand, 0.7))
end

function B.umbrella(k, r)
	local a, b = pick(r, BRIGHTS), C.white
	k:cyl(0.3, 6.2, V(0, 3.1, 0), C.white)
	k:cone(8, 0.8, 1.8, V(0, 5.6, 0), { a, b, a, b, a, b }, 6)
	k:ball(0.5, V(0, 7.5, 0), a)
	k:block(V(2, 0.3, 4), CFrame.new(1.6, 0.6, 1) * CFrame.Angles(0.15, 0.3, 0), pick(r, PASTELS))
end

function B.palm(k, r)
	local trunk = rgb(160, 120, 80)
	local p = V(0, 0, 0)
	local lean = r:NextNumber(0.6, 1.2)
	for i = 1, 6 do
		local nextP = p + V(lean * 0.35 * i * 0.3, 1.8, 0)
		k:rod(1.3 - i * 0.07, p, nextP, i % 2 == 0 and trunk or shade(trunk, 0.88))
		p = nextP
	end
	local top = p
	local leaf = pick(r, LEAVES)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local cf = CFrame.new(top) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-25), 0, 0)
		k:block(V(1.4, 0.3, 6), cf * CFrame.new(0, 0, -3), i % 2 == 0 and leaf or shade(leaf, 1.12))
	end
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		k:ball(0.8, top + V(math.cos(a) * 0.6, -0.6, math.sin(a) * 0.6), C.brown)
	end
end

function B.boat(k, r)
	local hull = pick(r, { C.white, C.red, C.blue, C.yellow })
	k:block(V(4, 1.8, 8), V(0, 0.9, 1), hull)
	k:wedge(V(4, 1.8, 3), CFrame.new(0, 0.9, -4.5), hull)
	k:block(V(4.1, 0.35, 11.1), V(0, 1.6, -0.5), shade(hull, 0.75))
	k:cyl(0.3, 9, V(0, 6, 0.5), C.wood)
	k:wedge(V(0.15, 7.5, 4), CFrame.new(0, 6, 2.6), pick(r, { C.white, C.red, C.yellow, C.sky }))
	k:block(V(3.2, 0.3, 3), V(0, 1.85, 2.5), C.wood)
end

function B.lifeguard(k, r)
	local c = C.white
	for _, x in { -1.6, 1.6 } do
		k:beam(0.4, 0.4, V(x, 0, -1.6), V(x * 0.8, 6, -0.4), c)
		k:beam(0.4, 0.4, V(x, 0, 1.6), V(x * 0.8, 6, 0.6), c)
	end
	k:block(V(3.4, 0.3, 2.4), V(0, 6, 0), C.wood)
	k:block(V(3.2, 2.6, 0.3), V(0, 7.4, 1.1), C.red)
	k:cyl(0.2, 4, V(1.4, 8, 0.2), C.white)
	k:cone(5, 0.5, 1.2, V(1.4, 9.6, 0.2), { C.red, C.white, C.red, C.white }, 4)
	for y = 1, 5 do
		k:block(V(2.6, 0.2, 0.3), V(0, y, -1.5 + y * 0.18), C.wood)
	end
end

function B.lighthouse(k, r)
	local stripe = pick(r, { C.red, C.red, rgb(40, 80, 160) })
	k:cyl(12, 2, V(0, 1, 0), C.gray, { material = Enum.Material.Slate })
	k:cone(9, 5.5, 30, V(0, 2, 0), { C.white, C.white, stripe, stripe }, 8)
	k:cyl(8, 0.6, V(0, 32.3, 0), C.dark)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		k:block(V(0.2, 1.4, 0.2), V(math.cos(a) * 3.8, 33.3, math.sin(a) * 3.8), C.dark)
	end
	k:cyl(4.4, 4, V(0, 34.6, 0), rgb(255, 245, 180), NEON)
	k:cone(5.4, 0.8, 3, V(0, 36.6, 0), stripe, 4)
	k:ball(0.8, V(0, 39.8, 0), C.dark)
	k:block(V(2, 3.6, 0.3), V(0, 3.8, -3.95), C.dark)
end

---------------------------------------------------------------- Candy

function B.lollipop(k, r)
	k:cyl(0.3, 4, V(0, 2, 0), C.white)
	local a, b = pick(r, BRIGHTS), pick(r, PASTELS)
	local disc = CFrame.new(0, 4.8, 0) * CFrame.Angles(0, math.pi / 2, 0)
	k:hcyl(2.8, 0.4, disc, a)
	k:hcyl(2.0, 0.45, disc, b)
	k:hcyl(1.2, 0.5, disc, a)
	k:hcyl(0.5, 0.55, disc, C.white)
end

function B.gumdrop(k, r)
	local c = pick(r, BRIGHTS)
	k:blob(V(2.4, 2.4, 2.4), V(0, 0.6, 0), c, { reflectance = 0.15 })
	k:cyl(2.2, 0.6, V(0, 0.3, 0), c, { reflectance = 0.15 })
	for _ = 1, 8 do
		k:block(V(0.2, 0.2, 0.2), V(r:NextNumber(-0.7, 0.7), r:NextNumber(1.1, 1.7), r:NextNumber(-0.7, 0.7)), C.white)
	end
end

function B.cupcake(k, r)
	local wrap = pick(r, PASTELS)
	k:cone(1.7, 2.2, 1.4, V(0, 0, 0), { wrap, shade(wrap, 0.9) }, 4)
	local frost = pick(r, PASTELS)
	k:cyl(2.3, 0.6, V(0, 1.6, 0), frost)
	k:ball(1.9, V(0, 2.1, 0), frost)
	k:ball(1.2, V(0, 2.9, 0), frost)
	k:ball(0.6, V(0, 3.6, 0), C.red)
	for _ = 1, 10 do
		local a = r:NextNumber() * math.pi * 2
		k:block(V(0.12, 0.12, 0.35), V(math.cos(a) * 0.9, 2.5, math.sin(a) * 0.9), pick(r, BRIGHTS))
	end
end

function B.donut(k, r)
	local dough = rgb(215, 160, 95)
	local icing = pick(r, { C.pink, rgb(120, 70, 50), C.white, rgb(180, 140, 255) })
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local p = V(math.cos(a) * 1.6, 0.7, math.sin(a) * 1.6)
		k:ball(1.4, p, dough)
		k:ball(1.2, p + V(0, 0.35, 0), icing)
	end
	for _ = 1, 12 do
		local a = r:NextNumber() * math.pi * 2
		local d = r:NextNumber(1.1, 2.1)
		k:block(V(0.12, 0.12, 0.4), CFrame.new(math.cos(a) * d, 1.6, math.sin(a) * d) * CFrame.Angles(0, a, 0), pick(r, BRIGHTS))
	end
end

function B.icecream(k, r)
	k:cone(0.4, 2.2, 3, V(0, 0, 0), { rgb(220, 170, 100), rgb(200, 150, 85) }, 6)
	local flavors = { C.pink, C.white, rgb(130, 80, 50), rgb(180, 240, 180), rgb(255, 230, 140) }
	k:ball(2.3, V(0, 3.4, 0), pick(r, flavors))
	k:ball(2.0, V(0, 4.9, 0), pick(r, flavors))
	k:ball(0.6, V(0, 6.0, 0), C.red)
end

local function cake(k, r, tiers)
	local d = 10
	local y = 0
	for i = 1, tiers do
		local c = pick(r, PASTELS)
		local h = 3.2
		k:cyl(d, h, V(0, y + h / 2, 0), c)
		k:cyl(d + 0.3, 0.5, V(0, y + h - 0.2, 0), C.white)
		for j = 1, 10 do
			local a = j / 10 * math.pi * 2
			k:ball(0.7, V(math.cos(a) * d / 2, y + h - 0.6, math.sin(a) * d / 2), C.white)
		end
		y += h
		d *= 0.72
	end
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		local p = V(math.cos(a) * d * 0.5, y, math.sin(a) * d * 0.5)
		k:cyl(0.3, 1.4, p + V(0, 0.7, 0), pick(r, BRIGHTS))
		k:ball(0.35, p + V(0, 1.6, 0), rgb(255, 200, 80), NEON)
	end
	k:ball(1.2, V(0, y + 0.5, 0), C.red)
end

function B.cake(k, r)
	cake(k, r, 2)
end

function B.bigcake(k, r)
	cake(k, r, 5)
end

---------------------------------------------------------------- Gates

-- A wall of bricks between two areas. `width` and `height` in studs.
local function brickWall(k, r, width, height, style)
	local brickH = height / style.rows
	local brickW = brickH * 2
	local cols = math.ceil(width / brickW)
	brickW = width / cols
	local depth = brickH * 1.2
	for row = 0, style.rows - 1 do
		local offset = (row % 2 == 1) and brickW / 2 or 0
		local x = -width / 2 + offset
		local first = true
		while x < width / 2 - 0.01 do
			local w = brickW
			if first and offset > 0 then
				w = offset
			end
			w = math.min(w, width / 2 - x)
			local c = style.colors[r:NextInteger(1, #style.colors)]
			k:block(V(w - 0.15, brickH - 0.15, depth), V(x + w / 2, row * brickH + brickH / 2, 0), c, style.opts)
			x += w
			first = false
		end
	end
	if style.cap then
		k:block(V(width, brickH * 0.3, depth * 1.15), V(0, height + brickH * 0.15, 0), style.cap)
	end
end

B.GateStyles = {
	Town = { rows = 4, colors = { C.brick, shade(C.brick, 0.9), shade(C.brick, 1.1) }, opts = { material = Enum.Material.Brick }, cap = C.gray },
	Farm = { rows = 4, colors = { C.hay, shade(C.hay, 0.92), shade(C.hay, 1.05) }, opts = { material = Enum.Material.Fabric } },
	Snow = { rows = 4, colors = { C.ice, rgb(200, 235, 255), rgb(150, 210, 250) }, opts = { material = Enum.Material.Ice }, cap = C.snow },
	Beach = { rows = 4, colors = { C.sand, shade(C.sand, 0.93), shade(C.sand, 1.04) }, opts = { material = Enum.Material.Sandstone } },
	Candy = { rows = 4, colors = { rgb(110, 65, 40), rgb(125, 75, 45), rgb(100, 60, 35) }, cap = rgb(255, 170, 210) },
}

function B.gate(r, width: number, height: number, styleName: string)
	local k = Kit.new("Gate")
	brickWall(k, r, width, height, B.GateStyles[styleName] or B.GateStyles.Town)
	return k:finish()
end

-- Builds a named item and returns its model.
function B.build(name: string, r: Random)
	local builder = B[name]
	assert(builder, "no item builder called " .. name)
	local k = Kit.new(name)
	builder(k, r)
	return k:finish()
end

B.Colors = C
B.pick = pick
B.shade = shade

return B
