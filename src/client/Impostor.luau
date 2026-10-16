--!nonstrict
-- A flat picture of the water tower that stands in for it when you're far away.
-- Phones and tablets on lower graphics settings stop drawing parts past a few hundred studs,
-- but billboards always draw, so the tower stays on the horizon from the very start.
--
-- The picture is a front view (looking +Z, like from the spawn) projected from the tower's own parts.

local Players = game:GetService("Players")

local Impostor = {}

local SHOW_BEYOND = 420

local current = nil -- { gui, anchor, tower }

local function frame(parent, cx, cy, w, h, rot, color, round, z)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(cx, cy)
	f.Size = UDim2.fromScale(w, h)
	f.Rotation = rot
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z
	if round then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
	end
	f.Parent = parent
	return f
end

local function isRound(part: BasePart)
	if part.Shape == Enum.PartType.Ball then
		return true
	end
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	return mesh ~= nil and mesh.MeshType == Enum.MeshType.Sphere
end

function Impostor.clear()
	if current then
		current.gui:Destroy()
		current.anchor:Destroy()
		current = nil
	end
end

function Impostor.build(tower: Model)
	Impostor.clear()
	local cf, size = tower:GetBoundingBox()
	local W, H = size.X * 1.1, size.Y * 1.04
	local cx, cy = cf.Position.X, cf.Position.Y

	local anchor = Instance.new("Part")
	anchor.Name = "TowerImpostorAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = cf.Position
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Name = "TowerImpostor"
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0.6
	gui.Size = UDim2.fromScale(W, H)
	gui.Adornee = anchor
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Farther parts first, so nearer ones draw on top.
	local parts = {}
	for _, p in tower:GetDescendants() do
		if p:IsA("BasePart") and (p.Transparency < 0.9 or p.Name == "Letter") and p.Name ~= "SparklePart" then
			table.insert(parts, p)
		end
	end
	table.sort(parts, function(a, b)
		return a.Position.Z > b.Position.Z
	end)

	for i, p in parts do
		-- Front view: screen-right is world -X, screen-up is world +Y.
		local u = 0.5 - (p.Position.X - cx) / W
		local v = 0.5 - (p.Position.Y - cy) / H
		local half = p.Size / 2
		local axes = {
			Vector2.new(-p.CFrame.XVector.X, p.CFrame.XVector.Y) * half.X,
			Vector2.new(-p.CFrame.YVector.X, p.CFrame.YVector.Y) * half.Y,
			Vector2.new(-p.CFrame.ZVector.X, p.CFrame.ZVector.Y) * half.Z,
		}
		if p.Name == "Letter" then
			-- Only letters facing the spawn side.
			if p.CFrame.LookVector.Z < -0.3 then
				local gui2 = p:FindFirstChildOfClass("SurfaceGui")
				local label = gui2 and gui2:FindFirstChildOfClass("TextLabel")
				if label then
					local t = Instance.new("TextLabel")
					t.AnchorPoint = Vector2.new(0.5, 0.5)
					t.Position = UDim2.fromScale(u, v)
					t.Size = UDim2.fromScale(p.Size.X / W * math.abs(p.CFrame.LookVector.Z), p.Size.Y / H)
					t.BackgroundTransparency = 1
					t.Font = label.Font
					t.Text = label.Text
					t.TextScaled = true
					t.TextColor3 = label.TextColor3
					t.ZIndex = i + 1000
					t.Parent = gui
				end
			end
		elseif isRound(p) then
			local w = math.abs(axes[1].X) + math.abs(axes[2].X) + math.abs(axes[3].X)
			local h = math.abs(axes[1].Y) + math.abs(axes[2].Y) + math.abs(axes[3].Y)
			frame(gui, u, v, w * 2 / W, h * 2 / H, 0, p.Color, true, i)
		else
			-- Draw as a (possibly tilted) bar along its longest on-screen axis.
			table.sort(axes, function(a, b)
				return a.Magnitude > b.Magnitude
			end)
			local long = axes[1]
			if long.Magnitude < 1e-3 then
				continue
			end
			local dir = long.Unit
			local perp = Vector2.new(-dir.Y, dir.X)
			local thick = math.abs(axes[2]:Dot(perp)) + math.abs(axes[3]:Dot(perp))
			if p.Shape == Enum.PartType.Cylinder and math.abs(p.CFrame.XVector.Z) > 0.9 then
				-- A cylinder pointing at the camera looks like a circle.
				local d = p.Size.Y
				frame(gui, u, v, d / W, d / H, 0, p.Color, true, i)
			else
				-- The gui is W×H studs, so one stud is the same number of pixels both ways and a
				-- frame sized (len/W, thick/H) keeps its true shape when rotated. Screen y points down.
				local angle = math.deg(math.atan2(-dir.Y, dir.X))
				frame(gui, u, v, long.Magnitude * 2 / W, math.max(thick * 2, 0.3) / H, angle, p.Color, false, i)
			end
		end
	end

	current = { gui = gui, anchor = anchor, tower = tower }
end

-- Call every so often: shows the picture only when the camera is far from the tower.
function Impostor.update()
	if not current then
		return
	end
	local tower = current.tower
	if not tower.Parent or tower:GetAttribute("Smashed") then
		Impostor.clear()
		return
	end
	local cam = workspace.CurrentCamera
	current.gui.Enabled = (cam.CFrame.Position - current.anchor.Position).Magnitude > SHOW_BEYOND
end

return Impostor
