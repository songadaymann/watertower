--!nonstrict
-- Builds one "land": three areas that get wider as you go, walls between them,
-- and a water tower at the far end. Everything lives in workspace.Land.
--
--   spawn (z=0) ── area 1 ── [wall] ── area 2 ── [big wall] ── area 3 ── water tower (z≈1190)

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.WaterTowerShared.Config)
local Items = require(script.Parent.Items)
local Towers = require(script.Parent.Towers)
local Biomes = require(script.Parent.Biomes)

local V = Vector3.new

local Land = {}

-- counts[t] = how many tier-t things to scatter in that area.
Land.ZONES = {
	{ halfW = 90, z0 = 0, z1 = 220, pathW = 14, cliffH = { 35, 70 }, counts = { 28, 9 } },
	{ halfW = 180, z0 = 220, z1 = 600, pathW = 24, cliffH = { 60, 110 }, counts = { 8, 22, 14, 4 } },
	{ halfW = 330, z0 = 600, z1 = 1220, pathW = 40, cliffH = { 90, 150 }, counts = { 0, 0, 12, 16, 9 } },
}
Land.SPAWN = V(0, 0, 24)
Land.TOWER = V(0, 0, 1090)
Land.GATE_HEIGHT = { 17, 34 }

local current: Folder? = nil

local function newFolder(name: string, parent: Instance)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function plain(parent: Instance, size: Vector3, cf, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = if typeof(cf) == "CFrame" then cf else CFrame.new(cf)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function longestSide(model: Model)
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Y, size.Z), size
end

-- An invisible box around the thing that twinkles when you're big enough to smash it.
-- The client turns the sparkles on and off; the server only builds them.
local function addSparkle(model: Model, extent: number)
	local cf, size = model:GetBoundingBox()
	local p = Instance.new("Part")
	p.Name = "SparklePart"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.CFrame = cf
	p.Size = size * 1.05
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Sparkle"
	pe.Enabled = false
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	pe.Rate = math.clamp(extent * 3, 10, 90)
	pe.Lifetime = NumberRange.new(0.7, 1.3)
	pe.Speed = NumberRange.new(0.5, 2)
	pe.SpreadAngle = Vector2.new(180, 180)
	local s = math.clamp(0.7 + extent * 0.1, 1, 8)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, s), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200), Color3.fromRGB(255, 220, 90))
	pe.Parent = p
	p.Parent = model
end

local function applyLighting(biome)
	Lighting.ClockTime = biome.lighting.clock
	Lighting.Brightness = 2.4
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(110, 110, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.FogEnd = 100000
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	-- Thin air, so the water tower is visible from the very start.
	atm.Density = 0.06
	atm.Offset = 0
	atm.Color = biome.lighting.atmosphere
	atm.Decay = biome.lighting.decay
	atm.Glare = 0
	atm.Haze = 0
	atm.Parent = Lighting
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.Enabled = false
	end
end

local function buildGround(f: Folder, biome)
	for _, z in Land.ZONES do
		local len = z.z1 - z.z0
		plain(f, V(z.halfW * 2 + 4, 8, len), V(0, -4, (z.z0 + z.z1) / 2), biome.ground, biome.groundMat)
		plain(f, V(z.pathW, 0.3, len), V(0, 0, (z.z0 + z.z1) / 2), biome.path, biome.pathMat)
		if biome.stripe then
			for zz = z.z0 + 6, z.z1 - 6, 14 do
				plain(f, V(z.pathW * 0.06, 0.32, 5), V(0, 0, zz), biome.stripe)
			end
		end
	end
	-- A round starting pad.
	local pad = plain(f, V(0.4, 16, 16), CFrame.new(Land.SPAWN + V(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(80, 170, 255))
	pad.Shape = Enum.PartType.Cylinder
	local ring = plain(f, V(0.38, 19, 19), CFrame.new(Land.SPAWN + V(0, 0.09, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 255, 255))
	ring.Shape = Enum.PartType.Cylinder
end

-- Cliffs along a boundary line, plus an invisible wall so nobody can jump out.
local function boundary(decor: Folder, walls: Folder, rng: Random, biome, a: Vector3, b: Vector3, outward: Vector3, hRange)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local mid = (a + b) / 2
	local wall = plain(walls, V(4, 1600, len + 4), CFrame.lookAt(mid + V(0, 790, 0), mid + V(0, 790, 0) + dir), Color3.new())
	wall.Transparency = 1
	wall.CastShadow = false

	local n = math.max(1, math.ceil(len / 38))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		local h = rng:NextNumber(hRange[1], hRange[2])
		local depth = rng:NextNumber(30, 55)
		local w = len / n * 1.5 + 12
		local center = p + outward * (depth / 2 + 9) + V(0, h / 2 - 8, 0)
		local cf = CFrame.lookAt(center, center + dir)
			* CFrame.Angles(rng:NextNumber(-0.06, 0.06), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.06, 0.06))
		local c = biome.cliff[rng:NextInteger(1, #biome.cliff)]
		local rock = plain(decor, V(depth, h, w), cf, c, biome.cliffMat)
		rock.CanQuery = false
		-- A second, taller row behind for depth.
		if rng:NextNumber() < 0.7 then
			local h2 = h * rng:NextNumber(1.1, 1.5)
			local c2 = biome.cliff[rng:NextInteger(1, #biome.cliff)]
			local backCenter = center + outward * depth * 0.8 + V(0, (h2 - h) / 2, 0)
			local back = plain(decor, V(depth, h2, w * 0.8), CFrame.lookAt(backCenter, backCenter + dir) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), c2, biome.cliffMat)
			back.CanQuery = false
		end
	end
end

local function buildBoundaries(decor: Folder, walls: Folder, rng: Random, biome)
	local Z = Land.ZONES
	local L, R, F, Bk = V(-1, 0, 0), V(1, 0, 0), V(0, 0, 1), V(0, 0, -1)
	local function side(z)
		boundary(decor, walls, rng, biome, V(-z.halfW, 0, z.z0), V(-z.halfW, 0, z.z1), L, z.cliffH)
		boundary(decor, walls, rng, biome, V(z.halfW, 0, z.z0), V(z.halfW, 0, z.z1), R, z.cliffH)
	end
	for _, z in Z do
		side(z)
	end
	boundary(decor, walls, rng, biome, V(-Z[1].halfW, 0, 0), V(Z[1].halfW, 0, 0), Bk, { 40, 70 })
	for i = 2, #Z do
		local inner, outer, zz = Z[i - 1].halfW, Z[i].halfW, Z[i].z0
		boundary(decor, walls, rng, biome, V(-outer, 0, zz), V(-inner, 0, zz), Bk, Z[i].cliffH)
		boundary(decor, walls, rng, biome, V(inner, 0, zz), V(outer, 0, zz), Bk, Z[i].cliffH)
	end
	-- Keep the far wall low so the water tower stands out against the sky.
	local last = Z[#Z]
	boundary(decor, walls, rng, biome, V(-last.halfW, 0, last.z1), V(last.halfW, 0, last.z1), F, { 18, 35 })
end

local function buildClouds(decor: Folder, rng: Random)
	for _ = 1, 16 do
		local center = V(rng:NextNumber(-550, 550), rng:NextNumber(190, 300), rng:NextNumber(-150, 1500))
		for _ = 1, rng:NextInteger(4, 7) do
			local d = rng:NextNumber(22, 48)
			local p = plain(decor, V(d, d, d), center + V(rng:NextNumber(-40, 40), rng:NextNumber(-6, 8), rng:NextNumber(-20, 20)), Color3.new(1, 1, 1))
			p.Shape = Enum.PartType.Ball
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
		end
	end
end

-- Scatter `count` tier-t things inside a zone without overlapping each other, the path, the spawn, or the tower.
local function scatter(smash: Folder, rng: Random, biome, zone, tier: number, count: number, placed)
	local names = biome.tiers[tier]
	for _ = 1, count do
		local name = names[rng:NextInteger(1, #names)]
		local model = Items.build(name, rng)
		local ext = longestSide(model)
		local target = Config.TIER_EXTENT[tier] * rng:NextNumber(0.85, 1.15)
		model:ScaleTo(target / ext)
		local yaw = rng:NextNumber() * math.pi * 2
		model:PivotTo(CFrame.Angles(0, yaw, 0))
		local _, size = model:GetBoundingBox()
		local radius = math.max(size.X, size.Z) / 2

		local spot
		for _ = 1, 40 do
			local margin = radius + 6
			local x = rng:NextNumber(-zone.halfW + margin, zone.halfW - margin)
			local z = rng:NextNumber(zone.z0 + margin, zone.z1 - margin)
			local pos = V(x, 0, z)
			local ok = math.abs(x) > zone.pathW / 2 + radius + 2
				and (pos - Land.SPAWN).Magnitude > 22 + radius
				and (pos - Land.TOWER).Magnitude > 75 + radius
			if ok then
				for _, other in placed do
					if (other.pos - pos).Magnitude < other.r + radius + 3 then
						ok = false
						break
					end
				end
			end
			if ok then
				spot = pos
				break
			end
		end

		if spot then
			table.insert(placed, { pos = spot, r = radius })
			model:PivotTo(CFrame.new(spot) * CFrame.Angles(0, yaw, 0))
			model:SetAttribute("Need", Config.TIER_NEED[tier])
			model:SetAttribute("Tier", tier)
			model:SetAttribute("Kind", "Item")
			model:SetAttribute("Extent", target)
			addSparkle(model, target)
			model.Parent = smash
		else
			model:Destroy()
		end
	end
end

function Land.clear()
	if current then
		current:Destroy()
		current = nil
	end
	local debris = workspace:FindFirstChild("SmashDebris")
	if debris then
		debris:ClearAllChildren()
	end
	workspace.Terrain:Clear()
end

function Land.get(): Folder?
	return current
end

-- Builds a whole new land. Returns the Land folder.
function Land.generate(biomeName: string, seed: number)
	Land.clear()
	local biome = Biomes[biomeName]
	local rng = Random.new(seed)

	local root = Instance.new("Folder")
	root.Name = "Land"
	root:SetAttribute("Ready", false)
	local ground = newFolder("Ground", root)
	local decor = newFolder("Decor", root)
	local walls = newFolder("Walls", root)
	local barriers = newFolder("Barriers", root)
	local smash = newFolder("Smashables", root)
	root.Parent = workspace
	current = root

	applyLighting(biome)
	buildGround(ground, biome)
	buildBoundaries(decor, walls, rng, biome)
	buildClouds(decor, rng)
	task.wait()

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Size = V(6, 1, 6)
	spawn.CFrame = CFrame.lookAt(Land.SPAWN + V(0, 0.5, 0), Land.SPAWN + V(0, 0.5, 10))
	spawn.Parent = root

	-- The water tower.
	local townName = biome.names[rng:NextInteger(1, #biome.names)]
	local style = biome.towers[rng:NextInteger(1, #biome.towers)]
	local tower = Towers.build(style, rng, townName)
	tower:ScaleTo(Config.TOWER_SCALE)
	tower:PivotTo(CFrame.new(Land.TOWER))
	tower:SetAttribute("Need", Config.TOWER_NEED)
	tower:SetAttribute("Kind", "Tower")
	tower:SetAttribute("Extent", Config.TOWER_HEIGHT)
	addSparkle(tower, Config.TOWER_HEIGHT)
	tower.Parent = smash

	-- Walls between the areas.
	for gi = 1, #Land.ZONES - 1 do
		local zone = Land.ZONES[gi]
		local width = zone.halfW * 2
		local height = Land.GATE_HEIGHT[gi]
		local gate = Items.gate(rng, width, height, biome.gate)
		gate:PivotTo(CFrame.new(0, 0, zone.z1))
		gate:SetAttribute("Need", Config.GATE_NEED[gi])
		gate:SetAttribute("Kind", "Gate")
		gate:SetAttribute("GateIndex", gi)
		gate:SetAttribute("Extent", height)
		addSparkle(gate, height)
		gate.Parent = smash
		local barrier = plain(barriers, V(width, 1600, 3), V(0, height + 800, zone.z1), Color3.new())
		barrier.Transparency = 1
		barrier:SetAttribute("GateIndex", gi)
	end
	task.wait()

	-- Stuff to smash, small near the start and bigger farther along.
	local placed = {}
	for _, zone in Land.ZONES do
		for tier = #zone.counts, 1, -1 do
			scatter(smash, rng, biome, zone, tier, zone.counts[tier], placed)
			task.wait()
		end
	end

	root:SetAttribute("Biome", biomeName)
	root:SetAttribute("TownName", townName)
	root:SetAttribute("TowerStyle", style)
	root:SetAttribute("TowerPos", Land.TOWER)
	root:SetAttribute("Ready", true)
	return root
end

return Land
