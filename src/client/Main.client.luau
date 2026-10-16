--!nonstrict
-- Client: the meter, sparkles on things you can smash, the camera pulling back as you grow,
-- a marker over the water tower, music, and all the celebrating.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("WaterTowerShared"):WaitForChild("Config"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Impostor = require(script.Parent:WaitForChild("Impostor"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("WaterTowerRemotes")
local hud = Hud.new(player)
local rng = Random.new()

local function mySize(): number
	return player:GetAttribute("Size") or Config.START_SIZE
end

local function myRoot(): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------- Music

local MUSIC_VOLUME = 0.22
local music = Instance.new("Sound")
music.Name = "Music"
music.Looped = true
music.Volume = MUSIC_VOLUME
music.Parent = SoundService

-- A sound on/off button. Starts muted in Studio playtests so testing stays quiet.
local muteButton = Instance.new("TextButton")
muteButton.Name = "MuteButton"
muteButton.AnchorPoint = Vector2.new(1, 0)
muteButton.Position = UDim2.new(1, -18, 0, 70)
muteButton.Size = UDim2.fromOffset(56, 56)
muteButton.BackgroundColor3 = Color3.new(1, 1, 1)
muteButton.BackgroundTransparency = 0.2
muteButton.Font = Enum.Font.FredokaOne
muteButton.TextScaled = true
local muteCorner = Instance.new("UICorner")
muteCorner.CornerRadius = UDim.new(0.5, 0)
muteCorner.Parent = muteButton
muteButton.Parent = hud.gui

local function setMuted(muted: boolean)
	Effects.muted = muted
	music.Volume = muted and 0 or MUSIC_VOLUME
	muteButton.Text = muted and "🔇" or "🔊"
end
muteButton.Activated:Connect(function()
	setMuted(not Effects.muted)
end)
setMuted(RunService:IsStudio())

local function playMusic(biome: string?)
	local id = biome and Config.Music[biome]
	if id and music.SoundId ~= id then
		music.SoundId = id
		music.TimePosition = 0
		music:Play()
	end
end

---------------------------------------------------------------- Camera pulls back as you grow

local zoomTarget = Config.cameraZoomFor(mySize())
local zoomShown = zoomTarget
local pushing = false

RunService.RenderStepped:Connect(function(dt)
	if zoomTarget > zoomShown + 0.05 then
		zoomShown += (zoomTarget - zoomShown) * math.min(1, dt * 3)
		player.CameraMinZoomDistance = zoomShown
		pushing = true
	elseif pushing then
		pushing = false
		zoomShown = zoomTarget
		player.CameraMinZoomDistance = 0.5
	end
end)

local function resetZoom()
	zoomTarget = Config.cameraZoomFor(mySize())
	zoomShown = zoomTarget
	pushing = false
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = zoomTarget
	task.delay(0.4, function()
		player.CameraMaxZoomDistance = math.max(80, zoomTarget * 4)
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(0.1)
	resetZoom()
end)
if player.Character then
	resetZoom()
end

---------------------------------------------------------------- Growing

local lastSize = mySize()
player:GetAttributeChangedSignal("Size"):Connect(function()
	local size = mySize()
	hud:setSize(size)
	zoomTarget = Config.cameraZoomFor(size)
	player.CameraMaxZoomDistance = math.max(80, zoomTarget * 4)
	if size > lastSize then
		for _, need in Config.GATE_NEED do
			if lastSize + 1e-3 < need and size + 1e-3 >= need then
				hud:showBanner("You can smash the WALL! 🧱", 3)
				Effects.play(Config.Sounds.Arrive, 0.7)
			end
		end
		if lastSize + 1e-3 < Config.TOWER_NEED and size + 1e-3 >= Config.TOWER_NEED then
			hud:showBanner("Big enough for the WATER TOWER! 💦", 4, Color3.fromRGB(255, 240, 120))
			Effects.play(Config.Sounds.Cheer, 0.8)
		end
	end
	lastSize = size
end)
hud:setSize(mySize())

player:GetAttributeChangedSignal("Towers"):Connect(function()
	hud:setTrophies(player:GetAttribute("Towers") or 0)
end)
hud:setTrophies(player:GetAttribute("Towers") or 0)

---------------------------------------------------------------- Sparkles on things you can smash

local emitters = setmetatable({}, { __mode = "k" })

task.spawn(function()
	while true do
		local land = workspace:FindFirstChild("Land")
		local smash = land and land:FindFirstChild("Smashables")
		local root = myRoot()
		if smash and root then
			local size = mySize()
			local range = 260 + size * 40
			for _, item in smash:GetChildren() do
				local pe = emitters[item]
				if not pe then
					local sp = item:FindFirstChild("SparklePart")
					pe = sp and sp:FindFirstChild("Sparkle")
					emitters[item] = pe
				end
				if pe then
					local need = item:GetAttribute("Need") or 1
					local near = (item:GetPivot().Position - root.Position).Magnitude < range
					pe.Enabled = near and size + 1e-3 >= need
				end
			end
		end
		task.wait(0.35)
	end
end)

---------------------------------------------------------------- Marker over the water tower (and later the portal)

local marker = Instance.new("BillboardGui")
marker.Name = "TowerMarker"
marker.AlwaysOnTop = true
marker.Size = UDim2.fromOffset(110, 120)
marker.Enabled = false
marker.Parent = player:WaitForChild("PlayerGui")
local markerIcon = Instance.new("TextLabel")
markerIcon.BackgroundTransparency = 1
markerIcon.Size = UDim2.fromScale(1, 0.62)
markerIcon.Font = Enum.Font.FredokaOne
markerIcon.TextScaled = true
markerIcon.Text = "💧"
markerIcon.Parent = marker
local markerArrow = Instance.new("TextLabel")
markerArrow.BackgroundTransparency = 1
markerArrow.Position = UDim2.fromScale(0, 0.6)
markerArrow.Size = UDim2.fromScale(1, 0.4)
markerArrow.Font = Enum.Font.FredokaOne
markerArrow.TextScaled = true
markerArrow.TextColor3 = Color3.fromRGB(255, 230, 80)
markerArrow.Text = "▼"
markerArrow.Parent = marker
local arrowStroke = Instance.new("UIStroke")
arrowStroke.Thickness = 3
arrowStroke.Color = Color3.fromRGB(25, 60, 130)
arrowStroke.Parent = markerArrow

local function findTowerBeacon(land)
	local smash = land and land:FindFirstChild("Smashables")
	local tower = smash and smash:FindFirstChild("WaterTower")
	return tower and tower:FindFirstChild("Beacon")
end

local blinkOn = true
task.spawn(function()
	while true do
		local land = workspace:FindFirstChild("Land")
		local portal = land and land:FindFirstChild("Portal")
		local beacon = findTowerBeacon(land)
		if portal and portal:FindFirstChild("Disk") then
			marker.Adornee = portal.Disk
			marker.StudsOffsetWorldSpace = Vector3.new(0, (portal:GetAttribute("Radius") or 20) + 8, 0)
			markerIcon.Text = "✨"
			markerArrow.Text = "▼"
			marker.Enabled = true
		elseif beacon then
			marker.Adornee = beacon
			marker.StudsOffsetWorldSpace = Vector3.new(0, 14, 0)
			local ready = mySize() + 1e-3 >= Config.TOWER_NEED
			markerIcon.Text = ready and "💦" or "💧"
			markerArrow.Text = ready and "GO!" or "▼"
			marker.Size = ready and UDim2.fromOffset(150, 150) or UDim2.fromOffset(90, 100)
			marker.Enabled = true
			blinkOn = not blinkOn
			beacon.Transparency = blinkOn and 0 or 0.75
		else
			marker.Enabled = false
		end
		Impostor.update()
		task.wait(0.5)
	end
end)

RunService.RenderStepped:Connect(function()
	if marker.Enabled then
		marker.StudsOffset = Vector3.new(0, math.abs(math.sin(os.clock() * 4)) * 1.5, 0)
	end
end)

---------------------------------------------------------------- Snow falling in the snowy land

local snowPart = Instance.new("Part")
snowPart.Name = "Snowfall"
snowPart.Anchored = true
snowPart.CanCollide = false
snowPart.CanQuery = false
snowPart.CanTouch = false
snowPart.Transparency = 1
snowPart.Size = Vector3.new(260, 1, 260)
local snow = Instance.new("ParticleEmitter")
snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
snow.Rate = 160
snow.Lifetime = NumberRange.new(5, 8)
snow.Speed = NumberRange.new(8, 14)
snow.EmissionDirection = Enum.NormalId.Bottom
snow.SpreadAngle = Vector2.new(20, 20)
snow.Size = NumberSequence.new(0.6)
snow.LightEmission = 0.4
snow.Enabled = false
snow.Parent = snowPart
snowPart.Parent = workspace

RunService.RenderStepped:Connect(function()
	if snow.Enabled then
		snowPart.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 60, 0)
	end
end)

---------------------------------------------------------------- A new land appears

local currentLand = nil

local function onLand(land: Instance)
	if land == currentLand then
		return
	end
	currentLand = land
	while land.Parent and not land:GetAttribute("Ready") do
		task.wait(0.1)
	end
	if not land.Parent or currentLand ~= land then
		return
	end
	table.clear(emitters)
	lastSize = mySize()
	local town = land:GetAttribute("TownName") or "Water Town"
	hud:setTownName(town)
	playMusic(land:GetAttribute("Biome"))
	snow.Enabled = land:GetAttribute("Biome") == "Snow"
	local tower = land:FindFirstChild("Smashables") and land.Smashables:FindFirstChild("WaterTower")
	if tower then
		Impostor.build(tower)
	end
	task.delay(2, function()
		if currentLand == land then
			hud:showBanner("Welcome to " .. town .. "!", 3.5)
			Effects.play(Config.Sounds.Arrive, 0.6)
		end
	end)
	task.delay(6.5, function()
		if currentLand == land and mySize() < 1.3 then
			hud:showBanner("Smash things to grow BIG! 💪", 3.5)
		end
	end)
end

workspace.ChildAdded:Connect(function(c)
	if c.Name == "Land" then
		task.spawn(onLand, c)
	end
end)
if workspace:FindFirstChild("Land") then
	task.spawn(onLand, workspace.Land)
end

---------------------------------------------------------------- Server events

remotes.Smashed.OnClientEvent:Connect(function(info)
	local root = myRoot()
	local mine = info.userId == player.UserId
	local dist = root and (root.Position - info.pos).Magnitude or 0
	Effects.burst(info.pos, info.extent, info.color)
	if mine or dist < 300 then
		local pitch = math.clamp(1.5 - info.extent / 50, 0.6, 1.5) * rng:NextNumber(0.92, 1.08)
		Effects.play(Config.Sounds.Pop, mine and 0.7 or 0.35, pitch)
		if info.extent >= 12 or info.kind == "Gate" then
			Effects.play(Config.Sounds.Crash, 0.5, math.clamp(1.2 - info.extent / 80, 0.6, 1.1))
		end
	end
	if mine then
		local size = mySize()
		local n = math.clamp(math.floor(info.gain * 25), 3, 12)
		Effects.stars(info.pos, n, 0.35 * size + 0.2, function()
			hud:bump()
		end)
		if info.extent >= 20 or info.kind == "Gate" then
			Effects.shake(0.15 * size, 0.4)
		end
	end
end)

remotes.Bonk.OnClientEvent:Connect(function(item)
	if not item or not item.Parent then
		return
	end
	Effects.wobble(item)
	Effects.play(Config.Sounds.Boing, 0.5, rng:NextNumber(0.9, 1.1))
	local kind = item:GetAttribute("Kind")
	Effects.popup(item, "💪", kind == "Tower" and "Grow BIGGER first!" or "Too big! Grow more!")
end)

remotes.TowerFalling.OnClientEvent:Connect(function()
	Effects.shake(0.3 * mySize(), 1.2)
	hud:showBanner("WHOOOAAA!", 1.6)
	Effects.play(Config.Sounds.Crash, 0.8, 0.6)
end)

remotes.TowerSplash.OnClientEvent:Connect(function(info)
	Effects.splash(info.pos, info.radius)
	Effects.play(Config.Sounds.TankImpact, 0.9)
	Effects.play(Config.Sounds.Splash, 1)
	Effects.play(Config.Sounds.SplashSmall, 0.6, 0.6)
	task.delay(0.4, function()
		Effects.play(Config.Sounds.Cheer, 0.9)
	end)
	Effects.shake(0.5 * mySize(), 1.4)
	hud:showBanner("SPLASH!!!", 2.5, Color3.fromRGB(150, 220, 255))
	hud:confetti(110)
	task.delay(1.2, function()
		Effects.rainbow(info.pos, info.radius)
	end)
	task.delay(3, function()
		hud:showBanner("You knocked down the water tower!", 3.5)
	end)
	task.delay(7.5, function()
		hud:showBanner("Jump in the magic ring! ✨", 4)
	end)
end)

remotes.Fade.OnClientEvent:Connect(function(on)
	hud:fade(on)
	if on then
		Effects.play(Config.Sounds.Magic, 0.8)
	end
end)
