-- Paste into Roblox Studio's command bar (Edit mode) while tools/dev-sync-server.py is running.
-- Replaces the game's scripts with the ones in src/. HttpEnabled is switched on only for the fetch.

local HttpService = game:GetService("HttpService")
local was = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local ok, body = pcall(HttpService.GetAsync, HttpService, "http://127.0.0.1:34877/manifest")
HttpService.HttpEnabled = was
assert(ok, body)

local files = HttpService:JSONDecode(body)
local roots = {
	shared = { parent = game:GetService("ReplicatedStorage"), name = "WaterTowerShared" },
	server = { parent = game:GetService("ServerScriptService"), name = "WaterTowerServer" },
	client = { parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), name = "WaterTowerClient" },
}
for _, r in roots do
	local folder = Instance.new("Folder")
	folder.Name = r.name
	r.folder = folder
end

local count = 0
for path, source in files do
	local top, file = string.match(path, "^src/(%w+)/(.+)$")
	local r = roots[top]
	if r then
		local name, kind = string.match(file, "^(.-)%.(%a+)%.luau$")
		if kind ~= "server" and kind ~= "client" then
			name, kind = string.match(file, "^(.-)%.luau$"), "module"
		end
		local className = (kind == "server" and "Script") or (kind == "client" and "LocalScript") or "ModuleScript"
		local s = Instance.new(className)
		s.Name = name
		s.Source = source
		s.Parent = r.folder
		count += 1
	end
end

for _, r in roots do
	local old = r.parent:FindFirstChild(r.name)
	if old then
		old:Destroy()
	end
	r.folder.Parent = r.parent
end

return "synced " .. count .. " scripts"
