-- Mock Roblox & Lua environment globals
package.path = "./Scripts/?.lua;./?.lua;" .. package.path

UDim = {
	new = function(a, b) return { a = a, b = b } end
}
UDim2 = {
	fromOffset = function(x, y) return { x = x, y = y } end,
	new = function(a, b, c, d) return { a = a, b = b, c = c, d = d } end
}
Color3 = {
	fromRGB = function(r, g, b) return { r = r, g = g, b = b } end,
	new = function(r, g, b) return { r = r, g = g, b = b } end
}
Enum = {
	EasingStyle = { Quad = 1 },
	EasingDirection = { Out = 1 },
	Font = { GothamSemibold = 1, Gotham = 1 },
	TextTruncate = { AtEnd = 1 },
	TextXAlignment = { Left = 1 },
	UserInputType = { MouseButton1 = 1, Touch = 1, MouseMovement = 2 },
	ZIndexBehavior = { Sibling = 1 },
	AutomaticSize = { Y = 1 }
}
TweenInfo = { new = function(...) return {} end }

local function createMockSignal()
	return {
		Connect = function(self, fn) end
	}
end

local mockInstance = {}
mockInstance.__index = function(self, key)
	if key:sub(1, 2) == "UI" or key == "InputBegan" or key == "InputEnded" or key == "MouseButton1Click" or key == "Changed" then
		return createMockSignal()
	end
	return rawget(self, key)
end

function mockInstance.new(class, parent)
	local self = setmetatable({
		Name = "",
		Parent = parent,
		Size = nil,
		Position = nil,
		CanvasSize = nil,
		AbsoluteSize = { X = 100, Y = 100 },
		InputBegan = createMockSignal(),
		InputEnded = createMockSignal(),
		MouseButton1Click = createMockSignal(),
		Changed = createMockSignal(),
		GetChildren = function() return {} end,
		IsA = function() return false end,
	}, mockInstance)
	return self
end

function mockInstance:Connect() end
function mockInstance:IsA() return false end
function mockInstance:GetChildren() return {} end

Instance = mockInstance

UserInputService = {
	InputChanged = createMockSignal(),
	InputEnded = createMockSignal(),
}

game = {
	GetService = function(self, name)
		if name == "UserInputService" then
			return UserInputService
		end
		return {
			LocalPlayer = {
				WaitForChild = function() return {} end
			},
			Create = function() return { Play = function() end } end,
			Connect = function() end
		}
	end
}

-- Prevent loadstring from being called during execution
local loadstringCalled = false
loadstring = function(...)
	loadstringCalled = true
	error("loadstring should not be called!")
end

-- Run ControlerScript.lua
dofile("Scripts/ControlerScript.lua")

assert(loadstringCalled == false, "TEST FAILED: loadstring was called!")
assert(_G.ScriptModule ~= nil, "TEST FAILED: ScriptModule was not loaded!")
assert(_G.WindowBase ~= nil, "TEST FAILED: WindowBase was not loaded!")
assert(_G.FloatingWindow ~= nil, "TEST FAILED: FloatingWindow was not loaded!")
assert(_G.SpeedLogic ~= nil, "TEST FAILED: SpeedLogic was not loaded!")
assert(_G.TPLogic ~= nil, "TEST FAILED: TPLogic was not loaded!")
assert(_G.Controller ~= nil, "TEST FAILED: Controller was not set!")

print("ALL TESTS PASSED SUCCESSFULLY!")
