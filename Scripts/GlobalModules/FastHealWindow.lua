local env = getgenv and getgenv() or _G
if env.FastHealWindow then return env.FastHealWindow end

local FastHealWindow = {}
FastHealWindow.GetTable = "Player"
FastHealWindow.GetPosition = 5
FastHealWindow.QuickToggle = true

local function Str(key, fallback)
	local GC = env.GlobalControler
	if GC and GC.Str then
		return GC:Str(key)
	end
	return fallback
end

function FastHealWindow.Name()
	return Str("healName", "Быстрый хил")
end

function FastHealWindow.Desc()
	return Str("healDesc", "Ускоренное восстановление HP")
end

function FastHealWindow.IsOn()
	local L = env.FastHealLogic
	return L ~= nil and L.isEnabled() == true
end

function FastHealWindow.SetOn(state)
	local L = env.FastHealLogic
	assert(L, "FastHealLogic не загружен")
	if state then
		L.enable()
	else
		L.disable()
	end
	local GC = env.GlobalControler
	if GC and GC.SaveModuleState then
		GC:SaveModuleState("FastHealWindow", {
			enabled = state == true,
			amount = L.getAmount(),
		})
	end
	return FastHealWindow.IsOn()
end

function FastHealWindow.Restore(config)
	config = config or {}
	local L = env.FastHealLogic
	if not L then
		return
	end
	if config.amount then
		L.setAmount(config.amount)
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

local function makeSlider(parent, minV, maxV, startV, onChange)
	local P = currentPalette() or {}
	local box = Instance.new("Frame")
	box.Name = "SliderBox"
	box.Size = UDim2.new(1, 0, 0, 72)
	box.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)
	box.BorderSizePixel = 0
	box.Parent = parent
	corner(box, 4)
	stroke(box, P.line or Color3.fromRGB(58, 73, 75))

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -70, 0, 14)
	label.Position = UDim2.fromOffset(10, 8)
	label.BackgroundTransparency = 1
	label.Text = Str("healRate", "HP за тик")
	label.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	label.Font = Enum.Font.Gotham
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = box

	local readout = Instance.new("TextLabel")
	readout.Name = "Readout"
	readout.Size = UDim2.new(0, 56, 0, 20)
	readout.Position = UDim2.new(1, -66, 0, 6)
	readout.BackgroundTransparency = 1
	readout.Text = tostring(math.floor(startV + 0.5))
	readout.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)
	readout.Font = Enum.Font.Code
	readout.TextSize = 16
	readout.TextXAlignment = Enum.TextXAlignment.Right
	readout.Parent = box

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -20, 0, 6)
	track.Position = UDim2.fromOffset(10, 34)
	track.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)
	track.BorderSizePixel = 0
	track.Active = true
	track.Parent = box
	corner(track, 99)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 99)

	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.Size = UDim2.fromOffset(18, 18)
	thumb.Position = UDim2.new(0, -9, 0.5, -9)
	thumb.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 3
	thumb.Parent = track
	corner(thumb, 99)
	pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = P.bg or Color3.fromRGB(15, 19, 29)
		s.Parent = thumb
	end)

	local mins = Instance.new("TextLabel")
	mins.Size = UDim2.new(0, 36, 0, 12)
	mins.Position = UDim2.fromOffset(10, 48)
	mins.BackgroundTransparency = 1
	mins.Text = tostring(minV)
	mins.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	mins.Font = Enum.Font.Code
	mins.TextSize = 9
	mins.TextXAlignment = Enum.TextXAlignment.Left
	mins.Parent = box

	local maxs = Instance.new("TextLabel")
	maxs.Size = UDim2.new(0, 36, 0, 12)
	maxs.Position = UDim2.new(1, -46, 0, 48)
	maxs.BackgroundTransparency = 1
	maxs.Text = tostring(maxV)
	maxs.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	maxs.Font = Enum.Font.Code
	maxs.TextSize = 9
	maxs.TextXAlignment = Enum.TextXAlignment.Right
	maxs.Parent = box

	local value = startV
	local dragging = false

	local function applyVisual()
		local range = maxV - minV
		local frac = 0
		if range > 0 then
			frac = (value - minV) / range
		end
		frac = math.clamp(frac, 0, 1)
		fill.Size = UDim2.new(frac, 0, 1, 0)
		thumb.Position = UDim2.new(frac, -9, 0.5, -9)
		readout.Text = tostring(math.floor(value + 0.5))
	end

	local function fromInput(input)
		local abs = track.AbsolutePosition.X
		local sizeX = track.AbsoluteSize.X
		if sizeX <= 0 then
			return
		end
		local frac = (input.Position.X - abs) / sizeX
		frac = math.clamp(frac, 0, 1)
		value = minV + frac * (maxV - minV)
		applyVisual()
		if onChange then
			onChange(value)
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		fromInput(input)
	end)

	local UIS = game:GetService("UserInputService")
	UIS.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		fromInput(input)
	end)

	local function endDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = false
	end
	UIS.InputEnded:Connect(endDrag)
	track.InputEnded:Connect(endDrag)

	task.defer(applyVisual)

	return {
		get = function()
			return value
		end,
		set = function(v)
			value = math.clamp(v, minV, maxV)
			applyVisual()
		end,
	}
end

function FastHealWindow.Open(config)
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
	local L = env.FastHealLogic
	assert(WindowBase, "WindowBase не загружен")
	assert(L, "FastHealLogic не загружен")

	local P = currentPalette() or WindowBase.Palette
	local base = WindowBase.new("FastHeal", FastHealWindow.Name(), 300, 220)
	window = base
	local content = base.Content
	local PAD = 6

	local stateLabel
	local toggle
	local bigState

	local function saveState()
		local GC = env.GlobalControler
		if GC and GC.SaveModuleState then
			GC:SaveModuleState("FastHealWindow", {
				enabled = L.isEnabled(),
				amount = L.getAmount(),
			})
		end
	end

	local function refreshStatus()
		if stateLabel then
			if not L.canRun() then
				stateLabel.Text = Str("noChar", "Нет персонажа")
				stateLabel.TextColor3 = P.textDim
				return
			end
			local h = L.getHumanoid()
			if L.isEnabled() then
				stateLabel.Text = ("ON  ·  HP %.0f/%.0f  ·  +%d/тик"):format(
					h and h.Health or 0,
					h and h.MaxHealth or 0,
					L.getAmount()
				)
				stateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)
			else
				stateLabel.Text = ("OFF  ·  HP %.0f/%.0f"):format(
					h and h.Health or 0,
					h and h.MaxHealth or 0
				)
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
	cardLbl.Text = FastHealWindow.Desc()
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

	local sliderY = PAD + 64 + 8
	makeSlider(content, 1, 50, L.getAmount(), function(v)
		L.setAmount(math.floor(v + 0.5))
		saveState()
		refreshStatus()
	end)
	content:FindFirstChild("SliderBox").Position = UDim2.fromOffset(0, sliderY)

	stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "State"
	stateLabel.Position = UDim2.fromOffset(0, sliderY + 72 + 8)
	stateLabel.Size = UDim2.new(1, 0, 0, 14)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = "OFF"
	stateLabel.TextColor3 = P.textDim
	stateLabel.Font = Enum.Font.Code
	stateLabel.TextSize = 10
	stateLabel.TextXAlignment = Enum.TextXAlignment.Left
	stateLabel.Parent = content

	base:setSize(300, 28 + PAD + 64 + 8 + 72 + 8 + 14 + PAD)
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

env.FastHealWindow = FastHealWindow
return FastHealWindow
