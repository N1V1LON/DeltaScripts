local Mock = {}

-- Create Enum table
local EnumMock = {
	EasingStyle = { Quad = "Quad" },
	EasingDirection = { Out = "Out" },
	ZIndexBehavior = { Sibling = "Sibling" },
	Font = { GothamSemibold = "GothamSemibold" },
	TextXAlignment = { Left = "Left" },
	TextTruncate = { AtEnd = "AtEnd" },
	UserInputType = {
		MouseButton1 = "MouseButton1",
		Touch = "Touch",
		MouseMovement = "MouseMovement",
		Keyboard = "Keyboard",
	},
}
_G.Enum = EnumMock

-- Position helper table with metatable for subtraction
local PosMT = {}
PosMT.__index = PosMT

function PosMT.__sub(a, b)
	return Mock.createPos(a.X - b.X, a.Y - b.Y)
end

function Mock.createPos(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, PosMT)
end

-- Signal / Connection implementation
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
	table.insert(self._listeners, fn)
	local conn = {
		Connected = true,
		Disconnect = function(c)
			c.Connected = false
			for i, listener in ipairs(self._listeners) do
				if listener == fn then
					table.remove(self._listeners, i)
					break
				end
			end
		end,
	}
	return conn
end

function Signal:Fire(...)
	local listeners = { unpack(self._listeners) }
	for _, fn in ipairs(listeners) do
		fn(...)
	end
end

-- Instance class mock
local InstanceClass = {}

function InstanceClass.new(className)
	local inst = {
		ClassName = className,
		Name = className,
		_parent = nil,
		Children = {},
		AbsoluteSize = { X = 800, Y = 600 },
		Position = nil,
		Size = nil,
		_destroyed = false,

		-- Events
		InputBegan = Signal.new(),
		InputChanged = Signal.new(),
		InputEnded = Signal.new(),
		MouseButton1Click = Signal.new(),
		Changed = Signal.new(),
	}
	return setmetatable(inst, InstanceClass)
end

function InstanceClass:WaitForChild(name)
	for _, child in ipairs(self.Children) do
		if child.Name == name then
			return child
		end
	end
	local child = Instance.new("Folder")
	child.Name = name
	child.Parent = self
	return child
end

function InstanceClass:FindFirstChild(name)
	for _, child in ipairs(self.Children) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function InstanceClass:GetChildren()
	return self.Children
end

function InstanceClass:IsA(className)
	return self.ClassName == className
end

function InstanceClass:Destroy()
	self._destroyed = true
	self.Parent = nil
end

InstanceClass.__index = function(t, k)
	if k == "Parent" then
		return rawget(t, "_parent")
	end
	local val = rawget(t, k)
	if val ~= nil then
		return val
	end
	return InstanceClass[k]
end

InstanceClass.__newindex = function(t, k, v)
	if k == "Parent" then
		local oldParent = rawget(t, "_parent")
		if oldParent == v then return end
		if oldParent then
			for i, child in ipairs(oldParent.Children) do
				if child == t then
					table.remove(oldParent.Children, i)
					break
				end
			end
		end
		rawset(t, "_parent", v)
		if v then
			table.insert(v.Children, t)
		end
	else
		rawset(t, k, v)
	end
end

local Instance = {}

function Instance.new(className, parent)
	local obj = InstanceClass.new(className)
	if parent then
		obj.Parent = parent
	end
	return obj
end

_G.Instance = Instance

-- Datatypes
_G.UDim = {
	new = function(scale, offset)
		return { Scale = scale or 0, Offset = offset or 0 }
	end,
}

_G.UDim2 = {
	new = function(sx, ox, sy, oy)
		return {
			X = { Scale = sx or 0, Offset = ox or 0 },
			Y = { Scale = sy or 0, Offset = oy or 0 },
		}
	end,
	fromOffset = function(x, y)
		return {
			X = { Scale = 0, Offset = x or 0 },
			Y = { Scale = 0, Offset = y or 0 },
		}
	end,
}

_G.Color3 = {
	fromRGB = function(r, g, b)
		return { R = r / 255, G = g / 255, B = b / 255 }
	end,
	new = function(r, g, b)
		return { R = r or 0, G = g or 0, B = b or 0 }
	end,
}

_G.TweenInfo = {
	new = function(...)
		return { args = { ... } }
	end,
}

-- Services
local LocalPlayer = Instance.new("Folder")
LocalPlayer.Name = "LocalPlayer"

local PlayerGui = Instance.new("Folder")
PlayerGui.Name = "PlayerGui"
PlayerGui.Parent = LocalPlayer

local Players = {
	LocalPlayer = LocalPlayer,
}

local TweenService = {
	CreatedTweens = {},
	Create = function(self, instance, tweenInfo, goals)
		local tween = {
			Instance = instance,
			TweenInfo = tweenInfo,
			Goals = goals,
			Played = false,
			Play = function(t)
				t.Played = true
				if goals.Size then
					instance.Size = goals.Size
				end
			end,
		}
		table.insert(self.CreatedTweens, tween)
		return tween
	end,
}

local UserInputService = {
	InputChanged = Signal.new(),
	InputEnded = Signal.new(),
}

local Services = {
	Players = Players,
	TweenService = TweenService,
	UserInputService = UserInputService,
}

_G.game = {
	GetService = function(self, serviceName)
		return Services[serviceName]
	end,
}

Mock.Services = Services
Mock.Signal = Signal
Mock.PlayerGui = PlayerGui
Mock.LocalPlayer = LocalPlayer
return Mock
