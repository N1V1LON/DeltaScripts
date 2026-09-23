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

local HEADER_H = 28
local CORNER = UDim.new(0, 4)
local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

WindowBase.Palette = {
	bg = Color3.fromRGB(15, 19, 29),
	header = Color3.fromRGB(23, 28, 37),
	panel = Color3.fromRGB(23, 28, 37),
	panelAlt = Color3.fromRGB(27, 32, 41),
	line = Color3.fromRGB(58, 73, 75),
	text = Color3.fromRGB(223, 226, 240),
	textDim = Color3.fromRGB(185, 202, 203),
	accent = Color3.fromRGB(0, 242, 254),
	danger = Color3.fromRGB(147, 0, 10),
	dangerText = Color3.fromRGB(255, 180, 171),
	info = Color3.fromRGB(14, 165, 233),
	btn = Color3.fromRGB(38, 42, 52),
	accentOn = Color3.fromRGB(0, 55, 58),
}

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function currentPalette()
	local GC = env.GlobalControler
	if GC and type(GC.ModuleTheme) == "table" then
		return GC.ModuleTheme
	end
	return WindowBase.Palette
end

function WindowBase.tweenSize(frame, w, h)
	local tween = TweenService:Create(frame, TWEEN, { Size = UDim2.fromOffset(w, h) })
	tween:Play()
	return tween
end

function WindowBase.new(key, titleText, w, h)
	if WindowBase.Registry[key] then
		WindowBase.Registry[key]:Destroy()
	end

	w = w or 260
	h = h or 210

	local self = setmetatable({}, WindowBase)
	self.Key = key
	self.Minimized = false
	self.ContentHeight = h

	local GC = env.GlobalControler
	local P = currentPalette()
	self.P = P
	local host = GC and GC._moduleHost
	self._embedded = host ~= nil

	local gui = nil
	if not self._embedded then
		gui = Instance.new("ScreenGui")
		gui.Name = ("%sWindowGui"):format(key)
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 20
		gui.Parent = player:WaitForChild("PlayerGui")
		self.Gui = gui
	end

	local position = UDim2.fromOffset(0, 0)
	if not self._embedded then
		if GC and GC.ClaimPosition then
			self._rect, position = GC:ClaimPosition(w, h)
		else
			WindowBase._spawnN = (WindowBase._spawnN or 0) + 1
			local off = ((WindowBase._spawnN - 1) % 5) * 24
			position = UDim2.fromOffset(70 + off, 70 + off)
		end
	end

	local root = Instance.new("Frame")
	root.Name = ("%sRoot"):format(key)
	root.Position = position
	if self._embedded then
		root.Size = UDim2.new(1, 0, 1, 0)
	else
		root.Size = UDim2.fromOffset(w, h)
	end
	root.BackgroundColor3 = P.bg
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Active = true
	if self._embedded and GC and GC.GetHubTransparency then
		root.BackgroundTransparency = GC:GetHubTransparency()
	end
	root.Parent = self._embedded and host or gui
	self.Root = root

	Instance.new("UICorner", root).CornerRadius = CORNER

	pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = 1
		s.Color = P.line
		s.Parent = root
	end)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = root
	self.Content = content

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, self._embedded and 4 or 8)
	contentPad.PaddingRight = UDim.new(0, self._embedded and 4 or 8)
	contentPad.PaddingTop = UDim.new(0, self._embedded and 4 or 6)
	contentPad.PaddingBottom = UDim.new(0, self._embedded and 4 or 8)
	contentPad.Parent = content
	self.ContentPad = contentPad

	if self._embedded then
		-- hub уже имеет шапку (← / title / ✕) — вторая не нужна
		content.Position = UDim2.fromOffset(0, 0)
		content.Size = UDim2.new(1, 0, 1, 0)
		self.Title = nil
		self.MinimizeButton = nil
		self.CloseButton = nil
		self._destroyed = false
		WindowBase.Registry[key] = self
		return self
	end

	content.Position = UDim2.new(0, 0, 0, HEADER_H)
	content.Size = UDim2.new(1, 0, 1, -HEADER_H)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, HEADER_H)
	header.BackgroundColor3 = P.header
	header.BorderSizePixel = 0
	header.Parent = root

	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.fromOffset(8, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText or "Окно"
	title.TextColor3 = P.text
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = header
	self.Title = title

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.fromOffset(26, HEADER_H)
	minBtn.Position = UDim2.new(1, -56, 0, 0)
	minBtn.BackgroundColor3 = P.btn
	minBtn.BorderSizePixel = 0
	minBtn.AutoButtonColor = true
	minBtn.Text = "—"
	minBtn.TextColor3 = P.text
	minBtn.Font = Enum.Font.GothamSemibold
	minBtn.TextSize = 14
	minBtn.Parent = header
	self.MinimizeButton = minBtn

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(26, HEADER_H)
	closeBtn.Position = UDim2.new(1, -28, 0, 0)
	closeBtn.BackgroundColor3 = P.danger
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = true
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = P.dangerText or Color3.fromRGB(255, 180, 171)
	closeBtn.Font = Enum.Font.GothamSemibold
	closeBtn.TextSize = 12
	closeBtn.Parent = header
	self.CloseButton = closeBtn

	local dragStart, dragPos, dragging
	header.Active = true

	local function isPrimary(ty)
		return ty == Enum.UserInputType.MouseButton1 or ty == Enum.UserInputType.Touch
	end
	local function isMove(ty)
		return ty == Enum.UserInputType.MouseMovement or ty == Enum.UserInputType.Touch
	end

	header.InputBegan:Connect(function(input)
		if not isPrimary(input.UserInputType) or dragging then return end
		if input.Target == closeBtn or input.Target == minBtn then return end
		dragging = true
		dragStart = input.Position
		dragPos = root.Position
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not isMove(input.UserInputType) then return end
		local delta = input.Position - dragStart
		local maxX = math.max(0, gui.AbsoluteSize.X - root.AbsoluteSize.X)
		local maxY = math.max(0, gui.AbsoluteSize.Y - root.AbsoluteSize.Y)
		root.Position = UDim2.new(
			dragPos.X.Scale, math.clamp(dragPos.X.Offset + delta.X, 0, maxX),
			dragPos.Y.Scale, math.clamp(dragPos.Y.Offset + delta.Y, 0, maxY)
		)
	end)

	local function endDrag(input)
		if not isPrimary(input.UserInputType) or not dragging then return end
		dragging = nil
		local GCnow = env.GlobalControler
		if GCnow and self._rect then
			GCnow:UpdateWindow(
				self._rect,
				root.Position.X.Offset,
				root.Position.Y.Offset,
				root.AbsoluteSize.X,
				root.AbsoluteSize.Y
			)
		end
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

	self._destroyed = false
	WindowBase.Registry[key] = self
	return self
end

function WindowBase:setSize(w, h)
	self.ContentHeight = h
	if self._embedded then
		return
	end
	WindowBase.tweenSize(self.Root, w, h)
end

function WindowBase:setTitle(text)
	if self.Title then
		self.Title.Text = text
	end
end

function WindowBase:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if WindowBase.Registry[self.Key] == self then
		WindowBase.Registry[self.Key] = nil
	end
	local GC = env.GlobalControler
	if GC and self._rect then
		GC:ReleaseWindow(self._rect)
		self._rect = nil
	end
	local embedded = self._embedded
	if self.OnClosed then
		pcall(self.OnClosed, self)
	end
	if self.Gui then
		pcall(function()
			self.Gui:Destroy()
		end)
	else
		pcall(function()
			self.Root:Destroy()
		end)
	end
	if embedded and GC and GC.ExitModuleView then
		GC:ExitModuleView()
		if GC.RenderTab then
			GC:RenderTab()
		end
		if GC.ApplyHubTransparency and GC.GetHubTransparency then
			GC:ApplyHubTransparency(GC:GetHubTransparency())
		end
	end
end

env.WindowBase = WindowBase
return WindowBase
