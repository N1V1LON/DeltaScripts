-- Unit tests for Scripts/SpeedLogic.lua - setSpeed

-- Setup mock Roblox environment before requiring target module
local mockTask = {}
mockTask.tasks = {}

function mockTask.spawn(fn, ...)
	local thread = coroutine.create(fn)
	local tObj = { thread = thread, cancelled = false }
	table.insert(mockTask.tasks, tObj)
	local ok, err = coroutine.resume(thread, ...)
	if not ok then error(err) end
	return tObj
end

function mockTask.wait(sec)
	coroutine.yield(sec)
end

function mockTask.cancel(tObj)
	if type(tObj) == "table" then
		tObj.cancelled = true
	end
	for i, t in ipairs(mockTask.tasks) do
		if t == tObj then
			table.remove(mockTask.tasks, i)
			break
		end
	end
end

function mockTask.step()
	for i = #mockTask.tasks, 1, -1 do
		local t = mockTask.tasks[i]
		if t.cancelled or coroutine.status(t.thread) == "dead" then
			table.remove(mockTask.tasks, i)
		else
			local ok, err = coroutine.resume(t.thread)
			if not ok then error(err) end
			if coroutine.status(t.thread) == "dead" then
				table.remove(mockTask.tasks, i)
			end
		end
	end
end

function mockTask.reset()
	mockTask.tasks = {}
end

_G.task = mockTask

local mockHumanoid = { WalkSpeed = 16 }
function mockHumanoid:FindFirstChildOfClass(className)
	if className == "Humanoid" then return mockHumanoid end
	return nil
end

local mockCharacter = {
	FindFirstChildOfClass = function(self, className)
		if className == "Humanoid" then return mockHumanoid end
		return nil
	end,
}

local mockLocalPlayer = {
	Character = mockCharacter,
}

local mockPlayers = {
	LocalPlayer = mockLocalPlayer,
}

_G.game = {
	GetService = function(self, serviceName)
		if serviceName == "Players" then
			return mockPlayers
		end
		error("Unknown service: " .. tostring(serviceName))
	end,
}

_G.getgenv = function()
	return _G
end

-- Helper to reload SpeedLogic cleanly for each test case
local function loadSpeedLogic()
	_G.SpeedLogic = nil
	mockTask.reset()
	local chunk, err = loadfile("Scripts/SpeedLogic.lua")
	if not chunk then
		error("Failed to load Scripts/SpeedLogic.lua: " .. tostring(err))
	end
	return chunk()
end

-- Test harness framework
local testsPassed = 0
local testsFailed = 0

local function test(name, fn)
	io.write("Running " .. name .. "... ")
	-- Reset default mock state
	mockHumanoid.WalkSpeed = 16
	mockLocalPlayer.Character = mockCharacter

	local ok, err = pcall(fn)
	if ok then
		print("PASSED")
		testsPassed = testsPassed + 1
	else
		print("FAILED")
		print("  Error: " .. tostring(err))
		testsFailed = testsFailed + 1
	end
end

local function assertEqual(actual, expected, msg)
	if actual ~= expected then
		error(string.format("%s - Expected: %s, Got: %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
	end
end

local function assertTrue(value, msg)
	if not value then
		error(msg or "Expected true, got false/nil")
	end
end

-- ==================== TEST CASES ====================

test("setSpeed - sets WalkSpeed and captures originalSpeed", function()
	local SpeedLogic = loadSpeedLogic()
	mockHumanoid.WalkSpeed = 16

	local result = SpeedLogic.setSpeed(50)

	assertTrue(result, "setSpeed should return true")
	assertEqual(mockHumanoid.WalkSpeed, 50, "WalkSpeed should be set to 50")
	assertEqual(SpeedLogic.getBaseSpeed(), 16, "getBaseSpeed should return original speed 16")
	assertEqual(SpeedLogic.getCurrentSpeed(), 50, "getCurrentSpeed should return 50")
end)

test("setSpeed - preserves originalSpeed on subsequent calls", function()
	local SpeedLogic = loadSpeedLogic()
	mockHumanoid.WalkSpeed = 16

	SpeedLogic.setSpeed(50)
	assertEqual(mockHumanoid.WalkSpeed, 50, "First setSpeed WalkSpeed")
	assertEqual(SpeedLogic.getBaseSpeed(), 16, "Original speed captured on first setSpeed")

	SpeedLogic.setSpeed(100)
	assertEqual(mockHumanoid.WalkSpeed, 100, "Second setSpeed WalkSpeed")
	assertEqual(SpeedLogic.getBaseSpeed(), 16, "Original speed should remain 16 after second setSpeed")
end)

test("setSpeed - when Humanoid is nil", function()
	local SpeedLogic = loadSpeedLogic()
	mockLocalPlayer.Character = nil

	local result = SpeedLogic.setSpeed(50)

	assertTrue(result, "setSpeed should return true even if Humanoid is nil")
	assertEqual(SpeedLogic.canRun(), false, "canRun should be false when Character is nil")
	assertEqual(SpeedLogic.getCurrentSpeed(), 0, "getCurrentSpeed should return 0 when Humanoid is nil")
end)

test("setSpeed - keepTask maintains WalkSpeed when modified externally", function()
	local SpeedLogic = loadSpeedLogic()
	mockHumanoid.WalkSpeed = 16

	SpeedLogic.setSpeed(50)
	assertEqual(mockHumanoid.WalkSpeed, 50)

	-- External script resets WalkSpeed back to 16
	mockHumanoid.WalkSpeed = 16

	-- Step task loop
	mockTask.step()

	assertEqual(mockHumanoid.WalkSpeed, 50, "keepTask should restore WalkSpeed back to 50")
end)

test("setSpeed - prevents duplicate keep tasks", function()
	local SpeedLogic = loadSpeedLogic()
	mockHumanoid.WalkSpeed = 16

	SpeedLogic.setSpeed(50)
	assertEqual(#mockTask.tasks, 1, "One keep task should be active")

	SpeedLogic.setSpeed(75)
	assertEqual(#mockTask.tasks, 1, "Should still be only one keep task active")

	SpeedLogic.setSpeed(100)
	assertEqual(#mockTask.tasks, 1, "Should still be only one keep task active")

	assertEqual(mockHumanoid.WalkSpeed, 100, "WalkSpeed updated to 100")
end)

test("setSpeed - interaction with resetSpeed", function()
	local SpeedLogic = loadSpeedLogic()
	mockHumanoid.WalkSpeed = 16

	SpeedLogic.setSpeed(50)
	assertEqual(mockHumanoid.WalkSpeed, 50)

	SpeedLogic.resetSpeed()
	assertEqual(mockHumanoid.WalkSpeed, 16, "WalkSpeed should be restored to originalSpeed 16")
	assertEqual(#mockTask.tasks, 0, "Keep task should be cancelled on resetSpeed")

	-- External modification after reset should not be overridden by keepTask
	mockHumanoid.WalkSpeed = 20
	mockTask.step()
	assertEqual(mockHumanoid.WalkSpeed, 20, "Keep task should not override WalkSpeed after reset")
end)

test("setSpeed - with float/decimal speed values", function()
	local SpeedLogic = loadSpeedLogic()
	mockHumanoid.WalkSpeed = 16.5

	SpeedLogic.setSpeed(32.25)
	assertEqual(mockHumanoid.WalkSpeed, 32.25, "WalkSpeed should equal 32.25")
	assertEqual(SpeedLogic.getBaseSpeed(), 16.5, "getBaseSpeed should equal 16.5")
end)

-- Summary
print("\n========================================")
print(string.format("Test Summary: %d passed, %d failed", testsPassed, testsFailed))
print("========================================")

if testsFailed > 0 then
	os.exit(1)
end
