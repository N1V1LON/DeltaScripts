local env = getgenv and getgenv() or _G
if env.SettingsWindow then return env.SettingsWindow end

local SettingsWindow = {}
SettingsWindow.GetTable = "Settings"
SettingsWindow.GetPosition = 1

function SettingsWindow.Name()
	local GC = env.GlobalControler
	if GC and GC.Str then
		return GC:Str("settingsName")
	end
	return "Интерфейс"
end

function SettingsWindow.Desc()
	local GC = env.GlobalControler
	if GC and GC.Str then
		return GC:Str("settingsDesc")
	end
	return "Язык, тема, цвет, прозрачность"
end

local window = nil

local ACCENTS = {
	{ r = 0, g = 242, b = 254 },
	{ r = 14, g = 165, b = 233 },
	{ r = 52, g = 211, b = 153 },
	{ r = 250, g = 204, b = 21 },
	{ r = 251, g = 146, b = 60 },
	{ r = 244, g = 63, b = 94 },
	{ r = 167, g = 139, b = 250 },
	{ r = 255, g = 255, b = 255 },
}

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

local function label(parent, text, y, P)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.Position = UDim2.fromOffset(0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	return lbl
end

local function section(parent, titleText, y, h, P)
	local box = Instance.new("Frame")
	box.Name = "Section"
	box.Size = UDim2.new(1, 0, 0, h)
	box.Position = UDim2.fromOffset(0, y)
	box.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)
	box.BorderSizePixel = 0
	box.Parent = parent
	corner(box, 4)
	stroke(box, P.line or Color3.fromRGB(58, 73, 75))
	label(box, titleText, 8, P)
	return box
end

local function makeSegments(parent, options, selectedKey, onSelect, P)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 28)
	row.Position = UDim2.fromOffset(10, 28)
	row.BackgroundTransparency = 1
	row.Parent = parent
	pcall(function()
		local g = Instance.new("UIGridLayout")
		g.CellSize = UDim2.new(1 / #options, -6, 1, 0)
		g.CellPadding = UDim2.fromOffset(6, 0)
		g.SortOrder = Enum.SortOrder.LayoutOrder
		g.Parent = row
	end)

	local buttons = {}
	for i, opt in ipairs(options) do
		local btn = Instance.new("TextButton")
		btn.Name = opt.key
		btn.Size = UDim2.new(1 / #options, -6, 0, 28)
		btn.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Text = opt.label
		btn.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 11
		btn.LayoutOrder = i
		btn.Parent = row
		corner(btn, 4)

		local function paint()
			local on = opt.key == selectedKey
			btn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.panelAlt or Color3.fromRGB(27, 32, 41))
			btn.TextColor3 = on and (P.accentOn or Color3.fromRGB(15, 19, 29)) or (P.textDim or Color3.fromRGB(185, 202, 203))
		end
		paint()
		btn.MouseButton1Click:Connect(function()
			selectedKey = opt.key
			for _, b in ipairs(buttons) do
				b.paint()
			end
			onSelect(opt.key)
		end)
		buttons[#buttons + 1] = { paint = paint }
	end
	return row
end

local function makeSwatches(parent, current, onPick, onReset, P)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 36)
	row.Position = UDim2.fromOffset(10, 28)
	row.BackgroundTransparency = 1
	row.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local function isCur(c)
		if not current then
			return c.r == 0 and c.g == 242 and c.b == 254
		end
		return tonumber(current.r) == c.r
			and tonumber(current.g) == c.g
			and tonumber(current.b) == c.b
	end

	local swatches = {}
	for i, c in ipairs(ACCENTS) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(28, 28)
		btn.BackgroundColor3 = Color3.fromRGB(c.r, c.g, c.b)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Text = ""
		btn.LayoutOrder = i
		btn.Parent = row
		corner(btn, 4)
		local ring = Instance.new("UIStroke")
		ring.Thickness = 2
		ring.Color = isCur(c) and (P.text or Color3.new(1, 1, 1)) or (P.line or Color3.fromRGB(58, 73, 75))
		ring.Parent = btn

		btn.MouseButton1Click:Connect(function()
			current = { r = c.r, g = c.g, b = c.b }
			for _, s in ipairs(swatches) do
				s.ring.Color = s.isCur() and (P.text or Color3.new(1, 1, 1)) or (P.line or Color3.fromRGB(58, 73, 75))
			end
			onPick(c.r, c.g, c.b)
		end)
		swatches[#swatches + 1] = {
			ring = ring,
			isCur = function()
				return isCur(c)
			end,
		}
	end

	local reset = Instance.new("TextButton")
	reset.Size = UDim2.fromOffset(64, 28)
	reset.BackgroundColor3 = P.btn or Color3.fromRGB(38, 42, 52)
	reset.BorderSizePixel = 0
	reset.AutoButtonColor = true
	reset.Text = "↺"
	reset.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	reset.Font = Enum.Font.GothamBold
	reset.TextSize = 14
	reset.LayoutOrder = #ACCENTS + 1
	reset.Parent = row
	corner(reset, 4)
	reset.MouseButton1Click:Connect(function()
		current = { r = 0, g = 242, b = 254 }
		for _, s in ipairs(swatches) do
			s.ring.Color = s.isCur() and (P.text or Color3.new(1, 1, 1)) or (P.line or Color3.fromRGB(58, 73, 75))
		end
		onReset()
	end)
	return row
end

	local function makeAlpha(parent, startV, onInput, P)
		local box = Instance.new("Frame")
		box.Size = UDim2.new(1, -20, 0, 64)
		box.Position = UDim2.fromOffset(10, 28)
		box.BackgroundTransparency = 1
		box.Parent = parent

		local readout = Instance.new("TextLabel")
		readout.Size = UDim2.new(0, 48, 0, 16)
		readout.Position = UDim2.new(1, -48, 0, 0)
		readout.BackgroundTransparency = 1
		readout.Text = tostring(math.floor(startV * 100 + 0.5)) .. "%"
		readout.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)
		readout.Font = Enum.Font.Code
		readout.TextSize = 14
		readout.TextXAlignment = Enum.TextXAlignment.Right
		readout.Parent = box

		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(1, -56, 0, 14)
		hint.Position = UDim2.fromOffset(0, 0)
		hint.BackgroundTransparency = 1
		hint.Text = "0% = opaque · 85% = clear"
		hint.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 10
		hint.TextXAlignment = Enum.TextXAlignment.Left
		hint.Parent = box

		local hit = Instance.new("TextButton")
		hit.Name = "AlphaHit"
		hit.Size = UDim2.new(1, 0, 0, 40)
		hit.Position = UDim2.fromOffset(0, 20)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.AutoButtonColor = false
		hit.Parent = box

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, 0, 0, 8)
		track.Position = UDim2.fromOffset(0, 36)
		track.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)
		track.BorderSizePixel = 0
		track.Active = false
		track.Parent = box
		corner(track, 99)

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(math.clamp(startV / 0.85, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)
		fill.BorderSizePixel = 0
		fill.Parent = track
		corner(fill, 99)

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.fromOffset(18, 18)
		thumb.Position = UDim2.new(math.clamp(startV / 0.85, 0, 1), -9, 0.5, -9)
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

		local value = math.clamp(startV or 0, 0, 0.85)
		local dragging = false
		local UIS = game:GetService("UserInputService")

		local function paint()
			local frac = math.clamp(value / 0.85, 0, 1)
			fill.Size = UDim2.new(frac, 0, 1, 0)
			thumb.Position = UDim2.new(frac, -9, 0.5, -9)
			readout.Text = tostring(math.floor(value * 100 + 0.5)) .. "%"
		end

		local function fromInput(input)
			local abs = track.AbsolutePosition.X
			local sizeX = track.AbsoluteSize.X
			if sizeX <= 0 then
				return
			end
			local frac = (input.Position.X - abs) / sizeX
			frac = math.clamp(frac, 0, 1)
			value = frac * 0.85
			paint()
			onInput(value)
		end

		hit.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			dragging = true
			fromInput(input)
		end)

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

		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				if dragging then
					dragging = false
				end
			end
		end)

		paint()
		return box
	end

function SettingsWindow.Open(config)
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
	assert(WindowBase, "WindowBase не загружен")
	local GC = env.GlobalControler
	assert(GC, "GlobalControler не загружен")

	local P = currentPalette() or WindowBase.Palette
	local PAD = 6
	local SAVE_H = 88
	local LANG_H = 72
	local THEME_H = 72
	local COLOR_H = 72
	local ALPHA_H = 96

	local base = WindowBase.new("Settings", GC:Str("settingsName"), 300, 380)
	window = base
	local content = base.Content

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = P.line or Color3.fromRGB(58, 73, 75)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = content

	local placeId, placeName = GC:GetPlaceInfo()
	local statusText = ""

	local ySave = PAD
	local yLang = ySave + SAVE_H + 6
	local yTheme = yLang + LANG_H + 6
	local yColor = yTheme + THEME_H + 6
	local yAlpha = yColor + COLOR_H + 6

	local secSave = section(scroll, GC:Str("settingsSaves"), ySave, SAVE_H, P)

	local statusLbl
	local function setStatus(msg)
		statusText = msg or ""
		if statusLbl then
			statusLbl.Text = statusText
		end
	end

	statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "SaveStatus"
	statusLbl.Size = UDim2.new(1, -20, 0, 14)
	statusLbl.Position = UDim2.fromOffset(10, 66)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = placeName
	statusLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 10
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
	statusLbl.ZIndex = 5
	statusLbl.Parent = secSave

	local function makeBtn(parent, x, w, labelKey, onClick)
		local btn = Instance.new("TextButton")
		btn.Name = labelKey
		btn.Size = UDim2.fromOffset(w, 28)
		btn.Position = UDim2.fromOffset(x, 28)
		btn.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Text = GC:Str(labelKey)
		btn.TextColor3 = P.text or Color3.fromRGB(223, 226, 240)
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 11
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.Parent = parent
		btn.ZIndex = 4
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		pcall(function()
			local s = Instance.new("UIStroke")
			s.Thickness = 1
			s.Color = P.line or Color3.fromRGB(58, 73, 75)
			s.Parent = btn
		end)
		btn.MouseButton1Click:Connect(onClick)
		return btn
	end

	local pickFrame = Instance.new("Frame")
	pickFrame.Name = "PickList"
	pickFrame.Size = UDim2.new(1, -20, 0, 0)
	pickFrame.Position = UDim2.fromOffset(10, 88)
	pickFrame.BackgroundTransparency = 1
	pickFrame.Visible = false
	pickFrame.Parent = secSave
	local pickLayout = Instance.new("UIListLayout")
	pickLayout.Padding = UDim.new(0, 4)
	pickLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pickLayout.Parent = pickFrame

	local function openPicker()
		for _, c in ipairs(pickFrame:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		local list = GC:ListProfiles()
		if #list == 0 then
			pickFrame.Visible = false
			secSave.Size = UDim2.new(1, 0, 0, SAVE_H)
			setStatus(GC:Str("settingsNoSaves"))
			return
		end
		pickFrame.Visible = true
		for i, item in ipairs(list) do
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, 0, 0, 26)
			row.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)
			row.BorderSizePixel = 0
			row.AutoButtonColor = true
			row.Text = "  " .. tostring(item.placeName)
			row.TextColor3 = P.text
			row.Font = Enum.Font.Gotham
			row.TextSize = 11
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.LayoutOrder = i
			row.Parent = pickFrame
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
			row.MouseButton1Click:Connect(function()
				local ok, name = GC:LoadProfilePath(item.path)
				pickFrame.Visible = false
				secSave.Size = UDim2.new(1, 0, 0, SAVE_H)
				if ok then
					setStatus(GC:Str("settingsLoaded") .. " · " .. tostring(name or item.placeName))
				else
					setStatus("error load")
				end
			end)
		end
		local h = SAVE_H + #list * 30 + 8
		pickFrame.Size = UDim2.new(1, -20, 0, #list * 30)
		secSave.Size = UDim2.new(1, 0, 0, h)
		setStatus(GC:Str("settingsLoad"))
	end

	makeBtn(secSave, 10, 92, "settingsSave", function()
		local ok, name = GC:SaveProfile()
		if ok then
			setStatus(GC:Str("settingsSaved") .. " · " .. tostring(name))
		else
			setStatus("error save")
		end
	end)
	makeBtn(secSave, 106, 92, "settingsLoad", openPicker)
	makeBtn(secSave, 202, 82, "settingsResetAll", function()
		pickFrame.Visible = false
		secSave.Size = UDim2.new(1, 0, 0, SAVE_H)
		GC:ResetCurrentProfile()
		setStatus(GC:Str("settingsResetAll"))
	end)

	local autoHint = Instance.new("TextLabel")
	autoHint.Size = UDim2.new(1, -20, 0, 12)
	autoHint.Position = UDim2.fromOffset(10, 54)
	autoHint.BackgroundTransparency = 1
	autoHint.Text = GC:Str("settingsAutoHint")
	autoHint.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)
	autoHint.Font = Enum.Font.Gotham
	autoHint.TextSize = 9
	autoHint.TextXAlignment = Enum.TextXAlignment.Left
	autoHint.Parent = secSave

	local lang = GC.Config and GC.Config.language or "ru"
	local theme = (GC.Config and GC.Config.theme and GC.Config.theme.gui) or "dark"
	local accent = GC.Config and GC.Config.accent
	local alpha = GC:GetHubTransparency()

	local secLang = section(scroll, GC:Str("settingsLang"), yLang, LANG_H, P)
	makeSegments(secLang, {
		{ key = "ru", label = "Русский" },
		{ key = "en", label = "English" },
	}, lang, function(key)
		GC:SetLanguage(key)
	end, P)

	local secTheme = section(scroll, GC:Str("settingsTheme"), yTheme, THEME_H, P)
	makeSegments(secTheme, {
		{ key = "dark", label = "Dark" },
		{ key = "light", label = "Light" },
	}, theme, function(key)
		GC:SetTheme(key)
	end, P)

	local secColor = section(scroll, GC:Str("settingsColor"), yColor, COLOR_H, P)
	makeSwatches(
		secColor,
		accent,
		function(r, g, b)
			GC:SetAccent(r, g, b)
		end,
		function()
			GC:SetAccent(nil)
		end,
		P
	)

	local secAlpha = section(scroll, GC:Str("settingsAlpha"), yAlpha, ALPHA_H, P)
	makeAlpha(secAlpha, alpha, function(v)
		GC:SetHubTransparency(v)
	end, P)

	base:setSize(300, 380)
	base.OnClosed = function()
		window = nil
	end
end

env.SettingsWindow = SettingsWindow
return SettingsWindow
