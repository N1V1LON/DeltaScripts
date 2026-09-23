local env = getgenv and getgenv() or _G
if env.PlayersWindow then return env.PlayersWindow end

local PlayersWindow = {}
PlayersWindow.GetTable = "Server"
PlayersWindow.GetPosition = 2
PlayersWindow.QuickToggle = true

local function Str(key, fallback)
	local GC = env.GlobalControler
	if GC and GC.Str then
		return GC:Str(key)
	end
	return fallback
end

function PlayersWindow.Name()
	return Str("playersName", "Players")
end

function PlayersWindow.Desc()
	return Str("playersDesc", "Обводка, дистанция, HP")
end

function PlayersWindow.IsOn()
	local L = env.PlayersLogic
	return L ~= nil and L.isEnabled() == true
end

function PlayersWindow.SetOn(state)
	local L = env.PlayersLogic
	assert(L, "PlayersLogic не загружен")
	if state then
		L.enable()
	else
		L.disable()
	end
	local GC = env.GlobalControler
	if GC and GC.SaveModuleState then
		GC:SaveModuleState("PlayersWindow", {
			enabled = state == true,
			showDistance = L.getShowDistance(),
			showHp = L.getShowHp(),
		})
	end
	return PlayersWindow.IsOn()
end

function PlayersWindow.Restore(config)
	config = config or {}
	local L = env.PlayersLogic
	if not L then
		return
	end
	if config.showDistance ~= nil then
		L.setShowDistance(config.showDistance)
	end
	if config.showHp ~= nil then
		L.setShowHp(config.showHp)
	end
	if config.enabled then
		L.enable()
	end
end

local window = nil

local function currentPalette()
	local GC = env.GlobalControler
	if GC and type(GC.ModuleTheme) == "table" then
		return GC.ModuleTheme
	end
	local WindowBase = env.WindowBase
	return WindowBase and WindowBase.Palette or nil
end

local function corner(frame, r)
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, r or 4)
end

local function stroke(frame, color)
	pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = 1
		s.Color = color
		s.Parent = frame
	end)
end

local function makeToggle(parent, on, onToggle)
	local P = currentPalette() or {}
	local h = 28
	local w = 56

	local btn = Instance.new("TextButton")
	btn.Name = "Toggle"
	btn.Size = UDim2.fromOffset(w, h)
	btn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.Parent = parent
	corner(btn, 99)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Text = on and "ON" or "OFF"
	label.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))
	label.Font = Enum.Font.Code
	label.TextSize = 11
	label.ZIndex = 2
	label.Parent = btn

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(h - 8, h - 8)
	knob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)
	knob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))
	knob.BorderSizePixel = 0
	knob.ZIndex = 3
	knob.Parent = btn
	corner(knob, 99)

	local state = on
	local function paint()
		btn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))
		label.Text = state and "ON" or "OFF"
		label.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))
		knob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)
		knob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))
	end

	btn.MouseButton1Click:Connect(function()
		state = not state
		paint()
		if onToggle then
			onToggle(state)
		end
	end)

	return {
		get = function() return state end,
		set = function(v)
			state = v
			paint()
		end,
	}
end

local function optRow(parent, y, titleText, getter, setter, P, onSaved)
	local row = Instance.new("Frame")
	row.Name = "OptRow"
	row.Size = UDim2.new(1, 0, 0, 36)
	row.Position = UDim2.fromOffset(0, y)
	row.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 4)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText
	lbl.TextColor3 = P.text or Color3.fromRGB(223, 226, 240)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local t = makeToggle(row, getter(), function(on)
		setter(on)
		if onSaved then
			onSaved()
		end
	end)
	local tBtn = row:FindFirstChild("Toggle")
	if tBtn then
		tBtn.Position = UDim2.new(1, -66, 0.5, -14)
	end
	return t
end

function PlayersWindow.Open(config)
	config = config or {}
	if window then
		if window._destroyed then
			window = nil
		else
			window:Destroy()
			window = nil
			return
		end
	end

	local WindowBase = env.WindowBase
	local L = env.PlayersLogic
	assert(WindowBase, "WindowBase не загружен")
	assert(L, "PlayersLogic не загружен")

	local P = currentPalette() or WindowBase.Palette
	local base = WindowBase.new("Players", PlayersWindow.Name(), 280, 200)
	window = base
	local content = base.Content
	local PAD = 6

	local stateLabel
	local toggle
	local bigState

	local function saveState()
		local GC = env.GlobalControler
		if GC and GC.SaveModuleState then
			GC:SaveModuleState("PlayersWindow", {
				enabled = L.isEnabled(),
				showDistance = L.getShowDistance(),
				showHp = L.getShowHp(),
			})
		end
	end

	local function refreshStatus()
		if stateLabel then
			if L.isEnabled() then
				local n = 0
				local Players = game:GetService("Players")
				n = #Players:GetPlayers() - 1
				stateLabel.Text = ("ON  ·  %d players"):format(math.max(0, n))
				stateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)
			else
				stateLabel.Text = "OFF  ·  no esp"
				stateLabel.TextColor3 = P.textDim
			end
		end
		if bigState then
			bigState.Text = L.isEnabled() and "ON" or "OFF"
			bigState.TextColor3 = L.isEnabled() and (P.accent or Color3.fromRGB(0, 242, 254)) or P.textDim
		end
	end

	local function setEnabled(state)
		if state then
			L.enable()
		else
			L.disable()
		end
		saveState()
		refreshStatus()
	end

	local card = Instance.new("Frame")
	card.Name = "StateCard"
	card.Size = UDim2.new(1, 0, 0, 64)
	card.Position = UDim2.fromOffset(0, PAD)
	card.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)
	card.BorderSizePixel = 0
	card.Parent = content
	corner(card, 4)
	stroke(card, P.line or Color3.fromRGB(58, 73, 75))

	local cardLbl = Instance.new("TextLabel")
	cardLbl.Size = UDim2.new(1, -80, 0, 12)
	cardLbl.Position = UDim2.fromOffset(10, 10)
	cardLbl.BackgroundTransparency = 1
	cardLbl.Text = PlayersWindow.Desc()
	cardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	cardLbl.Font = Enum.Font.Gotham
	cardLbl.TextSize = 11
	cardLbl.TextXAlignment = Enum.TextXAlignment.Left
	cardLbl.Parent = card

	bigState = Instance.new("TextLabel")
	bigState.Name = "Big"
	bigState.Size = UDim2.new(1, -80, 0, 28)
	bigState.Position = UDim2.fromOffset(10, 26)
	bigState.BackgroundTransparency = 1
	bigState.Text = L.isEnabled() and "ON" or "OFF"
	bigState.TextColor3 = P.textDim
	bigState.Font = Enum.Font.Code
	bigState.TextSize = 24
	bigState.TextXAlignment = Enum.TextXAlignment.Left
	bigState.Parent = card

	toggle = makeToggle(card, L.isEnabled(), setEnabled)
	local tBtn = card:FindFirstChild("Toggle")
	if tBtn then
		tBtn.Size = UDim2.fromOffset(56, 28)
		tBtn.Position = UDim2.new(1, -66, 0.5, -14)
	end

	local y = PAD + 64 + 8
	optRow(content, y, Str("playersDist", "Показывать дистанцию"),
		L.getShowDistance,
		function(v) L.setShowDistance(v) end,
		P, saveState)
	y = y + 40
	optRow(content, y, Str("playersHp", "Показывать HP"),
		L.getShowHp,
		function(v) L.setShowHp(v) end,
		P, saveState)
	y = y + 44

	stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "State"
	stateLabel.Position = UDim2.fromOffset(0, y)
	stateLabel.Size = UDim2.new(1, 0, 0, 14)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = "OFF"
	stateLabel.TextColor3 = P.textDim
	stateLabel.Font = Enum.Font.Code
	stateLabel.TextSize = 10
	stateLabel.TextXAlignment = Enum.TextXAlignment.Left
	stateLabel.Parent = content
	y = y + 14 + PAD

	base:setSize(280, 28 + y)
	refreshStatus()
	task.spawn(function()
		while window == base and not base._destroyed do
			refreshStatus()
			task.wait(1)
		end
	end)

	base.OnClosed = function()
		window = nil
	end
end

env.PlayersWindow = PlayersWindow
return PlayersWindow
