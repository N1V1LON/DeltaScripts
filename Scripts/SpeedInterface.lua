local env = getgenv and getgenv() or _G
local ScriptModule = env.ScriptModule
local SpeedLogic = env.SpeedLogic
local WindowBase = env.WindowBase
assert(ScriptModule, "ScriptModule не загружен")
assert(SpeedLogic, "SpeedLogic не загружен")
assert(WindowBase, "WindowBase не загружен")

local P = WindowBase.Palette

local window = nil

local function openWindow()
	if window then
		window:Destroy()
		window = nil
		return
	end

	local base = WindowBase.new("Speed", "Скорость")
	window = base

	local W = 260
	local H = 210
	local PAD = 10
	local btnH = 36
	local content = base.Content

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(PAD, PAD)
	status.Size = UDim2.new(1, -PAD * 2, 0, 22)
	status.BackgroundTransparency = 1
	status.TextColor3 = P.text
	status.Font = Enum.Font.GothamSemibold
	status.TextSize = 15
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = content

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
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

	local applyBtn = Instance.new("TextButton")
	applyBtn.Name = "Apply"
	applyBtn.Position = UDim2.fromOffset(PAD, PAD + 28 + 42)
	applyBtn.Size = UDim2.new(1, -PAD * 2, 0, btnH)
	applyBtn.BackgroundColor3 = P.accent
	applyBtn.BorderSizePixel = 0
	applyBtn.Text = "Применить"
	applyBtn.TextColor3 = Color3.new(1, 1, 1)
	applyBtn.Font = Enum.Font.GothamSemibold
	applyBtn.TextSize = 16
	applyBtn.Parent = content
	Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 8)

	local resetBtn = Instance.new("TextButton")
	resetBtn.Name = "Reset"
	resetBtn.Position = UDim2.fromOffset(PAD, PAD + 28 + 42 + btnH + 8)
	resetBtn.Size = UDim2.new(1, -PAD * 2, 0, btnH)
	resetBtn.BackgroundColor3 = P.btn
	resetBtn.BorderSizePixel = 0
	resetBtn.Text = "Сброс (" .. SpeedLogic.BASE_SPEED .. ")"
	resetBtn.TextColor3 = P.text
	resetBtn.Font = Enum.Font.GothamSemibold
	resetBtn.TextSize = 16
	resetBtn.Parent = content
	Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

	local contentH = PAD + 28 + 42 + btnH + 8 + btnH + PAD
	base:setSize(W, 36 + contentH)

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