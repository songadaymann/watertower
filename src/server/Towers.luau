--!nonstrict
-- Water towers! Each style is built around the origin, about 95 studs tall.
-- Parts in the tank (the bit that falls over and splashes) get the attribute Tank = true.
-- The town name wraps around the tank facing -Z, toward the spawn.

local Kit = require(script.Parent.Kit)

local V = Vector3.new
local rgb = Color3.fromRGB

local Towers = {}

local PALETTES = {
	{ tank = rgb(245, 245, 240), roof = rgb(120, 190, 240), legs = rgb(200, 205, 210), text = rgb(30, 90, 190) },
	{ tank = rgb(130, 200, 245), roof = rgb(245, 245, 240), legs = rgb(200, 205, 210), text = rgb(255, 255, 255), stroke = rgb(30, 90, 190) },
	{ tank = rgb(205, 210, 215), roof = rgb(205, 210, 215), legs = rgb(150, 155, 160), text = rgb(25, 60, 140), metal = true },
	{ tank = rgb(120, 200, 140), roof = rgb(245, 245, 240), legs = rgb(245, 245, 240), text = rgb(255, 255, 255), stroke = rgb(40, 110, 60) },
	{ tank = rgb(255, 215, 80), roof = rgb(220, 60, 60), legs = rgb(245, 245, 240), text = rgb(200, 40, 40) },
	{ tank = rgb(245, 245, 240), roof = rgb(220, 60, 60), legs = rgb(220, 60, 60), text = rgb(220, 60, 60) },
	{ tank = rgb(255, 170, 210), roof = rgb(245, 245, 240), legs = rgb(245, 245, 240), text = rgb(255, 255, 255), stroke = rgb(200, 60, 130) },
}

local function markTank(k, fromIndex: number)
	for i = fromIndex + 1, #k.created do
		k.created[i]:SetAttribute("Tank", true)
	end
end

-- Letters wrapped around a vertical cylinder or sphere of radius `radius` at height `y`.
local function wrapText(k, text: string, y: number, radius: number, letterH: number, color: Color3, stroke: Color3?)
	local letterW = letterH * 0.68
	local n = #text
	local step = letterW / radius
	for i = 1, n do
		local ch = string.sub(text, i, i)
		if ch ~= " " then
			local theta = (i - (n + 1) / 2) * step
			-- Seen from the spawn (looking +Z), screen-right is world -X, so letters run toward -X.
			local out = V(-math.sin(theta), 0, -math.cos(theta))
			local pos = V(0, y, 0) + out * (radius + 0.15)
			local p = k:block(V(letterW, letterH, 0.2), CFrame.lookAt(pos, pos + out), color, { transparency = 1 })
			p.CanCollide = false
			p.Name = "Letter"
			local gui = k:label(p, Enum.NormalId.Front, ch, color, stroke)
			gui.LightInfluence = 0.15
		end
	end
end

local function beacon(k, y: number)
	local b = k:ball(2.2, V(0, y, 0), rgb(255, 40, 40), { material = Enum.Material.Neon, name = "Beacon" })
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 60, 60)
	light.Range = 30
	light.Brightness = 3
	light.Parent = b
	return b
end

local function railing(k, y: number, radius: number, color: Color3)
	local n = 18
	for i = 1, n do
		local a = i / n * math.pi * 2
		local b = (i + 1) / n * math.pi * 2
		local pa = V(math.cos(a) * radius, y, math.sin(a) * radius)
		local pb = V(math.cos(b) * radius, y, math.sin(b) * radius)
		k:block(V(0.4, 2.6, 0.4), pa + V(0, 1.3, 0), color)
		k:beam(0.35, 0.35, pa + V(0, 2.6, 0), pb + V(0, 2.6, 0), color)
	end
end

local function ladder(k, fromY: number, toY: number, z: number, color: Color3)
	for _, x in { -0.9, 0.9 } do
		k:block(V(0.3, toY - fromY, 0.3), V(x, (fromY + toY) / 2, z), color)
	end
	for y = fromY + 2, toY - 1, 3 do
		k:block(V(1.8, 0.25, 0.25), V(0, y, z), color)
	end
end

-- Legs that lean in from radius rBase at the ground to rTop at height topY, plus X-bracing.
local function legs(k, count: number, rBase: number, rTop: number, topY: number, color: Color3)
	local legPoints = {}
	for i = 1, count do
		local a = (i - 0.5) / count * math.pi * 2
		local base = V(math.cos(a) * rBase, 0, math.sin(a) * rBase)
		local top = V(math.cos(a) * rTop, topY, math.sin(a) * rTop)
		k:rod(2.4, base - V(0, 1, 0), top, color)
		k:cyl(4, 1.4, base + V(0, 0.7, 0), rgb(150, 150, 150))
		legPoints[i] = function(y)
			return base:Lerp(top, y / topY)
		end
	end
	local levels = { 0.5, topY * 0.34, topY * 0.67, topY - 1 }
	for i = 1, count do
		local j = i % count + 1
		for l = 2, #levels do
			k:rod(1.1, legPoints[i](levels[l]), legPoints[j](levels[l]), color)
		end
		for l = 1, #levels - 1 do
			k:rod(0.6, legPoints[i](levels[l]), legPoints[j](levels[l + 1]), color)
			k:rod(0.6, legPoints[j](levels[l]), legPoints[i](levels[l + 1]), color)
		end
	end
end

local Styles = {}

function Styles.Classic(k, r, pal, name, striped)
	local tankBottom, tankH, tankD = 58, 22, 34
	local legCount = striped and 4 or r:NextInteger(4, 6)
	legs(k, legCount, 22, 15, tankBottom, pal.legs)
	k:cyl(4.5, tankBottom, V(0, tankBottom / 2, 0), pal.legs)
	ladder(k, 0, tankBottom, -2.6, rgb(90, 90, 95))

	local mark = #k.created
	local core
	k:blob(V(tankD, 14, tankD), V(0, tankBottom, 0), pal.tank, pal.metal and { material = Enum.Material.Metal } or nil)
	if striped then
		local bands = 5
		local bandH = tankH / bands
		for i = 0, bands - 1 do
			local p = k:cyl(tankD, bandH, V(0, tankBottom + bandH * (i + 0.5), 0), i % 2 == 0 and pal.roof or pal.tank)
			if i == 2 then
				core = p
			end
		end
	else
		core = k:cyl(tankD, tankH, V(0, tankBottom + tankH / 2, 0), pal.tank, pal.metal and { material = Enum.Material.Metal } or nil)
	end
	core.Name = "TankCore"
	k:cyl(tankD + 5, 0.7, V(0, tankBottom + 0.5, 0), rgb(80, 80, 90))
	railing(k, tankBottom + 0.85, (tankD + 4) / 2, rgb(80, 80, 90))
	k:cone(tankD + 1.6, 3, 10, V(0, tankBottom + tankH, 0), pal.roof, 6)
	k:ball(2.4, V(0, tankBottom + tankH + 10.6, 0), pal.legs)
	beacon(k, tankBottom + tankH + 12.4)
	if not striped then
		wrapText(k, name, tankBottom + tankH / 2, tankD / 2, 8, pal.text, pal.stroke)
	end
	markTank(k, mark)
end

function Styles.Stripes(k, r, pal, name)
	local stripePal = {
		tank = rgb(245, 245, 240),
		roof = pal.roof == pal.tank and rgb(220, 60, 60) or pal.roof,
		legs = rgb(245, 245, 240),
		text = pal.text,
	}
	if stripePal.roof == rgb(245, 245, 240) then
		stripePal.roof = rgb(220, 60, 60)
	end
	Styles.Classic(k, r, stripePal, name, true)
end

function Styles.Sphere(k, r, pal, name)
	k:cyl(22, 2, V(0, 1, 0), pal.legs)
	k:cone(14, 8, 58, V(0, 2, 0), pal.legs, 8)
	k:block(V(4, 7, 0.4), V(0, 5.5, -6.9), rgb(90, 90, 95))
	local mark = #k.created
	k:cone(8, 15, 6, V(0, 58, 0), pal.legs, 3)
	local core = k:ball(40, V(0, 82, 0), pal.tank, pal.metal and { material = Enum.Material.Metal } or nil)
	core.Name = "TankCore"
	k:cyl(5, 1.2, V(0, 102.3, 0), pal.roof)
	beacon(k, 103.8)
	wrapText(k, name, 82, 20, 8, pal.text, pal.stroke)
	markTank(k, mark)
end

function Styles.Pillar(k, r, pal, name)
	k:cyl(28, 2, V(0, 1, 0), pal.legs)
	k:cyl(22, 58, V(0, 31, 0), pal.legs)
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		k:block(V(1.4, 56, 1.4), V(math.cos(a) * 11, 31, math.sin(a) * 11), pal.tank)
	end
	k:block(V(5, 8, 0.4), V(0, 6, -11.05), rgb(90, 90, 95))
	local mark = #k.created
	k:blob(V(48, 18, 48), V(0, 64, 0), pal.tank, pal.metal and { material = Enum.Material.Metal } or nil)
	local core = k:cyl(48, 14, V(0, 72, 0), pal.tank, pal.metal and { material = Enum.Material.Metal } or nil)
	core.Name = "TankCore"
	k:blob(V(48, 12, 48), V(0, 79, 0), pal.roof)
	railing(k, 84.2, 6, rgb(80, 80, 90))
	k:cyl(13, 0.5, V(0, 84.1, 0), pal.roof)
	beacon(k, 86.5)
	wrapText(k, name, 72, 24, 9, pal.text, pal.stroke)
	markTank(k, mark)
end

function Styles.Peach(k, r, pal, name)
	local peach = rgb(255, 175, 120)
	k:cyl(22, 2, V(0, 1, 0), rgb(200, 205, 210))
	k:cone(14, 8, 58, V(0, 2, 0), rgb(200, 205, 210), 8)
	local mark = #k.created
	k:cone(8, 15, 6, V(0, 58, 0), rgb(200, 205, 210), 3)
	local core = k:ball(40, V(0, 82, 0), peach)
	core.Name = "TankCore"
	-- The cleft, a blush, a stem, and a big leaf.
	k:hcyl(40.3, 0.8, CFrame.new(0, 82, 0) * CFrame.Angles(0, math.rad(20), 0), rgb(230, 130, 90))
	k:blob(V(26, 26, 8), CFrame.new(-9, 86, -15) * CFrame.Angles(0, math.rad(30), 0), rgb(255, 130, 110))
	k:cyl(2, 5, V(0, 103, 0), rgb(110, 75, 45))
	k:blob(V(16, 1.2, 7), CFrame.new(6, 104, 0) * CFrame.Angles(0, 0, math.rad(-20)), rgb(90, 170, 70))
	beacon(k, 106)
	markTank(k, mark)
end

Towers.STYLES = { "Classic", "Stripes", "Sphere", "Pillar", "Peach" }

function Towers.build(styleName: string, r: Random, townName: string)
	local k = Kit.new("WaterTower")
	local pal = PALETTES[r:NextInteger(1, #PALETTES)]
	local style = Styles[styleName] or Styles.Classic
	style(k, r, pal, string.upper(townName))
	local model = k:finish()
	model:SetAttribute("Style", styleName)
	return model
end

return Towers
