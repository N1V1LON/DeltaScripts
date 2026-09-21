const fs = require('fs');
const path = require('path');
const fengari = require('fengari');

const lua = fengari.lua;
const lauxlib = fengari.lauxlib;
const lualib = fengari.lualib;

function run() {
	const L = lauxlib.luaL_newstate();
	lualib.luaL_openlibs(L);

	// Load SpeedLogic source and test suite source from files
	const speedLogicPath = path.join(__dirname, 'Scripts', 'SpeedLogic.lua');
	const testSuitePath = path.join(__dirname, 'Scripts', 'SpeedLogic.test.lua');

	const speedLogicCode = fs.readFileSync(speedLogicPath, 'utf8');
	const testSuiteCode = fs.readFileSync(testSuitePath, 'utf8');

	const bootstrapCode = `
		loadstring = loadstring or load

		local env = {}
		_G = env
		getgenv = function() return env end

		local mockPlayer = { Character = nil }
		_G.MockPlayer = mockPlayer

		_G.CreateMockCharacter = function(humanoid)
			return {
				FindFirstChildOfClass = function(self, className)
					if className == "Humanoid" then
						return humanoid
					end
					return nil
				end
			}
		end

		game = {
			GetService = function(self, serviceName)
				if serviceName == "Players" then
					return { LocalPlayer = mockPlayer }
				end
				error("Unknown service: " .. tostring(serviceName))
			end
		}

		local spawnedTasks = {}
		task = {
			spawn = function(f)
				table.insert(spawnedTasks, f)
				return #spawnedTasks
			end,
			cancel = function(t)
				if spawnedTasks[t] then
					spawnedTasks[t] = nil
				end
			end,
			wait = function(s) end
		}

		_G.ResetSpeedLogicState = function()
			env.SpeedLogic = nil
			local chunk, err = loadstring(${JSON.stringify(speedLogicCode)}, "@Scripts/SpeedLogic.lua")
			if not chunk then error(err) end
			_G.SpeedLogic = chunk()
			return _G.SpeedLogic
		end

		_G.ResetSpeedLogicState()

		require_speed_logic = function()
			return _G.SpeedLogic
		end

		local testChunk, testErr = loadstring(${JSON.stringify(testSuiteCode)}, "@Scripts/SpeedLogic.test.lua")
		if not testChunk then error(testErr) end
		testChunk()
	`;

	const status = lauxlib.luaL_dostring(L, fengari.to_luastring(bootstrapCode));
	if (status !== lua.LUA_OK) {
		const err = fengari.to_jsstring(lua.lua_tostring(L, -1));
		console.error("Test execution failed:\n", err);
		process.exit(1);
	}
}

run();
