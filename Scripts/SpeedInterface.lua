local env = getgenv and getgenv() or _G
local ScriptModule = env.ScriptModule
local SpeedLogic = env.SpeedLogic
local WindowBase = env.WindowBase
assert(ScriptModule, "ScriptModule не загружен")
assert(SpeedLogic, "SpeedLogic не загружен")
assert(WindowBase, "WindowBase не загружен")

local P = WindowBase.Palette

local window = nil

local PAD = 10
local BTN_H = 36
local WIN_WIDTH = 260

local function createStatusLabel(parent)
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(PAD, PAD)
	status.Size = UDim2.new(1, -PAD * 2, 0, 22)
	status.BackgroundTransparency = 1
	status.TextColor3 = P.text
	status.Font = Enum.Font.GothamSemibold
	status.TextSize = 15
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = parent
	return status
end

local function createSpeedBox(parent)
	local box = Instance.new("TextBox")
	box.Name = "SpeedBox"
	box.Position = UDim2.fromOffset(PAD, PAD + 28)
	box.Size = UDim2.new(1, -PAD * 2, 0, 34)
	box.BackgroundColor3 = P.panelAlt
	box.BorderSizePixel = 0
	box.PlaceholderText = "Скорость"
	box.PlaceholderColor3 = P.textDim
	box.TextColor3 = P.text
	box.Font = Enum.Font.GothamSemibold
	box.TextSize = 15
	box.Parent = parent
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
	return box
end

local function createButton(parent, name, text, posY, bgColor, textColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Position = UDim2.fromOffset(PAD, posY)
	btn.Size = UDim2.new(1, -PAD * 2, 0, BTN_H)
	btn.BackgroundColor3 = bgColor
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = textColor
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 16
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local function bindWindowEvents(status, box, applyBtn, resetBtn)
	local function refreshStatus()
		status.Text = ("Текущая скорость: %.0f"):format(SpeedLogic.getCurrentSpeed())
	end

	applyBtn.MouseButton1Click:Connect(function()
		if not SpeedLogic.canRun() then
			status.Text = "Нет персонажа"
			return
		end
		local value = tonumber(box.Text)
		if not value then
			status.Text = "Некорректное число"
			return
		end
		SpeedLogic.setSpeed(value)
		refreshStatus()
	end)

	resetBtn.MouseButton1Click:Connect(function()
		if not SpeedLogic.canRun() then return end
		SpeedLogic.resetSpeed()
		box.Text = tostring(SpeedLogic.getBaseSpeed())
		refreshStatus()
	end)

	refreshStatus()
	box.Text = tostring(SpeedLogic.getCurrentSpeed())
end

local function openWindow()
	if window then
		window:Destroy()
		window = nil
		return
	end

	local base = WindowBase.new("Speed", "Скорость")
	window = base

	local content = base.Content

	local status = createStatusLabel(content)
	local box = createSpeedBox(content)

	local applyPosY = PAD + 28 + 42
	local applyBtn = createButton(content, "Apply", "Применить", applyPosY, P.accent, Color3.new(1, 1, 1))

	local resetPosY = applyPosY + BTN_H + 8
	local resetText = "Сброс (" .. SpeedLogic.BASE_SPEED .. ")"
	local resetBtn = createButton(content, "Reset", resetText, resetPosY, P.btn, P.text)

	bindWindowEvents(status, box, applyBtn, resetBtn)

	local contentH = resetPosY + BTN_H + PAD
	base:setSize(WIN_WIDTH, 36 + contentH)

	base.OnClosed = function()
		window = nil
	end
end

ScriptModule.new({
	gui = {
		name = "Скорость",
		desc = "Управление WalkSpeed",
		icon = "rbxassetid://0",
		group = "Движение",
		what = function()
			if not SpeedLogic.canRun() then return "нет персонажа" end
			return ("скорость: %.0f"):format(SpeedLogic.getCurrentSpeed())
		end,
	},
	logic = {
		canRun = function()
			return SpeedLogic.canRun()
		end,
		run = function()
			openWindow()
		end,
		unload = function()
			if window then
				window:Destroy()
				window = nil
			end
		end,
	},
})