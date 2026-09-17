local env = getgenv and getgenv() or _G
local lines = {}

local function add(text)
	table.insert(lines, tostring(text))
	print("[TEST] " .. tostring(text))
end

add("getgenv: " .. tostring(type(getgenv)))
add("isfile: " .. tostring(type(isfile)))
add("readfile: " .. tostring(type(readfile)))
add("loadfile: " .. tostring(type(loadfile)))
add("loadstring: " .. tostring(type(loadstring)))
add("listfiles: " .. tostring(type(listfiles)))
add("LocalPlayer: " .. tostring(game:GetService("Players").LocalPlayer ~= nil))

local paths = {
	"ScriptModule.lua",
	"Scripts/ScriptModule.lua",
	"/storage/emulated/0/Delta/Scripts/ScriptModule.lua",
	"/sdcard/Delta/Scripts/ScriptModule.lua",
}

for _, path in ipairs(paths) do
	if type(isfile) == "function" then
		local ok, res = pcall(isfile, path)
		add(("isfile(%s) -> ok=%s res=%s"):format(path, tostring(ok), tostring(res)))
	elseif type(loadfile) == "function" then
		local ok, res = pcall(loadfile, path)
		add(("loadfile(%s) -> ok=%s res=%s"):format(path, tostring(ok), tostring(res ~= nil)))
	end
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "DiagnosticGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(520, 40 + #lines * 20)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 1, -16)
label.Position = UDim2.fromOffset(8, 8)
label.BackgroundTransparency = 1
label.Text = table.concat(lines, "\n")
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.Code
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Parent = frame

env.TestDiag = { lines = lines }
return true
