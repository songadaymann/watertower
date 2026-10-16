--!nonstrict
-- Small helpers for building toy-like things out of primitive parts.
-- Everything is built around the origin with the ground at y = 0.

local Kit = {}
Kit.__index = Kit

local function toCFrame(at)
	if typeof(at) == "CFrame" then
		return at
	end
	return CFrame.new(at)
end

function Kit.new(name: string)
	local self = setmetatable({}, Kit)
	self.model = Instance.new("Model")
	self.model.Name = name
	self.created = {}
	return self
end

function Kit:_part(shape, size: Vector3, cf: CFrame, color: Color3, opts)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.CFrame = cf
	p.Color = color
	if opts then
		if opts.material then
			p.Material = opts.material
		end
		if opts.transparency then
			p.Transparency = opts.transparency
		end
		if opts.reflectance then
			p.Reflectance = opts.reflectance
		end
		if opts.name then
			p.Name = opts.name
		end
		if opts.shadow == false then
			p.CastShadow = false
		end
	end
	p.Parent = self.model
	table.insert(self.created, p)
	return p
end

function Kit:block(size: Vector3, at, color: Color3, opts)
	return self:_part(Enum.PartType.Block, size, toCFrame(at), color, opts)
end

function Kit:ball(d: number, at, color: Color3, opts)
	return self:_part(Enum.PartType.Ball, Vector3.new(d, d, d), toCFrame(at), color, opts)
end

-- Upright cylinder centered on `at`.
function Kit:cyl(d: number, h: number, at, color: Color3, opts)
	local cf = toCFrame(at) * CFrame.Angles(0, 0, math.pi / 2)
	return self:_part(Enum.PartType.Cylinder, Vector3.new(h, d, d), cf, color, opts)
end

-- Cylinder lying along the X axis of `at`.
function Kit:hcyl(d: number, len: number, at, color: Color3, opts)
	return self:_part(Enum.PartType.Cylinder, Vector3.new(len, d, d), toCFrame(at), color, opts)
end

-- Cylinder lying along the Z axis of `at` (wheels on a car that drives along Z, etc).
function Kit:zcyl(d: number, len: number, at, color: Color3, opts)
	local cf = toCFrame(at) * CFrame.Angles(0, math.pi / 2, 0)
	return self:_part(Enum.PartType.Cylinder, Vector3.new(len, d, d), cf, color, opts)
end

-- Cylinder running from point a to point b.
function Kit:rod(d: number, a: Vector3, b: Vector3, color: Color3, opts)
	local mid = (a + b) / 2
	if math.abs((b - a).Unit.Y) > 0.999 then
		return self:cyl(d, (b - a).Magnitude, mid, color, opts)
	end
	local cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0)
	return self:_part(Enum.PartType.Cylinder, Vector3.new((b - a).Magnitude, d, d), cf, color, opts)
end

-- Block running from point a to point b (beams, planks).
function Kit:beam(w: number, t: number, a: Vector3, b: Vector3, color: Color3, opts)
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b)
	return self:_part(Enum.PartType.Block, Vector3.new(w, t, (b - a).Magnitude), cf, color, opts)
end

function Kit:wedge(size: Vector3, at, color: Color3, opts)
	return self:_part(Enum.PartType.Wedge, size, toCFrame(at), color, opts)
end

-- A squashed or stretched ball.
function Kit:blob(size: Vector3, at, color: Color3, opts)
	local p = self:_part(Enum.PartType.Block, size, toCFrame(at), color, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Stepped cone: a stack of cylinders from baseD (bottom) to topD (top), sitting on `at`.
-- `colors` may be a single Color3 or a list that cycles per step (for stripes).
function Kit:cone(baseD: number, topD: number, h: number, at, colors, steps: number?, opts)
	local n = steps or 5
	local base = toCFrame(at)
	local stepH = h / n
	local parts = {}
	for i = 0, n - 1 do
		local t = i / math.max(n - 1, 1)
		local d = baseD + (topD - baseD) * t
		local color = if typeof(colors) == "table" then colors[i % #colors + 1] else colors
		table.insert(parts, self:cyl(d, stepH, base * CFrame.new(0, stepH * (i + 0.5), 0), color, opts))
	end
	return parts
end

-- Pitched roof from two wedges. Footprint w (along X, the ridge) by d (along Z), sitting on `at`.
function Kit:roof(w: number, d: number, h: number, at, color: Color3, opts)
	local base = toCFrame(at)
	local a = self:wedge(Vector3.new(w, h, d / 2), base * CFrame.new(0, h / 2, -d / 4), color, opts)
	local b = self:wedge(
		Vector3.new(w, h, d / 2),
		base * CFrame.new(0, h / 2, d / 4) * CFrame.Angles(0, math.pi, 0),
		color,
		opts
	)
	return a, b
end

-- Big friendly text on one face of a part.
function Kit:label(part: BasePart, face: Enum.NormalId, text: string, textColor: Color3, strokeColor: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0.3
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = textColor
	if strokeColor then
		local s = Instance.new("UIStroke")
		s.Color = strokeColor
		s.Thickness = 3
		s.Parent = t
	end
	t.Parent = gui
	gui.Parent = part
	return gui
end

-- Pivot at the origin (ground center) so PivotTo puts the thing on the ground.
function Kit:finish()
	self.model.WorldPivot = CFrame.new()
	return self.model
end

return Kit
