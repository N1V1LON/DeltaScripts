local env = getgenv and getgenv() or _G
if env.PlayersLogic then return env.PlayersLogic end

local PlayersLogic = {}
PlayersLogic.__index = PlayersLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local showDistance = true
local showHp = true
local marks = {}
local scanTask = nil

local ACCENT = Color3.fromRGB(0, 242, 254)
local HP_OK = Color3.fromRGB(52, 211, 153)
local HP_LOW = Color3.fromRGB(250, 204, 21)
local HP_CRIT = Color3.fromRGB(244, 63, 94)

function PlayersLogic.isEnabled()
	return enabled
end

function PlayersLogic.getShowDistance()
	return showDistance
end

function PlayersLogic.getShowHp()
	return showHp
end

function PlayersLogic.setShowDistance(value)
	showDistance = value == true
	return showDistance
end

function PlayersLogic.setShowHp(value)
	showHp = value == true
	return showHp
end

local function destroyMark(plr)
	local mark = marks[plr]
	if not mark then
		return
	end
	if mark.highlight then
		pcall(function()
			mark.highlight:Destroy()
		end)
	end
	if mark.billboard then
		pcall(function()
			mark.billboard:Destroy()
		end)
	end
	marks[plr] = nil
end

local function ensureMark(plr)
	if plr == LocalPlayer then
		return nil
	end
	local char = plr.Character
	if not char or not char:FindFirstChildOfClass("Humanoid") then
		destroyMark(plr)
		return nil
	end
	local mark = marks[plr]
	if mark and mark.char == char and mark.highlight and mark.highlight.Parent and mark.billboard and mark.billboard.Parent then
		return mark
	end
	destroyMark(plr)

	local highlight = Instance.new("Highlight")
	highlight.Name = "PlayersESP"
	highlight.Adornee = char
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = ACCENT
	highlight.FillTransparency = 0.85
	highlight.OutlineColor = ACCENT
	highlight.OutlineTransparency = 0.1
	highlight.Parent = char

	local head = char:FindFirstChild("Head") or char:FindFirstChildOfClass("Part")
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayersInfo"
	billboard.Adornee = head or char
	billboard.Size = UDim2.fromOffset(140, 36)
	billboard.StudsOffset = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 200
	billboard.Parent = head or char

	local label = Instance.new("TextLabel")
	label.Name = "Info"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Code
	label.TextSize = 11
	label.TextColor3 = Color3.fromRGB(223, 226, 240)
	label.TextStrokeTransparency = 0.4
	label.Text = plr.Name
	label.Parent = billboard

	marks[plr] = {
		char = char,
		highlight = highlight,
		billboard = billboard,
		label = label,
	}
	return mark
end

local function refreshMark(plr, mark)
	local char = plr.Character
	if not char then
		destroyMark(plr)
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 then
		if mark.highlight then
			mark.highlight.Enabled = false
		end
		if mark.billboard then
			mark.billboard.Enabled = false
		end
		return
	end
	if mark.highlight then
		mark.highlight.Enabled = true
		mark.highlight.Adornee = char
	end
	if mark.billboard then
		mark.billboard.Enabled = true
	end

	local parts = { plr.DisplayName }
	if showDistance and myRoot and root then
		local dist = math.floor((myRoot.Position - root.Position).Magnitude + 0.5)
		parts[#parts + 1] = dist .. "m"
	end
	if showHp then
		local pct = math.floor((hum.Health / math.max(1, hum.MaxHealth)) * 100 + 0.5)
		parts[#parts + 1] = math.floor(hum.Health + 0.5) .. "/" .. math.floor(hum.MaxHealth + 0.5) .. " (" .. pct .. "%)"
		if mark.label then
			if pct <= 25 then
				mark.label.TextColor3 = HP_CRIT
			elseif pct <= 55 then
				mark.label.TextColor3 = HP_LOW
			else
				mark.label.TextColor3 = HP_OK
			end
		end
	elseif mark.label then
		mark.label.TextColor3 = Color3.fromRGB(223, 226, 240)
	end
	if mark.label then
		mark.label.Text = table.concat(parts, "  ·  ")
	end
end

local function scan()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local mark = ensureMark(plr)
			if mark then
				refreshMark(plr, mark)
			end
		end
	end
	for plr in pairs(marks) do
		if not Players:FindFirstChild(plr.Name) then
			destroyMark(plr)
		end
	end
end

local function startLoop()
	if scanTask then
		return
	end
	scanTask = task.spawn(function()
		while enabled do
			pcall(scan)
			task.wait(0.35)
		end
		scanTask = nil
	end)
end

local function stopLoop()
	if scanTask then
		task.cancel(scanTask)
		scanTask = nil
	end
	for plr in pairs(marks) do
		destroyMark(plr)
	end
end

function PlayersLogic.enable()
	if enabled then
		return true
	end
	enabled = true
	startLoop()
	return true
end

function PlayersLogic.disable()
	if not enabled then
		return true
	end
	enabled = false
	stopLoop()
	return true
end

function PlayersLogic.toggle()
	if enabled then
		return PlayersLogic.disable()
	end
	return PlayersLogic.enable()
end

LocalPlayer.CharacterAdded:Connect(function()
	if enabled then
		task.wait(0.3)
		startLoop()
	end
end)

env.PlayersLogic = PlayersLogic
return PlayersLogic
