-- tests/test_TPLogic.lua

local mockEnv = {}

function mockEnv.createVector3(x, y, z)
	return { X = x or 0, Y = y or 0, Z = z or 0 }
end

function mockEnv.createCFrame(pos)
	return { Position = pos }
end

local function setupGlobals()
	_G.TPLogic = nil
	_G.TPModuleStore = nil

	local mockRoot = {
		Position = mockEnv.createVector3(10, 20, 30),
		CFrame = mockEnv.createCFrame(mockEnv.createVector3(10, 20, 30))
	}

	local mockChar = {}
	mockChar.HumanoidRootPart = mockRoot
	mockChar.FindFirstChild = function(self, name)
		if name == "HumanoidRootPart" then
			return self.HumanoidRootPart
		end
		return nil
	end

	local mockPlayers = {
		LocalPlayer = {
			Character = mockChar
		}
	}

	game = {
		GetService = function(self, service)
			if service == "Players" then
				return mockPlayers
			end
			error("Unknown service: " .. tostring(service))
		end
	}

	Vector3 = {
		new = function(x, y, z)
			return mockEnv.createVector3(x, y, z)
		end
	}

	CFrame = {
		new = function(pos)
			return mockEnv.createCFrame(pos)
		end
	}

	local activeTasks = {}
	task = {
		spawn = function(fn)
			local taskObj = { cancelled = false }
			table.insert(activeTasks, taskObj)
			local coroutineThread = coroutine.create(function()
				fn()
			end)
			taskObj.thread = coroutineThread
			coroutine.resume(coroutineThread)
			return taskObj
		end,
		cancel = function(taskObj)
			if taskObj then
				taskObj.cancelled = true
			end
		end,
		wait = function(s)
			return s or 0
		end
	}

	return {
		mockRoot = mockRoot,
		mockChar = mockChar,
		mockPlayers = mockPlayers,
		activeTasks = activeTasks
	}
end

local passedCount = 0
local failedCount = 0

local function test(name, fn)
	io.write("Running: " .. name .. " ... ")
	local ok, err = pcall(fn)
	if ok then
		passedCount = passedCount + 1
		print("PASSED")
	else
		failedCount = failedCount + 1
		print("FAILED\n  Error: " .. tostring(err))
	end
end

local function assertEqual(expected, actual, msg)
	if expected ~= actual then
		error(string.format("%s (Expected %s, got %s)", msg or "Assertion failed", tostring(expected), tostring(actual)), 2)
	end
end

local function assertTrue(cond, msg)
	if not cond then
		error(msg or "Expected true, got false/nil", 2)
	end
end

local function assertNil(val, msg)
	if val ~= nil then
		error(string.format("%s (Expected nil, got %s)", msg or "Expected nil", tostring(val)), 2)
	end
end

setupGlobals()

local function loadTPLogic()
	package.loaded["Scripts/TPLogic"] = nil
	package.loaded["Scripts.TPLogic"] = nil
	return dofile("Scripts/TPLogic.lua")
end

test("Module initialization exports to global env and creates TPModuleStore", function()
	_G.TPLogic = nil
	_G.TPModuleStore = nil

	local TPLogic = loadTPLogic()
	assertTrue(TPLogic ~= nil, "TPLogic module should return table")
	assertEqual(TPLogic, _G.TPLogic, "TPLogic should be registered in _G.TPLogic")
	assertTrue(_G.TPModuleStore ~= nil, "_G.TPModuleStore should be initialized")
	assertTrue(type(_G.TPModuleStore) == "table", "TPModuleStore should be a table")
end)

test("Module initialization returns cached env.TPLogic if present", function()
	_G.TPLogic = { isCached = true }
	local TPLogic = loadTPLogic()
	assertEqual(true, TPLogic.isCached, "Should return cached TPLogic from global env")
end)

test("Module reuses pre-existing env.TPModuleStore", function()
	_G.TPLogic = nil
	local existingStore = { { X = 1, Y = 2, Z = 3 } }
	_G.TPModuleStore = existingStore

	local TPLogic = loadTPLogic()
	assertEqual(existingStore, TPLogic.getPoints(), "TPLogic should reuse existing TPModuleStore")
end)

test("getRoot returns HumanoidRootPart when Character is valid", function()
	setupGlobals()
	local TPLogic = loadTPLogic()
	local root = TPLogic.getRoot()
	assertTrue(root ~= nil, "getRoot should return root part")
	assertEqual(10, root.Position.X, "Root part position X should match mock")
end)

test("getRoot returns nil when Character is nil or HumanoidRootPart is missing", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	ctx.mockPlayers.LocalPlayer.Character = nil
	assertNil(TPLogic.getRoot(), "getRoot should return nil when Character is nil")

	ctx.mockPlayers.LocalPlayer.Character = ctx.mockChar
	ctx.mockChar.HumanoidRootPart = nil
	assertNil(TPLogic.getRoot(), "getRoot should return nil when HumanoidRootPart is missing")
end)

test("canRun returns true when root part exists, false otherwise", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	assertTrue(TPLogic.canRun(), "canRun should return true when root exists")

	ctx.mockPlayers.LocalPlayer.Character = nil
	assertEqual(false, TPLogic.canRun(), "canRun should return false when character is nil")
end)

test("getPoints and getPoint return correct store data", function()
	setupGlobals()
	local TPLogic = loadTPLogic()

	local points = TPLogic.getPoints()
	assertEqual(0, #points, "Points should initially be empty")

	table.insert(points, mockEnv.createVector3(1, 2, 3))
	table.insert(points, mockEnv.createVector3(4, 5, 6))

	assertEqual(2, #TPLogic.getPoints(), "getPoints should return updated store")
	assertEqual(1, TPLogic.getPoint(1).X, "getPoint(1).X should be 1")
	assertEqual(4, TPLogic.getPoint(2).X, "getPoint(2).X should be 4")
	assertNil(TPLogic.getPoint(3), "getPoint(3) should be nil")
end)

test("addPoint adds current position to store when root exists", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	ctx.mockRoot.Position = mockEnv.createVector3(100, 200, 300)
	local newIndex = TPLogic.addPoint()

	assertEqual(1, newIndex, "addPoint should return new index 1")
	assertEqual(100, TPLogic.getPoint(1).X, "Stored point X should be 100")
	assertEqual(200, TPLogic.getPoint(1).Y, "Stored point Y should be 200")
	assertEqual(300, TPLogic.getPoint(1).Z, "Stored point Z should be 300")
end)

test("addPoint returns nil when root does not exist", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	ctx.mockPlayers.LocalPlayer.Character = nil
	local res = TPLogic.addPoint()
	assertNil(res, "addPoint should return nil when root is missing")
end)

test("deletePoint removes point by index and re-indexes store", function()
	setupGlobals()
	local TPLogic = loadTPLogic()

	TPLogic.addPoint()
	TPLogic.addPoint()

	assertEqual(2, #TPLogic.getPoints(), "Should have 2 points")

	local deleted = TPLogic.deletePoint(1)
	assertTrue(deleted, "deletePoint(1) should return true")
	assertEqual(1, #TPLogic.getPoints(), "Should have 1 point left")

	local deletedInvalid = TPLogic.deletePoint(99)
	assertEqual(false, deletedInvalid, "deletePoint(99) should return false")
end)

test("teleportTo updates root CFrame and returns true when valid", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	ctx.mockRoot.Position = mockEnv.createVector3(50, 50, 50)
	TPLogic.addPoint()

	local success = TPLogic.teleportTo(1)
	assertTrue(success, "teleportTo(1) should return true")
	assertTrue(ctx.mockRoot.CFrame ~= nil, "root.CFrame should be updated")
	assertEqual(50, ctx.mockRoot.CFrame.Position.X, "CFrame position X should be 50")
end)

test("teleportTo returns false when point index or character is missing", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	assertEqual(false, TPLogic.teleportTo(1), "teleportTo(1) should return false when no point exists")

	ctx.mockRoot.Position = mockEnv.createVector3(50, 50, 50)
	TPLogic.addPoint()
	ctx.mockPlayers.LocalPlayer.Character = nil
	assertEqual(false, TPLogic.teleportTo(1), "teleportTo(1) should return false when root missing")
end)

test("teleportTo cancels previous teleport task on consecutive calls", function()
	local ctx = setupGlobals()
	local TPLogic = loadTPLogic()

	TPLogic.addPoint()

	TPLogic.teleportTo(1)
	local firstTask = ctx.activeTasks[#ctx.activeTasks]
	assertTrue(firstTask ~= nil, "Task should be spawned")

	TPLogic.teleportTo(1)
	assertTrue(firstTask.cancelled, "First task should be cancelled on second teleport call")
end)

print(string.format("\nTest Summary: %d Passed, %d Failed", passedCount, failedCount))

if failedCount > 0 then
	os.exit(1)
end
