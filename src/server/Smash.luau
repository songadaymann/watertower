--!nonstrict
-- Touching things: smash them if you're big enough, wobble them if you're not.
-- Smashing makes you grow. The water tower gets its own big fall and splash.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.WaterTowerShared.Config)
local Land = require(script.Parent.Land)

local Smash = {}

Smash.remotes = nil :: Folder?
Smash.debris = nil :: Folder?
-- Called as onTowerDown(towerBase: Vector3, pond: Vector3) after the splash.
Smash.onTowerDown = nil :: ((Vector3, Vector3) -> ())?

local rng = Random.new()
local lastBonk: { [Player]: { [Instance]: number } } = {}

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.MaxParts = 400

local function itemOf(part: Instance, smash: Instance): Instance?
	local node = part
	while node and node.Parent ~= smash do
		node = node.Parent
	end
	return node
end

-- The color of the biggest piece, for the puff of sparkles.
local function mainColor(model: Instance): Color3
	local best, bestVol = Color3.new(1, 1, 1), -1
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.9 then
			local vol = d.Size.X * d.Size.Y * d.Size.Z
			if vol > bestVol then
				best, bestVol = d.Color, vol
			end
		end
	end
	return best
end

local function fadeAndRemove(model: Instance, delay: number)
	task.delay(delay, function()
		if not model.Parent then
			return
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				TweenService:Create(d, TweenInfo.new(0.8), { Transparency = 1 }):Play()
			elseif d:IsA("SurfaceGui") then
				d.Enabled = false
			end
		end
		task.wait(0.9)
		model:Destroy()
	end)
end

local function loosen(part: BasePart)
	part.Anchored = false
	part.CanQuery = false
	part.CanTouch = false
	part.CollisionGroup = "Debris"
	pcall(part.SetNetworkOwner, part, nil)
end

-- Unanchor every piece and fling it away from `from`. Bigger smashers fling harder.
local function explode(model: Instance, from: Vector3, power: number)
	local sparkle = model:FindFirstChild("SparklePart")
	if sparkle then
		sparkle:Destroy()
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			loosen(d)
			local away = (d.Position - from) * Vector3.new(1, 0, 1)
			if away.Magnitude < 0.01 then
				away = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
			end
			local speed = (10 + 5 * power) * rng:NextNumber(0.6, 1.3)
			local up = (16 + 4 * power) * rng:NextNumber(0.5, 1.2)
			d.AssemblyLinearVelocity = away.Unit * speed + Vector3.new(0, up, 0)
			d.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8))
		end
	end
end

function Smash.grow(player: Player, amount: number)
	local size = player:GetAttribute("Size") or Config.START_SIZE
	player:SetAttribute("Size", size + amount)
end

local function towerFall(tower: Model, player: Player, from: Vector3)
	local base = tower:GetPivot().Position
	local dir = (base - from) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(0, 0, 1)
	end
	dir = dir.Unit
	Smash.remotes.TowerFalling:FireAllClients({ pos = base, dir = dir, userId = player.UserId })

	local sparkle = tower:FindFirstChild("SparklePart")
	if sparkle then
		sparkle:Destroy()
	end
	tower.Parent = Smash.debris

	local core = tower:FindFirstChild("TankCore")
	local tankParts, frame = {}, {}
	for _, p in tower:GetDescendants() do
		if p:IsA("BasePart") then
			if p:GetAttribute("Tank") then
				table.insert(tankParts, p)
			else
				table.insert(frame, p)
			end
		end
	end
	for _, p in tankParts do
		if p ~= core then
			local w = Instance.new("WeldConstraint")
			w.Part0 = core
			w.Part1 = p
			w.Parent = core
		end
	end
	for _, p in tankParts do
		loosen(p)
	end
	for _, p in frame do
		loosen(p)
		local out = (p.Position - base) * Vector3.new(1, 0, 1)
		if out.Magnitude < 0.1 then
			out = dir
		end
		p.AssemblyLinearVelocity = out.Unit * rng:NextNumber(8, 26) + dir * 14 + Vector3.new(0, rng:NextNumber(4, 18), 0)
		p.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-3, 3), rng:NextNumber(-3, 3))
	end
	-- Tip the tank over away from whoever pushed it.
	core.AssemblyLinearVelocity = dir * 26 + Vector3.new(0, 6, 0)
	core.AssemblyAngularVelocity = Vector3.yAxis:Cross(dir) * 1.1

	task.spawn(function()
		local radius = math.max(core.Size.Y, core.Size.Z) / 2
		local t0 = os.clock()
		while os.clock() - t0 < 5 do
			task.wait(0.03)
			if not core.Parent then
				break
			end
			local t = os.clock() - t0
			if t > 0.5 and core.Position.Y < radius + 10 then
				break
			end
			if t > 1.5 and math.abs(core.AssemblyLinearVelocity.Y) < 2 then
				break
			end
		end
		local hit = core.Position
		local pond = Vector3.new(hit.X, 0, hit.Z)

		-- Burst the tank open.
		for _, w in core:GetChildren() do
			if w:IsA("WeldConstraint") then
				w:Destroy()
			end
		end
		for _, p in tankParts do
			local out = (p.Position - pond) * Vector3.new(1, 0, 1)
			if out.Magnitude < 0.1 then
				out = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
			end
			p.AssemblyLinearVelocity = out.Unit * rng:NextNumber(15, 45) + Vector3.new(0, rng:NextNumber(25, 60), 0)
		end

		local pondRadius = 85
		workspace.Terrain:FillCylinder(CFrame.new(pond + Vector3.new(0, 2, 0)), 4, pondRadius, Enum.Material.Water)
		Smash.remotes.TowerSplash:FireAllClients({ pos = pond, radius = pondRadius })
		fadeAndRemove(tower, 7)
		if Smash.onTowerDown then
			Smash.onTowerDown(base, pond)
		end
	end)
end

local function smashItem(item: Model, player: Player, root: BasePart)
	if item:GetAttribute("Smashed") then
		return
	end
	item:SetAttribute("Smashed", true)
	local kind = item:GetAttribute("Kind")
	if kind == "Tower" then
		towerFall(item, player, root.Position)
		return
	end

	local need = item:GetAttribute("Need") or 1
	local size = player:GetAttribute("Size") or 1
	local cf, bsize = item:GetBoundingBox()
	local extent = item:GetAttribute("Extent") or math.max(bsize.X, bsize.Y, bsize.Z)
	local color = mainColor(item)

	local gain = Config.gainFor(need, size)
	Smash.grow(player, gain)

	if kind == "Gate" then
		local land = Land.get()
		local gi = item:GetAttribute("GateIndex")
		if land and land:FindFirstChild("Barriers") then
			for _, b in land.Barriers:GetChildren() do
				if b:GetAttribute("GateIndex") == gi then
					b:Destroy()
				end
			end
		end
	end

	item.Parent = Smash.debris
	explode(item, root.Position, size)
	fadeAndRemove(item, Config.DEBRIS_LIFETIME)
	Smash.remotes.Smashed:FireAllClients({
		pos = cf.Position,
		extent = extent,
		kind = kind,
		color = color,
		userId = player.UserId,
		gain = gain,
	})
end

local function bonk(item: Instance, player: Player)
	local now = os.clock()
	local seen = lastBonk[player]
	if not seen then
		seen = setmetatable({}, { __mode = "k" })
		lastBonk[player] = seen
	end
	if seen[item] and now - seen[item] < 1.5 then
		return
	end
	seen[item] = now
	Smash.remotes.Bonk:FireClient(player, item)
end

-- Look around one player's body and smash or bonk whatever is touching it.
function Smash.check(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root then
		return
	end
	local land = Land.get()
	local smash = land and land:FindFirstChild("Smashables")
	if not smash or not land:GetAttribute("Ready") then
		return
	end

	params.FilterDescendantsInstances = { smash }
	local size = player:GetAttribute("Size") or 1
	local scale = char:GetScale()
	local reach = Config.REACH * scale + 0.6
	local boxCF = root.CFrame * CFrame.new(0, -0.4 * scale, 0)
	local boxSize = Vector3.new(reach * 2, 6.4 * scale, reach * 2)
	local touched = workspace:GetPartBoundsInBox(boxCF, boxSize, params)

	local seen = {}
	for _, part in touched do
		local item = itemOf(part, smash)
		if item and not seen[item] then
			seen[item] = true
			local need = item:GetAttribute("Need") or 1
			if size + 1e-3 >= need then
				smashItem(item, player, root)
			else
				bonk(item, player)
			end
		end
	end
end

function Smash.forget(player: Player)
	lastBonk[player] = nil
end

return Smash
