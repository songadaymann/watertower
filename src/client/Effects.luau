--!nonstrict
-- Client-only juice: puffs, flying stars, wobbles, sounds, camera shake, the big splash, and a rainbow.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Effects = {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local rng = Random.new()

local fx = Instance.new("Folder")
fx.Name = "ClientEffects"
fx.Parent = workspace

local function kp(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

local function anchor(pos: Vector3, size: Vector3?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size or Vector3.one
	p.Position = pos
	p.Parent = fx
	return p
end

Effects.muted = false

function Effects.play(id: string, volume: number?, pitch: number?)
	if Effects.muted then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 12)
	return s
end

function Effects.burst(pos: Vector3, extent: number, color: Color3)
	local p = anchor(pos)
	local puff = Instance.new("ParticleEmitter")
	puff.Texture = SMOKE
	puff.Enabled = false
	puff.Color = ColorSequence.new(Color3.new(1, 1, 1))
	puff.Size = NumberSequence.new({ kp(0, extent * 0.25), kp(1, extent * 0.6) })
	puff.Transparency = NumberSequence.new({ kp(0, 0.15), kp(1, 1) })
	puff.Lifetime = NumberRange.new(0.5, 0.9)
	puff.Speed = NumberRange.new(extent * 1, extent * 2.5)
	puff.SpreadAngle = Vector2.new(180, 180)
	puff.Drag = 4
	puff.Parent = p
	puff:Emit(math.clamp(math.floor(extent * 1.2), 6, 30))

	local stars = Instance.new("ParticleEmitter")
	stars.Texture = SPARKLE
	stars.Enabled = false
	stars.Color = ColorSequence.new(color, Color3.fromRGB(255, 250, 170))
	stars.LightEmission = 1
	stars.Size = NumberSequence.new({ kp(0, extent * 0.14), kp(1, 0) })
	stars.Speed = NumberRange.new(extent * 1.5, extent * 3)
	stars.Lifetime = NumberRange.new(0.6, 1.1)
	stars.Acceleration = Vector3.new(0, -extent * 3, 0)
	stars.SpreadAngle = Vector2.new(180, 180)
	stars.Parent = p
	stars:Emit(22)
	Debris:AddItem(p, 2.5)
end

-- Glowing stars that fly from `from` into your character, then call onArrive.
function Effects.stars(from: Vector3, count: number, starSize: number, onArrive: (() -> ())?)
	local player = Players.LocalPlayer
	for i = 1, count do
		local s = Instance.new("Part")
		s.Shape = Enum.PartType.Ball
		s.Anchored = true
		s.CanCollide = false
		s.CanQuery = false
		s.CanTouch = false
		s.Material = Enum.Material.Neon
		s.Color = Color3.fromRGB(255, 225, 90)
		s.Size = Vector3.one * starSize
		local start = from + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0, 1), rng:NextNumber(-1, 1)) * starSize * 3
		s.Position = start
		s.Parent = fx
		local t0 = os.clock() + i * 0.035
		local dur = 0.55
		local arc = starSize * rng:NextNumber(6, 12)
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local t = (os.clock() - t0) / dur
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or t >= 1 then
				conn:Disconnect()
				s:Destroy()
				if root and onArrive then
					onArrive()
				end
				return
			end
			if t < 0 then
				return
			end
			local e = t * t
			s.Position = start:Lerp(root.Position, e) + Vector3.new(0, math.sin(t * math.pi) * arc, 0)
		end)
	end
end

local wobbling = {}

-- Shake something that's still too big to smash.
function Effects.wobble(item: Instance)
	if wobbling[item] or not item.Parent then
		return
	end
	wobbling[item] = true
	local originals = {}
	for _, d in item:GetDescendants() do
		if d:IsA("BasePart") and d.Anchored then
			originals[d] = d.CFrame
		end
	end
	local pivot = item:GetPivot()
	local a = rng:NextNumber() * math.pi * 2
	local axis = Vector3.new(math.cos(a), 0, math.sin(a))
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local done = t > 0.5 or item:GetAttribute("Smashed") or not item.Parent
		local angle = done and 0 or math.sin(t * 38) * 0.06 * (1 - t / 0.5)
		local rot = pivot * CFrame.fromAxisAngle(axis, angle) * pivot:Inverse()
		for p, cf in originals do
			if p.Anchored then
				p.CFrame = rot * cf
			end
		end
		if done then
			conn:Disconnect()
			wobbling[item] = nil
		end
	end)
end

-- A floating "💪" over something you need to be bigger for.
function Effects.popup(item: Instance, text: string, sub: string?)
	local ok, cf, size = pcall(item.GetBoundingBox, item)
	if not ok then
		return
	end
	local p = anchor(cf.Position + Vector3.new(0, size.Y / 2 + 1, 0))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 120)
	bb.AlwaysOnTop = true
	bb.Adornee = p
	bb.Parent = p
	local big = Instance.new("TextLabel")
	big.BackgroundTransparency = 1
	big.Size = UDim2.new(1, 0, 0.7, 0)
	big.Font = Enum.Font.FredokaOne
	big.TextScaled = true
	big.Text = text
	big.Parent = bb
	if sub then
		local small = Instance.new("TextLabel")
		small.BackgroundTransparency = 1
		small.Position = UDim2.fromScale(0, 0.7)
		small.Size = UDim2.new(1, 0, 0.3, 0)
		small.Font = Enum.Font.FredokaOne
		small.TextScaled = true
		small.TextColor3 = Color3.new(1, 1, 1)
		small.Text = sub
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = Color3.fromRGB(25, 60, 130)
		st.Parent = small
		small.Parent = bb
	end
	TweenService:Create(bb, TweenInfo.new(1.3, Enum.EasingStyle.Quad), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	task.delay(0.9, function()
		for _, l in bb:GetChildren() do
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			local st = l:FindFirstChildOfClass("UIStroke")
			if st then
				TweenService:Create(st, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			end
		end
	end)
	Debris:AddItem(p, 1.5)
end

local shakeAmp, shakeEnd, shakeLen = 0, 0, 1
function Effects.shake(amount: number, duration: number)
	local now = os.clock()
	if amount > shakeAmp * math.max(0, (shakeEnd - now) / shakeLen) then
		shakeAmp, shakeEnd, shakeLen = amount, now + duration, duration
	end
end

RunService.RenderStepped:Connect(function()
	local char = Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local left = shakeEnd - os.clock()
	if left > 0 then
		local a = shakeAmp * left / shakeLen
		hum.CameraOffset = Vector3.new(rng:NextNumber(-a, a), rng:NextNumber(-a, a), rng:NextNumber(-a, a))
	elseif hum.CameraOffset ~= Vector3.zero then
		hum.CameraOffset = Vector3.zero
	end
end)

-- The big one: water everywhere.
function Effects.splash(pos: Vector3, radius: number)
	local spray = anchor(pos + Vector3.new(0, 3, 0), Vector3.new(radius * 0.8, 1, radius * 0.8))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = SMOKE
	pe.Enabled = false
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Color = ColorSequence.new(Color3.fromRGB(150, 215, 255), Color3.fromRGB(235, 248, 255))
	pe.Size = NumberSequence.new({ kp(0, 6), kp(0.5, 12), kp(1, 4) })
	pe.Transparency = NumberSequence.new({ kp(0, 0.1), kp(0.8, 0.4), kp(1, 1) })
	pe.Lifetime = NumberRange.new(2.2, 3.6)
	pe.Speed = NumberRange.new(60, 140)
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Acceleration = Vector3.new(0, -70, 0)
	pe.Drag = 0.4
	pe.Parent = spray
	pe:Emit(160)

	local drops = Instance.new("ParticleEmitter")
	drops.Texture = SPARKLE
	drops.Enabled = false
	drops.Shape = Enum.ParticleEmitterShape.Box
	drops.EmissionDirection = Enum.NormalId.Top
	drops.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255))
	drops.LightEmission = 0.6
	drops.Size = NumberSequence.new({ kp(0, 3), kp(1, 1) })
	drops.Lifetime = NumberRange.new(2.5, 4)
	drops.Speed = NumberRange.new(80, 170)
	drops.SpreadAngle = Vector2.new(45, 45)
	drops.Acceleration = Vector3.new(0, -90, 0)
	drops.Parent = spray
	drops:Emit(220)
	Debris:AddItem(spray, 6)

	-- A dome of water that swells and fades.
	local dome = Instance.new("Part")
	dome.Shape = Enum.PartType.Ball
	dome.Anchored = true
	dome.CanCollide = false
	dome.CanQuery = false
	dome.CanTouch = false
	dome.Material = Enum.Material.Glass
	dome.Color = Color3.fromRGB(110, 190, 255)
	dome.Transparency = 0.35
	dome.Size = Vector3.one * 10
	dome.Position = pos
	dome.Parent = fx
	TweenService:Create(dome, TweenInfo.new(1.4, Enum.EasingStyle.Quad), { Size = Vector3.one * radius * 2.2, Transparency = 1 }):Play()
	Debris:AddItem(dome, 1.6)

	-- A ring of foam racing outward.
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Color = Color3.new(1, 1, 1)
	ring.Material = Enum.Material.SmoothPlastic
	ring.Transparency = 0.2
	ring.Size = Vector3.new(1, 10, 10)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = fx
	TweenService:Create(ring, TweenInfo.new(1.8, Enum.EasingStyle.Quart), { Size = Vector3.new(1, radius * 3.2, radius * 3.2), Transparency = 1 }):Play()
	Debris:AddItem(ring, 2)
end

-- A rainbow arching over the splash, facing the camera.
function Effects.rainbow(pos: Vector3, radius: number)
	local cam = workspace.CurrentCamera
	local look = (pos - cam.CFrame.Position) * Vector3.new(1, 0, 1)
	if look.Magnitude < 1 then
		look = Vector3.new(0, 0, 1)
	end
	local base = CFrame.lookAt(pos, pos + look.Unit)
	local colors = {
		Color3.fromRGB(255, 70, 70),
		Color3.fromRGB(255, 160, 50),
		Color3.fromRGB(255, 230, 70),
		Color3.fromRGB(90, 210, 90),
		Color3.fromRGB(70, 150, 255),
		Color3.fromRGB(160, 90, 230),
	}
	local band = radius * 0.09
	local model = Instance.new("Model")
	model.Name = "Rainbow"
	local parts = {}
	for i, c in colors do
		local r = radius * 1.5 - (i - 1) * band
		local n = 30
		for j = 0, n - 1 do
			local a0 = j / n * math.pi
			local a1 = (j + 1) / n * math.pi
			local mid = (a0 + a1) / 2
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = c
			p.Transparency = 1
			p.Size = Vector3.new(r * (a1 - a0) * 1.08, band, band * 0.5)
			p.CFrame = base * CFrame.new(math.cos(mid) * r, math.sin(mid) * r, 0) * CFrame.Angles(0, 0, mid + math.pi / 2)
			p.Parent = model
			table.insert(parts, p)
		end
	end
	model.Parent = fx
	for _, p in parts do
		TweenService:Create(p, TweenInfo.new(1.5), { Transparency = 0.35 }):Play()
	end
	task.delay(12, function()
		for _, p in parts do
			TweenService:Create(p, TweenInfo.new(2), { Transparency = 1 }):Play()
		end
		task.wait(2.1)
		model:Destroy()
	end)
end

return Effects
