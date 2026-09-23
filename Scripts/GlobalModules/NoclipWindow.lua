local env = getgenv and getgenv() or _G
if env.NoclipWindow then return env.NoclipWindow end

local NoclipWindow = {}
NoclipWindow.GetTable = "Player"
NoclipWindow.GetPosition = 3
NoclipWindow.QuickToggle = true

local function Str(key, fallback)
	local GC = env.GlobalControler
	if GC and GC.Str then
		return GC:Str(key)
	end
	return fallback
end

function NoclipWindow.Name()
	return Str("noclipName", "NoClip")
end

function NoclipWindow.Desc()
	return Str("noclipDesc", "Проход сквозь стены")
end

function NoclipWindow.IsOn()
	local L = env.NoclipLogic
	return L ~= nil and L.isEnabled() == true
end

function NoclipWindow.SetOn(state)
	local L = env.NoclipLogic
	assert(L, "NoclipLogic не загружен")
	if state then
		L.enable()
	else
		L.disable()
	end
	local GC = env.GlobalControler
	if GC and GC.SaveModuleState then
		GC:SaveModuleState("NoclipWindow", { enabled = state == true })
	end
	return NoclipWindow.IsOn()
end

function NoclipWindow.Restore(config)
	config = config or {}
	if config.enabled then
		local L = env.NoclipLogic
		if L then
			L.enable()
		end
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

function NoclipWindow.Open(config)
	config = config or {}
	if window then
		window:Destroy()
		window = nil
		return
	end

	local WindowBase = env.WindowBase
	local NoclipLogic = env.NoclipLogic
	assert(WindowBase, "WindowBase не загружен")
	assert(NoclipLogic, "NoclipLogic не загружен")

	local P = currentPalette() or WindowBase.Palette
	local base = WindowBase.new("Noclip", NoclipWindow.Name(), 280, 160)
	window = base

	local content = base.Content
	local PAD = 6

	local stateLabel
	local toggle

	local function refreshStatus()
		if not NoclipLogic.canRun() then
			if stateLabel then
				stateLabel.Text = Str("noChar", "Нет персонажа")
				stateLabel.TextColor3 = P.textDim
			end
			return
		end
		local on = NoclipLogic.isEnabled()
		if stateLabel then
			if on then
				stateLabel.Text = "ON  ·  стены отключены"
				stateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)
			else
				stateLabel.Text = "OFF  ·  обычный режим"
				stateLabel.TextColor3 = P.textDim
			end
		end
	end

	local function setEnabled(state)
		if state then
			NoclipLogic.enable()
		else
			NoclipLogic.disable()
		end
		local GC = env.GlobalControler
		if GC and GC.SaveModuleState then
			GC:SaveModuleState("NoclipWindow", { enabled = state == true })
		end
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
	cardLbl.Text = "NoClip"
	cardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	cardLbl.Font = Enum.Font.Gotham
	cardLbl.TextSize = 11
	cardLbl.TextXAlignment = Enum.TextXAlignment.Left
	cardLbl.Parent = card

	local bigState = Instance.new("TextLabel")
	bigState.Name = "Big"
	bigState.Size = UDim2.new(1, -80, 0, 28)
	bigState.Position = UDim2.fromOffset(10, 26)
	bigState.BackgroundTransparency = 1
	bigState.Text = "OFF"
	bigState.TextColor3 = P.textDim
	bigState.Font = Enum.Font.Code
	bigState.TextSize = 24
	bigState.TextXAlignment = Enum.TextXAlignment.Left
	bigState.Parent = card

	toggle = makeToggle(card, false, setEnabled)
	local tBtn = card:FindFirstChild("Toggle")
	if tBtn then
		tBtn.Size = UDim2.fromOffset(56, 28)
		tBtn.Position = UDim2.new(1, -66, 0.5, -14)
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(0, PAD + 64 + 8)
	hint.Size = UDim2.new(1, 0, 0, 28)
	hint.BackgroundTransparency = 1
	hint.Text = Str("noclipHint", "Включи — и иди сквозь стены.\nВыключение вернёт коллизию.")
	hint.TextColor3 = P.textDim
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 10
	hint.TextWrapped = true
	hint.TextYAlignment = Enum.TextYAlignment.Top
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = content

	stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "State"
	stateLabel.Position = UDim2.fromOffset(0, PAD + 64 + 8 + 28 + 8)
	stateLabel.Size = UDim2.new(1, 0, 0, 14)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = "OFF"
	stateLabel.TextColor3 = P.textDim
	stateLabel.Font = Enum.Font.Code
	stateLabel.TextSize = 10
	stateLabel.TextXAlignment = Enum.TextXAlignment.Left
	stateLabel.Parent = content

	base:setSize(280, 28 + PAD + 64 + 8 + 28 + 8 + 14 + PAD)

	refreshStatus()
	task.spawn(function()
		while window == base and not base._destroyed do
			refreshStatus()
			task.wait(0.5)
		end
	end)

	base.OnClosed = function()
		window = nil
	end
end

env.NoclipWindow = NoclipWindow
return NoclipWindow
