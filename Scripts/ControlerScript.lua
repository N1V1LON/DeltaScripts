local env = getgenv and getgenv() or _G

local VERSION = "V26.0.1D"

local function log(msg)
	print("[CS] " .. tostring(msg))
end

local Modules = {
	{ name = "ScriptModule.lua", key = "ScriptModule" },
	{ name = "WindowBase.lua", key = "WindowBase" },
	{ name = "FloatingWindow.lua", key = "FloatingWindow" },
	{ name = "SpeedLogic.lua", key = "SpeedLogic" },
	{ name = "SpeedInterface.lua", key = "SpeedInterface" },
	{ name = "TPLogic.lua", key = "TPLogic" },
	{ name = "TPInterface.lua", key = "TPInterface" },
}

local loaded = 0

-- Secure module loader using require and loadfile (avoids dynamic loadstring)
local function loadModule(mod)
	if env[mod.key] and env[mod.key] ~= true then
		log("(" .. mod.name .. " уже в памяти)")
		loaded = loaded + 1
		return true
	end

	local ok, err = pcall(function()
		if typeof and typeof(script) == "Instance" and script.Parent and script.Parent:FindFirstChild(mod.key) then
			require(script.Parent[mod.key])
		elseif type(loadfile) == "function" then
			local paths = { mod.name, "Scripts/" .. mod.name }
			local loadedChunk = nil
			for _, path in ipairs(paths) do
				local lfOk, lfRes = pcall(loadfile, path)
				if lfOk and type(lfRes) == "function" then
					loadedChunk = lfRes
					break
				end
			end
			if loadedChunk then
				loadedChunk()
			else
				require(mod.key)
			end
		else
			require(mod.key)
		end
	end)

	if not ok then
		log("(" .. mod.name .. " ошибка: " .. tostring(err or "не удалось загрузить модуль") .. ")")
		return false
	end

	loaded = loaded + 1
	log("(" .. mod.name .. " загружен)")
	return true
end

log(VERSION .. " === загружаю модули")
for _, mod in ipairs(Modules) do
	loadModule(mod)
end

local ScriptModule = env.ScriptModule
local FloatingWindow = env.FloatingWindow

if not ScriptModule then error("ScriptModule не загружен") end
if not FloatingWindow then error("FloatingWindow не загружен") end

log("=== создаю окно и контроллер")
local Controller = {}
Controller.Window = FloatingWindow.new("Скрипты " .. VERSION)

function Controller:Refresh(modules)
	local data = {}
	for _, module in ipairs(modules) do
		table.insert(data, module:getData())
	end
	self.Window:Render(data)
end

ScriptModule.setController(Controller)
env.Controller = Controller

log("=== ГОТОВО, загружено модулей: " .. loaded .. ", зарегистрировано: " .. ScriptModule.getCount())
