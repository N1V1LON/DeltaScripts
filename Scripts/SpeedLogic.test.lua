local SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

local passedCount = 0
local failedCount = 0

local function assert_eq(actual, expected, msg)
	if actual == expected then
		passedCount = passedCount + 1
	else
		failedCount = failedCount + 1
		error(string.format("FAILED: %s | Expected: %s, Got: %s", msg or "assertion failed", tostring(expected), tostring(actual)))
	end
end

local function runTest(name, func)
	local ok, err = pcall(func)
	if ok then
		print("  [PASS] " .. name)
	else
		print("  [FAIL] " .. name .. "\n    " .. tostring(err))
	end
end

print("=== SpeedLogic Unit Tests ===")

runTest("Module exports & environment registration", function()
	assert_eq(type(SpeedLogic), "table", "SpeedLogic should be a table")
	assert_eq(SpeedLogic.BASE_SPEED, 16, "BASE_SPEED should default to 16")
	local env = getgenv and getgenv() or _G
	assert_eq(env.SpeedLogic, SpeedLogic, "env.SpeedLogic should reference SpeedLogic module")
end)

runTest("getHumanoid() and canRun() behavior", function()
	-- Test when Character is nil
	_G.MockPlayer.Character = nil
	assert_eq(SpeedLogic.getHumanoid(), nil, "getHumanoid should return nil when Character is nil")
	assert_eq(SpeedLogic.canRun(), false, "canRun should return false when Character is nil")

	-- Test when Character exists but Humanoid is missing
	_G.MockPlayer.Character = _G.CreateMockCharacter(nil)
	assert_eq(SpeedLogic.getHumanoid(), nil, "getHumanoid should return nil when Humanoid missing")
	assert_eq(SpeedLogic.canRun(), false, "canRun should return false when Humanoid missing")

	-- Test when Character and Humanoid exist
	local mockHum = { WalkSpeed = 16 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)
	assert_eq(SpeedLogic.getHumanoid(), mockHum, "getHumanoid should return the humanoid object")
	assert_eq(SpeedLogic.canRun(), true, "canRun should return true when Humanoid present")
end)

runTest("getCurrentSpeed() behavior", function()
	-- Without character
	_G.MockPlayer.Character = nil
	assert_eq(SpeedLogic.getCurrentSpeed(), 0, "getCurrentSpeed should return 0 without humanoid")

	-- With character and WalkSpeed = 24
	local mockHum = { WalkSpeed = 24 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)
	assert_eq(SpeedLogic.getCurrentSpeed(), 24, "getCurrentSpeed should return humanoid WalkSpeed")
end)

runTest("getBaseSpeed() initial state", function()
	assert_eq(SpeedLogic.getBaseSpeed(), 16, "getBaseSpeed should return BASE_SPEED when no original speed is recorded")
end)

runTest("setSpeed() sets WalkSpeed, captures originalSpeed, and returns true", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 16 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	local res = SpeedLogic.setSpeed(50)
	assert_eq(res, true, "setSpeed should return true")
	assert_eq(mockHum.WalkSpeed, 50, "Humanoid WalkSpeed should update to 50")
	assert_eq(SpeedLogic.getBaseSpeed(), 16, "getBaseSpeed should return original speed 16")
	assert_eq(SpeedLogic.getCurrentSpeed(), 50, "getCurrentSpeed should return 50")
end)

runTest("setSpeed() preserves originalSpeed on subsequent calls", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 16 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	SpeedLogic.setSpeed(50)
	assert_eq(mockHum.WalkSpeed, 50, "First setSpeed WalkSpeed")
	assert_eq(SpeedLogic.getBaseSpeed(), 16, "Original speed captured on first setSpeed")

	SpeedLogic.setSpeed(100)
	assert_eq(mockHum.WalkSpeed, 100, "Second setSpeed WalkSpeed")
	assert_eq(SpeedLogic.getBaseSpeed(), 16, "Original speed should remain 16 after second setSpeed")
end)

runTest("setSpeed() behavior when Character or Humanoid is nil", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	_G.MockPlayer.Character = nil
	local okSet = SpeedLogic.setSpeed(40)
	assert_eq(okSet, true, "setSpeed should return true even if character is nil")
	assert_eq(SpeedLogic.canRun(), false, "canRun should return false when character is nil")
	assert_eq(SpeedLogic.getCurrentSpeed(), 0, "getCurrentSpeed should return 0 when character is nil")
end)

runTest("setSpeed() keep task maintains desiredSpeed when WalkSpeed is modified externally", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 16 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	SpeedLogic.setSpeed(50)
	assert_eq(mockHum.WalkSpeed, 50, "WalkSpeed set to 50 initially")

	-- External script resets WalkSpeed back to 16
	mockHum.WalkSpeed = 16

	-- Step task loop execution
	if task and task.step then task.step() end

	assert_eq(mockHum.WalkSpeed, 50, "keepTask should restore WalkSpeed back to 50")
end)

runTest("setSpeed() prevents duplicate keep tasks", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 16 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	SpeedLogic.setSpeed(50)
	if task and task.getActiveCount then
		assert_eq(task.getActiveCount(), 1, "One keep task should be active")
	end

	SpeedLogic.setSpeed(75)
	if task and task.getActiveCount then
		assert_eq(task.getActiveCount(), 1, "Should still be only one keep task active")
	end

	SpeedLogic.setSpeed(100)
	if task and task.getActiveCount then
		assert_eq(task.getActiveCount(), 1, "Should still be only one keep task active")
	end

	assert_eq(mockHum.WalkSpeed, 100, "WalkSpeed updated to 100")
end)

runTest("setSpeed() with floating-point speed values", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 16.5 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	SpeedLogic.setSpeed(32.25)
	assert_eq(mockHum.WalkSpeed, 32.25, "WalkSpeed should equal 32.25")
	assert_eq(SpeedLogic.getBaseSpeed(), 16.5, "getBaseSpeed should equal 16.5")
end)

runTest("setSpeed() and resetSpeed() lifecycle interaction", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 16 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	SpeedLogic.setSpeed(50)
	assert_eq(mockHum.WalkSpeed, 50, "WalkSpeed set to 50")

	local res = SpeedLogic.resetSpeed()
	assert_eq(res, true, "resetSpeed should return true")
	assert_eq(mockHum.WalkSpeed, 16, "Humanoid WalkSpeed should reset to original speed 16")
	if task and task.getActiveCount then
		assert_eq(task.getActiveCount(), 0, "Keep task should be cancelled on resetSpeed")
	end
end)

runTest("resetSpeed() without prior setSpeed()", function()
	if _G.ResetSpeedLogicState then _G.ResetSpeedLogicState() end
	SpeedLogic = require_speed_logic and require_speed_logic() or (getgenv and getgenv().SpeedLogic or _G.SpeedLogic)

	local mockHum = { WalkSpeed = 20 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	SpeedLogic.resetSpeed()
	assert_eq(mockHum.WalkSpeed, 16, "resetSpeed should fallback to BASE_SPEED (16)")
end)

runTest("setSpeed() and resetSpeed() when Character is nil", function()
	_G.MockPlayer.Character = nil
	local okSet = SpeedLogic.setSpeed(40)
	assert_eq(okSet, true, "setSpeed should return true even if character is nil")

	local okReset = SpeedLogic.resetSpeed()
	assert_eq(okReset, true, "resetSpeed should return true even if character is nil")
end)

runTest("setSpeed() with floating point numbers", function()
	local SL = _G.ResetSpeedLogicState()
	local mockHum = { WalkSpeed = 16.5 }
	_G.MockPlayer.Character = _G.CreateMockCharacter(mockHum)

	local res = SL.setSpeed(32.25)
	assert_eq(res, true, "setSpeed should return true for float speed")
	assert_eq(mockHum.WalkSpeed, 32.25, "WalkSpeed should update to float 32.25")
	assert_eq(SL.getBaseSpeed(), 16.5, "getBaseSpeed should return float original speed 16.5")
end)

if failedCount > 0 then
	error(string.format("%d tests failed!", failedCount))
else
	print("All SpeedLogic unit tests passed!")
end
