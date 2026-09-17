local env = getgenv and getgenv() or _G
if env.FloatingWindow then return env.FloatingWindow end

local WindowBase = env.WindowBase
assert(WindowBase, "WindowBase не загружен")

local FloatingWindow = {}
FloatingWindow.__index = FloatingWindow

local P = WindowBase.Palette

local MIN_W = 250
local HEADER_H = 36
local PAD = 8
local ROW_H = 44
local MAX_ROWS = 6

function FloatingWindow.new(title)
	local self = setmetatable({}, FloatingWindow)

	local base = WindowBase.new("Scripts", title or "Скрипты")
	self.Base = base
	self.Gui = base.Gui
	self.Root = base.Root
	self.Content = base.Content

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(PAD, PAD)
	list.Size = UDim2.new(1, -PAD * 2, 1, -PAD * 2)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = P.line
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = base.Content

	self.List = list
	self._lastData = nil
	self._sizeTween = nil

	base:setSize(MIN_W, HEADER_H + PAD * 2)
	return self
end

function FloatingWindow:setSize(w, h)
	self.Base:setSize(w, h)
end

function FloatingWindow:Render(listData)
	self._lastData = listData or {}
	for _, child in ipairs(self.List:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local count = #self._lastData
	local rows = math.min(count, MAX_ROWS)
	local windowH = math.max(HEADER_H + PAD * 2, HEADER_H + PAD * 2 + rows * ROW_H)
	self:setSize(MIN_W, windowH)

	if count == 0 then
		self.List.CanvasSize = UDim2.fromOffset(0, 0)
		return
	end

	for i, data in ipairs(self._lastData) do
		local btn = Instance.new("TextButton")
		btn.Name = "Module_" .. i
		btn.Size = UDim2.new(1, 0, 0, ROW_H - 4)
		btn.Position = UDim2.fromOffset(0, (i - 1) * ROW_H)
		btn.BackgroundColor3 = data.hasAccess and Color3.fromRGB(47, 57, 47) or Color3.fromRGB(57, 47, 47)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Text = ""
		btn.Parent = self.List

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		local status = Instance.new("Frame")
		status.Name = "Status"
		status.Size = UDim2.fromOffset(4, ROW_H - 12)
		status.Position = UDim2.new(0, 4, 0.5, -(ROW_H - 12) / 2)
		status.BackgroundColor3 = data.hasAccess and P.accent or P.danger
		status.BorderSizePixel = 0
		status.Parent = btn
		Instance.new("UICorner", status).CornerRadius = UDim.new(0, 2)

		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.Size = UDim2.new(1, -16, 0, 18)
		name.Position = UDim2.new(0, 14, 0, 5)
		name.BackgroundTransparency = 1
		name.Text = data.name
		name.TextColor3 = P.text
		name.Font = Enum.Font.GothamSemibold
		name.TextSize = 14
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Parent = btn

		local what = Instance.new("TextLabel")
		what.Name = "What"
		what.Size = UDim2.new(1, -16, 0, 14)
		what.Position = UDim2.new(0, 14, 0, 23)
		what.BackgroundTransparency = 1
		what.Text = (data.hasAccess and "● " or "○ ") .. (data.what or "")
		what.Font = Enum.Font.Gotham
		what.TextSize = 11
		what.TextColor3 = P.textDim
		what.TextXAlignment = Enum.TextXAlignment.Left
		what.TextTruncate = Enum.TextTruncate.AtEnd
		what.Parent = btn

		local runnable = data.hasAccess
		btn.MouseButton1Click:Connect(function()
			if not runnable or not data.run then return end
			local ok, err = pcall(data.run)
			if not ok then
				warn(("[ControlerScript] %s: %s"):format(data.name, tostring(err)))
			end
		end)
	end

	self.List.CanvasSize = UDim2.fromOffset(0, count * ROW_H)
end

function FloatingWindow:Destroy()
	self.Base:Destroy()
end

env.FloatingWindow = FloatingWindow
return FloatingWindow