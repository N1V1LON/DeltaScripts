local env = getgenv and getgenv() or _G
if env.TPWindow then return env.TPWindow end

local TPWindow = {}
TPWindow.GetTable = "Player"
TPWindow.GetPosition = 2

local function Str(key, fallback)
	local GC = env.GlobalControler
	if GC and GC.Str then
		return GC:Str(key)
	end
	return fallback
end

function TPWindow.Name()
	return Str("tpName", "Телепорт")
end

function TPWindow.Desc()
	return Str("tpDesc", "Точки, ТП и удаление")
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

local function destroyButtons(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function TPWindow.Open(config)
	config = config or {}
	if window then
		window:Destroy()
		window = nil
		return
	end

	local WindowBase = env.WindowBase
	local TPLogic = env.TPLogic
	assert(WindowBase, "WindowBase не загружен")
	assert(TPLogic, "TPLogic не загружен")

	local P = currentPalette()
	local holdTime = tonumber(config.holdTime) or 0.7
	local WIDTH = 280
	local ROW_H = 40
	local btnH = 36
	local PAD = 6

	local base = WindowBase.new("TP", TPWindow.Name(), WIDTH, 280)
	window = base
	local content = base.Content

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Position = UDim2.fromOffset(0, 2)
	hint.Size = UDim2.new(1, 0, 0, 14)
	hint.BackgroundTransparency = 1
	hint.Text = Str("tpHint", "нажми — тп, удерживай — удалить")
	hint.TextColor3 = P.textDim
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 10
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = content

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(0, 18)
	list.Size = UDim2.new(1, 0, 1, -(18 + btnH + PAD * 2))
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = P.line
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local addBtn = Instance.new("TextButton")
	addBtn.Name = "Add"
	addBtn.Position = UDim2.new(0, 0, 1, -(btnH + PAD))
	addBtn.Size = UDim2.new(1, 0, 0, btnH)
	addBtn.BackgroundColor3 = P.info
	addBtn.BorderSizePixel = 0
	addBtn.AutoButtonColor = true
	addBtn.Text = Str("tpAdd", "+ Добавить точку")
	addBtn.TextColor3 = Color3.new(1, 1, 1)
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 13
	addBtn.Parent = content
	Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 4)

	local function refresh()
		if not window then return end
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local pts = TPLogic.getPoints()
		for i, pos in ipairs(pts) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -4, 0, ROW_H - 4)
			btn.BackgroundColor3 = P.panel
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = true
			btn.Text = ""
			btn.LayoutOrder = i
			btn.Parent = list
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			pcall(function()
				local s = Instance.new("UIStroke")
				s.Thickness = 1
				s.Color = P.line
				s.Parent = btn
			end)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -110, 1, -8)
			label.Position = UDim2.fromOffset(8, 4)
			label.BackgroundTransparency = 1
			label.Text = ("Точка %d"):format(i)
			label.TextColor3 = P.text
			label.Font = Enum.Font.GothamSemibold
			label.TextSize = 12
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = btn

			local coords = Instance.new("TextLabel")
			coords.Name = "Coords"
			coords.Size = UDim2.new(0, 96, 1, -8)
			coords.Position = UDim2.new(1, -104, 0, 4)
			coords.BackgroundTransparency = 1
			coords.Text = ("(%.0f, %.0f, %.0f)"):format(pos.X, pos.Y, pos.Z)
			coords.TextColor3 = P.textDim
			coords.Font = Enum.Font.Code
			coords.TextSize = 10
			coords.TextXAlignment = Enum.TextXAlignment.Right
			coords.TextTruncate = Enum.TextTruncate.AtEnd
			coords.Parent = btn

			local index = i
			local holdTask = nil
			local deleted = false

			btn.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				deleted = false
				holdTask = task.delay(holdTime, function()
					if deleted then return end
					deleted = true
					TPLogic.deletePoint(index)
					refresh()
				end)
			end)

			btn.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch then
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

		local count = #pts
		local listH = math.max(count * ROW_H, 60)
		local contentH = math.min(18 + listH + btnH + PAD * 2, 360)
		base:setSize(WIDTH, 28 + contentH)
		list.Size = UDim2.new(1, 0, 1, -(18 + btnH + PAD * 2))
		list.CanvasSize = UDim2.fromOffset(0, 0)
	end

	addBtn.MouseButton1Click:Connect(function()
		if not TPLogic.canRun() then
			warn("[TPWindow] персонаж не заспавнен")
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

env.TPWindow = TPWindow
return TPWindow
