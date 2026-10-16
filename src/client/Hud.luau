--!nonstrict
-- On-screen stuff: a little water tower that fills with water as you grow,
-- a row of water tower trophies, big banners, confetti, and the watery fade between lands.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("WaterTowerShared"):WaitForChild("Config"))

local FONT = Enum.Font.FredokaOne
local WATER = Color3.fromRGB(60, 160, 255)
local INK = Color3.fromRGB(25, 60, 130)

local Hud = {}
Hud.__index = Hud

local function make(className: string, props, children)
	local inst = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(r)
	return make("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(color, thickness)
	return make("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function textStroke(color, thickness)
	return make("UIStroke", { Color = color, Thickness = thickness })
end

-- A tiny water tower made of frames. Returns the root frame and the fill frame.
local function towerIcon(parent, size: Vector2, tankColor: Color3, roofColor: Color3)
	local w, h = size.X, size.Y
	local root = make("Frame", { Parent = parent, BackgroundTransparency = 1, Size = UDim2.fromOffset(w, h) })
	local tankW, tankH = w * 0.86, h * 0.42
	local tankY = h * 0.2
	local roofSide = tankW * 0.62
	make("Frame", {
		Parent = root,
		BackgroundColor3 = roofColor,
		Size = UDim2.fromOffset(roofSide, roofSide),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(w / 2, tankY + roofSide * 0.28),
		Rotation = 45,
		ZIndex = 1,
	}, { stroke(INK, math.max(1, w / 40)) })
	local tank = make("CanvasGroup", {
		Parent = root,
		BackgroundColor3 = tankColor,
		Size = UDim2.fromOffset(tankW, tankH),
		Position = UDim2.fromOffset((w - tankW) / 2, tankY),
		ZIndex = 3,
	}, { corner(tankH * 0.35) })
	local fill = make("Frame", {
		Parent = tank,
		BackgroundColor3 = WATER,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
	}, {
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(130, 210, 255), WATER),
		}),
	})
	make("Frame", {
		Parent = root,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(tankW, tankH),
		Position = UDim2.fromOffset((w - tankW) / 2, tankY),
		ZIndex = 4,
	}, { corner(tankH * 0.35), stroke(INK, math.max(1.5, w / 30)) })
	local legTop = tankY + tankH - 2
	local legH = h - legTop
	for i, x in { 0.24, 0.42, 0.58, 0.76 } do
		local tilt = (i == 1 and 6) or (i == 4 and -6) or 0
		make("Frame", {
			Parent = root,
			BackgroundColor3 = INK,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(math.max(2, w * 0.05), legH),
			Position = UDim2.fromOffset(w * x, legTop),
			Rotation = tilt,
			ZIndex = 2,
		})
	end
	make("Frame", {
		Parent = root,
		BackgroundColor3 = INK,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(w * 0.56, math.max(2, w * 0.035)),
		Position = UDim2.fromOffset(w * 0.22, legTop + legH * 0.5),
		ZIndex = 2,
	})
	return root, fill, tank
end

function Hud.new(player: Player)
	local self = setmetatable({}, Hud)
	local gui = make("ScreenGui", {
		Name = "WaterTowerHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	self.gui = gui

	-- The size meter.
	local meter = make("Frame", {
		Parent = gui,
		Name = "Meter",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(130, 200),
		Position = UDim2.fromOffset(18, 70),
	})
	self.meterScale = make("UIScale", { Parent = meter })
	local icon, fill, tank = towerIcon(meter, Vector2.new(130, 190), Color3.fromRGB(250, 250, 250), Color3.fromRGB(240, 80, 80))
	self.fill = fill
	self.tank = tank
	self.townLabel = make("TextLabel", {
		Parent = icon,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(100, 26),
		Position = UDim2.fromOffset(65, 190 * 0.2 + 190 * 0.21),
		Font = FONT,
		Text = "",
		TextScaled = true,
		TextColor3 = INK,
		ZIndex = 5,
	})
	self.star = make("TextLabel", {
		Parent = meter,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromOffset(95, -10),
		Font = FONT,
		Text = "⭐",
		TextScaled = true,
		Visible = false,
		ZIndex = 6,
	})
	-- Little brick marks for the walls you'll be able to smash.
	self.gateMarks = {}
	local tankTop, tankH = 190 * 0.2, 190 * 0.42
	for i, need in Config.GATE_NEED do
		local frac = (need - Config.START_SIZE) / (Config.TOWER_NEED - Config.START_SIZE)
		self.gateMarks[i] = make("TextLabel", {
			Parent = meter,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(26, 26),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(122, tankTop + tankH * (1 - frac)),
			Font = FONT,
			Text = "🧱",
			TextScaled = true,
			ZIndex = 6,
		})
	end

	-- Trophy row along the top.
	self.trophies = make("Frame", {
		Parent = gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(600, 56),
	}, {
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	self.trophyCount = 0

	-- Banner text.
	self.banner = make("TextLabel", {
		Parent = gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 130),
		Size = UDim2.new(0.66, 0, 0, 96),
		Font = FONT,
		Text = "",
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 1,
		ZIndex = 20,
	}, { textStroke(INK, 5), make("UITextSizeConstraint", { MaxTextSize = 90 }) })
	self.bannerStroke = self.banner:FindFirstChildOfClass("UIStroke")
	self.bannerScale = make("UIScale", { Parent = self.banner })
	self.bannerToken = 0

	-- Watery fade between lands.
	self.fadeFrame = make("Frame", {
		Parent = gui,
		BackgroundColor3 = WATER,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Visible = false,
	}, {
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(140, 215, 255), Color3.fromRGB(30, 110, 220)),
		}),
	})
	return self
end

function Hud:setTownName(name: string)
	self.townLabel.Text = string.upper(name or "")
end

function Hud:setSize(size: number)
	local frac = math.clamp((size - Config.START_SIZE) / (Config.TOWER_NEED - Config.START_SIZE), 0, 1)
	TweenService:Create(self.fill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, frac) }):Play()
	for i, need in Config.GATE_NEED do
		self.gateMarks[i].Text = size + 1e-3 >= need and "✅" or "🧱"
	end
	local full = size + 1e-3 >= Config.TOWER_NEED
	self.star.Visible = full
	if full and not self.pulsing then
		self.pulsing = true
		task.spawn(function()
			while self.pulsing do
				TweenService:Create(self.meterScale, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { Scale = 1.1 }):Play()
				task.wait(0.45)
				TweenService:Create(self.meterScale, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
				task.wait(0.45)
			end
		end)
	elseif not full then
		self.pulsing = false
	end
end

-- A little bump when growth stars land.
function Hud:bump()
	if self.pulsing then
		return
	end
	self.meterScale.Scale = 1.12
	TweenService:Create(self.meterScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

function Hud:setTrophies(count: number)
	while self.trophyCount < count do
		self.trophyCount += 1
		if self.trophyCount <= 12 then
			local holder = make("Frame", {
				Parent = self.trophies,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(40, 52),
				LayoutOrder = self.trophyCount,
			})
			local icon, fill = towerIcon(holder, Vector2.new(40, 52), Color3.fromRGB(250, 250, 250), Color3.fromRGB(240, 80, 80))
			fill.Size = UDim2.fromScale(1, 1)
			local s = make("UIScale", { Parent = icon, Scale = 0 })
			TweenService:Create(s, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	if count > 12 then
		self.extraLabel = self.extraLabel
			or make("TextLabel", {
				Parent = self.trophies,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(70, 40),
				LayoutOrder = 999,
				Font = FONT,
				TextScaled = true,
				TextColor3 = Color3.new(1, 1, 1),
			}, { textStroke(INK, 3) })
		self.extraLabel.Text = "x" .. count
	end
end

function Hud:showBanner(text: string, seconds: number?, color: Color3?)
	self.bannerToken += 1
	local token = self.bannerToken
	local b = self.banner
	b.Text = text
	b.TextColor3 = color or Color3.new(1, 1, 1)
	b.TextTransparency = 0
	self.bannerStroke.Transparency = 0
	self.bannerScale.Scale = 0.3
	TweenService:Create(self.bannerScale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(seconds or 2.5, function()
		if token ~= self.bannerToken then
			return
		end
		TweenService:Create(b, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(self.bannerStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	end)
end

function Hud:confetti(amount: number?)
	local colors = {
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(90, 200, 120),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(200, 120, 255),
		Color3.fromRGB(255, 140, 200),
	}
	local rng = Random.new()
	for _ = 1, amount or 90 do
		local piece = make("Frame", {
			Parent = self.gui,
			BackgroundColor3 = colors[rng:NextInteger(1, #colors)],
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(rng:NextInteger(8, 16), rng:NextInteger(12, 22)),
			Position = UDim2.new(rng:NextNumber(), 0, 0, -30),
			Rotation = rng:NextNumber(0, 360),
			ZIndex = 30,
		})
		local dur = rng:NextNumber(2, 3.8)
		task.delay(rng:NextNumber(0, 0.8), function()
			TweenService:Create(piece, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(piece.Position.X.Scale + rng:NextNumber(-0.15, 0.15), 0, 1.1, 0),
				Rotation = piece.Rotation + rng:NextNumber(-540, 540),
			}):Play()
			task.delay(dur, function()
				piece:Destroy()
			end)
		end)
	end
end

function Hud:fade(on: boolean)
	local f = self.fadeFrame
	if on then
		f.Visible = true
		TweenService:Create(f, TweenInfo.new(0.9), { BackgroundTransparency = 0 }):Play()
		local rng = Random.new()
		for _ = 1, 26 do
			local d = rng:NextInteger(14, 46)
			local bubble = make("Frame", {
				Parent = f,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				Size = UDim2.fromOffset(d, d),
				Position = UDim2.new(rng:NextNumber(), 0, 1.05, 0),
				ZIndex = 51,
			}, { corner(d), stroke(Color3.new(1, 1, 1), 2) })
			TweenService:Create(bubble, TweenInfo.new(rng:NextNumber(1.4, 2.6), Enum.EasingStyle.Sine), {
				Position = UDim2.new(bubble.Position.X.Scale + rng:NextNumber(-0.05, 0.05), 0, -0.1, 0),
			}):Play()
			task.delay(2.8, function()
				bubble:Destroy()
			end)
		end
	else
		local t = TweenService:Create(f, TweenInfo.new(0.9), { BackgroundTransparency = 1 })
		t:Play()
		t.Completed:Once(function()
			if f.BackgroundTransparency > 0.99 then
				f.Visible = false
			end
		end)
	end
end

return Hud
