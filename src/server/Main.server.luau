--!nonstrict
-- Water Tower Smash: grow by smashing stuff until you're big enough to knock down the water tower.
-- Then hop through the portal to a brand new land.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("WaterTowerShared"):WaitForChild("Config"))
local Biomes = require(script.Parent.Biomes)
local Land = require(script.Parent.Land)
local Smash = require(script.Parent.Smash)

PhysicsService:RegisterCollisionGroup("Debris")
PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:CollisionGroupSetCollidable("Debris", "Players", false)
PhysicsService:CollisionGroupSetCollidable("Debris", "Debris", false)

local remotes = Instance.new("Folder")
remotes.Name = "WaterTowerRemotes"
for _, name in { "Smashed", "Bonk", "TowerFalling", "TowerSplash", "Fade", "LandReady" } do
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local debris = Instance.new("Folder")
debris.Name = "SmashDebris"
debris.Parent = workspace

Smash.remotes = remotes
Smash.debris = debris

Players.CharacterAutoLoads = false

local landCount = 0
local currentBiome: string? = nil
local busy = true

local function pickBiome(): string
	local options = {}
	for _, name in Biomes.ORDER do
		if name ~= currentBiome then
			table.insert(options, name)
		end
	end
	return options[math.random(1, #options)]
end

local function buildLand()
	landCount += 1
	currentBiome = pickBiome()
	Land.generate(currentBiome, (os.time() * 31 + landCount * 7919) % 2 ^ 31)
end

---------------------------------------------------------------- Characters

-- When each player's next growth pop is due (see popGrow).
local POP_DELAY = 0.45
local popAt: { [Player]: number } = {}

local function applySize(char: Model, size: number)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	hum.UseJumpPower = true
	hum.WalkSpeed = Config.walkSpeedFor(size)
	hum.JumpPower = Config.jumpPowerFor(size)
end

local function setupCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	local function group(p)
		if p:IsA("BasePart") then
			p.CollisionGroup = "Players"
		end
	end
	for _, p in char:GetDescendants() do
		group(p)
	end
	char.DescendantAdded:Connect(group)

	hum.Died:Connect(function()
		task.delay(2.5, function()
			if player.Parent and player.Character == char then
				player:LoadCharacter()
			end
		end)
	end)

	-- Wait for hats and hair so they scale along with the body.
	if not player:HasAppearanceLoaded() then
		local done = false
		local conn = player.CharacterAppearanceLoaded:Connect(function()
			done = true
		end)
		local t0 = os.clock()
		while not done and os.clock() - t0 < 4 do
			task.wait(0.1)
		end
		conn:Disconnect()
	end
	if not char.Parent then
		return
	end
	local size = player:GetAttribute("Size") or Config.START_SIZE
	if math.abs(size - 1) > 1e-3 then
		char:ScaleTo(size)
	end
	applySize(char, size)
	char:SetAttribute("ScaleReady", true)
end

local function waitForLand()
	while busy or not (Land.get() and Land.get():GetAttribute("Ready")) do
		task.wait(0.2)
	end
end

local function onPlayerAdded(player: Player)
	player:SetAttribute("Size", Config.START_SIZE)
	player:SetAttribute("Towers", 0)
	player:GetAttributeChangedSignal("Size"):Connect(function()
		if not popAt[player] then
			popAt[player] = os.clock() + POP_DELAY
		end
	end)
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
	waitForLand()
	if player.Parent then
		player:LoadCharacter()
	end
end

-- Grow in pops: a moment after a smash (when the stars reach you), snap to the new size.
-- Resizing every frame kept layered clothing invisible while it re-fit, and moving a
-- player-controlled character from the server fights its own movement. So the server only
-- resizes, and each player's client keeps its own feet on the ground.
local function popGrow(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0 and char:GetAttribute("ScaleReady")) then
		return
	end
	local target = player:GetAttribute("Size") or Config.START_SIZE
	if math.abs(target - char:GetScale()) < 1e-3 then
		return
	end
	char:ScaleTo(target)
	applySize(char, target)
	-- Clients flash a rainbow on whoever just grew.
	char:SetAttribute("GrowPulse", (char:GetAttribute("GrowPulse") or 0) + 1)
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for player, t in popAt do
		if now >= t then
			popAt[player] = nil
			popGrow(player)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	popAt[player] = nil
	Smash.forget(player)
end)

-- Check what everyone is touching ten times a second.
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		return
	end
	acc = 0
	for _, player in Players:GetPlayers() do
		Smash.check(player)
	end
end)

---------------------------------------------------------------- Portal to the next land

local function nextLand()
	if busy then
		return
	end
	busy = true
	remotes.Fade:FireAllClients(true)
	task.wait(1.3)
	buildLand()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Size", Config.START_SIZE)
		task.spawn(player.LoadCharacter, player)
	end
	task.wait(0.8)
	busy = false
	remotes.Fade:FireAllClients(false)
	remotes.LandReady:FireAllClients()
end

local function spawnPortal(at: Vector3)
	local land = Land.get()
	if not land then
		return
	end
	local biggest = 1
	for _, player in Players:GetPlayers() do
		biggest = math.max(biggest, player:GetAttribute("Size") or 1)
	end
	local radius = math.max(14, 3.4 * biggest)
	local center = at + Vector3.new(0, radius + 2, 0)

	-- Stand the ring up facing whoever is closest.
	local nearest, nearestDist = nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - at).Magnitude < nearestDist then
			nearest, nearestDist = root.Position, (root.Position - at).Magnitude
		end
	end
	local facing = nearest and (nearest - at) * Vector3.new(1, 0, 1) or Vector3.new(0, 0, -1)
	if facing.Magnitude < 1 then
		facing = Vector3.new(0, 0, -1)
	end
	local frame = CFrame.lookAt(center, center + facing.Unit)

	local model = Instance.new("Model")
	model.Name = "Portal"
	local function part(size, cf, color, material)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.Neon
		p.Parent = model
		return p
	end
	local n = 36
	for i = 1, n do
		local a = i / n * math.pi * 2
		part(
			Vector3.new(radius * 2 * math.pi / n * 1.15, radius * 0.13, radius * 0.13),
			frame * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a + math.pi / 2),
			Color3.fromHSV(i / n, 0.55, 1)
		)
	end
	local disk = part(
		Vector3.new(0.6, radius * 2, radius * 2),
		frame * CFrame.Angles(0, math.pi / 2, 0),
		Color3.fromRGB(120, 210, 255),
		Enum.Material.ForceField
	)
	disk.Name = "Disk"
	disk.Shape = Enum.PartType.Cylinder
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Speed = NumberRange.new(2, 8)
	pe.Size = NumberSequence.new(radius * 0.06)
	pe.LightEmission = 1
	pe.Parent = disk
	model:SetAttribute("Radius", radius)
	model.Parent = land
	land:SetAttribute("PortalPos", center)

	-- You have to walk into it: anyone already standing inside when it appears must step out first.
	task.spawn(function()
		local wasOutside = {}
		while model.Parent and not busy do
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local d = (root.Position - center).Magnitude
					if d > radius * 1.2 then
						wasOutside[player] = true
					elseif d < radius and wasOutside[player] then
						task.spawn(nextLand)
						return
					end
				end
			end
			task.wait(0.15)
		end
	end)
end

Smash.onTowerDown = function(_base: Vector3, pond: Vector3)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Towers", (player:GetAttribute("Towers") or 0) + 1)
	end
	-- Let the splash, rainbow, and cheering play out before the portal shows up in the pond.
	task.wait(7)
	spawnPortal(pond)
end

---------------------------------------------------------------- Start

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

buildLand()
busy = false
remotes.LandReady:FireAllClients()
