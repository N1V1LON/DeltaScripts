local mock = require("tests.roblox_mock")

-- Load WindowBase
local WindowBase = require("Scripts.WindowBase")

local passedCount = 0
local failedCount = 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passedCount = passedCount + 1
		print("[PASS] " .. name)
	else
		failedCount = failedCount + 1
		print("[FAIL] " .. name .. "\n       " .. tostring(err))
	end
end

local function assertEqual(expected, actual, msg)
	if expected ~= actual then
		error((msg or "Assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function assertTrue(cond, msg)
	if not cond then
		error((msg or "Assertion failed") .. ": expected true, got " .. tostring(cond), 2)
	end
end

-- 1. Test WindowBase module structure and environment
test("WindowBase initialization & environment registry", function()
	assertTrue(WindowBase ~= nil, "WindowBase module should be loaded")
	assertTrue(type(WindowBase.new) == "function", "WindowBase.new should be a function")
	assertTrue(WindowBase.Palette ~= nil, "Palette should exist")
	assertEqual(WindowBase.Registry, _G.WindowRegistry, "Registry should be synced with environment WindowRegistry")
end)

-- 2. Test WindowBase.new creation and hierarchy
test("WindowBase.new creates UI elements and sets default properties", function()
	local win = WindowBase.new("TestKey1", "Test Title")

	assertTrue(win ~= nil, "Window instance should be created")
	assertEqual("TestKey1", win.Key)
	assertEqual(false, win.Minimized)
	assertEqual(200, win.ContentHeight)
	assertEqual("TestKey1WindowGui", win.Gui.Name)
	assertEqual("TestKey1Root", win.Root.Name)
	assertEqual("Test Title", win.Title.Text)

	-- Check parent hierarchy
	local pg = mock.LocalPlayer:WaitForChild("PlayerGui")
	assertEqual(pg, win.Gui.Parent, "Gui parent check")
	assertEqual(win.Gui, win.Root.Parent, "Root parent check")
	assertEqual(win.Root, win.Header.Parent, "Header parent check")
	assertEqual(win.Root, win.Content.Parent, "Content parent check")

	-- Check Registry
	assertEqual(win, WindowBase.Registry["TestKey1"])

	win:Destroy()
end)

-- 3. Test WindowBase.new replacing existing window with same key
test("WindowBase.new destroys previous window if same key is used", function()
	local win1 = WindowBase.new("DuplicateKey", "First")
	local gui1 = win1.Gui

	local win2 = WindowBase.new("DuplicateKey", "Second")

	assertTrue(gui1._destroyed, "First window's GUI should be destroyed")
	assertEqual(win2, WindowBase.Registry["DuplicateKey"], "Registry should hold the new window")

	win2:Destroy()
end)

-- 4. Test WindowBase default position offset calculation
test("WindowBase.new handles default position offsetting", function()
	WindowBase._spawnN = 0

	local win1 = WindowBase.new("WinPos1", "Title")
	local win2 = WindowBase.new("WinPos2", "Title")

	assertEqual(60, win1.Root.Position.X.Offset)
	assertEqual(60, win1.Root.Position.Y.Offset)

	assertEqual(84, win2.Root.Position.X.Offset)
	assertEqual(84, win2.Root.Position.Y.Offset)

	win1:Destroy()
	win2:Destroy()
end)

-- 5. Test WindowBase custom position
test("WindowBase.new respects custom position", function()
	local customPos = UDim2.fromOffset(300, 400)
	local win = WindowBase.new("WinCustomPos", "Title", customPos)

	assertEqual(300, win.Root.Position.X.Offset)
	assertEqual(400, win.Root.Position.Y.Offset)

	win:Destroy()
end)

-- 6. Test setSize, setTitle, bringToFront
test("WindowBase methods: setSize, setTitle, bringToFront", function()
	local win = WindowBase.new("TestMethods", "Original Title")

	-- setTitle
	win:setTitle("New Title")
	assertEqual("New Title", win.Title.Text)

	-- setSize
	win:setSize(300, 250)
	assertEqual(250, win.ContentHeight)
	assertEqual(300, win.Root.Size.X.Offset)
	assertEqual(250, win.Root.Size.Y.Offset)

	-- bringToFront
	win.Gui.DisplayOrder = 10
	win:bringToFront()
	assertEqual(11, win.Gui.DisplayOrder)

	win:Destroy()
end)

-- 7. Test Minimize button behavior
test("WindowBase minimize button toggles minimized state and updates size/text", function()
	local win = WindowBase.new("TestMinimize", "Title")
	win.Root.AbsoluteSize = { X = 240, Y = 200 }

	assertEqual(false, win.Minimized)
	assertEqual("—", win.MinimizeButton.Text)

	-- Click minimize button to minimize
	win.MinimizeButton.MouseButton1Click:Fire()

	assertTrue(win.Minimized, "Window should be minimized")
	assertEqual(200, win.ContentHeight, "ContentHeight should store pre-minimize height")
	assertEqual("+", win.MinimizeButton.Text)
	assertEqual(36, win.Root.Size.Y.Offset, "Root height should be header height (36)")

	-- Click minimize button to un-minimize
	win.MinimizeButton.MouseButton1Click:Fire()

	assertEqual(false, win.Minimized, "Window should be un-minimized")
	assertEqual("—", win.MinimizeButton.Text)
	assertEqual(200, win.Root.Size.Y.Offset, "Root height should be restored")

	win:Destroy()
end)

-- 8. Test Close button behavior
test("WindowBase close button destroys the window", function()
	local win = WindowBase.new("TestClose", "Title")
	local destroyed = false
	win.OnClosed = function(w)
		destroyed = true
		assertEqual(win, w)
	end

	win.CloseButton.MouseButton1Click:Fire()

	assertTrue(destroyed, "OnClosed callback should be called")
	assertTrue(win._destroyed, "Window should be marked destroyed")
	assertTrue(win.Gui._destroyed, "ScreenGui should be destroyed")
	assertEqual(nil, WindowBase.Registry["TestClose"], "Window should be removed from registry")
end)

-- 9. Test Destroy method idempotency and callback
test("WindowBase Destroy is idempotent", function()
	local win = WindowBase.new("TestDestroyOnce", "Title")
	local callCount = 0
	win.OnClosed = function()
		callCount = callCount + 1
	end

	win:Destroy()
	win:Destroy()

	assertEqual(1, callCount, "OnClosed callback should only be triggered once")
end)

-- 10. Test Window dragging functionality
test("Window header dragging updates root position within boundaries", function()
	WindowBase._spawnN = 0

	local win = WindowBase.new("TestDrag", "Title")
	win.Gui.AbsoluteSize = { X = 1000, Y = 800 }
	win.Root.AbsoluteSize = { X = 200, Y = 100 }

	local inputStart = {
		UserInputType = Enum.UserInputType.MouseButton1,
		Position = mock.createPos(150, 110),
		Changed = mock.Signal.new(),
	}

	-- Begin drag on Header
	win.Header.InputBegan:Fire(inputStart)

	-- Move mouse via UserInputService
	local inputMove = {
		UserInputType = Enum.UserInputType.MouseMovement,
		Position = mock.createPos(250, 210),
	}
	mock.Services.UserInputService.InputChanged:Fire(inputMove)

	-- Initial pos offset was 60, drag delta is (250-150, 210-110) = (100, 100)
	-- Expected position offset = 60 + 100 = 160
	assertEqual(160, win.Root.Position.X.Offset, "Root X offset should be initial (60) + delta (100)")
	assertEqual(160, win.Root.Position.Y.Offset, "Root Y offset should be initial (60) + delta (100)")

	-- Test clamping max boundary (maxX = 1000 - 200 = 800, maxY = 800 - 100 = 700)
	local inputFar = {
		UserInputType = Enum.UserInputType.MouseMovement,
		Position = mock.createPos(2000, 2000),
	}
	mock.Services.UserInputService.InputChanged:Fire(inputFar)

	assertEqual(800, win.Root.Position.X.Offset, "Root X should be clamped to maxX")
	assertEqual(700, win.Root.Position.Y.Offset, "Root Y should be clamped to maxY")

	-- End drag via UserInputService
	mock.Services.UserInputService.InputEnded:Fire(inputStart)

	-- Subsequent moves should not change position
	mock.Services.UserInputService.InputChanged:Fire(inputMove)
	assertEqual(800, win.Root.Position.X.Offset)

	win:Destroy()
end)

-- Summary
print("\n================================")
print(string.format("Test Results: %d Passed, %d Failed", passedCount, failedCount))
print("================================")

if failedCount > 0 then
	os.exit(1)
end
