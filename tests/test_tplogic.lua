-- Unit tests for TPLogic module (specifically TPLogic.getRoot and related functionality)

local passedCount = 0
local failedCount = 0
local totalCount = 0

local function assertEqual(actual, expected, message)
	if actual ~= expected then
		error(string.format("Assertion failed: expected %s, got %s. %s",
			tostring(expected), tostring(actual), message or ""), 2)
	end
end

local function assertNil(actual, message)
	if actual ~= nil then
		error(string.format("Assertion failed: expected nil, got %s. %s",
			tostring(actual), message or ""), 2)
	end
end

local function assertNotNil(actual, message)
	if actual == nil then
		error(string.format("Assertion failed: expected non-nil value. %s",
			message or ""), 2)
	end
end

local function assertTrue(condition, message)
	if not condition then
		error(string.format("Assertion failed: expected true. %s",
			message or ""), 2)
	end
end

local function assertFalse(condition, message)
	if condition then
		error(string.format("Assertion failed: expected false. %s",
			message or ""), 2)
	end
end

local function runTest(name, func)
	totalCount = totalCount + 1
	io.write(string.format("Running test %d: %s ... ", totalCount, name))
	local ok, err = pcall(func)
	if ok then
		passedCount = passedCount + 1
		print("PASSED")
	else
		failedCount = failedCount + 1
		print("FAILED")
		print("  Error: " .. tostring(err))
	end
end

-- Setup Mock Roblox Environment
local mockLocalPlayer = {
	Character = nil
}

local mockPlayers = {
	LocalPlayer = mockLocalPlayer
}

_G.game = {
	GetService = function(self, serviceName)
		if serviceName == "Players" then
			return mockPlayers
		end
		error("Unknown Roblox service requested: " .. tostring(serviceName))
	end
}

_G.CFrame = {
	new = function(pos)
		return { Position = pos }
	end
}

_G.task = {
	spawn = function(f)
		f()
		return {}
	end,
	cancel = function(t) end,
	wait = function(sec) end
}

-- Helper to reset global state and load TPLogic module
local function loadTPLogic()
	_G.TPLogic = nil
	_G.TPModuleStore = nil
	if getgenv then
		getgenv().TPLogic = nil
		getgenv().TPModuleStore = nil
	end
	return dofile("Scripts/TPLogic.lua")
end

-- Test 1: Module loading
runTest("TPLogic module loads correctly", function()
	local TPLogic = loadTPLogic()
	assertNotNil(TPLogic, "TPLogic module should not be nil")
	assertEqual(type(TPLogic.getRoot), "function", "TPLogic.getRoot should be a function")
	assertEqual(type(TPLogic.canRun), "function", "TPLogic.canRun should be a function")
end)

-- Test 2: Case 1 - getRoot returns nil when Character is nil
runTest("getRoot returns nil when LocalPlayer.Character is nil", function()
	local TPLogic = loadTPLogic()
	mockLocalPlayer.Character = nil
	assertNil(TPLogic.getRoot(), "getRoot should return nil when Character is nil")
end)

-- Test 3: Case 2 - getRoot returns nil when FindFirstChild('HumanoidRootPart') returns nil
runTest("getRoot returns nil when Character does not have HumanoidRootPart", function()
	local TPLogic = loadTPLogic()
	local mockCharacterWithoutRoot = {
		FindFirstChild = function(self, childName)
			return nil
		end
	}
	mockLocalPlayer.Character = mockCharacterWithoutRoot
	assertNil(TPLogic.getRoot(), "getRoot should return nil when HumanoidRootPart is missing")
end)

-- Test 4: Case 3 - getRoot returns HumanoidRootPart instance when present
runTest("getRoot returns HumanoidRootPart when Character has HumanoidRootPart", function()
	local TPLogic = loadTPLogic()
	local mockRootPart = { Name = "HumanoidRootPart", Position = { X = 0, Y = 10, Z = 0 } }
	local mockCharacterWithRoot = {
		FindFirstChild = function(self, childName)
			if childName == "HumanoidRootPart" then
				return mockRootPart
			end
			return nil
		end
	}
	mockLocalPlayer.Character = mockCharacterWithRoot
	local root = TPLogic.getRoot()
	assertNotNil(root, "getRoot should return a non-nil object")
	assertEqual(root, mockRootPart, "getRoot should return the exact HumanoidRootPart instance")
end)

-- Test 5: Case 4 - getRoot dynamically reflects character changes (e.g. respawning)
runTest("getRoot dynamically reflects character respawning / updates", function()
	local TPLogic = loadTPLogic()

	-- Initially no character
	mockLocalPlayer.Character = nil
	assertNil(TPLogic.getRoot(), "Initially should be nil")

	-- Character spawns
	local mockRoot1 = { Name = "HumanoidRootPart", id = 1 }
	mockLocalPlayer.Character = {
		FindFirstChild = function(self, name)
			if name == "HumanoidRootPart" then return mockRoot1 end
		end
	}
	assertEqual(TPLogic.getRoot(), mockRoot1, "Should return character 1 root part")

	-- Character dies/despawns
	mockLocalPlayer.Character = nil
	assertNil(TPLogic.getRoot(), "Should return nil after despawning")

	-- New character respawns
	local mockRoot2 = { Name = "HumanoidRootPart", id = 2 }
	mockLocalPlayer.Character = {
		FindFirstChild = function(self, name)
			if name == "HumanoidRootPart" then return mockRoot2 end
		end
	}
	assertEqual(TPLogic.getRoot(), mockRoot2, "Should return character 2 root part after respawning")
end)

-- Test 6: Case 5 - canRun behavior tied to getRoot()
runTest("canRun returns boolean corresponding to whether getRoot() is non-nil", function()
	local TPLogic = loadTPLogic()

	mockLocalPlayer.Character = nil
	assertFalse(TPLogic.canRun(), "canRun should return false when getRoot is nil")

	local mockRoot = { Name = "HumanoidRootPart" }
	mockLocalPlayer.Character = {
		FindFirstChild = function(self, name)
			if name == "HumanoidRootPart" then return mockRoot end
		end
	}
	assertTrue(TPLogic.canRun(), "canRun should return true when getRoot is non-nil")
end)

-- Test 7: Case 5 - addPoint returns nil when getRoot() is nil
runTest("addPoint returns nil when getRoot() is nil", function()
	local TPLogic = loadTPLogic()
	mockLocalPlayer.Character = nil
	assertNil(TPLogic.addPoint(), "addPoint should return nil when character root part is nil")
end)

print(string.format("\nTest Summary: %d total, %d passed, %d failed", totalCount, passedCount, failedCount))
if failedCount > 0 then
	os.exit(1)
end
