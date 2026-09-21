local env = getgenv and getgenv() or _G
if env.WindowBase then return env.WindowBase end

local WindowBase = {}
WindowBase.__index = WindowBase

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

WindowBase.Registry = env.WindowRegistry or {}
env.WindowRegistry = WindowBase.Registry

local HEADER_H = 36
local CORNER = UDim.new(0, 10)
local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

WindowBase.Palette = {
	bg = Color3.fromRGB(27, 27, 33),
	header = Color3.fromRGB(38, 38, 46),
	panel = Color3.fromRGB(47, 47, 57),
	panelAlt = Color3.fromRGB(56, 56, 68),
	line = Color3.fromRGB(62, 62, 74),
	text = Color3.fromRGB(235, 235, 245),
	textDim = Color3.fromRGB(150, 150, 165),
	accent = Color3.fromRGB(78, 133, 96),
	danger = Color3.fromRGB(168, 76, 76),
	info = Color3.fromRGB(70, 108, 172),
	btn = Color3.fromRGB(50, 50, 60),
}

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

function WindowBase.tweenSize(frame, w, h)
	local tween = TweenService:Create(frame, TWEEN, { Size = UDim2.fromOffset(w, h) })
	tween:Play()
	return tween
end

function WindowBase.new(key, titleText, position)
	if WindowBase.Registry[key] then
		WindowBase.Registry[key]:Destroy()
	end

	local self = setmetatable({}, WindowBase)
	self.Key = key
	self.Minimized = false
	self.ContentHeight = 200
	self.OnClosed = nil

	local P = WindowBase.Palette

	local gui = Instance.new("ScreenGui")
	gui.Name = ("%sWindowGui"):format(key)
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = Instance.new("Frame")
	root.Name = ("%sRoot"):format(key)
	if position then
		root.Position = position
	else
		WindowBase._spawnN = (WindowBase._spawnN or 0) + 1
		local off = ((WindowBase._spawnN - 1) % 5) * 24
		root.Position = UDim2.fromOffset(60 + off, 60 + off)
	end
	root.Size = UDim2.fromOffset(240, 200)
	root.BackgroundColor3 = P.bg
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Active = true
	root.Parent = gui

	Instance.new("UICorner", root).CornerRadius = CORNER

	pcall(function()
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = P.line
		stroke.Parent = root
	end)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = P.header
	header.BorderSizePixel = 0
	header.Parent = root

	local headerCorner = Instance.new("UICorner", header)
	headerCorner.CornerRadius = UDim.new(0, 10)

	local headerDivider = Instance.new("Frame")
	headerDivider.Name = "HeaderDivider"
	headerDivider.Size = UDim2.new(1, -4, 0, 1)
	headerDivider.Position = UDim2.new(0, 2, 1, -1)
	headerDivider.BackgroundColor3 = P.line
	headerDivider.BorderSizePixel = 0
	headerDivider.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -84, 1, 0)
	title.Position = UDim2.fromOffset(12, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText or "Окно"
	title.TextColor3 = P.text
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = header

	local btnSize = UDim2.fromOffset(32, HEADER_H)

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = btnSize
	minBtn.Position = UDim2.new(1, -70, 0, 0)
	minBtn.BackgroundColor3 = P.btn
	minBtn.BorderSizePixel = 0
	minBtn.AutoButtonColor = true
	minBtn.Text = "—"
	minBtn.TextColor3 = P.text
	minBtn.Font = Enum.Font.GothamSemibold
	minBtn.TextSize = 18
	minBtn.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = btnSize
	closeBtn.Position = UDim2.new(1, -34, 0, 0)
	closeBtn.BackgroundColor3 = P.danger
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = true
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamSemibold
	closeBtn.TextSize = 15
	closeBtn.Parent = header

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -HEADER_H)
	content.Position = UDim2.new(0, 0, 0, HEADER_H)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = root

	local dragInput = nil
	local dragStart = nil
	local dragPos = nil

	local function isDragType(t)
		return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
	end

	local function applyDrag(input)
		if not dragStart then return end
		local delta = input.Position - dragStart
		local maxX = math.max(0, gui.AbsoluteSize.X - root.AbsoluteSize.X)
		local maxY = math.max(0, gui.AbsoluteSize.Y - root.AbsoluteSize.Y)
		local x = clamp(dragPos.X.Offset + delta.X, 0, maxX)
		local y = clamp(dragPos.Y.Offset + delta.Y, 0, maxY)
		root.Position = UDim2.fromOffset(x, y)
	end

	header.InputBegan:Connect(function(input)
		if not isDragType(input.UserInputType) then return end
		if dragInput then return end
		dragInput = input
		dragStart = input.Position
		dragPos = root.Position

		input.Changed:Connect(function()
			if input ~= dragInput then return end
			local t = input.UserInputType
			if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
			applyDrag(input)
		end)
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragInput then return end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
		applyDrag(input)
	end)

	local function endDrag(input)
		if input ~= dragInput then return end
		dragInput = nil
		dragStart = nil
		dragPos = nil
	end

	header.InputEnded:Connect(endDrag)
	UserInputService.InputEnded:Connect(endDrag)

	minBtn.MouseButton1Click:Connect(function()
		if self.Minimized then
			self.Minimized = false
			WindowBase.tweenSize(root, root.AbsoluteSize.X, self.ContentHeight)
			minBtn.Text = "—"
		else
			self.Minimized = true
			self.ContentHeight = root.AbsoluteSize.Y
			WindowBase.tweenSize(root, root.AbsoluteSize.X, HEADER_H)
			minBtn.Text = "+"
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	self.Gui = gui
	self.Root = root
	self.Header = header
	self.Content = content
	self.Title = title
	self.MinimizeButton = minBtn
	self.CloseButton = closeBtn
	self._destroyed = false

	WindowBase.Registry[key] = self

	return self
end

function WindowBase:setSize(w, h)
	self.ContentHeight = h
	WindowBase.tweenSize(self.Root, w, h)
end

function WindowBase:setTitle(text)
	self.Title.Text = text
end

function WindowBase:bringToFront()
	self.Gui.DisplayOrder = (self.Gui.DisplayOrder or 0) + 1
end

function WindowBase:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if WindowBase.Registry[self.Key] == self then
		WindowBase.Registry[self.Key] = nil
	end
	if self.OnClosed then
		self.OnClosed(self)
	end
	self.Gui:Destroy()
end

env.WindowBase = WindowBase
return WindowBase