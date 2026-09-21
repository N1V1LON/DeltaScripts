local env = getgenv and getgenv() or _G
local ScriptModule = env.ScriptModule
local TPLogic = env.TPLogic
local WindowBase = env.WindowBase
assert(ScriptModule, "ScriptModule не загружен")
assert(TPLogic, "TPLogic не загружен")
assert(WindowBase, "WindowBase не загружен")

local HOLD_TIME = 0.7
local WIDTH = 280
local ROW_H = 40
local P = WindowBase.Palette
local window = nil

local function destroyButtons(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function createPointRow(list, index, pos, refreshFn)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, ROW_H - 4)
	btn.Position = UDim2.fromOffset(0, (index - 1) * ROW_H)
	btn.BackgroundColor3 = Color3.fromRGB(67, 47, 47)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.Parent = list
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.fromOffset(10, 0)
	label.BackgroundTransparency = 1
	label.Text = ("Точка %d   (%.0f, %.0f, %.0f)"):format(index, pos.X, pos.Y, pos.Z)
	label.TextColor3 = P.text
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = btn

	local holdTask = nil
	local deleted = false

	btn.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		deleted = false
		holdTask = task.delay(HOLD_TIME, function()
			if deleted then return end
			deleted = true
			TPLogic.deletePoint(index)
			refreshFn()
		end)
	end)

	btn.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if holdTask then
			task.cancel(holdTask)
			holdTask = nil
		end
		if deleted then return end
		TPLogic.teleportTo(index)
	end)
end

local function refreshList(base, list, btnH, pad)
	if not window then return end
	destroyButtons(list)

	local pts = TPLogic.getPoints()
	for i, pos in ipairs(pts) do
		createPointRow(list, i, pos, function()
			refreshList(base, list, btnH, pad)
		end)
	end

	local count = #pts
	local contentH = math.max(24 + count * ROW_H + btnH + pad * 2, 140)
	base:setSize(WIDTH, 36 + math.min(contentH, 420))
	list.CanvasSize = UDim2.fromOffset(0, math.max(count * ROW_H, 0))
end

local function createWindowContent(content, btnH, pad)
	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(pad, 6)
	hint.Size = UDim2.new(1, -pad * 2, 0, 16)
	hint.BackgroundTransparency = 1
	hint.Text = "нажми — тп, удерживай — удалить"
	hint.TextColor3 = P.textDim
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 11
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = content

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(pad, 24)
	list.Size = UDim2.new(1, -pad * 2, 1, -(24 + btnH + pad * 2))
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = P.line
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = content

	local addBtn = Instance.new("TextButton")
	addBtn.Name = "Add"
	addBtn.Position = UDim2.new(0, pad, 1, -(btnH + pad))
	addBtn.Size = UDim2.new(1, -pad * 2, 0, btnH)
	addBtn.BackgroundColor3 = P.info
	addBtn.BorderSizePixel = 0
	addBtn.Text = "Добавить точку"
	addBtn.TextColor3 = Color3.new(1, 1, 1)
	addBtn.Font = Enum.Font.GothamSemibold
	addBtn.TextSize = 15
	addBtn.Parent = content
	Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 8)

	return hint, list, addBtn
end

local function openWindow()
	if window then
		window:Destroy()
		window = nil
		return
	end

	local base = WindowBase.new("TP", "Телепорт")
	window = base

	local pad = 10
	local btnH = 38

	local _, list, addBtn = createWindowContent(base.Content, btnH, pad)

	local function refresh()
		refreshList(base, list, btnH, pad)
	end

	addBtn.MouseButton1Click:Connect(function()
		if not TPLogic.canRun() then
			warn("[TPInterface] персонаж не заспавнен")
			return
		end
		TPLogic.addPoint()
		refresh()
	end)

	base.OnClosed = function()
		window = nil
	end

	refresh()
end

ScriptModule.new({
	gui = {
		name = "Телепорт",
		desc = "Точки с лёгким управлением",
		icon = "rbxassetid://0",
		group = "Движение",
		what = function()
			return window and "окно открыто" or ("точек: " .. #TPLogic.getPoints())
		end,
	},
	logic = {
		canRun = function()
			return TPLogic.canRun()
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
