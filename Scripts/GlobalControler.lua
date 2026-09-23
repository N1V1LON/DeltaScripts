local env = getgenv and getgenv() or _G
local VERSION = "V26.1.0R"

local existing = env.GlobalControler
if existing and existing.Running then
	warn("[GC] " .. tostring(existing.VERSION or "") .. " уже запущен")
	return existing
end
if existing and existing.Destroy then
	pcall(existing.Destroy, existing)
end

local GC = {
	VERSION = VERSION,
	Running = false,
	Base = "",
	Config = nil,
	Theme = nil,
	ModuleTheme = nil,
	Strings = nil,
	Modules = {},
	Errors = {},
	_rects = {},
	_gui = nil,
	_launcher = nil,
	_hub = nil,
	_root = nil,
	_list = nil,
	_status = nil,
	_tabButtons = nil,
	_hubRect = nil,
	_tabs = nil,
	_byTab = nil,
	_activeTab = nil,
}

env.GlobalControler = GC

local DEFAULT_TABS = { "Player", "Server", "Settings" }

local STRINGS = {
	ru = {
		title = "GlobalControler",
		noBase = "Не найдена папка Scripts",
		loaded = "Загружено модулей: %d",
		errors = "ошибки: %d",
		noModules = "Нет модулей",
		emptyTab = "Пусто",
		emptyTitle = "Здесь пока пусто",
		emptyDesc = "Модули с GetTable = %s попадут сюда",
		launcher = "[N]",
		back = "← Назад",
		resize = "⤡",
		tabPlayer = "Игрок",
		tabServer = "Сервер",
		tabSettings = "Настройки",
		settingsName = "Интерфейс",
		settingsDesc = "Язык, тема, цвет, прозрачность",
		settingsLang = "Язык интерфейса",
		settingsTheme = "Тема оформления",
		settingsColor = "Цвет акцента",
		settingsAlpha = "Прозрачность меню",
		settingsReset = "Сброс цвета",
		settingsSaves = "Сохранения",
		settingsSave = "Сохранить",
		settingsLoad = "Загрузить",
		settingsResetAll = "Удалить",
		settingsSaved = "Сохранено",
		settingsLoaded = "Загружено",
		settingsNoSaves = "Нет сохранений",
		settingsAutoHint = "Авто при входе в эту игру",
		speedName = "Скорость",
		speedDesc = "Ползунок + ON/OFF",
		speedSlider = "Скорость бега",
		tpName = "Телепорт",
		tpDesc = "Точки, ТП и удаление",
		tpHint = "Удерживай кнопку, чтобы телепортироваться",
		tpAdd = "+ Добавить точку",
		tpHere = "Здесь",
		tpClear = "Очистить",
		noclipName = "NoClip",
		noclipDesc = "Проход сквозь стены",
		noclipHint = "Иди сквозь стены и объекты",
		jumpName = "Прыжок",
		jumpDesc = "Бесконечный прыжок",
		jumpPower = "Сила прыжка",
		jumpHint = "Прыгай без остановки",
		noChar = "Нет персонажа",
		spoofName = "Spoofing",
		spoofDesc = "Обход speed / jump / tp",
		spoofSpeed = "Обход проверки скорости",
		spoofJump = "Обход проверки прыжка",
		spoofTp = "Обход проверки телепорта",
		playersName = "Players",
		playersDesc = "Обводка, дистанция, HP",
		playersDist = "Показывать дистанцию",
		playersHp = "Показывать HP",
		healName = "Быстрый хил",
		healDesc = "Ускоренное восстановление HP",
		healRate = "HP за тик",
	},
	en = {
		title = "GlobalControler",
		noBase = "Scripts folder not found",
		loaded = "Modules loaded: %d",
		errors = "errors: %d",
		noModules = "No modules",
		emptyTab = "Empty",
		emptyTitle = "Nothing here yet",
		emptyDesc = "Modules with GetTable = %s will appear here",
		launcher = "[N]",
		back = "← Back",
		resize = "⤡",
		tabPlayer = "Player",
		tabServer = "Server",
		tabSettings = "Settings",
		settingsName = "Interface",
		settingsDesc = "Language, theme, color, transparency",
		settingsLang = "Interface language",
		settingsTheme = "Theme",
		settingsColor = "Accent color",
		settingsAlpha = "Menu transparency",
		settingsReset = "Reset color",
		settingsSaves = "Saves",
		settingsSave = "Save",
		settingsLoad = "Load",
		settingsResetAll = "Delete",
		settingsSaved = "Saved",
		settingsLoaded = "Loaded",
		settingsNoSaves = "No saves",
		settingsAutoHint = "Auto on join this game",
		speedName = "Speed",
		speedDesc = "Slider + ON/OFF",
		speedSlider = "Walk speed",
		tpName = "Teleport",
		tpDesc = "Points, TP and clear",
		tpHint = "Hold a button to teleport",
		tpAdd = "+ Add point",
		tpHere = "Here",
		tpClear = "Clear",
		noclipName = "NoClip",
		noclipDesc = "Walk through walls",
		noclipHint = "Move through walls and objects",
		jumpName = "Jump",
		jumpDesc = "Infinite jump",
		jumpPower = "Jump power",
		jumpHint = "Jump without stopping",
		noChar = "No character",
		spoofName = "Spoofing",
		spoofDesc = "Bypass speed / jump / tp",
		spoofSpeed = "Bypass speed check",
		spoofJump = "Bypass jump check",
		spoofTp = "Bypass teleport check",
		playersName = "Players",
		playersDesc = "Outline, distance, HP",
		playersDist = "Show distance",
		playersHp = "Show HP",
		healName = "Fast heal",
		healDesc = "Faster HP regen",
		healRate = "HP per tick",
	},
}

local THEMES = {
	dark = {
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
	},
	light = {
		bg = Color3.fromRGB(240, 240, 245),
		header = Color3.fromRGB(250, 250, 252),
		panel = Color3.fromRGB(255, 255, 255),
		panelAlt = Color3.fromRGB(230, 230, 238),
		line = Color3.fromRGB(200, 200, 210),
		text = Color3.fromRGB(30, 30, 36),
		textDim = Color3.fromRGB(110, 110, 125),
		accent = Color3.fromRGB(0, 176, 190),
		danger = Color3.fromRGB(147, 0, 10),
		dangerText = Color3.fromRGB(255, 180, 171),
		info = Color3.fromRGB(14, 165, 233),
		btn = Color3.fromRGB(225, 225, 232),
		accentOn = Color3.fromRGB(255, 255, 255),
	},
}

local DEFAULT_CONFIG = {
	language = "ru",
	theme = { gui = "dark", module = "dark" },
	ui = { transparency = 0 },
	window = { width = 480, height = 270 },
	icons = {},
	modules = {},
}

local function deepcopy(v)
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in pairs(v) do
		out[k] = deepcopy(x)
	end
	return out
end

local FALLBACK_FILES = {
	"GlobalScripts/SpeedLogic.lua",
	"GlobalScripts/TPLogic.lua",
	"GlobalScripts/NoclipLogic.lua",
	"GlobalScripts/JumpLogic.lua",
	"GlobalScripts/SpoofingLogic.lua",
	"GlobalScripts/PlayersLogic.lua",
	"GlobalScripts/FastHealLogic.lua",
	"GlobalModules/WindowBase.lua",
	"GlobalModules/SpeedWindow.lua",
	"GlobalModules/TPWindow.lua",
	"GlobalModules/NoclipWindow.lua",
	"GlobalModules/JumpWindow.lua",
	"GlobalModules/SpoofingWindow.lua",
	"GlobalModules/PlayersWindow.lua",
	"GlobalModules/FastHealWindow.lua",
	"GlobalModules/SettingsWindow.lua",
}
local LOAD_ORDER = {
	"SpeedLogic", "TPLogic", "NoclipLogic", "JumpLogic",
	"SpoofingLogic", "PlayersLogic", "FastHealLogic",
	"WindowBase", "SpeedWindow", "TPWindow", "NoclipWindow", "JumpWindow",
	"SpoofingWindow", "PlayersWindow", "FastHealWindow", "SettingsWindow",
}

local BASE_CANDIDATES = {
	"/storage/emulated/0/Delta/Scripts/",
	"/sdcard/Delta/Scripts/",
	"Scripts/",
	"./Scripts/",
	"",
}

local function t(str)
	return tostring(str)
end

local function fileExists(path)
	if type(isfile) ~= "function" then
		return false
	end
	local ok, res = pcall(isfile, path)
	return ok and res == true
end

local function readFile(path)
	if type(readfile) ~= "function" then
		return nil
	end
	local ok, res = pcall(readfile, path)
	if ok and type(res) == "string" then
		return res
	end
	return nil
end

local function listDir(dir)
	local out = {}
	if type(listfiles) ~= "function" then
		return out
	end
	local candidates = { dir, dir:gsub("/+$", "") }
	for _, d in ipairs(candidates) do
		if d ~= "" then
			local ok, res = pcall(listfiles, d)
			if ok and type(res) == "table" then
				for _, p in ipairs(res) do
					p = t(p)
					local name = p:match("([^/\\]+)$") or p
					if name:match("%.lua$") then
						if p:sub(1, 1) ~= "/" and not p:find("/") and not p:find("\\") then
							out[#out + 1] = d .. "/" .. name
						else
							out[#out + 1] = p
						end
					end
				end
				if #out > 0 then
					break
				end
			end
		end
	end
	table.sort(out)
	return out
end

local function listJsonFiles(dir)
	local out = {}
	if type(listfiles) ~= "function" then
		return out
	end
	local ok, res = pcall(listfiles, dir)
	if ok and type(res) == "table" then
		for _, p in ipairs(res) do
			p = t(p)
			local name = p:match("([^/\\]+)$") or p
			if name:match("%.json$") then
				if p:sub(1, 1) ~= "/" and not p:find("/") and not p:find("\\") then
					out[#out + 1] = dir:gsub("/+$", "") .. "/" .. name
				else
					out[#out + 1] = p
				end
			end
		end
	end
	table.sort(out)
	return out
end

local function joinPath(base, rel)
	if rel:sub(1, 1) == "/" then
		return rel
	end
	if base == "" then
		return rel
	end
	return base .. rel
end

local function fileName(path)
	return t(path):match("([^/\\]+)$") or t(path)
end

local function moduleNameOf(path)
	return (fileName(path):gsub("%.lua$", ""))
end

local function findBase()
	for _, cand in ipairs(BASE_CANDIDATES) do
		local hit = false
		if fileExists(cand .. "GlobalControler.lua") then
			hit = true
		end
		if not hit and fileExists(cand .. "GlobalSystemFiles/Config.json") then
			hit = true
		end
		if not hit and #listDir(cand .. "GlobalScripts") > 0 then
			hit = true
		end
		if not hit and fileExists(cand .. "GlobalScripts/SpeedLogic.lua") then
			hit = true
		end
		if hit then
			return cand
		end
	end
	return nil
end

local function mergeConfig(user)
	local out = deepcopy(DEFAULT_CONFIG)
	if type(user) ~= "table" then
		return out
	end
	for k, v in pairs(user) do
		if type(v) == "table" and type(out[k]) == "table" then
			local sub = deepcopy(out[k])
			for sk, sv in pairs(v) do
				if type(sv) == "table" and type(sub[sk]) == "table" then
					local sub2 = deepcopy(sub[sk])
					for sk2, sv2 in pairs(sv) do
						sub2[sk2] = sv2
					end
					sub[sk] = sub2
				else
					sub[sk] = sv
				end
			end
			out[k] = sub
		elseif v ~= nil then
			out[k] = v
		end
	end
	return out
end

local function decodeJSON(str)
	local ok, res = pcall(function()
		return game:GetService("HttpService"):JSONDecode(str)
	end)
	if ok and type(res) == "table" then
		return res
	end
	return nil
end

local function encodeJSON(value)
	local ok, res = pcall(function()
		return game:GetService("HttpService"):JSONEncode(value)
	end)
	if ok and type(res) == "string" then
		return res
	end
	return nil
end

local function writeFile(path, content)
	if type(writefile) ~= "function" then
		return false
	end
	local ok = pcall(writefile, path, content)
	return ok == true
end

local function loadConfig(base)
	local raw = readFile(base .. "GlobalSystemFiles/Config.json")
	if not raw and base ~= "" then
		raw = readFile("Scripts/GlobalSystemFiles/Config.json")
	end
	if not raw then
		warn("[GC] Config.json не прочитан, значения по умолчанию")
		return mergeConfig(nil)
	end
	local decoded = decodeJSON(raw)
	if not decoded then
		warn("[GC] Config.json — ошибка JSON")
		return mergeConfig(nil)
	end
	return mergeConfig(decoded)
end

local function getMeta(mod, field)
	if type(mod) ~= "table" then
		return nil
	end
	local v = mod[field]
	if v == nil then
		local lower = field:sub(1, 1):lower() .. field:sub(2)
		v = mod[lower]
	end
	if type(v) == "function" then
		local ok, res = pcall(v)
		if ok then
			return res
		end
		return nil
	end
	return v
end

local function overlaps(a, b)
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
end

function GC:Log(msg)
	print("[GC] " .. t(msg))
end

function GC:Str(key)
	local s = self.Strings and self.Strings[key]
	if s then
		return s
	end
	local ru = STRINGS.ru[key]
	return ru or key
end

function GC:ClaimPosition(w, h)
	w = w or 64
	h = h or 64
	local step = 32
	local originX, originY = 56, 56
	for ring = 0, 40 do
		for dy = -ring, ring do
			for dx = -ring, ring do
				if math.max(math.abs(dx), math.abs(dy)) == ring then
					local x = originX + dx * step
					local y = originY + dy * step
					if x >= 8 and y >= 8 then
						local rect = { x = x, y = y, w = w, h = h }
						local busy = false
						for _, r in ipairs(self._rects) do
							if overlaps(rect, r) then
								busy = true
								break
							end
						end
						if not busy then
							self._rects[#self._rects + 1] = rect
							return rect, UDim2.fromOffset(x, y)
						end
					end
				end
			end
		end
	end
	local rect = { x = originX, y = originY, w = w, h = h }
	self._rects[#self._rects + 1] = rect
	return rect, UDim2.fromOffset(originX, originY)
end

function GC:ReleaseWindow(rect)
	if not rect then
		return
	end
	for i, r in ipairs(self._rects) do
		if r == rect then
			table.remove(self._rects, i)
			return
		end
	end
end

function GC:UpdateWindow(rect, x, y, w, h)
	if not rect then
		return
	end
	rect.x = x or rect.x
	rect.y = y or rect.y
	rect.w = w or rect.w
	rect.h = h or rect.h
end

function GC:GetIconPath(key)
	local icons = self.Config and self.Config.icons
	if type(icons) == "table" and type(icons[key]) == "string" and icons[key] ~= "" then
		return icons[key]
	end
	return nil
end

function GC:ResolveIcon(path)
	if not path or type(getcustomasset) ~= "function" then
		return nil
	end
	local ok, res = pcall(getcustomasset, path)
	if ok and type(res) == "string" and res ~= "" then
		return res
	end
	return nil
end

function GC:GetModuleConfig(key)
	local modules = self.Config and self.Config.modules
	if type(modules) == "table" and type(modules[key]) == "table" then
		return modules[key]
	end
	return {}
end

function GC:SaveConfig(immediate)
	if type(self.Config) ~= "table" then
		return false
	end
	if not immediate then
		self._savePending = true
		if self._saveTask then
			return true
		end
		self._saveTask = task.delay(0.4, function()
			self._saveTask = nil
			if self._savePending then
				self._savePending = false
				self:SaveConfig(true)
			end
		end)
		return true
	end
	self._savePending = false
	local json = encodeJSON(self.Config)
	if not json then
		warn("[GC] SaveConfig: JSONEncode failed")
		return false
	end
	local base = self.Base or ""
	local path = base .. "GlobalSystemFiles/Config.json"
	if base == "" then
		path = "Scripts/GlobalSystemFiles/Config.json"
	end
	if writeFile(path, json) then
		self:Log("Config сохранён: " .. path)
		return true
	end
	warn("[GC] SaveConfig: writefile failed " .. path)
	return false
end

function GC:SaveModuleState(key, patch)
	if type(key) ~= "string" or type(patch) ~= "table" then
		return false
	end
	if type(self.Config) ~= "table" then
		return false
	end
	if type(self.Config.modules) ~= "table" then
		self.Config.modules = {}
	end
	local m = self.Config.modules[key]
	if type(m) ~= "table" then
		m = {}
		self.Config.modules[key] = m
	end
	for k, v in pairs(patch) do
		m[k] = v
	end
	return self:SaveConfig()
end

function GC:RestoreQuickToggles()
	for _, entry in ipairs(self.Modules) do
		local mod = entry.mod
		if type(mod) == "table" and mod.QuickToggle and type(mod.Restore) == "function" then
			local ok, err = pcall(mod.Restore, self:GetModuleConfig(entry.name))
			if not ok then
				self.Errors[entry.name] = "restore: " .. t(err)
			end
		end
	end
end

function GC:RestoreTPPoints()
	local TP = env.TPLogic
	if not TP or type(TP.setPoints) ~= "function" then
		return
	end
	local pts = self:GetModuleConfig("TPWindow").points
	TP.setPoints(pts)
end

function GC:GetPlaceInfo()
	local id = tonumber(game.PlaceId) or 0
	local name = tostring(game.Name or "Unknown")
	pcall(function()
		local info = game:GetService("MarketplaceService"):GetProductInfo(id)
		if info and type(info.Name) == "string" and info.Name ~= "" then
			name = info.Name
		end
	end)
	return id, name
end

function GC:ProfilesDir()
	local base = self.Base or ""
	return base .. "GlobalSystemFiles/Profiles"
end

function GC:ProfilePath(placeId)
	return self:ProfilesDir() .. "/" .. tostring(placeId) .. ".json"
end

function GC:ListProfiles()
	local dir = self:ProfilesDir()
	if type(makefolder) == "function" then
		pcall(makefolder, (self.Base or "") .. "GlobalSystemFiles")
		pcall(makefolder, dir)
	end
	local out = {}
	for _, path in ipairs(listJsonFiles(dir)) do
		local raw = readFile(path)
		if raw then
			local data = decodeJSON(raw)
			if type(data) == "table" then
				out[#out + 1] = {
					path = path,
					placeId = data.placeId,
					placeName = data.placeName or tostring(data.placeId or "?"),
					savedAt = data.savedAt,
				}
			end
		end
	end
	return out
end

function GC:SaveProfile()
	local placeId, placeName = self:GetPlaceInfo()
	if type(self.Config) ~= "table" then
		return false
	end
	if type(makefolder) == "function" then
		pcall(makefolder, (self.Base or "") .. "GlobalSystemFiles")
		pcall(makefolder, self:ProfilesDir())
	end
	local profile = {
		placeId = placeId,
		placeName = placeName,
		savedAt = os.time(),
		config = deepcopy(self.Config),
	}
	local json = encodeJSON(profile)
	if not json then
		return false
	end
	local path = self:ProfilePath(placeId)
	if not writeFile(path, json) then
		return false
	end
	self:Log("Профиль сохранён: " .. path)
	return true, placeName
end

function GC:LoadProfilePath(path)
	local raw = readFile(path)
	if not raw then
		return false
	end
	local data = decodeJSON(raw)
	if type(data) ~= "table" then
		return false
	end
	local cfg = type(data.config) == "table" and data.config or data
	self.Config = mergeConfig(cfg)
	env.GCConfig = self.Config
	self:ApplyAppearance()
	self:RefreshTitles()
	self:RestoreQuickToggles()
	self:RestoreTPPoints()
	self:SaveConfig(true)
	task.defer(function()
		self:RebuildHub()
	end)
	return true, data.placeName
end

function GC:TryAutoLoadProfile()
	local placeId = tonumber(game.PlaceId) or 0
	local path = self:ProfilePath(placeId)
	if not fileExists(path) then
		return false
	end
	local raw = readFile(path)
	if not raw then
		return false
	end
	local data = decodeJSON(raw)
	if type(data) ~= "table" then
		return false
	end
	local cfg = type(data.config) == "table" and data.config or data
	self.Config = mergeConfig(cfg)
	return true
end

function GC:ResetCurrentProfile()
	local placeId = tonumber(game.PlaceId) or 0
	local path = self:ProfilePath(placeId)
	local deleted = false
	if type(delfile) == "function" and fileExists(path) then
		local ok = pcall(delfile, path)
		deleted = ok == true
	end
	self.Config = mergeConfig(nil)
	env.GCConfig = self.Config
	self:ApplyAppearance()
	self:RefreshTitles()
	self:RestoreQuickToggles()
	self:RestoreTPPoints()
	self:SaveConfig(true)
	task.defer(function()
		self:RebuildHub()
	end)
	return deleted
end

local function copyTheme(base)
	local out = {}
	for k, v in pairs(base) do
		out[k] = v
	end
	return out
end

function GC:BuildTheme(name)
	local base = THEMES[name] or THEMES.dark
	local theme = copyTheme(base)
	local accent = self.Config and self.Config.accent
	if type(accent) == "table" and accent.r ~= nil then
		local r = math.clamp(math.floor(tonumber(accent.r) or 0), 0, 255)
		local g = math.clamp(math.floor(tonumber(accent.g) or 0), 0, 255)
		local b = math.clamp(math.floor(tonumber(accent.b) or 0), 0, 255)
		theme.accent = Color3.fromRGB(r, g, b)
		local lum = r * 0.299 + g * 0.587 + b * 0.114
		if lum > 160 then
			theme.accentOn = Color3.fromRGB(15, 19, 29)
		else
			theme.accentOn = Color3.fromRGB(255, 255, 255)
		end
	end
	theme.accentDim = Color3.fromRGB(
		math.floor(theme.accent.R * 255 * 0.55),
		math.floor(theme.accent.G * 255 * 0.55),
		math.floor(theme.accent.B * 255 * 0.55)
	)
	return theme
end

function GC:ApplyAppearance()
	if type(self.Config) ~= "table" then
		return false
	end
	local themeName = (self.Config.theme and self.Config.theme.gui) or "dark"
	local moduleName = (self.Config.theme and self.Config.theme.module) or themeName
	self.Theme = self:BuildTheme(themeName)
	self.ModuleTheme = self:BuildTheme(moduleName)
	self.Strings = STRINGS[self.Config.language] or STRINGS.ru
	env.GCTheme = self.Theme
	env.GCConfig = self.Config
	local WB = env.WindowBase
	if WB and type(self.ModuleTheme) == "table" then
		WB.Palette = self.ModuleTheme
	end
	return true
end

function GC:RebuildHub()
	if not self._hub then
		return false
	end
	local wasVisible = self._hub.Visible == true
	local pos = self._hub.Position
	local size = self._hub.Size
	local activeTab = self._activeTab
	local activeModule = self._activeModule

	local reg = env.WindowRegistry
	if type(reg) == "table" then
		for _, win in pairs(reg) do
			if win._embedded then
				pcall(function()
					win:Destroy()
				end)
			end
		end
	end

	if self._hubRect then
		self:ReleaseWindow(self._hubRect)
		self._hubRect = nil
	end

	pcall(function()
		self._hub:Destroy()
	end)
	self._hub = nil
	self._root = nil
	self._list = nil
	self._status = nil
	self._statusLine = nil
	self._tabBar = nil
	self._tabButtons = nil
	self._grip = nil
	self._hubTitle = nil
	self._titleHome = nil
	self._verBadge = nil
	self._moduleBack = nil
	self._moduleHostFrame = nil
	self._moduleHost = nil
	self._activeModule = nil
	self._relayoutHub = nil
	self._hubM = nil
	self._hubHeaderH = nil
	self._hubHeader = nil
	self._bodyTop = nil
	self._listBottomPad = nil
	self._exitingModule = false

	self:BuildHub()
	if not self._hub then
		return false
	end
	self._hub.Size = size
	self._hub.Position = pos
	if self._hubRect then
		self._hubRect.x = pos.X.Offset
		self._hubRect.y = pos.Y.Offset
		self._hubRect.w = size.X.Offset
		self._hubRect.h = size.Y.Offset
	end
	if self._relayoutHub then
		self._relayoutHub()
	end
	self._activeTab = activeTab or self._activeTab

	if wasVisible then
		self._hub.Visible = true
		if self._launcher then
			self._launcher.Visible = false
		end
		self:RenderTab()
		self:ApplyHubTransparency(self:GetHubTransparency())
		if activeModule then
			for _, entry in ipairs(self.Modules) do
				if entry.name == activeModule then
					self:OpenInHub(entry)
					break
				end
			end
		end
	else
		self._hub.Visible = false
		if self._launcher then
			self._launcher.Visible = true
		end
	end
	return true
end

function GC:SetLanguage(lang)
	if type(lang) ~= "string" or not STRINGS[lang] then
		return false
	end
	if type(self.Config) ~= "table" then
		return false
	end
	if self.Config.language == lang then
		return true
	end
	self.Config.language = lang
	self:ApplyAppearance()
	self:RefreshTitles()
	self:SaveConfig(true)
	task.defer(function()
		self:RebuildHub()
	end)
	return true
end

function GC:SetTheme(name)
	if type(name) ~= "string" or not THEMES[name] then
		return false
	end
	if type(self.Config) ~= "table" then
		return false
	end
	if type(self.Config.theme) ~= "table" then
		self.Config.theme = {}
	end
	if self.Config.theme.gui == name and self.Config.theme.module == name then
		return true
	end
	self.Config.theme.gui = name
	self.Config.theme.module = name
	self:ApplyAppearance()
	self:SaveConfig(true)
	task.defer(function()
		self:RebuildHub()
	end)
	return true
end

function GC:SetAccent(r, g, b)
	if type(self.Config) ~= "table" then
		return false
	end
	if r == nil then
		self.Config.accent = nil
	else
		self.Config.accent = {
			r = math.clamp(math.floor(tonumber(r) or 0), 0, 255),
			g = math.clamp(math.floor(tonumber(g) or 0), 0, 255),
			b = math.clamp(math.floor(tonumber(b) or 0), 0, 255),
		}
	end
	self:ApplyAppearance()
	self:SaveConfig(true)
	task.defer(function()
		self:RebuildHub()
	end)
	return true
end

function GC:CountUIModules()
	local n = 0
	local byTab = self._byTab
	if type(byTab) == "table" then
		for _, list in pairs(byTab) do
			if type(list) == "table" then
				n = n + #list
			end
		end
		return n
	end
	for _, entry in ipairs(self.Modules) do
		if entry.slot ~= nil or getMeta(entry.mod, "GetTable") ~= nil then
			n = n + 1
		end
	end
	return n
end

function GC:ApplyHubTransparency(value)
	value = tonumber(value) or 0
	value = math.clamp(value, 0, 0.85)
	local hub = self._hub
	if hub then
		hub.BackgroundTransparency = value
	end
	if self._hubHeader then
		self._hubHeader.BackgroundTransparency = value
	end
	if self._tabBar then
		self._tabBar.BackgroundTransparency = value
	end
	if self._grip then
		self._grip.BackgroundTransparency = math.min(1, value + 0.15)
	end
	if self._statusLine then
		self._statusLine.BackgroundTransparency = math.min(1, value + 0.1)
	end
	if self._list then
		for _, child in ipairs(self._list:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
				if child.Name == "Empty" or child.Name:find("^Module_") == 1 then
					child.BackgroundTransparency = value
				end
			end
		end
	end
	if self._moduleHostFrame then
		self._moduleHostFrame.BackgroundTransparency = 1
	end
	local SKIP = {
		Track = true,
		Fill = true,
		Knob = true,
		Accent = true,
		Thumb = true,
		AlphaHit = true,
	}
	local PANEL_KEYS = { "bg", "header", "panel", "panelAlt", "btn" }
	local panelRGB = {}
	local function addPanelColors(th)
		if type(th) ~= "table" then
			return
		end
		for _, key in ipairs(PANEL_KEYS) do
			local c = th[key]
			if c and type(c) == "Color3" then
				panelRGB[#panelRGB + 1] = { c.R * 255, c.G * 255, c.B * 255 }
			end
		end
	end
	addPanelColors(THEMES.dark)
	addPanelColors(THEMES.light)
	addPanelColors(self.Theme)
	addPanelColors(self.ModuleTheme)
	local function isSolidPanel(d)
		if not d:IsA("Frame") then
			return false
		end
		if d.BackgroundTransparency >= 1 then
			return false
		end
		local ok, c = pcall(function()
			return d.BackgroundColor3
		end)
		if not ok or type(c) ~= "Color3" then
			return false
		end
		local r, g, b = c.R * 255, c.G * 255, c.B * 255
		for i = 1, #panelRGB do
			local p = panelRGB[i]
			local tol = 8
			if math.abs(r - p[1]) < tol and math.abs(g - p[2]) < tol and math.abs(b - p[3]) < tol then
				return true
			end
		end
		return false
	end
	local function paint(d)
		if not d or not d:IsA("GuiObject") then
			return
		end
		local n = d.Name
		if SKIP[n] then
			return
		end
		if n == "Section"
			or n == "StateCard"
			or n == "SliderBox"
			or n == "Empty"
			or n == "Content"
			or n:find("Root$")
			or n == "Header"
		then
			if d.BackgroundTransparency < 1 or n == "Content" then
				d.BackgroundTransparency = value
			end
			return
		end
		if isSolidPanel(d) then
			d.BackgroundTransparency = value
		end
	end
	local function walkWin(win)
		if type(win) ~= "table" or win._destroyed then
			return
		end
		local root = win.Root
		if not root then
			return
		end
		root.BackgroundTransparency = value
		if win.Header then
			paint(win.Header)
		end
		if win.Content then
			paint(win.Content)
		end
		pcall(function()
			for _, d in ipairs(root:GetDescendants()) do
				paint(d)
			end
		end)
	end
	local reg = env.WindowRegistry
	if type(reg) == "table" then
		for _, win in pairs(reg) do
			walkWin(win)
		end
	end
	return value
end

function GC:SetHubTransparency(value)
	value = tonumber(value) or 0
	value = math.clamp(value, 0, 0.85)
	if type(self.Config) ~= "table" then
		return value
	end
	if type(self.Config.ui) ~= "table" then
		self.Config.ui = {}
	end
	self.Config.ui.transparency = value
	self:ApplyHubTransparency(value)
	self:SaveConfig()
	return value
end

function GC:GetHubTransparency()
	local ui = self.Config and self.Config.ui
	return tonumber(ui and ui.transparency) or 0
end

function GC:RefreshTitles()
	for _, entry in ipairs(self.Modules) do
		entry.title = t(getMeta(entry.mod, "Name") or entry.name)
		entry.desc = t(getMeta(entry.mod, "Desc") or "")
	end
end

local function readSource(base, rel)
	local name = fileName(rel)
	local tries = {}
	if rel:sub(1, 1) == "/" then
		tries[#tries + 1] = rel
	else
		tries[#tries + 1] = joinPath(base, rel)
		tries[#tries + 1] = rel
		if base ~= "" then
			tries[#tries + 1] = base .. "GlobalScripts/" .. name
			tries[#tries + 1] = base .. "GlobalModules/" .. name
		end
		tries[#tries + 1] = "Scripts/GlobalScripts/" .. name
		tries[#tries + 1] = "Scripts/GlobalModules/" .. name
		tries[#tries + 1] = "/storage/emulated/0/Delta/Scripts/GlobalScripts/" .. name
		tries[#tries + 1] = "/storage/emulated/0/Delta/Scripts/GlobalModules/" .. name
		tries[#tries + 1] = "/sdcard/Delta/Scripts/GlobalScripts/" .. name
		tries[#tries + 1] = "/sdcard/Delta/Scripts/GlobalModules/" .. name
	end
	local seen = {}
	for _, p in ipairs(tries) do
		if p ~= "" and not seen[p] then
			seen[p] = true
			local src = readFile(p)
			if src and src ~= "" then
				return src, p
			end
		end
	end
	if type(loadfile) == "function" then
		for _, p in ipairs(tries) do
			if p ~= "" then
				local ok, chunk = pcall(loadfile, p)
				if ok and chunk then
					return nil, nil, chunk
				end
			end
		end
	end
	return nil, nil, nil
end

local function compileAndRun(src, name)
	local chunk, err = loadstring(src, "=" .. name)
	if not chunk then
		return nil, t(err)
	end
	local ok, result = pcall(chunk)
	if not ok then
		return nil, t(result)
	end
	return result, nil
end

local function collectFiles(base)
	local files = {}
	local seen = {}
	local function add(p)
		local n = moduleNameOf(p)
		if not seen[n] then
			seen[n] = true
			files[#files + 1] = p
		end
	end
	for _, p in ipairs(listDir(base .. "GlobalScripts")) do
		add(p)
	end
	for _, p in ipairs(listDir(base .. "GlobalModules")) do
		add(p)
	end
	for _, rel in ipairs(FALLBACK_FILES) do
		local name = fileName(rel)
		if fileExists(joinPath(base, rel))
			or fileExists("Scripts/" .. rel)
			or fileExists("/storage/emulated/0/Delta/Scripts/" .. rel)
			or fileExists("/sdcard/Delta/Scripts/" .. rel)
			or seen[name:gsub("%.lua$", "")]
		then
			add(rel)
		end
	end
	return files
end

local EMBEDDED = {
	SpeedLogic = "local env = getgenv and getgenv() or _G\nif env.SpeedLogic then return env.SpeedLogic end\n\nlocal SpeedLogic = {}\nSpeedLogic.__index = SpeedLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\n\nSpeedLogic.BASE_SPEED = 16\n\nlocal originalSpeed = nil\nlocal desiredSpeed = nil\nlocal keepTask = nil\n\nfunction SpeedLogic.getHumanoid()\n\tlocal char = LocalPlayer.Character\n\tif not char then return nil end\n\treturn char:FindFirstChildOfClass(\"Humanoid\")\nend\n\nfunction SpeedLogic.canRun()\n\treturn SpeedLogic.getHumanoid() ~= nil\nend\n\nfunction SpeedLogic.getCurrentSpeed()\n\tlocal h = SpeedLogic.getHumanoid()\n\treturn h and h.WalkSpeed or 0\nend\n\nlocal function startKeep()\n\tif keepTask then return end\n\tkeepTask = task.spawn(function()\n\t\twhile desiredSpeed do\n\t\t\tlocal h = SpeedLogic.getHumanoid()\n\t\t\tif h and math.abs(h.WalkSpeed - desiredSpeed) > 0.001 then\n\t\t\t\th.WalkSpeed = desiredSpeed\n\t\t\tend\n\t\t\ttask.wait(0.4)\n\t\tend\n\t\tkeepTask = nil\n\tend)\nend\n\nfunction SpeedLogic.setSpeed(value)\n\tdesiredSpeed = value\n\tlocal h = SpeedLogic.getHumanoid()\n\tif h then\n\t\tif originalSpeed == nil then\n\t\t\toriginalSpeed = h.WalkSpeed\n\t\tend\n\t\th.WalkSpeed = value\n\tend\n\tstartKeep()\n\treturn true\nend\n\nfunction SpeedLogic.resetSpeed()\n\tdesiredSpeed = nil\n\tif keepTask then\n\t\ttask.cancel(keepTask)\n\t\tkeepTask = nil\n\tend\n\tlocal h = SpeedLogic.getHumanoid()\n\tif h then\n\t\th.WalkSpeed = originalSpeed or SpeedLogic.BASE_SPEED\n\tend\n\treturn true\nend\n\nfunction SpeedLogic.getBaseSpeed()\n\treturn originalSpeed or SpeedLogic.BASE_SPEED\nend\n\nfunction SpeedLogic.isEnabled()\n\treturn desiredSpeed ~= nil\nend\n\nfunction SpeedLogic.getDesired()\n\treturn desiredSpeed\nend\n\nLocalPlayer.CharacterAdded:Connect(function()\n\tif desiredSpeed then\n\t\ttask.wait(0.2)\n\t\tlocal h = SpeedLogic.getHumanoid()\n\t\tif h then\n\t\t\th.WalkSpeed = desiredSpeed\n\t\tend\n\t\tstartKeep()\n\tend\nend)\n\nenv.SpeedLogic = SpeedLogic\nreturn SpeedLogic\n",
	TPLogic = "local env = getgenv and getgenv() or _G\nif env.TPLogic then return env.TPLogic end\n\nlocal TPLogic = {}\nTPLogic.__index = TPLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\n\nlocal store = env.TPModuleStore or {}\nenv.TPModuleStore = store\n\nlocal function persist()\n\tlocal GC = env.GlobalControler\n\tif GC and GC.SaveModuleState then\n\t\tlocal pts = {}\n\t\tfor i, pos in ipairs(store) do\n\t\t\tpts[i] = { x = pos.X, y = pos.Y, z = pos.Z }\n\t\tend\n\t\tGC:SaveModuleState(\"TPWindow\", { points = pts })\n\tend\nend\n\nfunction TPLogic.setPoints(list)\n\tstore = {}\n\tenv.TPModuleStore = store\n\tif type(list) == \"table\" then\n\t\tfor _, item in ipairs(list) do\n\t\t\tif type(item) == \"table\" then\n\t\t\t\tlocal x = tonumber(item.x or item[1])\n\t\t\t\tlocal y = tonumber(item.y or item[2])\n\t\t\t\tlocal z = tonumber(item.z or item[3])\n\t\t\t\tif x and y and z then\n\t\t\t\t\tstore[#store + 1] = Vector3.new(x, y, z)\n\t\t\t\tend\n\t\t\tend\n\t\tend\n\tend\n\treturn #store\nend\n\nfunction TPLogic.getRoot()\n\tlocal char = LocalPlayer.Character\n\tif not char then return nil end\n\treturn char:FindFirstChild(\"HumanoidRootPart\")\nend\n\nfunction TPLogic.canRun()\n\treturn TPLogic.getRoot() ~= nil\nend\n\nfunction TPLogic.getPoints()\n\treturn store\nend\n\nfunction TPLogic.getPoint(index)\n\treturn store[index]\nend\n\nfunction TPLogic.addPoint()\n\tlocal root = TPLogic.getRoot()\n\tif not root then return nil end\n\tlocal point = root.Position\n\ttable.insert(store, point)\n\tpersist()\n\treturn #store\nend\n\nfunction TPLogic.deletePoint(index)\n\tif not store[index] then return false end\n\ttable.remove(store, index)\n\tpersist()\n\treturn true\nend\n\nlocal teleportTask = nil\n\nfunction TPLogic.teleportTo(index)\n\tlocal pos = store[index]\n\tif not pos then return false end\n\tlocal root = TPLogic.getRoot()\n\tif not root then return false end\n\n\tlocal cf = CFrame.new(pos)\n\troot.CFrame = cf\n\n\tif teleportTask then\n\t\ttask.cancel(teleportTask)\n\t\tteleportTask = nil\n\tend\n\n\tlocal started = os.clock()\n\tteleportTask = task.spawn(function()\n\t\tfor _ = 1, 50 do\n\t\t\tif os.clock() - started > 2.0 then break end\n\t\t\tlocal r = TPLogic.getRoot()\n\t\t\tif r then\n\t\t\t\tr.CFrame = cf\n\t\t\tend\n\t\t\ttask.wait(0.03)\n\t\tend\n\t\tteleportTask = nil\n\tend)\n\n\treturn true\nend\n\nenv.TPLogic = TPLogic\nreturn TPLogic\n",
	NoclipLogic = "local env = getgenv and getgenv() or _G\nif env.NoclipLogic then return env.NoclipLogic end\n\nlocal NoclipLogic = {}\nNoclipLogic.__index = NoclipLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\n\nlocal enabled = false\nlocal clipTask = nil\n\nfunction NoclipLogic.getCharacter()\n\treturn LocalPlayer.Character\nend\n\nfunction NoclipLogic.canRun()\n\tlocal char = NoclipLogic.getCharacter()\n\treturn char ~= nil and char:FindFirstChildOfClass(\"Humanoid\") ~= nil\nend\n\nfunction NoclipLogic.isEnabled()\n\treturn enabled\nend\n\nlocal function applyNoCollide(char)\n\tfor _, part in ipairs(char:GetDescendants()) do\n\t\tif part:IsA(\"BasePart\") then\n\t\t\tpart.CanCollide = false\n\t\tend\n\tend\nend\n\nlocal function startLoop()\n\tif clipTask then return end\n\tclipTask = task.spawn(function()\n\t\twhile enabled do\n\t\t\tlocal char = NoclipLogic.getCharacter()\n\t\t\tif char then\n\t\t\t\tapplyNoCollide(char)\n\t\t\tend\n\t\t\ttask.wait(0.05)\n\t\tend\n\t\tclipTask = nil\n\tend)\nend\n\nfunction NoclipLogic.enable()\n\tenabled = true\n\tif NoclipLogic.canRun() then\n\t\tstartLoop()\n\tend\n\treturn true\nend\n\nfunction NoclipLogic.disable()\n\tif not enabled then return true end\n\tenabled = false\n\tif clipTask then\n\t\ttask.cancel(clipTask)\n\t\tclipTask = nil\n\tend\n\tlocal char = NoclipLogic.getCharacter()\n\tif char then\n\t\tfor _, part in ipairs(char:GetDescendants()) do\n\t\t\tif part:IsA(\"BasePart\") then\n\t\t\t\tpart.CanCollide = true\n\t\t\tend\n\t\tend\n\tend\n\treturn true\nend\n\nfunction NoclipLogic.toggle()\n\tif enabled then\n\t\treturn NoclipLogic.disable()\n\tend\n\treturn NoclipLogic.enable()\nend\n\nLocalPlayer.CharacterAdded:Connect(function()\n\tif enabled then\n\t\ttask.wait(0.2)\n\t\tstartLoop()\n\tend\nend)\n\nenv.NoclipLogic = NoclipLogic\nreturn NoclipLogic\n",
	JumpLogic = "local env = getgenv and getgenv() or _G\nif env.JumpLogic then return env.JumpLogic end\n\nlocal JumpLogic = {}\nJumpLogic.__index = JumpLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal UserInputService = game:GetService(\"UserInputService\")\nlocal LocalPlayer = Players.LocalPlayer\n\nlocal enabled = false\nlocal power = 50\nlocal jumpConn = nil\nlocal originalPower = nil\n\nfunction JumpLogic.getHumanoid()\n\tlocal char = LocalPlayer.Character\n\tif not char then return nil end\n\treturn char:FindFirstChildOfClass(\"Humanoid\")\nend\n\nfunction JumpLogic.canRun()\n\treturn JumpLogic.getHumanoid() ~= nil\nend\n\nfunction JumpLogic.isEnabled()\n\treturn enabled\nend\n\nfunction JumpLogic.getPower()\n\treturn power\nend\n\nlocal function onJumpRequest()\n\tif not enabled then return end\n\tlocal h = JumpLogic.getHumanoid()\n\tif not h then return end\n\tif originalPower == nil then\n\t\toriginalPower = h.JumpPower\n\tend\n\th.JumpPower = power\n\th:ChangeState(Enum.HumanoidStateType.Jumping)\nend\n\nfunction JumpLogic.enable()\n\tif enabled then return true end\n\tenabled = true\n\tlocal h = JumpLogic.getHumanoid()\n\tif h and originalPower == nil then\n\t\toriginalPower = h.JumpPower\n\tend\n\tif h then\n\t\th.JumpPower = power\n\tend\n\tif not jumpConn then\n\t\tjumpConn = UserInputService.JumpRequest:Connect(onJumpRequest)\n\tend\n\treturn true\nend\n\nfunction JumpLogic.disable()\n\tif not enabled then return true end\n\tenabled = false\n\tif jumpConn then\n\t\tjumpConn:Disconnect()\n\t\tjumpConn = nil\n\tend\n\tlocal h = JumpLogic.getHumanoid()\n\tif h and originalPower then\n\t\th.JumpPower = originalPower\n\tend\n\treturn true\nend\n\nfunction JumpLogic.toggle()\n\tif enabled then\n\t\treturn JumpLogic.disable()\n\tend\n\treturn JumpLogic.enable()\nend\n\nfunction JumpLogic.setPower(value)\n\tpower = math.max(20, math.floor(value + 0.5))\n\tif enabled then\n\t\tlocal h = JumpLogic.getHumanoid()\n\t\tif h then\n\t\t\th.JumpPower = power\n\t\tend\n\tend\n\treturn power\nend\n\nLocalPlayer.CharacterAdded:Connect(function()\n\tif enabled then\n\t\ttask.wait(0.2)\n\t\tlocal h = JumpLogic.getHumanoid()\n\t\tif h then\n\t\t\tif originalPower == nil then\n\t\t\t\toriginalPower = h.JumpPower\n\t\t\tend\n\t\t\th.JumpPower = power\n\t\tend\n\t\tif not jumpConn then\n\t\t\tjumpConn = UserInputService.JumpRequest:Connect(onJumpRequest)\n\t\tend\n\tend\nend)\n\nenv.JumpLogic = JumpLogic\nreturn JumpLogic\n",
	SpoofingLogic = "local env = getgenv and getgenv() or _G\nif env.SpoofingLogic then return env.SpoofingLogic end\n\nlocal SpoofingLogic = {}\nSpoofingLogic.__index = SpoofingLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\n\nlocal enabled = false\nlocal flags = {\n\tspeed = true,\n\tjump = true,\n\ttp = true,\n}\nlocal keepTask = nil\nlocal hooksReady = false\nlocal lastJumpAt = 0\nlocal lockUntil = 0\nlocal lockCF = nil\n\nfunction SpoofingLogic.getHumanoid()\n\tlocal char = LocalPlayer.Character\n\tif not char then return nil end\n\treturn char:FindFirstChildOfClass(\"Humanoid\")\nend\n\nfunction SpoofingLogic.getRoot()\n\tlocal char = LocalPlayer.Character\n\tif not char then return nil end\n\treturn char:FindFirstChild(\"HumanoidRootPart\")\nend\n\nfunction SpoofingLogic.canRun()\n\treturn SpoofingLogic.getHumanoid() ~= nil\nend\n\nfunction SpoofingLogic.isEnabled()\n\treturn enabled\nend\n\nfunction SpoofingLogic.getFlag(name)\n\treturn flags[name] == true\nend\n\nfunction SpoofingLogic.setFlag(name, value)\n\tif flags[name] == nil then\n\t\treturn false\n\tend\n\tflags[name] = value == true\n\treturn flags[name]\nend\n\nfunction SpoofingLogic.getFlags()\n\treturn {\n\t\tspeed = flags.speed,\n\t\tjump = flags.jump,\n\t\ttp = flags.tp,\n\t}\nend\n\nfunction SpoofingLogic.noteTeleport()\n\tif not enabled or not flags.tp then\n\t\treturn\n\tend\n\tlocal root = SpoofingLogic.getRoot()\n\tif not root then\n\t\treturn\n\tend\n\tlockCF = root.CFrame\n\tlockUntil = os.clock() + 1.2\nend\n\nlocal function spoofedBase(value, base)\n\tif value == nil then\n\t\treturn base\n\tend\n\tif math.abs(value - base) < 0.01 then\n\t\treturn value\n\tend\n\treturn base\nend\n\nlocal function installHooks()\n\tif hooksReady then\n\t\treturn\n\tend\n\thooksReady = true\n\tif type(hookmetamethod) ~= \"function\" then\n\t\treturn\n\tend\n\tpcall(function()\n\t\tlocal old\n\t\told = hookmetamethod(game, \"__index\", newcclosure(function(self, key)\n\t\t\tif enabled and (key == \"WalkSpeed\" or key == \"JumpPower\") and typeof(self) == \"Instance\" then\n\t\t\t\tlocal h = SpoofingLogic.getHumanoid()\n\t\t\t\tif h and self == h then\n\t\t\t\t\tlocal real = old(self, key)\n\t\t\t\t\tif key == \"WalkSpeed\" and flags.speed then\n\t\t\t\t\t\tlocal SL = env.SpeedLogic\n\t\t\t\t\t\tif SL and SL.isEnabled and SL.isEnabled() then\n\t\t\t\t\t\t\treturn real\n\t\t\t\t\t\tend\n\t\t\t\t\t\treturn spoofedBase(real, 16)\n\t\t\t\t\tend\n\t\t\t\t\tif key == \"JumpPower\" and flags.jump then\n\t\t\t\t\t\treturn spoofedBase(real, 50)\n\t\t\t\t\tend\n\t\t\t\tend\n\t\t\tend\n\t\t\treturn old(self, key)\n\t\tend))\n\tend)\nend\n\nlocal function applySpeed()\n\tif not flags.speed then\n\t\treturn\n\tend\n\tlocal SL = env.SpeedLogic\n\tlocal h = SpoofingLogic.getHumanoid()\n\tif not h then\n\t\treturn\n\tend\n\tif SL and SL.isEnabled and SL.isEnabled() then\n\t\tlocal want = SL.getDesired and SL.getDesired()\n\t\tif want and math.abs(h.WalkSpeed - want) > 0.001 then\n\t\t\th.WalkSpeed = want\n\t\tend\n\tend\nend\n\nlocal function applyJump()\n\tif not flags.jump then\n\t\treturn\n\tend\n\tlocal JL = env.JumpLogic\n\tlocal h = SpoofingLogic.getHumanoid()\n\tif not h then\n\t\treturn\n\tend\n\tif JL and JL.isEnabled and JL.isEnabled() then\n\t\tlocal want = JL.getPower and JL.getPower()\n\t\tif want and math.abs(h.JumpPower - want) > 0.001 then\n\t\t\th.JumpPower = want\n\t\tend\n\tend\nend\n\nlocal function applyTp()\n\tif not flags.tp then\n\t\treturn\n\tend\n\tif os.clock() < lockUntil and lockCF then\n\t\tlocal root = SpoofingLogic.getRoot()\n\t\tif root and (root.CFrame.Position - lockCF.Position).Magnitude > 4 then\n\t\t\troot.CFrame = lockCF\n\t\tend\n\tend\nend\n\nlocal function startKeep()\n\tif keepTask then\n\t\treturn\n\tend\n\tkeepTask = task.spawn(function()\n\t\twhile enabled do\n\t\t\tpcall(applySpeed)\n\t\t\tpcall(applyJump)\n\t\t\tpcall(applyTp)\n\t\t\ttask.wait(0.08)\n\t\tend\n\t\tkeepTask = nil\n\tend)\nend\n\nlocal function stopKeep()\n\tif keepTask then\n\t\ttask.cancel(keepTask)\n\t\tkeepTask = nil\n\tend\n\tlockUntil = 0\n\tlockCF = nil\nend\n\nfunction SpoofingLogic.enable()\n\tif enabled then\n\t\treturn true\n\tend\n\tenabled = true\n\tinstallHooks()\n\tstartKeep()\n\treturn true\nend\n\nfunction SpoofingLogic.disable()\n\tif not enabled then\n\t\treturn true\n\tend\n\tenabled = false\n\tstopKeep()\n\treturn true\nend\n\nfunction SpoofingLogic.toggle()\n\tif enabled then\n\t\treturn SpoofingLogic.disable()\n\tend\n\treturn SpoofingLogic.enable()\nend\n\nLocalPlayer.CharacterAdded:Connect(function()\n\tif enabled then\n\t\ttask.wait(0.2)\n\t\tstartKeep()\n\tend\nend)\n\nlocal TP = env.TPLogic\nif type(TP) == \"table\" and type(TP.teleportTo) == \"function\" and not TP._spoofWrapped then\n\tlocal raw = TP.teleportTo\n\tTP.teleportTo = function(...)\n\t\tlocal ok = raw(...)\n\t\tif ok then\n\t\t\tSpoofingLogic.noteTeleport()\n\t\tend\n\t\treturn ok\n\tend\n\tTP._spoofWrapped = true\nend\n\nenv.SpoofingLogic = SpoofingLogic\nreturn SpoofingLogic\n",
	PlayersLogic = "local env = getgenv and getgenv() or _G\nif env.PlayersLogic then return env.PlayersLogic end\n\nlocal PlayersLogic = {}\nPlayersLogic.__index = PlayersLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\n\nlocal enabled = false\nlocal showDistance = true\nlocal showHp = true\nlocal marks = {}\nlocal scanTask = nil\n\nlocal ACCENT = Color3.fromRGB(0, 242, 254)\nlocal HP_OK = Color3.fromRGB(52, 211, 153)\nlocal HP_LOW = Color3.fromRGB(250, 204, 21)\nlocal HP_CRIT = Color3.fromRGB(244, 63, 94)\n\nfunction PlayersLogic.isEnabled()\n\treturn enabled\nend\n\nfunction PlayersLogic.getShowDistance()\n\treturn showDistance\nend\n\nfunction PlayersLogic.getShowHp()\n\treturn showHp\nend\n\nfunction PlayersLogic.setShowDistance(value)\n\tshowDistance = value == true\n\treturn showDistance\nend\n\nfunction PlayersLogic.setShowHp(value)\n\tshowHp = value == true\n\treturn showHp\nend\n\nlocal function destroyMark(plr)\n\tlocal mark = marks[plr]\n\tif not mark then\n\t\treturn\n\tend\n\tif mark.highlight then\n\t\tpcall(function()\n\t\t\tmark.highlight:Destroy()\n\t\tend)\n\tend\n\tif mark.billboard then\n\t\tpcall(function()\n\t\t\tmark.billboard:Destroy()\n\t\tend)\n\tend\n\tmarks[plr] = nil\nend\n\nlocal function ensureMark(plr)\n\tif plr == LocalPlayer then\n\t\treturn nil\n\tend\n\tlocal char = plr.Character\n\tif not char or not char:FindFirstChildOfClass(\"Humanoid\") then\n\t\tdestroyMark(plr)\n\t\treturn nil\n\tend\n\tlocal mark = marks[plr]\n\tif mark and mark.char == char and mark.highlight and mark.highlight.Parent and mark.billboard and mark.billboard.Parent then\n\t\treturn mark\n\tend\n\tdestroyMark(plr)\n\n\tlocal highlight = Instance.new(\"Highlight\")\n\thighlight.Name = \"PlayersESP\"\n\thighlight.Adornee = char\n\thighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop\n\thighlight.FillColor = ACCENT\n\thighlight.FillTransparency = 0.85\n\thighlight.OutlineColor = ACCENT\n\thighlight.OutlineTransparency = 0.1\n\thighlight.Parent = char\n\n\tlocal head = char:FindFirstChild(\"Head\") or char:FindFirstChildOfClass(\"Part\")\n\tlocal billboard = Instance.new(\"BillboardGui\")\n\tbillboard.Name = \"PlayersInfo\"\n\tbillboard.Adornee = head or char\n\tbillboard.Size = UDim2.fromOffset(140, 36)\n\tbillboard.StudsOffset = Vector3.new(0, 2.4, 0)\n\tbillboard.AlwaysOnTop = true\n\tbillboard.LightInfluence = 0\n\tbillboard.MaxDistance = 200\n\tbillboard.Parent = head or char\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Info\"\n\tlabel.Size = UDim2.fromScale(1, 1)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 11\n\tlabel.TextColor3 = Color3.fromRGB(223, 226, 240)\n\tlabel.TextStrokeTransparency = 0.4\n\tlabel.Text = plr.Name\n\tlabel.Parent = billboard\n\n\tmarks[plr] = {\n\t\tchar = char,\n\t\thighlight = highlight,\n\t\tbillboard = billboard,\n\t\tlabel = label,\n\t}\n\treturn mark\nend\n\nlocal function refreshMark(plr, mark)\n\tlocal char = plr.Character\n\tif not char then\n\t\tdestroyMark(plr)\n\t\treturn\n\tend\n\tlocal hum = char:FindFirstChildOfClass(\"Humanoid\")\n\tlocal root = char:FindFirstChild(\"HumanoidRootPart\")\n\tlocal myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(\"HumanoidRootPart\")\n\tif not hum or hum.Health <= 0 then\n\t\tif mark.highlight then\n\t\t\tmark.highlight.Enabled = false\n\t\tend\n\t\tif mark.billboard then\n\t\t\tmark.billboard.Enabled = false\n\t\tend\n\t\treturn\n\tend\n\tif mark.highlight then\n\t\tmark.highlight.Enabled = true\n\t\tmark.highlight.Adornee = char\n\tend\n\tif mark.billboard then\n\t\tmark.billboard.Enabled = true\n\tend\n\n\tlocal parts = { plr.DisplayName }\n\tif showDistance and myRoot and root then\n\t\tlocal dist = math.floor((myRoot.Position - root.Position).Magnitude + 0.5)\n\t\tparts[#parts + 1] = dist .. \"m\"\n\tend\n\tif showHp then\n\t\tlocal pct = math.floor((hum.Health / math.max(1, hum.MaxHealth)) * 100 + 0.5)\n\t\tparts[#parts + 1] = math.floor(hum.Health + 0.5) .. \"/\" .. math.floor(hum.MaxHealth + 0.5) .. \" (\" .. pct .. \"%)\"\n\t\tif mark.label then\n\t\t\tif pct <= 25 then\n\t\t\t\tmark.label.TextColor3 = HP_CRIT\n\t\t\telseif pct <= 55 then\n\t\t\t\tmark.label.TextColor3 = HP_LOW\n\t\t\telse\n\t\t\t\tmark.label.TextColor3 = HP_OK\n\t\t\tend\n\t\tend\n\telseif mark.label then\n\t\tmark.label.TextColor3 = Color3.fromRGB(223, 226, 240)\n\tend\n\tif mark.label then\n\t\tmark.label.Text = table.concat(parts, \"  ·  \")\n\tend\nend\n\nlocal function scan()\n\tfor _, plr in ipairs(Players:GetPlayers()) do\n\t\tif plr ~= LocalPlayer then\n\t\t\tlocal mark = ensureMark(plr)\n\t\t\tif mark then\n\t\t\t\trefreshMark(plr, mark)\n\t\t\tend\n\t\tend\n\tend\n\tfor plr in pairs(marks) do\n\t\tif not Players:FindFirstChild(plr.Name) then\n\t\t\tdestroyMark(plr)\n\t\tend\n\tend\nend\n\nlocal function startLoop()\n\tif scanTask then\n\t\treturn\n\tend\n\tscanTask = task.spawn(function()\n\t\twhile enabled do\n\t\t\tpcall(scan)\n\t\t\ttask.wait(0.35)\n\t\tend\n\t\tscanTask = nil\n\tend)\nend\n\nlocal function stopLoop()\n\tif scanTask then\n\t\ttask.cancel(scanTask)\n\t\tscanTask = nil\n\tend\n\tfor plr in pairs(marks) do\n\t\tdestroyMark(plr)\n\tend\nend\n\nfunction PlayersLogic.enable()\n\tif enabled then\n\t\treturn true\n\tend\n\tenabled = true\n\tstartLoop()\n\treturn true\nend\n\nfunction PlayersLogic.disable()\n\tif not enabled then\n\t\treturn true\n\tend\n\tenabled = false\n\tstopLoop()\n\treturn true\nend\n\nfunction PlayersLogic.toggle()\n\tif enabled then\n\t\treturn PlayersLogic.disable()\n\tend\n\treturn PlayersLogic.enable()\nend\n\nLocalPlayer.CharacterAdded:Connect(function()\n\tif enabled then\n\t\ttask.wait(0.3)\n\t\tstartLoop()\n\tend\nend)\n\nenv.PlayersLogic = PlayersLogic\nreturn PlayersLogic\n",
	FastHealLogic = "local env = getgenv and getgenv() or _G\nif env.FastHealLogic then return env.FastHealLogic end\n\nlocal FastHealLogic = {}\nFastHealLogic.__index = FastHealLogic\n\nlocal Players = game:GetService(\"Players\")\nlocal LocalPlayer = Players.LocalPlayer\n\nlocal enabled = false\nlocal amount = 5\nlocal healTask = nil\n\nfunction FastHealLogic.getHumanoid()\n\tlocal char = LocalPlayer.Character\n\tif not char then return nil end\n\treturn char:FindFirstChildOfClass(\"Humanoid\")\nend\n\nfunction FastHealLogic.canRun()\n\treturn FastHealLogic.getHumanoid() ~= nil\nend\n\nfunction FastHealLogic.isEnabled()\n\treturn enabled\nend\n\nfunction FastHealLogic.getAmount()\n\treturn amount\nend\n\nfunction FastHealLogic.setAmount(value)\n\tvalue = tonumber(value) or 5\n\tamount = math.clamp(math.floor(value + 0.5), 1, 50)\n\treturn amount\nend\n\nlocal function startLoop()\n\tif healTask then\n\t\treturn\n\tend\n\thealTask = task.spawn(function()\n\t\twhile enabled do\n\t\t\tlocal h = FastHealLogic.getHumanoid()\n\t\t\tif h and h.Health > 0 and h.Health < h.MaxHealth then\n\t\t\t\tpcall(function()\n\t\t\t\t\th.Health = math.min(h.MaxHealth, h.Health + amount)\n\t\t\t\tend)\n\t\t\tend\n\t\t\ttask.wait(0.12)\n\t\tend\n\t\thealTask = nil\n\tend)\nend\n\nlocal function stopLoop()\n\tif healTask then\n\t\ttask.cancel(healTask)\n\t\thealTask = nil\n\tend\nend\n\nfunction FastHealLogic.enable()\n\tif enabled then\n\t\treturn true\n\tend\n\tenabled = true\n\tif FastHealLogic.canRun() then\n\t\tstartLoop()\n\tend\n\treturn true\nend\n\nfunction FastHealLogic.disable()\n\tif not enabled then\n\t\treturn true\n\tend\n\tenabled = false\n\tstopLoop()\n\treturn true\nend\n\nfunction FastHealLogic.toggle()\n\tif enabled then\n\t\treturn FastHealLogic.disable()\n\tend\n\treturn FastHealLogic.enable()\nend\n\nLocalPlayer.CharacterAdded:Connect(function()\n\tif enabled then\n\t\ttask.wait(0.2)\n\t\tstartLoop()\n\tend\nend)\n\nenv.FastHealLogic = FastHealLogic\nreturn FastHealLogic\n",
	WindowBase = "local env = getgenv and getgenv() or _G\nif env.WindowBase then return env.WindowBase end\n\nlocal WindowBase = {}\nWindowBase.__index = WindowBase\n\nlocal Players = game:GetService(\"Players\")\nlocal TweenService = game:GetService(\"TweenService\")\nlocal UserInputService = game:GetService(\"UserInputService\")\n\nlocal player = Players.LocalPlayer\n\nWindowBase.Registry = env.WindowRegistry or {}\nenv.WindowRegistry = WindowBase.Registry\n\nlocal HEADER_H = 28\nlocal CORNER = UDim.new(0, 4)\nlocal TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)\n\nWindowBase.Palette = {\n\tbg = Color3.fromRGB(15, 19, 29),\n\theader = Color3.fromRGB(23, 28, 37),\n\tpanel = Color3.fromRGB(23, 28, 37),\n\tpanelAlt = Color3.fromRGB(27, 32, 41),\n\tline = Color3.fromRGB(58, 73, 75),\n\ttext = Color3.fromRGB(223, 226, 240),\n\ttextDim = Color3.fromRGB(185, 202, 203),\n\taccent = Color3.fromRGB(0, 242, 254),\n\tdanger = Color3.fromRGB(147, 0, 10),\n\tdangerText = Color3.fromRGB(255, 180, 171),\n\tinfo = Color3.fromRGB(14, 165, 233),\n\tbtn = Color3.fromRGB(38, 42, 52),\n\taccentOn = Color3.fromRGB(0, 55, 58),\n}\n\nlocal function clamp(v, lo, hi)\n\tif v < lo then return lo end\n\tif v > hi then return hi end\n\treturn v\nend\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\treturn WindowBase.Palette\nend\n\nfunction WindowBase.tweenSize(frame, w, h)\n\tlocal tween = TweenService:Create(frame, TWEEN, { Size = UDim2.fromOffset(w, h) })\n\ttween:Play()\n\treturn tween\nend\n\nfunction WindowBase.new(key, titleText, w, h)\n\tif WindowBase.Registry[key] then\n\t\tWindowBase.Registry[key]:Destroy()\n\tend\n\n\tw = w or 260\n\th = h or 210\n\n\tlocal self = setmetatable({}, WindowBase)\n\tself.Key = key\n\tself.Minimized = false\n\tself.ContentHeight = h\n\n\tlocal GC = env.GlobalControler\n\tlocal P = currentPalette()\n\tself.P = P\n\tlocal host = GC and GC._moduleHost\n\tself._embedded = host ~= nil\n\n\tlocal gui = nil\n\tif not self._embedded then\n\t\tgui = Instance.new(\"ScreenGui\")\n\t\tgui.Name = (\"%sWindowGui\"):format(key)\n\t\tgui.ResetOnSpawn = false\n\t\tgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling\n\t\tgui.DisplayOrder = 20\n\t\tgui.Parent = player:WaitForChild(\"PlayerGui\")\n\t\tself.Gui = gui\n\tend\n\n\tlocal position = UDim2.fromOffset(0, 0)\n\tif not self._embedded then\n\t\tif GC and GC.ClaimPosition then\n\t\t\tself._rect, position = GC:ClaimPosition(w, h)\n\t\telse\n\t\t\tWindowBase._spawnN = (WindowBase._spawnN or 0) + 1\n\t\t\tlocal off = ((WindowBase._spawnN - 1) % 5) * 24\n\t\t\tposition = UDim2.fromOffset(70 + off, 70 + off)\n\t\tend\n\tend\n\n\tlocal root = Instance.new(\"Frame\")\n\troot.Name = (\"%sRoot\"):format(key)\n\troot.Position = position\n\tif self._embedded then\n\t\troot.Size = UDim2.new(1, 0, 1, 0)\n\telse\n\t\troot.Size = UDim2.fromOffset(w, h)\n\tend\n\troot.BackgroundColor3 = P.bg\n\troot.BorderSizePixel = 0\n\troot.ClipsDescendants = true\n\troot.Active = true\n\tif self._embedded and GC and GC.GetHubTransparency then\n\t\troot.BackgroundTransparency = GC:GetHubTransparency()\n\tend\n\troot.Parent = self._embedded and host or gui\n\tself.Root = root\n\n\tInstance.new(\"UICorner\", root).CornerRadius = CORNER\n\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = P.line\n\t\ts.Parent = root\n\tend)\n\n\tlocal content = Instance.new(\"Frame\")\n\tcontent.Name = \"Content\"\n\tcontent.BackgroundTransparency = 1\n\tcontent.BorderSizePixel = 0\n\tcontent.Parent = root\n\tself.Content = content\n\n\tlocal contentPad = Instance.new(\"UIPadding\")\n\tcontentPad.PaddingLeft = UDim.new(0, self._embedded and 4 or 8)\n\tcontentPad.PaddingRight = UDim.new(0, self._embedded and 4 or 8)\n\tcontentPad.PaddingTop = UDim.new(0, self._embedded and 4 or 6)\n\tcontentPad.PaddingBottom = UDim.new(0, self._embedded and 4 or 8)\n\tcontentPad.Parent = content\n\tself.ContentPad = contentPad\n\n\tif self._embedded then\n\t\t-- hub уже имеет шапку (← / title / ✕) — вторая не нужна\n\t\tcontent.Position = UDim2.fromOffset(0, 0)\n\t\tcontent.Size = UDim2.new(1, 0, 1, 0)\n\t\tself.Title = nil\n\t\tself.MinimizeButton = nil\n\t\tself.CloseButton = nil\n\t\tself._destroyed = false\n\t\tWindowBase.Registry[key] = self\n\t\treturn self\n\tend\n\n\tcontent.Position = UDim2.new(0, 0, 0, HEADER_H)\n\tcontent.Size = UDim2.new(1, 0, 1, -HEADER_H)\n\n\tlocal header = Instance.new(\"Frame\")\n\theader.Name = \"Header\"\n\theader.Size = UDim2.new(1, 0, 0, HEADER_H)\n\theader.BackgroundColor3 = P.header\n\theader.BorderSizePixel = 0\n\theader.Parent = root\n\n\tInstance.new(\"UICorner\", header).CornerRadius = UDim.new(0, 4)\n\n\tlocal title = Instance.new(\"TextLabel\")\n\ttitle.Name = \"Title\"\n\ttitle.Size = UDim2.new(1, -70, 1, 0)\n\ttitle.Position = UDim2.fromOffset(8, 0)\n\ttitle.BackgroundTransparency = 1\n\ttitle.Text = titleText or \"Окно\"\n\ttitle.TextColor3 = P.text\n\ttitle.Font = Enum.Font.GothamSemibold\n\ttitle.TextSize = 13\n\ttitle.TextXAlignment = Enum.TextXAlignment.Left\n\ttitle.TextTruncate = Enum.TextTruncate.AtEnd\n\ttitle.Parent = header\n\tself.Title = title\n\n\tlocal minBtn = Instance.new(\"TextButton\")\n\tminBtn.Name = \"Minimize\"\n\tminBtn.Size = UDim2.fromOffset(26, HEADER_H)\n\tminBtn.Position = UDim2.new(1, -56, 0, 0)\n\tminBtn.BackgroundColor3 = P.btn\n\tminBtn.BorderSizePixel = 0\n\tminBtn.AutoButtonColor = true\n\tminBtn.Text = \"—\"\n\tminBtn.TextColor3 = P.text\n\tminBtn.Font = Enum.Font.GothamSemibold\n\tminBtn.TextSize = 14\n\tminBtn.Parent = header\n\tself.MinimizeButton = minBtn\n\n\tlocal closeBtn = Instance.new(\"TextButton\")\n\tcloseBtn.Name = \"Close\"\n\tcloseBtn.Size = UDim2.fromOffset(26, HEADER_H)\n\tcloseBtn.Position = UDim2.new(1, -28, 0, 0)\n\tcloseBtn.BackgroundColor3 = P.danger\n\tcloseBtn.BorderSizePixel = 0\n\tcloseBtn.AutoButtonColor = true\n\tcloseBtn.Text = \"✕\"\n\tcloseBtn.TextColor3 = P.dangerText or Color3.fromRGB(255, 180, 171)\n\tcloseBtn.Font = Enum.Font.GothamSemibold\n\tcloseBtn.TextSize = 12\n\tcloseBtn.Parent = header\n\tself.CloseButton = closeBtn\n\n\tlocal dragStart, dragPos, dragging\n\theader.Active = true\n\n\tlocal function isPrimary(ty)\n\t\treturn ty == Enum.UserInputType.MouseButton1 or ty == Enum.UserInputType.Touch\n\tend\n\tlocal function isMove(ty)\n\t\treturn ty == Enum.UserInputType.MouseMovement or ty == Enum.UserInputType.Touch\n\tend\n\n\theader.InputBegan:Connect(function(input)\n\t\tif not isPrimary(input.UserInputType) or dragging then return end\n\t\tif input.Target == closeBtn or input.Target == minBtn then return end\n\t\tdragging = true\n\t\tdragStart = input.Position\n\t\tdragPos = root.Position\n\tend)\n\n\tUserInputService.InputChanged:Connect(function(input)\n\t\tif not dragging or not isMove(input.UserInputType) then return end\n\t\tlocal delta = input.Position - dragStart\n\t\tlocal maxX = math.max(0, gui.AbsoluteSize.X - root.AbsoluteSize.X)\n\t\tlocal maxY = math.max(0, gui.AbsoluteSize.Y - root.AbsoluteSize.Y)\n\t\troot.Position = UDim2.new(\n\t\t\tdragPos.X.Scale, math.clamp(dragPos.X.Offset + delta.X, 0, maxX),\n\t\t\tdragPos.Y.Scale, math.clamp(dragPos.Y.Offset + delta.Y, 0, maxY)\n\t\t)\n\tend)\n\n\tlocal function endDrag(input)\n\t\tif not isPrimary(input.UserInputType) or not dragging then return end\n\t\tdragging = nil\n\t\tlocal GCnow = env.GlobalControler\n\t\tif GCnow and self._rect then\n\t\t\tGCnow:UpdateWindow(\n\t\t\t\tself._rect,\n\t\t\t\troot.Position.X.Offset,\n\t\t\t\troot.Position.Y.Offset,\n\t\t\t\troot.AbsoluteSize.X,\n\t\t\t\troot.AbsoluteSize.Y\n\t\t\t)\n\t\tend\n\tend\n\n\theader.InputEnded:Connect(endDrag)\n\tUserInputService.InputEnded:Connect(endDrag)\n\n\tminBtn.MouseButton1Click:Connect(function()\n\t\tif self.Minimized then\n\t\t\tself.Minimized = false\n\t\t\tWindowBase.tweenSize(root, root.AbsoluteSize.X, self.ContentHeight)\n\t\t\tminBtn.Text = \"—\"\n\t\telse\n\t\t\tself.Minimized = true\n\t\t\tself.ContentHeight = root.AbsoluteSize.Y\n\t\t\tWindowBase.tweenSize(root, root.AbsoluteSize.X, HEADER_H)\n\t\t\tminBtn.Text = \"+\"\n\t\tend\n\tend)\n\n\tcloseBtn.MouseButton1Click:Connect(function()\n\t\tself:Destroy()\n\tend)\n\n\tself._destroyed = false\n\tWindowBase.Registry[key] = self\n\treturn self\nend\n\nfunction WindowBase:setSize(w, h)\n\tself.ContentHeight = h\n\tif self._embedded then\n\t\treturn\n\tend\n\tWindowBase.tweenSize(self.Root, w, h)\nend\n\nfunction WindowBase:setTitle(text)\n\tif self.Title then\n\t\tself.Title.Text = text\n\tend\nend\n\nfunction WindowBase:Destroy()\n\tif self._destroyed then return end\n\tself._destroyed = true\n\tif WindowBase.Registry[self.Key] == self then\n\t\tWindowBase.Registry[self.Key] = nil\n\tend\n\tlocal GC = env.GlobalControler\n\tif GC and self._rect then\n\t\tGC:ReleaseWindow(self._rect)\n\t\tself._rect = nil\n\tend\n\tlocal embedded = self._embedded\n\tif self.OnClosed then\n\t\tpcall(self.OnClosed, self)\n\tend\n\tif self.Gui then\n\t\tpcall(function()\n\t\t\tself.Gui:Destroy()\n\t\tend)\n\telse\n\t\tpcall(function()\n\t\t\tself.Root:Destroy()\n\t\tend)\n\tend\n\tif embedded and GC and GC.ExitModuleView then\n\t\tGC:ExitModuleView()\n\t\tif GC.RenderTab then\n\t\t\tGC:RenderTab()\n\t\tend\n\t\tif GC.ApplyHubTransparency and GC.GetHubTransparency then\n\t\t\tGC:ApplyHubTransparency(GC:GetHubTransparency())\n\t\tend\n\tend\nend\n\nenv.WindowBase = WindowBase\nreturn WindowBase\n",
	SpeedWindow = "local env = getgenv and getgenv() or _G\nif env.SpeedWindow then return env.SpeedWindow end\n\nlocal SpeedWindow = {}\nSpeedWindow.GetTable = \"Player\"\nSpeedWindow.GetPosition = 1\nSpeedWindow.QuickToggle = true\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction SpeedWindow.Name()\n\treturn Str(\"speedName\", \"Скорость\")\nend\n\nfunction SpeedWindow.Desc()\n\treturn Str(\"speedDesc\", \"Ползунок + ON/OFF\")\nend\n\nlocal lastSpeed = nil\n\nfunction SpeedWindow.IsOn()\n\tlocal L = env.SpeedLogic\n\treturn L ~= nil and L.isEnabled() == true\nend\n\nfunction SpeedWindow.SetOn(state)\n\tlocal L = env.SpeedLogic\n\tassert(L, \"SpeedLogic не загружен\")\n\tlocal GC = env.GlobalControler\n\tif state then\n\t\tlocal cfg = GC and GC.GetModuleConfig and GC:GetModuleConfig(\"SpeedWindow\") or {}\n\t\tlocal v = tonumber(cfg.defaultSpeed) or lastSpeed or 50\n\t\tL.setSpeed(v)\n\t\tlastSpeed = v\n\telse\n\t\tL.resetSpeed()\n\tend\n\tif GC and GC.SaveModuleState then\n\t\tGC:SaveModuleState(\"SpeedWindow\", {\n\t\t\tenabled = state == true,\n\t\t\tdefaultSpeed = lastSpeed or (L.getDesired and L.getDesired()) or nil,\n\t\t})\n\tend\n\treturn SpeedWindow.IsOn()\nend\n\nfunction SpeedWindow.Restore(config)\n\tconfig = config or {}\n\tlocal L = env.SpeedLogic\n\tif not L then\n\t\treturn\n\tend\n\tlocal v = tonumber(config.defaultSpeed)\n\tif v then\n\t\tlastSpeed = v\n\tend\n\tif config.enabled then\n\t\tL.setSpeed(v or lastSpeed or 50)\n\tend\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal UIS = game:GetService(\"UserInputService\")\n\nlocal function makeToggle(parent, on, onToggle)\n\tlocal P = currentPalette() or {}\n\tlocal h = 32\n\tlocal w = 64\n\n\tlocal btn = Instance.new(\"TextButton\")\n\tbtn.Name = \"Toggle\"\n\tbtn.Size = UDim2.fromOffset(w, h)\n\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\tbtn.BorderSizePixel = 0\n\tbtn.AutoButtonColor = true\n\tbtn.Text = \"\"\n\tbtn.Parent = parent\n\tcorner(btn, 99)\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -12, 1, 0)\n\tlabel.Position = UDim2.fromOffset(8, 0)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = on and \"ON\" or \"OFF\"\n\tlabel.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 12\n\tlabel.ZIndex = 2\n\tlabel.Parent = btn\n\n\tlocal knob = Instance.new(\"Frame\")\n\tknob.Name = \"Knob\"\n\tknob.Size = UDim2.fromOffset(h - 8, h - 8)\n\tknob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\tknob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tknob.BorderSizePixel = 0\n\tknob.ZIndex = 3\n\tknob.Parent = btn\n\tcorner(knob, 99)\n\n\tlocal state = on\n\tlocal function paint()\n\t\tbtn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\t\tlabel.Text = state and \"ON\" or \"OFF\"\n\t\tlabel.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tknob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\t\tknob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tend\n\n\tbtn.MouseButton1Click:Connect(function()\n\t\tstate = not state\n\t\tpaint()\n\t\tif onToggle then\n\t\t\tonToggle(state)\n\t\tend\n\tend)\n\n\treturn {\n\t\tget = function()\n\t\t\treturn state\n\t\tend,\n\t\tset = function(v)\n\t\t\tstate = v\n\t\t\tpaint()\n\t\tend,\n\t}\nend\n\nlocal function makeSlider(parent, minV, maxV, startV, onChange)\n\tlocal P = currentPalette() or {}\n\tlocal box = Instance.new(\"Frame\")\n\tbox.Name = \"SliderBox\"\n\tbox.Size = UDim2.new(1, 0, 0, 84)\n\tbox.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tbox.BorderSizePixel = 0\n\tbox.Parent = parent\n\tcorner(box, 4)\n\tstroke(box, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -70, 0, 14)\n\tlabel.Position = UDim2.fromOffset(10, 8)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = Str(\"speedSlider\", \"Скорость бега\")\n\tlabel.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tlabel.Font = Enum.Font.Gotham\n\tlabel.TextSize = 11\n\tlabel.TextXAlignment = Enum.TextXAlignment.Left\n\tlabel.Parent = box\n\n\tlocal readout = Instance.new(\"TextLabel\")\n\treadout.Name = \"Readout\"\n\treadout.Size = UDim2.new(0, 56, 0, 20)\n\treadout.Position = UDim2.new(1, -66, 0, 6)\n\treadout.BackgroundTransparency = 1\n\treadout.Text = tostring(math.floor(startV + 0.5))\n\treadout.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\treadout.Font = Enum.Font.Code\n\treadout.TextSize = 16\n\treadout.TextXAlignment = Enum.TextXAlignment.Right\n\treadout.Parent = box\n\n\tlocal track = Instance.new(\"Frame\")\n\ttrack.Name = \"Track\"\n\ttrack.Size = UDim2.new(1, -20, 0, 6)\n\ttrack.Position = UDim2.fromOffset(10, 34)\n\ttrack.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\ttrack.BorderSizePixel = 0\n\ttrack.Active = true\n\ttrack.Parent = box\n\tcorner(track, 99)\n\n\tlocal fill = Instance.new(\"Frame\")\n\tfill.Name = \"Fill\"\n\tfill.Size = UDim2.new(0, 0, 1, 0)\n\tfill.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tfill.BorderSizePixel = 0\n\tfill.Parent = track\n\tcorner(fill, 99)\n\n\tlocal thumb = Instance.new(\"Frame\")\n\tthumb.Name = \"Thumb\"\n\tthumb.Size = UDim2.fromOffset(18, 18)\n\tthumb.Position = UDim2.new(0, -9, 0.5, -9)\n\tthumb.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tthumb.BorderSizePixel = 0\n\tthumb.ZIndex = 3\n\tthumb.Parent = track\n\tcorner(thumb, 99)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 2\n\t\ts.Color = P.bg or Color3.fromRGB(15, 19, 29)\n\t\ts.Parent = thumb\n\tend)\n\n\tlocal mins = Instance.new(\"TextLabel\")\n\tmins.Size = UDim2.new(0, 36, 0, 12)\n\tmins.Position = UDim2.fromOffset(10, 52)\n\tmins.BackgroundTransparency = 1\n\tmins.Text = tostring(minV)\n\tmins.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tmins.Font = Enum.Font.Code\n\tmins.TextSize = 9\n\tmins.TextXAlignment = Enum.TextXAlignment.Left\n\tmins.Parent = box\n\n\tlocal maxs = Instance.new(\"TextLabel\")\n\tmaxs.Size = UDim2.new(0, 36, 0, 12)\n\tmaxs.Position = UDim2.new(1, -46, 0, 52)\n\tmaxs.BackgroundTransparency = 1\n\tmaxs.Text = tostring(maxV)\n\tmaxs.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tmaxs.Font = Enum.Font.Code\n\tmaxs.TextSize = 9\n\tmaxs.TextXAlignment = Enum.TextXAlignment.Right\n\tmaxs.Parent = box\n\n\tlocal value = startV\n\tlocal dragging = false\n\n\tlocal function applyVisual()\n\t\tlocal range = maxV - minV\n\t\tlocal frac = 0\n\t\tif range > 0 then\n\t\t\tfrac = (value - minV) / range\n\t\tend\n\t\tfrac = math.clamp(frac, 0, 1)\n\t\tfill.Size = UDim2.new(frac, 0, 1, 0)\n\t\tthumb.Position = UDim2.new(frac, -9, 0.5, -9)\n\t\treadout.Text = tostring(math.floor(value + 0.5))\n\tend\n\n\tlocal function fromInput(input)\n\t\tlocal abs = track.AbsolutePosition.X\n\t\tlocal sizeX = track.AbsoluteSize.X\n\t\tif sizeX <= 0 then\n\t\t\treturn\n\t\tend\n\t\tlocal frac = (input.Position.X - abs) / sizeX\n\t\tfrac = math.clamp(frac, 0, 1)\n\t\tvalue = minV + frac * (maxV - minV)\n\t\tapplyVisual()\n\t\tif onChange then\n\t\t\tonChange(value)\n\t\tend\n\tend\n\n\ttrack.InputBegan:Connect(function(input)\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tdragging = true\n\t\tfromInput(input)\n\tend)\n\n\tUIS.InputChanged:Connect(function(input)\n\t\tif not dragging then\n\t\t\treturn\n\t\tend\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseMovement\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tfromInput(input)\n\tend)\n\n\tlocal function endDrag(input)\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tdragging = false\n\tend\n\tUIS.InputEnded:Connect(endDrag)\n\ttrack.InputEnded:Connect(endDrag)\n\n\ttask.defer(applyVisual)\n\n\treturn {\n\t\tget = function()\n\t\t\treturn value\n\t\tend,\n\t\tset = function(v)\n\t\t\tvalue = math.clamp(v, minV, maxV)\n\t\t\tapplyVisual()\n\t\tend,\n\t\trefresh = applyVisual,\n\t}\nend\n\nfunction SpeedWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\twindow:Destroy()\n\t\twindow = nil\n\t\treturn\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal SpeedLogic = env.SpeedLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(SpeedLogic, \"SpeedLogic не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal base = WindowBase.new(\"Speed\", SpeedWindow.Name(), 300, 200)\n\twindow = base\n\n\tlocal content = base.Content\n\tlocal PAD = 6\n\n\tlocal minV = tonumber(config.minSpeed) or 16\n\tlocal maxV = tonumber(config.maxSpeed) or 200\n\tif maxV <= minV then\n\t\tmaxV = minV + 1\n\tend\n\tlocal start = tonumber(config.defaultSpeed)\n\tif not start then\n\t\tstart = SpeedLogic.getCurrentSpeed()\n\t\tif start < minV then\n\t\t\tstart = minV\n\t\tend\n\t\tif start > maxV then\n\t\t\tstart = maxV\n\t\tend\n\tend\n\n\tlocal enabled = false\n\tlocal slider\n\tlocal stateLabel\n\tlocal readoutLabel\n\tlocal toggle\n\n\tlocal function refreshStatus()\n\t\tif not SpeedLogic.canRun() then\n\t\t\tif readoutLabel then\n\t\t\t\treadoutLabel.Text = \"—\"\n\t\t\t\treadoutLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\t\tif stateLabel then\n\t\t\t\tstateLabel.Text = Str(\"noChar\", \"Нет персонажа\")\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\t\treturn\n\t\tend\n\t\tlocal cur = SpeedLogic.getCurrentSpeed()\n\t\tif readoutLabel then\n\t\t\treadoutLabel.Text = tostring(math.floor(enabled and (slider and slider.get() or cur) or cur + 0.5))\n\t\t\treadoutLabel.TextColor3 = enabled and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tend\n\t\tif stateLabel then\n\t\t\tif enabled then\n\t\t\t\tstateLabel.Text = (\"ON  ·  WalkSpeed %.0f\"):format(cur)\n\t\t\t\tstateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\t\telse\n\t\t\t\tstateLabel.Text = (\"OFF  ·  WalkSpeed %.0f\"):format(cur)\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\tend\n\tend\n\n\tlocal function applyIfOn(value)\n\t\tlastSpeed = math.floor(value + 0.5)\n\t\tif not enabled then\n\t\t\tlocal GC = env.GlobalControler\n\t\t\tif GC and GC.SaveModuleState then\n\t\t\t\tGC:SaveModuleState(\"SpeedWindow\", { defaultSpeed = lastSpeed })\n\t\t\tend\n\t\t\trefreshStatus()\n\t\t\treturn\n\t\tend\n\t\tif not SpeedLogic.canRun() then\n\t\t\trefreshStatus()\n\t\t\treturn\n\t\tend\n\t\tSpeedLogic.setSpeed(lastSpeed)\n\t\tlocal GC2 = env.GlobalControler\n\t\tif GC2 and GC2.SaveModuleState then\n\t\t\tGC2:SaveModuleState(\"SpeedWindow\", {\n\t\t\t\tenabled = true,\n\t\t\t\tdefaultSpeed = lastSpeed,\n\t\t\t})\n\t\tend\n\t\trefreshStatus()\n\tend\n\n\tlocal function setEnabled(state)\n\t\tenabled = state\n\t\tif enabled then\n\t\t\tif SpeedLogic.canRun() then\n\t\t\t\tSpeedLogic.setSpeed(math.floor(slider.get() + 0.5))\n\t\t\tend\n\t\t\tlastSpeed = math.floor(slider.get() + 0.5)\n\t\telse\n\t\t\tif SpeedLogic.canRun() then\n\t\t\t\tSpeedLogic.resetSpeed()\n\t\t\tend\n\t\tend\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tGC:SaveModuleState(\"SpeedWindow\", {\n\t\t\t\tenabled = enabled == true,\n\t\t\t\tdefaultSpeed = lastSpeed or math.floor(slider.get() + 0.5),\n\t\t\t})\n\t\tend\n\t\trefreshStatus()\n\tend\n\n\t-- State card\n\tlocal card = Instance.new(\"Frame\")\n\tcard.Name = \"StateCard\"\n\tcard.Size = UDim2.new(1, 0, 0, 64)\n\tcard.Position = UDim2.fromOffset(0, PAD)\n\tcard.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tcard.BorderSizePixel = 0\n\tcard.Parent = content\n\tcorner(card, 4)\n\tstroke(card, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal cardLbl = Instance.new(\"TextLabel\")\n\tcardLbl.Size = UDim2.new(1, -80, 0, 12)\n\tcardLbl.Position = UDim2.fromOffset(10, 10)\n\tcardLbl.BackgroundTransparency = 1\n\tcardLbl.Text = \"WalkSpeed\"\n\tcardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tcardLbl.Font = Enum.Font.Gotham\n\tcardLbl.TextSize = 11\n\tcardLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tcardLbl.Parent = card\n\n\treadoutLabel = Instance.new(\"TextLabel\")\n\treadoutLabel.Name = \"Readout\"\n\treadoutLabel.Size = UDim2.new(1, -80, 0, 28)\n\treadoutLabel.Position = UDim2.fromOffset(10, 26)\n\treadoutLabel.BackgroundTransparency = 1\n\treadoutLabel.Text = \"0\"\n\treadoutLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\treadoutLabel.Font = Enum.Font.Code\n\treadoutLabel.TextSize = 24\n\treadoutLabel.TextXAlignment = Enum.TextXAlignment.Left\n\treadoutLabel.Parent = card\n\n\ttoggle = makeToggle(card, false, setEnabled)\n\ttoggle.set = toggle.set\n\tlocal tBtn = card:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Size = UDim2.fromOffset(56, 28)\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\t\tlocal kn = tBtn:FindFirstChild(\"Knob\")\n\t\tif kn then\n\t\t\tkn.Size = UDim2.fromOffset(20, 20)\n\t\tend\n\tend\n\n\t-- Slider box\n\tlocal sliderBoxY = PAD + 64 + 6\n\tslider = makeSlider(content, minV, maxV, start, applyIfOn)\n\tlocal sBox = content:FindFirstChild(\"SliderBox\")\n\tif sBox then\n\t\tsBox.Position = UDim2.fromOffset(0, sliderBoxY)\n\t\tsBox.Size = UDim2.new(1, 0, 0, 84)\n\tend\n\n\t-- Status line\n\tstateLabel = Instance.new(\"TextLabel\")\n\tstateLabel.Name = \"State\"\n\tstateLabel.Position = UDim2.fromOffset(0, sliderBoxY + 84 + 6)\n\tstateLabel.Size = UDim2.new(1, 0, 0, 14)\n\tstateLabel.BackgroundTransparency = 1\n\tstateLabel.Text = \"OFF\"\n\tstateLabel.TextColor3 = P.textDim\n\tstateLabel.Font = Enum.Font.Code\n\tstateLabel.TextSize = 10\n\tstateLabel.TextXAlignment = Enum.TextXAlignment.Left\n\tstateLabel.Parent = content\n\n\t-- Expose readout to refresh (bridge via slider box)\n\tlocal function wrapRefresh()\n\t\tlocal orig = slider.refresh\n\t\tslider.refresh = function()\n\t\t\torig()\n\t\t\trefreshStatus()\n\t\tend\n\tend\n\twrapRefresh()\n\n\tbase:setSize(300, 28 + PAD + 64 + 6 + 84 + 6 + 14 + PAD)\n\n\trefreshStatus()\n\ttask.spawn(function()\n\t\twhile window == base and not base._destroyed do\n\t\t\tif not enabled then\n\t\t\t\trefreshStatus()\n\t\t\tend\n\t\t\ttask.wait(0.5)\n\t\tend\n\tend)\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.SpeedWindow = SpeedWindow\nreturn SpeedWindow\n",
	TPWindow = "local env = getgenv and getgenv() or _G\nif env.TPWindow then return env.TPWindow end\n\nlocal TPWindow = {}\nTPWindow.GetTable = \"Player\"\nTPWindow.GetPosition = 2\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction TPWindow.Name()\n\treturn Str(\"tpName\", \"Телепорт\")\nend\n\nfunction TPWindow.Desc()\n\treturn Str(\"tpDesc\", \"Точки, ТП и удаление\")\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function destroyButtons(parent)\n\tfor _, child in ipairs(parent:GetChildren()) do\n\t\tif child:IsA(\"TextButton\") then\n\t\t\tchild:Destroy()\n\t\tend\n\tend\nend\n\nfunction TPWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\twindow:Destroy()\n\t\twindow = nil\n\t\treturn\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal TPLogic = env.TPLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(TPLogic, \"TPLogic не загружен\")\n\n\tlocal P = currentPalette()\n\tlocal holdTime = tonumber(config.holdTime) or 0.7\n\tlocal WIDTH = 280\n\tlocal ROW_H = 40\n\tlocal btnH = 36\n\tlocal PAD = 6\n\n\tlocal base = WindowBase.new(\"TP\", TPWindow.Name(), WIDTH, 280)\n\twindow = base\n\tlocal content = base.Content\n\n\tlocal hint = Instance.new(\"TextLabel\")\n\thint.Name = \"Hint\"\n\thint.Position = UDim2.fromOffset(0, 2)\n\thint.Size = UDim2.new(1, 0, 0, 14)\n\thint.BackgroundTransparency = 1\n\thint.Text = Str(\"tpHint\", \"нажми — тп, удерживай — удалить\")\n\thint.TextColor3 = P.textDim\n\thint.Font = Enum.Font.Gotham\n\thint.TextSize = 10\n\thint.TextXAlignment = Enum.TextXAlignment.Left\n\thint.Parent = content\n\n\tlocal list = Instance.new(\"ScrollingFrame\")\n\tlist.Name = \"List\"\n\tlist.Position = UDim2.fromOffset(0, 18)\n\tlist.Size = UDim2.new(1, 0, 1, -(18 + btnH + PAD * 2))\n\tlist.BackgroundTransparency = 1\n\tlist.BorderSizePixel = 0\n\tlist.ScrollBarThickness = 3\n\tlist.ScrollBarImageColor3 = P.line\n\tlist.CanvasSize = UDim2.fromOffset(0, 0)\n\tlist.AutomaticCanvasSize = Enum.AutomaticSize.Y\n\tlist.Parent = content\n\n\tlocal layout = Instance.new(\"UIListLayout\")\n\tlayout.FillDirection = Enum.FillDirection.Vertical\n\tlayout.Padding = UDim.new(0, 4)\n\tlayout.SortOrder = Enum.SortOrder.LayoutOrder\n\tlayout.Parent = list\n\n\tlocal addBtn = Instance.new(\"TextButton\")\n\taddBtn.Name = \"Add\"\n\taddBtn.Position = UDim2.new(0, 0, 1, -(btnH + PAD))\n\taddBtn.Size = UDim2.new(1, 0, 0, btnH)\n\taddBtn.BackgroundColor3 = P.info\n\taddBtn.BorderSizePixel = 0\n\taddBtn.AutoButtonColor = true\n\taddBtn.Text = Str(\"tpAdd\", \"+ Добавить точку\")\n\taddBtn.TextColor3 = Color3.new(1, 1, 1)\n\taddBtn.Font = Enum.Font.GothamBold\n\taddBtn.TextSize = 13\n\taddBtn.Parent = content\n\tInstance.new(\"UICorner\", addBtn).CornerRadius = UDim.new(0, 4)\n\n\tlocal function refresh()\n\t\tif not window then return end\n\t\tfor _, child in ipairs(list:GetChildren()) do\n\t\t\tif child:IsA(\"TextButton\") then\n\t\t\t\tchild:Destroy()\n\t\t\tend\n\t\tend\n\n\t\tlocal pts = TPLogic.getPoints()\n\t\tfor i, pos in ipairs(pts) do\n\t\t\tlocal btn = Instance.new(\"TextButton\")\n\t\t\tbtn.Size = UDim2.new(1, -4, 0, ROW_H - 4)\n\t\t\tbtn.BackgroundColor3 = P.panel\n\t\t\tbtn.BorderSizePixel = 0\n\t\t\tbtn.AutoButtonColor = true\n\t\t\tbtn.Text = \"\"\n\t\t\tbtn.LayoutOrder = i\n\t\t\tbtn.Parent = list\n\t\t\tInstance.new(\"UICorner\", btn).CornerRadius = UDim.new(0, 4)\n\t\t\tpcall(function()\n\t\t\t\tlocal s = Instance.new(\"UIStroke\")\n\t\t\t\ts.Thickness = 1\n\t\t\t\ts.Color = P.line\n\t\t\t\ts.Parent = btn\n\t\t\tend)\n\n\t\t\tlocal label = Instance.new(\"TextLabel\")\n\t\t\tlabel.Size = UDim2.new(1, -110, 1, -8)\n\t\t\tlabel.Position = UDim2.fromOffset(8, 4)\n\t\t\tlabel.BackgroundTransparency = 1\n\t\t\tlabel.Text = (\"Точка %d\"):format(i)\n\t\t\tlabel.TextColor3 = P.text\n\t\t\tlabel.Font = Enum.Font.GothamSemibold\n\t\t\tlabel.TextSize = 12\n\t\t\tlabel.TextXAlignment = Enum.TextXAlignment.Left\n\t\t\tlabel.TextTruncate = Enum.TextTruncate.AtEnd\n\t\t\tlabel.Parent = btn\n\n\t\t\tlocal coords = Instance.new(\"TextLabel\")\n\t\t\tcoords.Name = \"Coords\"\n\t\t\tcoords.Size = UDim2.new(0, 96, 1, -8)\n\t\t\tcoords.Position = UDim2.new(1, -104, 0, 4)\n\t\t\tcoords.BackgroundTransparency = 1\n\t\t\tcoords.Text = (\"(%.0f, %.0f, %.0f)\"):format(pos.X, pos.Y, pos.Z)\n\t\t\tcoords.TextColor3 = P.textDim\n\t\t\tcoords.Font = Enum.Font.Code\n\t\t\tcoords.TextSize = 10\n\t\t\tcoords.TextXAlignment = Enum.TextXAlignment.Right\n\t\t\tcoords.TextTruncate = Enum.TextTruncate.AtEnd\n\t\t\tcoords.Parent = btn\n\n\t\t\tlocal index = i\n\t\t\tlocal holdTask = nil\n\t\t\tlocal deleted = false\n\n\t\t\tbtn.InputBegan:Connect(function(input)\n\t\t\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\t\t\treturn\n\t\t\t\tend\n\t\t\t\tdeleted = false\n\t\t\t\tholdTask = task.delay(holdTime, function()\n\t\t\t\t\tif deleted then return end\n\t\t\t\t\tdeleted = true\n\t\t\t\t\tTPLogic.deletePoint(index)\n\t\t\t\t\trefresh()\n\t\t\t\tend)\n\t\t\tend)\n\n\t\t\tbtn.InputEnded:Connect(function(input)\n\t\t\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\t\t\treturn\n\t\t\t\tend\n\t\t\t\tif holdTask then\n\t\t\t\t\ttask.cancel(holdTask)\n\t\t\t\t\tholdTask = nil\n\t\t\t\tend\n\t\t\t\tif deleted then return end\n\t\t\t\tTPLogic.teleportTo(index)\n\t\t\tend)\n\t\tend\n\n\t\tlocal count = #pts\n\t\tlocal listH = math.max(count * ROW_H, 60)\n\t\tlocal contentH = math.min(18 + listH + btnH + PAD * 2, 360)\n\t\tbase:setSize(WIDTH, 28 + contentH)\n\t\tlist.Size = UDim2.new(1, 0, 1, -(18 + btnH + PAD * 2))\n\t\tlist.CanvasSize = UDim2.fromOffset(0, 0)\n\tend\n\n\taddBtn.MouseButton1Click:Connect(function()\n\t\tif not TPLogic.canRun() then\n\t\t\twarn(\"[TPWindow] персонаж не заспавнен\")\n\t\t\treturn\n\t\tend\n\t\tTPLogic.addPoint()\n\t\trefresh()\n\tend)\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\n\n\trefresh()\nend\n\nenv.TPWindow = TPWindow\nreturn TPWindow\n",
	NoclipWindow = "local env = getgenv and getgenv() or _G\nif env.NoclipWindow then return env.NoclipWindow end\n\nlocal NoclipWindow = {}\nNoclipWindow.GetTable = \"Player\"\nNoclipWindow.GetPosition = 3\nNoclipWindow.QuickToggle = true\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction NoclipWindow.Name()\n\treturn Str(\"noclipName\", \"NoClip\")\nend\n\nfunction NoclipWindow.Desc()\n\treturn Str(\"noclipDesc\", \"Проход сквозь стены\")\nend\n\nfunction NoclipWindow.IsOn()\n\tlocal L = env.NoclipLogic\n\treturn L ~= nil and L.isEnabled() == true\nend\n\nfunction NoclipWindow.SetOn(state)\n\tlocal L = env.NoclipLogic\n\tassert(L, \"NoclipLogic не загружен\")\n\tif state then\n\t\tL.enable()\n\telse\n\t\tL.disable()\n\tend\n\tlocal GC = env.GlobalControler\n\tif GC and GC.SaveModuleState then\n\t\tGC:SaveModuleState(\"NoclipWindow\", { enabled = state == true })\n\tend\n\treturn NoclipWindow.IsOn()\nend\n\nfunction NoclipWindow.Restore(config)\n\tconfig = config or {}\n\tif config.enabled then\n\t\tlocal L = env.NoclipLogic\n\t\tif L then\n\t\t\tL.enable()\n\t\tend\n\tend\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal function makeToggle(parent, on, onToggle)\n\tlocal P = currentPalette() or {}\n\tlocal h = 28\n\tlocal w = 56\n\n\tlocal btn = Instance.new(\"TextButton\")\n\tbtn.Name = \"Toggle\"\n\tbtn.Size = UDim2.fromOffset(w, h)\n\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\tbtn.BorderSizePixel = 0\n\tbtn.AutoButtonColor = true\n\tbtn.Text = \"\"\n\tbtn.Parent = parent\n\tcorner(btn, 99)\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -12, 1, 0)\n\tlabel.Position = UDim2.fromOffset(8, 0)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = on and \"ON\" or \"OFF\"\n\tlabel.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 11\n\tlabel.ZIndex = 2\n\tlabel.Parent = btn\n\n\tlocal knob = Instance.new(\"Frame\")\n\tknob.Name = \"Knob\"\n\tknob.Size = UDim2.fromOffset(h - 8, h - 8)\n\tknob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\tknob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tknob.BorderSizePixel = 0\n\tknob.ZIndex = 3\n\tknob.Parent = btn\n\tcorner(knob, 99)\n\n\tlocal state = on\n\tlocal function paint()\n\t\tbtn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\t\tlabel.Text = state and \"ON\" or \"OFF\"\n\t\tlabel.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tknob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\t\tknob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tend\n\n\tbtn.MouseButton1Click:Connect(function()\n\t\tstate = not state\n\t\tpaint()\n\t\tif onToggle then\n\t\t\tonToggle(state)\n\t\tend\n\tend)\n\n\treturn {\n\t\tget = function() return state end,\n\t\tset = function(v)\n\t\t\tstate = v\n\t\t\tpaint()\n\t\tend,\n\t}\nend\n\nfunction NoclipWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\twindow:Destroy()\n\t\twindow = nil\n\t\treturn\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal NoclipLogic = env.NoclipLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(NoclipLogic, \"NoclipLogic не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal base = WindowBase.new(\"Noclip\", NoclipWindow.Name(), 280, 160)\n\twindow = base\n\n\tlocal content = base.Content\n\tlocal PAD = 6\n\n\tlocal stateLabel\n\tlocal toggle\n\n\tlocal function refreshStatus()\n\t\tif not NoclipLogic.canRun() then\n\t\t\tif stateLabel then\n\t\t\t\tstateLabel.Text = Str(\"noChar\", \"Нет персонажа\")\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\t\treturn\n\t\tend\n\t\tlocal on = NoclipLogic.isEnabled()\n\t\tif stateLabel then\n\t\t\tif on then\n\t\t\t\tstateLabel.Text = \"ON  ·  стены отключены\"\n\t\t\t\tstateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\t\telse\n\t\t\t\tstateLabel.Text = \"OFF  ·  обычный режим\"\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\tend\n\tend\n\n\tlocal function setEnabled(state)\n\t\tif state then\n\t\t\tNoclipLogic.enable()\n\t\telse\n\t\t\tNoclipLogic.disable()\n\t\tend\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tGC:SaveModuleState(\"NoclipWindow\", { enabled = state == true })\n\t\tend\n\t\trefreshStatus()\n\tend\n\n\tlocal card = Instance.new(\"Frame\")\n\tcard.Name = \"StateCard\"\n\tcard.Size = UDim2.new(1, 0, 0, 64)\n\tcard.Position = UDim2.fromOffset(0, PAD)\n\tcard.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tcard.BorderSizePixel = 0\n\tcard.Parent = content\n\tcorner(card, 4)\n\tstroke(card, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal cardLbl = Instance.new(\"TextLabel\")\n\tcardLbl.Size = UDim2.new(1, -80, 0, 12)\n\tcardLbl.Position = UDim2.fromOffset(10, 10)\n\tcardLbl.BackgroundTransparency = 1\n\tcardLbl.Text = \"NoClip\"\n\tcardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tcardLbl.Font = Enum.Font.Gotham\n\tcardLbl.TextSize = 11\n\tcardLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tcardLbl.Parent = card\n\n\tlocal bigState = Instance.new(\"TextLabel\")\n\tbigState.Name = \"Big\"\n\tbigState.Size = UDim2.new(1, -80, 0, 28)\n\tbigState.Position = UDim2.fromOffset(10, 26)\n\tbigState.BackgroundTransparency = 1\n\tbigState.Text = \"OFF\"\n\tbigState.TextColor3 = P.textDim\n\tbigState.Font = Enum.Font.Code\n\tbigState.TextSize = 24\n\tbigState.TextXAlignment = Enum.TextXAlignment.Left\n\tbigState.Parent = card\n\n\ttoggle = makeToggle(card, false, setEnabled)\n\tlocal tBtn = card:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Size = UDim2.fromOffset(56, 28)\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\n\tlocal hint = Instance.new(\"TextLabel\")\n\thint.Name = \"Hint\"\n\thint.Position = UDim2.fromOffset(0, PAD + 64 + 8)\n\thint.Size = UDim2.new(1, 0, 0, 28)\n\thint.BackgroundTransparency = 1\n\thint.Text = Str(\"noclipHint\", \"Включи — и иди сквозь стены.\\nВыключение вернёт коллизию.\")\n\thint.TextColor3 = P.textDim\n\thint.Font = Enum.Font.Gotham\n\thint.TextSize = 10\n\thint.TextWrapped = true\n\thint.TextYAlignment = Enum.TextYAlignment.Top\n\thint.TextXAlignment = Enum.TextXAlignment.Left\n\thint.Parent = content\n\n\tstateLabel = Instance.new(\"TextLabel\")\n\tstateLabel.Name = \"State\"\n\tstateLabel.Position = UDim2.fromOffset(0, PAD + 64 + 8 + 28 + 8)\n\tstateLabel.Size = UDim2.new(1, 0, 0, 14)\n\tstateLabel.BackgroundTransparency = 1\n\tstateLabel.Text = \"OFF\"\n\tstateLabel.TextColor3 = P.textDim\n\tstateLabel.Font = Enum.Font.Code\n\tstateLabel.TextSize = 10\n\tstateLabel.TextXAlignment = Enum.TextXAlignment.Left\n\tstateLabel.Parent = content\n\n\tbase:setSize(280, 28 + PAD + 64 + 8 + 28 + 8 + 14 + PAD)\n\n\trefreshStatus()\n\ttask.spawn(function()\n\t\twhile window == base and not base._destroyed do\n\t\t\trefreshStatus()\n\t\t\ttask.wait(0.5)\n\t\tend\n\tend)\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.NoclipWindow = NoclipWindow\nreturn NoclipWindow\n",
	JumpWindow = "local env = getgenv and getgenv() or _G\nif env.JumpWindow then return env.JumpWindow end\n\nlocal JumpWindow = {}\nJumpWindow.GetTable = \"Player\"\nJumpWindow.GetPosition = 4\nJumpWindow.QuickToggle = true\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction JumpWindow.Name()\n\treturn Str(\"jumpName\", \"Прыжок\")\nend\n\nfunction JumpWindow.Desc()\n\treturn Str(\"jumpDesc\", \"Бесконечный прыжок\")\nend\n\nfunction JumpWindow.IsOn()\n\tlocal L = env.JumpLogic\n\treturn L ~= nil and L.isEnabled() == true\nend\n\nfunction JumpWindow.SetOn(state)\n\tlocal L = env.JumpLogic\n\tassert(L, \"JumpLogic не загружен\")\n\tif state then\n\t\tL.enable()\n\telse\n\t\tL.disable()\n\tend\n\tlocal GC = env.GlobalControler\n\tif GC and GC.SaveModuleState then\n\t\tGC:SaveModuleState(\"JumpWindow\", {\n\t\t\tenabled = state == true,\n\t\t\tdefaultPower = L.getPower(),\n\t\t})\n\tend\n\treturn JumpWindow.IsOn()\nend\n\nfunction JumpWindow.Restore(config)\n\tconfig = config or {}\n\tlocal L = env.JumpLogic\n\tif not L then\n\t\treturn\n\tend\n\tlocal p = tonumber(config.defaultPower)\n\tif p then\n\t\tL.setPower(p)\n\tend\n\tif config.enabled then\n\t\tL.enable()\n\tend\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal UIS = game:GetService(\"UserInputService\")\n\nlocal function makeToggle(parent, on, onToggle)\n\tlocal P = currentPalette() or {}\n\tlocal h = 28\n\n\tlocal btn = Instance.new(\"TextButton\")\n\tbtn.Name = \"Toggle\"\n\tbtn.Size = UDim2.fromOffset(56, h)\n\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\tbtn.BorderSizePixel = 0\n\tbtn.AutoButtonColor = true\n\tbtn.Text = \"\"\n\tbtn.Parent = parent\n\tcorner(btn, 99)\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -12, 1, 0)\n\tlabel.Position = UDim2.fromOffset(8, 0)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = on and \"ON\" or \"OFF\"\n\tlabel.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 11\n\tlabel.ZIndex = 2\n\tlabel.Parent = btn\n\n\tlocal knob = Instance.new(\"Frame\")\n\tknob.Name = \"Knob\"\n\tknob.Size = UDim2.fromOffset(h - 8, h - 8)\n\tknob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\tknob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tknob.BorderSizePixel = 0\n\tknob.ZIndex = 3\n\tknob.Parent = btn\n\tcorner(knob, 99)\n\n\tlocal state = on\n\tlocal function paint()\n\t\tbtn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\t\tlabel.Text = state and \"ON\" or \"OFF\"\n\t\tlabel.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tknob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\t\tknob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tend\n\n\tbtn.MouseButton1Click:Connect(function()\n\t\tstate = not state\n\t\tpaint()\n\t\tif onToggle then\n\t\t\tonToggle(state)\n\t\tend\n\tend)\n\n\treturn {\n\t\tget = function() return state end,\n\t\tset = function(v)\n\t\t\tstate = v\n\t\t\tpaint()\n\t\tend,\n\t}\nend\n\nlocal function makeSlider(parent, minV, maxV, startV, onChange)\n\tlocal P = currentPalette() or {}\n\tlocal box = Instance.new(\"Frame\")\n\tbox.Name = \"SliderBox\"\n\tbox.Size = UDim2.new(1, 0, 0, 72)\n\tbox.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tbox.BorderSizePixel = 0\n\tbox.Parent = parent\n\tcorner(box, 4)\n\tstroke(box, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -70, 0, 14)\n\tlabel.Position = UDim2.fromOffset(10, 8)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = Str(\"jumpPower\", \"Сила прыжка\")\n\tlabel.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tlabel.Font = Enum.Font.Gotham\n\tlabel.TextSize = 11\n\tlabel.TextXAlignment = Enum.TextXAlignment.Left\n\tlabel.Parent = box\n\n\tlocal readout = Instance.new(\"TextLabel\")\n\treadout.Name = \"Readout\"\n\treadout.Size = UDim2.new(0, 56, 0, 20)\n\treadout.Position = UDim2.new(1, -66, 0, 6)\n\treadout.BackgroundTransparency = 1\n\treadout.Text = tostring(math.floor(startV + 0.5))\n\treadout.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\treadout.Font = Enum.Font.Code\n\treadout.TextSize = 16\n\treadout.TextXAlignment = Enum.TextXAlignment.Right\n\treadout.Parent = box\n\n\tlocal track = Instance.new(\"Frame\")\n\ttrack.Name = \"Track\"\n\ttrack.Size = UDim2.new(1, -20, 0, 6)\n\ttrack.Position = UDim2.fromOffset(10, 34)\n\ttrack.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\ttrack.BorderSizePixel = 0\n\ttrack.Active = true\n\ttrack.Parent = box\n\tcorner(track, 99)\n\n\tlocal fill = Instance.new(\"Frame\")\n\tfill.Name = \"Fill\"\n\tfill.Size = UDim2.new(0, 0, 1, 0)\n\tfill.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tfill.BorderSizePixel = 0\n\tfill.Parent = track\n\tcorner(fill, 99)\n\n\tlocal thumb = Instance.new(\"Frame\")\n\tthumb.Name = \"Thumb\"\n\tthumb.Size = UDim2.fromOffset(18, 18)\n\tthumb.Position = UDim2.new(0, -9, 0.5, -9)\n\tthumb.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tthumb.BorderSizePixel = 0\n\tthumb.ZIndex = 3\n\tthumb.Parent = track\n\tcorner(thumb, 99)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 2\n\t\ts.Color = P.bg or Color3.fromRGB(15, 19, 29)\n\t\ts.Parent = thumb\n\tend)\n\n\tlocal mins = Instance.new(\"TextLabel\")\n\tmins.Size = UDim2.new(0, 36, 0, 12)\n\tmins.Position = UDim2.fromOffset(10, 48)\n\tmins.BackgroundTransparency = 1\n\tmins.Text = tostring(minV)\n\tmins.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tmins.Font = Enum.Font.Code\n\tmins.TextSize = 9\n\tmins.TextXAlignment = Enum.TextXAlignment.Left\n\tmins.Parent = box\n\n\tlocal maxs = Instance.new(\"TextLabel\")\n\tmaxs.Size = UDim2.new(0, 36, 0, 12)\n\tmaxs.Position = UDim2.new(1, -46, 0, 48)\n\tmaxs.BackgroundTransparency = 1\n\tmaxs.Text = tostring(maxV)\n\tmaxs.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tmaxs.Font = Enum.Font.Code\n\tmaxs.TextSize = 9\n\tmaxs.TextXAlignment = Enum.TextXAlignment.Right\n\tmaxs.Parent = box\n\n\tlocal value = startV\n\tlocal dragging = false\n\n\tlocal function applyVisual()\n\t\tlocal range = maxV - minV\n\t\tlocal frac = 0\n\t\tif range > 0 then\n\t\t\tfrac = (value - minV) / range\n\t\tend\n\t\tfrac = math.clamp(frac, 0, 1)\n\t\tfill.Size = UDim2.new(frac, 0, 1, 0)\n\t\tthumb.Position = UDim2.new(frac, -9, 0.5, -9)\n\t\treadout.Text = tostring(math.floor(value + 0.5))\n\tend\n\n\tlocal function fromInput(input)\n\t\tlocal abs = track.AbsolutePosition.X\n\t\tlocal sizeX = track.AbsoluteSize.X\n\t\tif sizeX <= 0 then\n\t\t\treturn\n\t\tend\n\t\tlocal frac = (input.Position.X - abs) / sizeX\n\t\tfrac = math.clamp(frac, 0, 1)\n\t\tvalue = minV + frac * (maxV - minV)\n\t\tapplyVisual()\n\t\tif onChange then\n\t\t\tonChange(value)\n\t\tend\n\tend\n\n\ttrack.InputBegan:Connect(function(input)\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tdragging = true\n\t\tfromInput(input)\n\tend)\n\n\tUIS.InputChanged:Connect(function(input)\n\t\tif not dragging then return end\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseMovement\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tfromInput(input)\n\tend)\n\n\tlocal function endDrag(input)\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tdragging = false\n\tend\n\tUIS.InputEnded:Connect(endDrag)\n\ttrack.InputEnded:Connect(endDrag)\n\n\ttask.defer(applyVisual)\n\n\treturn {\n\t\tget = function() return value end,\n\t\tset = function(v)\n\t\t\tvalue = math.clamp(v, minV, maxV)\n\t\t\tapplyVisual()\n\t\tend,\n\t\trefresh = applyVisual,\n\t}\nend\n\nfunction JumpWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\twindow:Destroy()\n\t\twindow = nil\n\t\treturn\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal JumpLogic = env.JumpLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(JumpLogic, \"JumpLogic не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal base = WindowBase.new(\"Jump\", JumpWindow.Name(), 300, 240)\n\twindow = base\n\n\tlocal content = base.Content\n\tlocal PAD = 6\n\n\tlocal minV = tonumber(config.minPower) or 20\n\tlocal maxV = tonumber(config.maxPower) or 120\n\tif maxV <= minV then\n\t\tmaxV = minV + 1\n\tend\n\tlocal start = tonumber(config.defaultPower) or JumpLogic.getPower()\n\tif start < minV then start = minV end\n\tif start > maxV then start = maxV end\n\n\tlocal stateLabel\n\tlocal toggle\n\tlocal slider\n\n\tlocal function refreshStatus()\n\t\tif not JumpLogic.canRun() then\n\t\t\tif stateLabel then\n\t\t\t\tstateLabel.Text = Str(\"noChar\", \"Нет персонажа\")\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\t\treturn\n\t\tend\n\t\tlocal on = JumpLogic.isEnabled()\n\t\tif stateLabel then\n\t\t\tif on then\n\t\t\t\tstateLabel.Text = (\"ON  ·  JumpPower %.0f\"):format(JumpLogic.getPower())\n\t\t\t\tstateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\t\telse\n\t\t\t\tstateLabel.Text = (\"OFF  ·  сила %.0f\"):format(JumpLogic.getPower())\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\tend\n\tend\n\n\tlocal function applyPower(value)\n\t\tJumpLogic.setPower(value)\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tGC:SaveModuleState(\"JumpWindow\", {\n\t\t\t\tdefaultPower = math.floor(value + 0.5),\n\t\t\t})\n\t\tend\n\t\trefreshStatus()\n\tend\n\n\tlocal function setEnabled(state)\n\t\tif state then\n\t\t\tJumpLogic.setPower(math.floor(slider.get() + 0.5))\n\t\t\tJumpLogic.enable()\n\t\telse\n\t\t\tJumpLogic.disable()\n\t\tend\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tGC:SaveModuleState(\"JumpWindow\", {\n\t\t\t\tenabled = state == true,\n\t\t\t\tdefaultPower = JumpLogic.getPower(),\n\t\t\t})\n\t\tend\n\t\trefreshStatus()\n\tend\n\n\tlocal card = Instance.new(\"Frame\")\n\tcard.Name = \"StateCard\"\n\tcard.Size = UDim2.new(1, 0, 0, 64)\n\tcard.Position = UDim2.fromOffset(0, PAD)\n\tcard.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tcard.BorderSizePixel = 0\n\tcard.Parent = content\n\tcorner(card, 4)\n\tstroke(card, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal cardLbl = Instance.new(\"TextLabel\")\n\tcardLbl.Size = UDim2.new(1, -80, 0, 12)\n\tcardLbl.Position = UDim2.fromOffset(10, 10)\n\tcardLbl.BackgroundTransparency = 1\n\tcardLbl.Text = Str(\"jumpDesc\", \"Бесконечный прыжок\")\n\tcardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tcardLbl.Font = Enum.Font.Gotham\n\tcardLbl.TextSize = 11\n\tcardLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tcardLbl.Parent = card\n\n\tlocal bigState = Instance.new(\"TextLabel\")\n\tbigState.Name = \"Big\"\n\tbigState.Size = UDim2.new(1, -80, 0, 28)\n\tbigState.Position = UDim2.fromOffset(10, 26)\n\tbigState.BackgroundTransparency = 1\n\tbigState.Text = \"OFF\"\n\tbigState.TextColor3 = P.textDim\n\tbigState.Font = Enum.Font.Code\n\tbigState.TextSize = 24\n\tbigState.TextXAlignment = Enum.TextXAlignment.Left\n\tbigState.Parent = card\n\n\ttoggle = makeToggle(card, false, setEnabled)\n\tlocal tBtn = card:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\n\tlocal sliderBoxY = PAD + 64 + 6\n\tslider = makeSlider(content, minV, maxV, start, applyPower)\n\tlocal sBox = content:FindFirstChild(\"SliderBox\")\n\tif sBox then\n\t\tsBox.Position = UDim2.fromOffset(0, sliderBoxY)\n\tend\n\n\tstateLabel = Instance.new(\"TextLabel\")\n\tstateLabel.Name = \"State\"\n\tstateLabel.Position = UDim2.fromOffset(0, sliderBoxY + 72 + 6)\n\tstateLabel.Size = UDim2.new(1, 0, 0, 14)\n\tstateLabel.BackgroundTransparency = 1\n\tstateLabel.Text = \"OFF\"\n\tstateLabel.TextColor3 = P.textDim\n\tstateLabel.Font = Enum.Font.Code\n\tstateLabel.TextSize = 10\n\tstateLabel.TextXAlignment = Enum.TextXAlignment.Left\n\tstateLabel.Parent = content\n\n\tbase:setSize(300, 28 + PAD + 64 + 6 + 72 + 6 + 14 + PAD)\n\n\trefreshStatus()\n\ttask.spawn(function()\n\t\twhile window == base and not base._destroyed do\n\t\t\trefreshStatus()\n\t\t\ttask.wait(0.5)\n\t\tend\n\tend)\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.JumpWindow = JumpWindow\nreturn JumpWindow\n",
	SpoofingWindow = "local env = getgenv and getgenv() or _G\nif env.SpoofingWindow then return env.SpoofingWindow end\n\nlocal SpoofingWindow = {}\nSpoofingWindow.GetTable = \"Server\"\nSpoofingWindow.GetPosition = 1\nSpoofingWindow.QuickToggle = true\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction SpoofingWindow.Name()\n\treturn Str(\"spoofName\", \"Spoofing\")\nend\n\nfunction SpoofingWindow.Desc()\n\treturn Str(\"spoofDesc\", \"Обход speed / jump / tp\")\nend\n\nfunction SpoofingWindow.IsOn()\n\tlocal L = env.SpoofingLogic\n\treturn L ~= nil and L.isEnabled() == true\nend\n\nfunction SpoofingWindow.SetOn(state)\n\tlocal L = env.SpoofingLogic\n\tassert(L, \"SpoofingLogic не загружен\")\n\tif state then\n\t\tL.enable()\n\telse\n\t\tL.disable()\n\tend\n\tlocal GC = env.GlobalControler\n\tif GC and GC.SaveModuleState then\n\t\tlocal flags = L.getFlags and L.getFlags() or {}\n\t\tGC:SaveModuleState(\"SpoofingWindow\", {\n\t\t\tenabled = state == true,\n\t\t\tspeed = flags.speed,\n\t\t\tjump = flags.jump,\n\t\t\ttp = flags.tp,\n\t\t})\n\tend\n\treturn SpoofingWindow.IsOn()\nend\n\nfunction SpoofingWindow.Restore(config)\n\tconfig = config or {}\n\tlocal L = env.SpoofingLogic\n\tif not L then\n\t\treturn\n\tend\n\tif L.setFlag then\n\t\tif config.speed ~= nil then\n\t\t\tL.setFlag(\"speed\", config.speed)\n\t\tend\n\t\tif config.jump ~= nil then\n\t\t\tL.setFlag(\"jump\", config.jump)\n\t\tend\n\t\tif config.tp ~= nil then\n\t\t\tL.setFlag(\"tp\", config.tp)\n\t\tend\n\tend\n\tif config.enabled then\n\t\tL.enable()\n\tend\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal function makeToggle(parent, on, onToggle)\n\tlocal P = currentPalette() or {}\n\tlocal h = 28\n\tlocal w = 56\n\n\tlocal btn = Instance.new(\"TextButton\")\n\tbtn.Name = \"Toggle\"\n\tbtn.Size = UDim2.fromOffset(w, h)\n\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\tbtn.BorderSizePixel = 0\n\tbtn.AutoButtonColor = true\n\tbtn.Text = \"\"\n\tbtn.Parent = parent\n\tcorner(btn, 99)\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -12, 1, 0)\n\tlabel.Position = UDim2.fromOffset(8, 0)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = on and \"ON\" or \"OFF\"\n\tlabel.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 11\n\tlabel.ZIndex = 2\n\tlabel.Parent = btn\n\n\tlocal knob = Instance.new(\"Frame\")\n\tknob.Name = \"Knob\"\n\tknob.Size = UDim2.fromOffset(h - 8, h - 8)\n\tknob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\tknob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tknob.BorderSizePixel = 0\n\tknob.ZIndex = 3\n\tknob.Parent = btn\n\tcorner(knob, 99)\n\n\tlocal state = on\n\tlocal function paint()\n\t\tbtn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\t\tlabel.Text = state and \"ON\" or \"OFF\"\n\t\tlabel.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tknob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\t\tknob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tend\n\n\tbtn.MouseButton1Click:Connect(function()\n\t\tstate = not state\n\t\tpaint()\n\t\tif onToggle then\n\t\t\tonToggle(state)\n\t\tend\n\tend)\n\n\treturn {\n\t\tget = function() return state end,\n\t\tset = function(v)\n\t\t\tstate = v\n\t\t\tpaint()\n\t\tend,\n\t}\nend\n\nlocal function flagRow(parent, y, titleText, flagName, L, P, onSaved)\n\tlocal row = Instance.new(\"Frame\")\n\trow.Name = \"FlagRow\"\n\trow.Size = UDim2.new(1, 0, 0, 36)\n\trow.Position = UDim2.fromOffset(0, y)\n\trow.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\trow.BorderSizePixel = 0\n\trow.Parent = parent\n\tcorner(row, 4)\n\n\tlocal lbl = Instance.new(\"TextLabel\")\n\tlbl.Size = UDim2.new(1, -70, 1, 0)\n\tlbl.Position = UDim2.fromOffset(10, 0)\n\tlbl.BackgroundTransparency = 1\n\tlbl.Text = titleText\n\tlbl.TextColor3 = P.text or Color3.fromRGB(223, 226, 240)\n\tlbl.Font = Enum.Font.Gotham\n\tlbl.TextSize = 11\n\tlbl.TextXAlignment = Enum.TextXAlignment.Left\n\tlbl.Parent = row\n\n\tlocal t = makeToggle(row, L.getFlag(flagName), function(on)\n\t\tL.setFlag(flagName, on)\n\t\tif onSaved then\n\t\t\tonSaved()\n\t\tend\n\tend)\n\tlocal tBtn = row:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\treturn t\nend\n\nfunction SpoofingWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\tif window._destroyed then\n\t\t\twindow = nil\n\t\telse\n\t\t\twindow:Destroy()\n\t\t\twindow = nil\n\t\t\treturn\n\t\tend\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal L = env.SpoofingLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(L, \"SpoofingLogic не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal base = WindowBase.new(\"Spoofing\", SpoofingWindow.Name(), 280, 240)\n\twindow = base\n\tlocal content = base.Content\n\tlocal PAD = 6\n\n\tlocal stateLabel\n\tlocal toggle\n\tlocal bigState\n\n\tlocal function saveState()\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tlocal flags = L.getFlags and L.getFlags() or {}\n\t\t\tGC:SaveModuleState(\"SpoofingWindow\", {\n\t\t\t\tenabled = L.isEnabled(),\n\t\t\t\tspeed = flags.speed,\n\t\t\t\tjump = flags.jump,\n\t\t\t\ttp = flags.tp,\n\t\t\t})\n\t\tend\n\tend\n\n\tlocal function refreshStatus()\n\t\tif stateLabel then\n\t\t\tif L.isEnabled() then\n\t\t\t\tstateLabel.Text = \"ON  ·  \" .. SpoofingWindow.Desc()\n\t\t\t\tstateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\t\telse\n\t\t\t\tstateLabel.Text = \"OFF  ·  checks active\"\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\tend\n\t\tif bigState then\n\t\t\tbigState.Text = L.isEnabled() and \"ON\" or \"OFF\"\n\t\t\tbigState.TextColor3 = L.isEnabled() and (P.accent or Color3.fromRGB(0, 242, 254)) or P.textDim\n\t\tend\n\tend\n\n\tlocal function setEnabled(state)\n\t\tif state then\n\t\t\tL.enable()\n\t\telse\n\t\t\tL.disable()\n\t\tend\n\t\tsaveState()\n\t\trefreshStatus()\n\tend\n\n\tlocal card = Instance.new(\"Frame\")\n\tcard.Name = \"StateCard\"\n\tcard.Size = UDim2.new(1, 0, 0, 64)\n\tcard.Position = UDim2.fromOffset(0, PAD)\n\tcard.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tcard.BorderSizePixel = 0\n\tcard.Parent = content\n\tcorner(card, 4)\n\tstroke(card, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal cardLbl = Instance.new(\"TextLabel\")\n\tcardLbl.Size = UDim2.new(1, -80, 0, 12)\n\tcardLbl.Position = UDim2.fromOffset(10, 10)\n\tcardLbl.BackgroundTransparency = 1\n\tcardLbl.Text = SpoofingWindow.Desc()\n\tcardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tcardLbl.Font = Enum.Font.Gotham\n\tcardLbl.TextSize = 11\n\tcardLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tcardLbl.Parent = card\n\n\tbigState = Instance.new(\"TextLabel\")\n\tbigState.Name = \"Big\"\n\tbigState.Size = UDim2.new(1, -80, 0, 28)\n\tbigState.Position = UDim2.fromOffset(10, 26)\n\tbigState.BackgroundTransparency = 1\n\tbigState.Text = L.isEnabled() and \"ON\" or \"OFF\"\n\tbigState.TextColor3 = P.textDim\n\tbigState.Font = Enum.Font.Code\n\tbigState.TextSize = 24\n\tbigState.TextXAlignment = Enum.TextXAlignment.Left\n\tbigState.Parent = card\n\n\ttoggle = makeToggle(card, L.isEnabled(), setEnabled)\n\tlocal tBtn = card:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Size = UDim2.fromOffset(56, 28)\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\n\tlocal y = PAD + 64 + 8\n\tflagRow(content, y, Str(\"spoofSpeed\", \"Обход проверки скорости\"), \"speed\", L, P, saveState)\n\ty = y + 40\n\tflagRow(content, y, Str(\"spoofJump\", \"Обход проверки прыжка\"), \"jump\", L, P, saveState)\n\ty = y + 40\n\tflagRow(content, y, Str(\"spoofTp\", \"Обход проверки телепорта\"), \"tp\", L, P, saveState)\n\ty = y + 44\n\n\tstateLabel = Instance.new(\"TextLabel\")\n\tstateLabel.Name = \"State\"\n\tstateLabel.Position = UDim2.fromOffset(0, y)\n\tstateLabel.Size = UDim2.new(1, 0, 0, 14)\n\tstateLabel.BackgroundTransparency = 1\n\tstateLabel.Text = \"OFF\"\n\tstateLabel.TextColor3 = P.textDim\n\tstateLabel.Font = Enum.Font.Code\n\tstateLabel.TextSize = 10\n\tstateLabel.TextXAlignment = Enum.TextXAlignment.Left\n\tstateLabel.Parent = content\n\ty = y + 14 + PAD\n\n\tbase:setSize(280, 28 + y)\n\trefreshStatus()\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.SpoofingWindow = SpoofingWindow\nreturn SpoofingWindow\n",
	PlayersWindow = "local env = getgenv and getgenv() or _G\nif env.PlayersWindow then return env.PlayersWindow end\n\nlocal PlayersWindow = {}\nPlayersWindow.GetTable = \"Server\"\nPlayersWindow.GetPosition = 2\nPlayersWindow.QuickToggle = true\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction PlayersWindow.Name()\n\treturn Str(\"playersName\", \"Players\")\nend\n\nfunction PlayersWindow.Desc()\n\treturn Str(\"playersDesc\", \"Обводка, дистанция, HP\")\nend\n\nfunction PlayersWindow.IsOn()\n\tlocal L = env.PlayersLogic\n\treturn L ~= nil and L.isEnabled() == true\nend\n\nfunction PlayersWindow.SetOn(state)\n\tlocal L = env.PlayersLogic\n\tassert(L, \"PlayersLogic не загружен\")\n\tif state then\n\t\tL.enable()\n\telse\n\t\tL.disable()\n\tend\n\tlocal GC = env.GlobalControler\n\tif GC and GC.SaveModuleState then\n\t\tGC:SaveModuleState(\"PlayersWindow\", {\n\t\t\tenabled = state == true,\n\t\t\tshowDistance = L.getShowDistance(),\n\t\t\tshowHp = L.getShowHp(),\n\t\t})\n\tend\n\treturn PlayersWindow.IsOn()\nend\n\nfunction PlayersWindow.Restore(config)\n\tconfig = config or {}\n\tlocal L = env.PlayersLogic\n\tif not L then\n\t\treturn\n\tend\n\tif config.showDistance ~= nil then\n\t\tL.setShowDistance(config.showDistance)\n\tend\n\tif config.showHp ~= nil then\n\t\tL.setShowHp(config.showHp)\n\tend\n\tif config.enabled then\n\t\tL.enable()\n\tend\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal function makeToggle(parent, on, onToggle)\n\tlocal P = currentPalette() or {}\n\tlocal h = 28\n\tlocal w = 56\n\n\tlocal btn = Instance.new(\"TextButton\")\n\tbtn.Name = \"Toggle\"\n\tbtn.Size = UDim2.fromOffset(w, h)\n\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\tbtn.BorderSizePixel = 0\n\tbtn.AutoButtonColor = true\n\tbtn.Text = \"\"\n\tbtn.Parent = parent\n\tcorner(btn, 99)\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -12, 1, 0)\n\tlabel.Position = UDim2.fromOffset(8, 0)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = on and \"ON\" or \"OFF\"\n\tlabel.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 11\n\tlabel.ZIndex = 2\n\tlabel.Parent = btn\n\n\tlocal knob = Instance.new(\"Frame\")\n\tknob.Name = \"Knob\"\n\tknob.Size = UDim2.fromOffset(h - 8, h - 8)\n\tknob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\tknob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tknob.BorderSizePixel = 0\n\tknob.ZIndex = 3\n\tknob.Parent = btn\n\tcorner(knob, 99)\n\n\tlocal state = on\n\tlocal function paint()\n\t\tbtn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\t\tlabel.Text = state and \"ON\" or \"OFF\"\n\t\tlabel.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tknob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\t\tknob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tend\n\n\tbtn.MouseButton1Click:Connect(function()\n\t\tstate = not state\n\t\tpaint()\n\t\tif onToggle then\n\t\t\tonToggle(state)\n\t\tend\n\tend)\n\n\treturn {\n\t\tget = function() return state end,\n\t\tset = function(v)\n\t\t\tstate = v\n\t\t\tpaint()\n\t\tend,\n\t}\nend\n\nlocal function optRow(parent, y, titleText, getter, setter, P, onSaved)\n\tlocal row = Instance.new(\"Frame\")\n\trow.Name = \"OptRow\"\n\trow.Size = UDim2.new(1, 0, 0, 36)\n\trow.Position = UDim2.fromOffset(0, y)\n\trow.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\trow.BorderSizePixel = 0\n\trow.Parent = parent\n\tcorner(row, 4)\n\n\tlocal lbl = Instance.new(\"TextLabel\")\n\tlbl.Size = UDim2.new(1, -70, 1, 0)\n\tlbl.Position = UDim2.fromOffset(10, 0)\n\tlbl.BackgroundTransparency = 1\n\tlbl.Text = titleText\n\tlbl.TextColor3 = P.text or Color3.fromRGB(223, 226, 240)\n\tlbl.Font = Enum.Font.Gotham\n\tlbl.TextSize = 11\n\tlbl.TextXAlignment = Enum.TextXAlignment.Left\n\tlbl.Parent = row\n\n\tlocal t = makeToggle(row, getter(), function(on)\n\t\tsetter(on)\n\t\tif onSaved then\n\t\t\tonSaved()\n\t\tend\n\tend)\n\tlocal tBtn = row:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\treturn t\nend\n\nfunction PlayersWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\tif window._destroyed then\n\t\t\twindow = nil\n\t\telse\n\t\t\twindow:Destroy()\n\t\t\twindow = nil\n\t\t\treturn\n\t\tend\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal L = env.PlayersLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(L, \"PlayersLogic не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal base = WindowBase.new(\"Players\", PlayersWindow.Name(), 280, 200)\n\twindow = base\n\tlocal content = base.Content\n\tlocal PAD = 6\n\n\tlocal stateLabel\n\tlocal toggle\n\tlocal bigState\n\n\tlocal function saveState()\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tGC:SaveModuleState(\"PlayersWindow\", {\n\t\t\t\tenabled = L.isEnabled(),\n\t\t\t\tshowDistance = L.getShowDistance(),\n\t\t\t\tshowHp = L.getShowHp(),\n\t\t\t})\n\t\tend\n\tend\n\n\tlocal function refreshStatus()\n\t\tif stateLabel then\n\t\t\tif L.isEnabled() then\n\t\t\t\tlocal n = 0\n\t\t\t\tlocal Players = game:GetService(\"Players\")\n\t\t\t\tn = #Players:GetPlayers() - 1\n\t\t\t\tstateLabel.Text = (\"ON  ·  %d players\"):format(math.max(0, n))\n\t\t\t\tstateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\t\telse\n\t\t\t\tstateLabel.Text = \"OFF  ·  no esp\"\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\tend\n\t\tif bigState then\n\t\t\tbigState.Text = L.isEnabled() and \"ON\" or \"OFF\"\n\t\t\tbigState.TextColor3 = L.isEnabled() and (P.accent or Color3.fromRGB(0, 242, 254)) or P.textDim\n\t\tend\n\tend\n\n\tlocal function setEnabled(state)\n\t\tif state then\n\t\t\tL.enable()\n\t\telse\n\t\t\tL.disable()\n\t\tend\n\t\tsaveState()\n\t\trefreshStatus()\n\tend\n\n\tlocal card = Instance.new(\"Frame\")\n\tcard.Name = \"StateCard\"\n\tcard.Size = UDim2.new(1, 0, 0, 64)\n\tcard.Position = UDim2.fromOffset(0, PAD)\n\tcard.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tcard.BorderSizePixel = 0\n\tcard.Parent = content\n\tcorner(card, 4)\n\tstroke(card, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal cardLbl = Instance.new(\"TextLabel\")\n\tcardLbl.Size = UDim2.new(1, -80, 0, 12)\n\tcardLbl.Position = UDim2.fromOffset(10, 10)\n\tcardLbl.BackgroundTransparency = 1\n\tcardLbl.Text = PlayersWindow.Desc()\n\tcardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tcardLbl.Font = Enum.Font.Gotham\n\tcardLbl.TextSize = 11\n\tcardLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tcardLbl.Parent = card\n\n\tbigState = Instance.new(\"TextLabel\")\n\tbigState.Name = \"Big\"\n\tbigState.Size = UDim2.new(1, -80, 0, 28)\n\tbigState.Position = UDim2.fromOffset(10, 26)\n\tbigState.BackgroundTransparency = 1\n\tbigState.Text = L.isEnabled() and \"ON\" or \"OFF\"\n\tbigState.TextColor3 = P.textDim\n\tbigState.Font = Enum.Font.Code\n\tbigState.TextSize = 24\n\tbigState.TextXAlignment = Enum.TextXAlignment.Left\n\tbigState.Parent = card\n\n\ttoggle = makeToggle(card, L.isEnabled(), setEnabled)\n\tlocal tBtn = card:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Size = UDim2.fromOffset(56, 28)\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\n\tlocal y = PAD + 64 + 8\n\toptRow(content, y, Str(\"playersDist\", \"Показывать дистанцию\"),\n\t\tL.getShowDistance,\n\t\tfunction(v) L.setShowDistance(v) end,\n\t\tP, saveState)\n\ty = y + 40\n\toptRow(content, y, Str(\"playersHp\", \"Показывать HP\"),\n\t\tL.getShowHp,\n\t\tfunction(v) L.setShowHp(v) end,\n\t\tP, saveState)\n\ty = y + 44\n\n\tstateLabel = Instance.new(\"TextLabel\")\n\tstateLabel.Name = \"State\"\n\tstateLabel.Position = UDim2.fromOffset(0, y)\n\tstateLabel.Size = UDim2.new(1, 0, 0, 14)\n\tstateLabel.BackgroundTransparency = 1\n\tstateLabel.Text = \"OFF\"\n\tstateLabel.TextColor3 = P.textDim\n\tstateLabel.Font = Enum.Font.Code\n\tstateLabel.TextSize = 10\n\tstateLabel.TextXAlignment = Enum.TextXAlignment.Left\n\tstateLabel.Parent = content\n\ty = y + 14 + PAD\n\n\tbase:setSize(280, 28 + y)\n\trefreshStatus()\n\ttask.spawn(function()\n\t\twhile window == base and not base._destroyed do\n\t\t\trefreshStatus()\n\t\t\ttask.wait(1)\n\t\tend\n\tend)\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.PlayersWindow = PlayersWindow\nreturn PlayersWindow\n",
	FastHealWindow = "local env = getgenv and getgenv() or _G\nif env.FastHealWindow then return env.FastHealWindow end\n\nlocal FastHealWindow = {}\nFastHealWindow.GetTable = \"Player\"\nFastHealWindow.GetPosition = 5\nFastHealWindow.QuickToggle = true\n\nlocal function Str(key, fallback)\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(key)\n\tend\n\treturn fallback\nend\n\nfunction FastHealWindow.Name()\n\treturn Str(\"healName\", \"Быстрый хил\")\nend\n\nfunction FastHealWindow.Desc()\n\treturn Str(\"healDesc\", \"Ускоренное восстановление HP\")\nend\n\nfunction FastHealWindow.IsOn()\n\tlocal L = env.FastHealLogic\n\treturn L ~= nil and L.isEnabled() == true\nend\n\nfunction FastHealWindow.SetOn(state)\n\tlocal L = env.FastHealLogic\n\tassert(L, \"FastHealLogic не загружен\")\n\tif state then\n\t\tL.enable()\n\telse\n\t\tL.disable()\n\tend\n\tlocal GC = env.GlobalControler\n\tif GC and GC.SaveModuleState then\n\t\tGC:SaveModuleState(\"FastHealWindow\", {\n\t\t\tenabled = state == true,\n\t\t\tamount = L.getAmount(),\n\t\t})\n\tend\n\treturn FastHealWindow.IsOn()\nend\n\nfunction FastHealWindow.Restore(config)\n\tconfig = config or {}\n\tlocal L = env.FastHealLogic\n\tif not L then\n\t\treturn\n\tend\n\tif config.amount then\n\t\tL.setAmount(config.amount)\n\tend\n\tif config.enabled then\n\t\tL.enable()\n\tend\nend\n\nlocal window = nil\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal function makeToggle(parent, on, onToggle)\n\tlocal P = currentPalette() or {}\n\tlocal h = 28\n\tlocal w = 56\n\n\tlocal btn = Instance.new(\"TextButton\")\n\tbtn.Name = \"Toggle\"\n\tbtn.Size = UDim2.fromOffset(w, h)\n\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\tbtn.BorderSizePixel = 0\n\tbtn.AutoButtonColor = true\n\tbtn.Text = \"\"\n\tbtn.Parent = parent\n\tcorner(btn, 99)\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -12, 1, 0)\n\tlabel.Position = UDim2.fromOffset(8, 0)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = on and \"ON\" or \"OFF\"\n\tlabel.TextColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tlabel.Font = Enum.Font.Code\n\tlabel.TextSize = 11\n\tlabel.ZIndex = 2\n\tlabel.Parent = btn\n\n\tlocal knob = Instance.new(\"Frame\")\n\tknob.Name = \"Knob\"\n\tknob.Size = UDim2.fromOffset(h - 8, h - 8)\n\tknob.Position = on and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\tknob.BackgroundColor3 = on and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tknob.BorderSizePixel = 0\n\tknob.ZIndex = 3\n\tknob.Parent = btn\n\tcorner(knob, 99)\n\n\tlocal state = on\n\tlocal function paint()\n\t\tbtn.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))\n\t\tlabel.Text = state and \"ON\" or \"OFF\"\n\t\tlabel.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tknob.Position = state and UDim2.new(1, -(h - 4), 0, 4) or UDim2.fromOffset(4, 4)\n\t\tknob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\tend\n\n\tbtn.MouseButton1Click:Connect(function()\n\t\tstate = not state\n\t\tpaint()\n\t\tif onToggle then\n\t\t\tonToggle(state)\n\t\tend\n\tend)\n\n\treturn {\n\t\tget = function() return state end,\n\t\tset = function(v)\n\t\t\tstate = v\n\t\t\tpaint()\n\t\tend,\n\t}\nend\n\nlocal function makeSlider(parent, minV, maxV, startV, onChange)\n\tlocal P = currentPalette() or {}\n\tlocal box = Instance.new(\"Frame\")\n\tbox.Name = \"SliderBox\"\n\tbox.Size = UDim2.new(1, 0, 0, 72)\n\tbox.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tbox.BorderSizePixel = 0\n\tbox.Parent = parent\n\tcorner(box, 4)\n\tstroke(box, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal label = Instance.new(\"TextLabel\")\n\tlabel.Name = \"Label\"\n\tlabel.Size = UDim2.new(1, -70, 0, 14)\n\tlabel.Position = UDim2.fromOffset(10, 8)\n\tlabel.BackgroundTransparency = 1\n\tlabel.Text = Str(\"healRate\", \"HP за тик\")\n\tlabel.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tlabel.Font = Enum.Font.Gotham\n\tlabel.TextSize = 11\n\tlabel.TextXAlignment = Enum.TextXAlignment.Left\n\tlabel.Parent = box\n\n\tlocal readout = Instance.new(\"TextLabel\")\n\treadout.Name = \"Readout\"\n\treadout.Size = UDim2.new(0, 56, 0, 20)\n\treadout.Position = UDim2.new(1, -66, 0, 6)\n\treadout.BackgroundTransparency = 1\n\treadout.Text = tostring(math.floor(startV + 0.5))\n\treadout.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\treadout.Font = Enum.Font.Code\n\treadout.TextSize = 16\n\treadout.TextXAlignment = Enum.TextXAlignment.Right\n\treadout.Parent = box\n\n\tlocal track = Instance.new(\"Frame\")\n\ttrack.Name = \"Track\"\n\ttrack.Size = UDim2.new(1, -20, 0, 6)\n\ttrack.Position = UDim2.fromOffset(10, 34)\n\ttrack.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\ttrack.BorderSizePixel = 0\n\ttrack.Active = true\n\ttrack.Parent = box\n\tcorner(track, 99)\n\n\tlocal fill = Instance.new(\"Frame\")\n\tfill.Name = \"Fill\"\n\tfill.Size = UDim2.new(0, 0, 1, 0)\n\tfill.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tfill.BorderSizePixel = 0\n\tfill.Parent = track\n\tcorner(fill, 99)\n\n\tlocal thumb = Instance.new(\"Frame\")\n\tthumb.Name = \"Thumb\"\n\tthumb.Size = UDim2.fromOffset(18, 18)\n\tthumb.Position = UDim2.new(0, -9, 0.5, -9)\n\tthumb.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tthumb.BorderSizePixel = 0\n\tthumb.ZIndex = 3\n\tthumb.Parent = track\n\tcorner(thumb, 99)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 2\n\t\ts.Color = P.bg or Color3.fromRGB(15, 19, 29)\n\t\ts.Parent = thumb\n\tend)\n\n\tlocal mins = Instance.new(\"TextLabel\")\n\tmins.Size = UDim2.new(0, 36, 0, 12)\n\tmins.Position = UDim2.fromOffset(10, 48)\n\tmins.BackgroundTransparency = 1\n\tmins.Text = tostring(minV)\n\tmins.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tmins.Font = Enum.Font.Code\n\tmins.TextSize = 9\n\tmins.TextXAlignment = Enum.TextXAlignment.Left\n\tmins.Parent = box\n\n\tlocal maxs = Instance.new(\"TextLabel\")\n\tmaxs.Size = UDim2.new(0, 36, 0, 12)\n\tmaxs.Position = UDim2.new(1, -46, 0, 48)\n\tmaxs.BackgroundTransparency = 1\n\tmaxs.Text = tostring(maxV)\n\tmaxs.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tmaxs.Font = Enum.Font.Code\n\tmaxs.TextSize = 9\n\tmaxs.TextXAlignment = Enum.TextXAlignment.Right\n\tmaxs.Parent = box\n\n\tlocal value = startV\n\tlocal dragging = false\n\n\tlocal function applyVisual()\n\t\tlocal range = maxV - minV\n\t\tlocal frac = 0\n\t\tif range > 0 then\n\t\t\tfrac = (value - minV) / range\n\t\tend\n\t\tfrac = math.clamp(frac, 0, 1)\n\t\tfill.Size = UDim2.new(frac, 0, 1, 0)\n\t\tthumb.Position = UDim2.new(frac, -9, 0.5, -9)\n\t\treadout.Text = tostring(math.floor(value + 0.5))\n\tend\n\n\tlocal function fromInput(input)\n\t\tlocal abs = track.AbsolutePosition.X\n\t\tlocal sizeX = track.AbsoluteSize.X\n\t\tif sizeX <= 0 then\n\t\t\treturn\n\t\tend\n\t\tlocal frac = (input.Position.X - abs) / sizeX\n\t\tfrac = math.clamp(frac, 0, 1)\n\t\tvalue = minV + frac * (maxV - minV)\n\t\tapplyVisual()\n\t\tif onChange then\n\t\t\tonChange(value)\n\t\tend\n\tend\n\n\ttrack.InputBegan:Connect(function(input)\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tdragging = true\n\t\tfromInput(input)\n\tend)\n\n\tlocal UIS = game:GetService(\"UserInputService\")\n\tUIS.InputChanged:Connect(function(input)\n\t\tif not dragging then\n\t\t\treturn\n\t\tend\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseMovement\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tfromInput(input)\n\tend)\n\n\tlocal function endDrag(input)\n\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\treturn\n\t\tend\n\t\tdragging = false\n\tend\n\tUIS.InputEnded:Connect(endDrag)\n\ttrack.InputEnded:Connect(endDrag)\n\n\ttask.defer(applyVisual)\n\n\treturn {\n\t\tget = function()\n\t\t\treturn value\n\t\tend,\n\t\tset = function(v)\n\t\t\tvalue = math.clamp(v, minV, maxV)\n\t\t\tapplyVisual()\n\t\tend,\n\t}\nend\n\nfunction FastHealWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\tif window._destroyed then\n\t\t\twindow = nil\n\t\telse\n\t\t\twindow:Destroy()\n\t\t\twindow = nil\n\t\t\treturn\n\t\tend\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tlocal L = env.FastHealLogic\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tassert(L, \"FastHealLogic не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal base = WindowBase.new(\"FastHeal\", FastHealWindow.Name(), 300, 220)\n\twindow = base\n\tlocal content = base.Content\n\tlocal PAD = 6\n\n\tlocal stateLabel\n\tlocal toggle\n\tlocal bigState\n\n\tlocal function saveState()\n\t\tlocal GC = env.GlobalControler\n\t\tif GC and GC.SaveModuleState then\n\t\t\tGC:SaveModuleState(\"FastHealWindow\", {\n\t\t\t\tenabled = L.isEnabled(),\n\t\t\t\tamount = L.getAmount(),\n\t\t\t})\n\t\tend\n\tend\n\n\tlocal function refreshStatus()\n\t\tif stateLabel then\n\t\t\tif not L.canRun() then\n\t\t\t\tstateLabel.Text = Str(\"noChar\", \"Нет персонажа\")\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\t\treturn\n\t\t\tend\n\t\t\tlocal h = L.getHumanoid()\n\t\t\tif L.isEnabled() then\n\t\t\t\tstateLabel.Text = (\"ON  ·  HP %.0f/%.0f  ·  +%d/тик\"):format(\n\t\t\t\t\th and h.Health or 0,\n\t\t\t\t\th and h.MaxHealth or 0,\n\t\t\t\t\tL.getAmount()\n\t\t\t\t)\n\t\t\t\tstateLabel.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\t\telse\n\t\t\t\tstateLabel.Text = (\"OFF  ·  HP %.0f/%.0f\"):format(\n\t\t\t\t\th and h.Health or 0,\n\t\t\t\t\th and h.MaxHealth or 0\n\t\t\t\t)\n\t\t\t\tstateLabel.TextColor3 = P.textDim\n\t\t\tend\n\t\tend\n\t\tif bigState then\n\t\t\tbigState.Text = L.isEnabled() and \"ON\" or \"OFF\"\n\t\t\tbigState.TextColor3 = L.isEnabled() and (P.accent or Color3.fromRGB(0, 242, 254)) or P.textDim\n\t\tend\n\tend\n\n\tlocal function setEnabled(state)\n\t\tif state then\n\t\t\tL.enable()\n\t\telse\n\t\t\tL.disable()\n\t\tend\n\t\tsaveState()\n\t\trefreshStatus()\n\tend\n\n\tlocal card = Instance.new(\"Frame\")\n\tcard.Name = \"StateCard\"\n\tcard.Size = UDim2.new(1, 0, 0, 64)\n\tcard.Position = UDim2.fromOffset(0, PAD)\n\tcard.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tcard.BorderSizePixel = 0\n\tcard.Parent = content\n\tcorner(card, 4)\n\tstroke(card, P.line or Color3.fromRGB(58, 73, 75))\n\n\tlocal cardLbl = Instance.new(\"TextLabel\")\n\tcardLbl.Size = UDim2.new(1, -80, 0, 12)\n\tcardLbl.Position = UDim2.fromOffset(10, 10)\n\tcardLbl.BackgroundTransparency = 1\n\tcardLbl.Text = FastHealWindow.Desc()\n\tcardLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tcardLbl.Font = Enum.Font.Gotham\n\tcardLbl.TextSize = 11\n\tcardLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tcardLbl.Parent = card\n\n\tbigState = Instance.new(\"TextLabel\")\n\tbigState.Name = \"Big\"\n\tbigState.Size = UDim2.new(1, -80, 0, 28)\n\tbigState.Position = UDim2.fromOffset(10, 26)\n\tbigState.BackgroundTransparency = 1\n\tbigState.Text = L.isEnabled() and \"ON\" or \"OFF\"\n\tbigState.TextColor3 = P.textDim\n\tbigState.Font = Enum.Font.Code\n\tbigState.TextSize = 24\n\tbigState.TextXAlignment = Enum.TextXAlignment.Left\n\tbigState.Parent = card\n\n\ttoggle = makeToggle(card, L.isEnabled(), setEnabled)\n\tlocal tBtn = card:FindFirstChild(\"Toggle\")\n\tif tBtn then\n\t\ttBtn.Size = UDim2.fromOffset(56, 28)\n\t\ttBtn.Position = UDim2.new(1, -66, 0.5, -14)\n\tend\n\n\tlocal sliderY = PAD + 64 + 8\n\tmakeSlider(content, 1, 50, L.getAmount(), function(v)\n\t\tL.setAmount(math.floor(v + 0.5))\n\t\tsaveState()\n\t\trefreshStatus()\n\tend)\n\tcontent:FindFirstChild(\"SliderBox\").Position = UDim2.fromOffset(0, sliderY)\n\n\tstateLabel = Instance.new(\"TextLabel\")\n\tstateLabel.Name = \"State\"\n\tstateLabel.Position = UDim2.fromOffset(0, sliderY + 72 + 8)\n\tstateLabel.Size = UDim2.new(1, 0, 0, 14)\n\tstateLabel.BackgroundTransparency = 1\n\tstateLabel.Text = \"OFF\"\n\tstateLabel.TextColor3 = P.textDim\n\tstateLabel.Font = Enum.Font.Code\n\tstateLabel.TextSize = 10\n\tstateLabel.TextXAlignment = Enum.TextXAlignment.Left\n\tstateLabel.Parent = content\n\n\tbase:setSize(300, 28 + PAD + 64 + 8 + 72 + 8 + 14 + PAD)\n\trefreshStatus()\n\ttask.spawn(function()\n\t\twhile window == base and not base._destroyed do\n\t\t\trefreshStatus()\n\t\t\ttask.wait(0.5)\n\t\tend\n\tend)\n\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.FastHealWindow = FastHealWindow\nreturn FastHealWindow\n",
	SettingsWindow = "local env = getgenv and getgenv() or _G\nif env.SettingsWindow then return env.SettingsWindow end\n\nlocal SettingsWindow = {}\nSettingsWindow.GetTable = \"Settings\"\nSettingsWindow.GetPosition = 1\n\nfunction SettingsWindow.Name()\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(\"settingsName\")\n\tend\n\treturn \"Интерфейс\"\nend\n\nfunction SettingsWindow.Desc()\n\tlocal GC = env.GlobalControler\n\tif GC and GC.Str then\n\t\treturn GC:Str(\"settingsDesc\")\n\tend\n\treturn \"Язык, тема, цвет, прозрачность\"\nend\n\nlocal window = nil\n\nlocal ACCENTS = {\n\t{ r = 0, g = 242, b = 254 },\n\t{ r = 14, g = 165, b = 233 },\n\t{ r = 52, g = 211, b = 153 },\n\t{ r = 250, g = 204, b = 21 },\n\t{ r = 251, g = 146, b = 60 },\n\t{ r = 244, g = 63, b = 94 },\n\t{ r = 167, g = 139, b = 250 },\n\t{ r = 255, g = 255, b = 255 },\n}\n\nlocal function currentPalette()\n\tlocal GC = env.GlobalControler\n\tif GC and type(GC.ModuleTheme) == \"table\" then\n\t\treturn GC.ModuleTheme\n\tend\n\tlocal WindowBase = env.WindowBase\n\treturn WindowBase and WindowBase.Palette or nil\nend\n\nlocal function corner(frame, r)\n\tInstance.new(\"UICorner\", frame).CornerRadius = UDim.new(0, r or 4)\nend\n\nlocal function stroke(frame, color)\n\tpcall(function()\n\t\tlocal s = Instance.new(\"UIStroke\")\n\t\ts.Thickness = 1\n\t\ts.Color = color\n\t\ts.Parent = frame\n\tend)\nend\n\nlocal function label(parent, text, y, P)\n\tlocal lbl = Instance.new(\"TextLabel\")\n\tlbl.Size = UDim2.new(1, 0, 0, 14)\n\tlbl.Position = UDim2.fromOffset(0, y)\n\tlbl.BackgroundTransparency = 1\n\tlbl.Text = text\n\tlbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tlbl.Font = Enum.Font.Gotham\n\tlbl.TextSize = 11\n\tlbl.TextXAlignment = Enum.TextXAlignment.Left\n\tlbl.Parent = parent\n\treturn lbl\nend\n\nlocal function section(parent, titleText, y, h, P)\n\tlocal box = Instance.new(\"Frame\")\n\tbox.Name = \"Section\"\n\tbox.Size = UDim2.new(1, 0, 0, h)\n\tbox.Position = UDim2.fromOffset(0, y)\n\tbox.BackgroundColor3 = P.panel or Color3.fromRGB(23, 28, 37)\n\tbox.BorderSizePixel = 0\n\tbox.Parent = parent\n\tcorner(box, 4)\n\tstroke(box, P.line or Color3.fromRGB(58, 73, 75))\n\tlabel(box, titleText, 8, P)\n\treturn box\nend\n\nlocal function makeSegments(parent, options, selectedKey, onSelect, P)\n\tlocal row = Instance.new(\"Frame\")\n\trow.Size = UDim2.new(1, -20, 0, 28)\n\trow.Position = UDim2.fromOffset(10, 28)\n\trow.BackgroundTransparency = 1\n\trow.Parent = parent\n\tpcall(function()\n\t\tlocal g = Instance.new(\"UIGridLayout\")\n\t\tg.CellSize = UDim2.new(1 / #options, -6, 1, 0)\n\t\tg.CellPadding = UDim2.fromOffset(6, 0)\n\t\tg.SortOrder = Enum.SortOrder.LayoutOrder\n\t\tg.Parent = row\n\tend)\n\n\tlocal buttons = {}\n\tfor i, opt in ipairs(options) do\n\t\tlocal btn = Instance.new(\"TextButton\")\n\t\tbtn.Name = opt.key\n\t\tbtn.Size = UDim2.new(1 / #options, -6, 0, 28)\n\t\tbtn.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\t\tbtn.BorderSizePixel = 0\n\t\tbtn.AutoButtonColor = true\n\t\tbtn.Text = opt.label\n\t\tbtn.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\t\tbtn.Font = Enum.Font.GothamSemibold\n\t\tbtn.TextSize = 11\n\t\tbtn.LayoutOrder = i\n\t\tbtn.Parent = row\n\t\tcorner(btn, 4)\n\n\t\tlocal function paint()\n\t\t\tlocal on = opt.key == selectedKey\n\t\t\tbtn.BackgroundColor3 = on and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.panelAlt or Color3.fromRGB(27, 32, 41))\n\t\t\tbtn.TextColor3 = on and (P.accentOn or Color3.fromRGB(15, 19, 29)) or (P.textDim or Color3.fromRGB(185, 202, 203))\n\t\tend\n\t\tpaint()\n\t\tbtn.MouseButton1Click:Connect(function()\n\t\t\tselectedKey = opt.key\n\t\t\tfor _, b in ipairs(buttons) do\n\t\t\t\tb.paint()\n\t\t\tend\n\t\t\tonSelect(opt.key)\n\t\tend)\n\t\tbuttons[#buttons + 1] = { paint = paint }\n\tend\n\treturn row\nend\n\nlocal function makeSwatches(parent, current, onPick, onReset, P)\n\tlocal row = Instance.new(\"Frame\")\n\trow.Size = UDim2.new(1, -20, 0, 36)\n\trow.Position = UDim2.fromOffset(10, 28)\n\trow.BackgroundTransparency = 1\n\trow.Parent = parent\n\tlocal layout = Instance.new(\"UIListLayout\")\n\tlayout.FillDirection = Enum.FillDirection.Horizontal\n\tlayout.Padding = UDim.new(0, 6)\n\tlayout.SortOrder = Enum.SortOrder.LayoutOrder\n\tlayout.Parent = row\n\n\tlocal function isCur(c)\n\t\tif not current then\n\t\t\treturn c.r == 0 and c.g == 242 and c.b == 254\n\t\tend\n\t\treturn tonumber(current.r) == c.r\n\t\t\tand tonumber(current.g) == c.g\n\t\t\tand tonumber(current.b) == c.b\n\tend\n\n\tlocal swatches = {}\n\tfor i, c in ipairs(ACCENTS) do\n\t\tlocal btn = Instance.new(\"TextButton\")\n\t\tbtn.Size = UDim2.fromOffset(28, 28)\n\t\tbtn.BackgroundColor3 = Color3.fromRGB(c.r, c.g, c.b)\n\t\tbtn.BorderSizePixel = 0\n\t\tbtn.AutoButtonColor = true\n\t\tbtn.Text = \"\"\n\t\tbtn.LayoutOrder = i\n\t\tbtn.Parent = row\n\t\tcorner(btn, 4)\n\t\tlocal ring = Instance.new(\"UIStroke\")\n\t\tring.Thickness = 2\n\t\tring.Color = isCur(c) and (P.text or Color3.new(1, 1, 1)) or (P.line or Color3.fromRGB(58, 73, 75))\n\t\tring.Parent = btn\n\n\t\tbtn.MouseButton1Click:Connect(function()\n\t\t\tcurrent = { r = c.r, g = c.g, b = c.b }\n\t\t\tfor _, s in ipairs(swatches) do\n\t\t\t\ts.ring.Color = s.isCur() and (P.text or Color3.new(1, 1, 1)) or (P.line or Color3.fromRGB(58, 73, 75))\n\t\t\tend\n\t\t\tonPick(c.r, c.g, c.b)\n\t\tend)\n\t\tswatches[#swatches + 1] = {\n\t\t\tring = ring,\n\t\t\tisCur = function()\n\t\t\t\treturn isCur(c)\n\t\t\tend,\n\t\t}\n\tend\n\n\tlocal reset = Instance.new(\"TextButton\")\n\treset.Size = UDim2.fromOffset(64, 28)\n\treset.BackgroundColor3 = P.btn or Color3.fromRGB(38, 42, 52)\n\treset.BorderSizePixel = 0\n\treset.AutoButtonColor = true\n\treset.Text = \"↺\"\n\treset.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\treset.Font = Enum.Font.GothamBold\n\treset.TextSize = 14\n\treset.LayoutOrder = #ACCENTS + 1\n\treset.Parent = row\n\tcorner(reset, 4)\n\treset.MouseButton1Click:Connect(function()\n\t\tcurrent = { r = 0, g = 242, b = 254 }\n\t\tfor _, s in ipairs(swatches) do\n\t\t\ts.ring.Color = s.isCur() and (P.text or Color3.new(1, 1, 1)) or (P.line or Color3.fromRGB(58, 73, 75))\n\t\tend\n\t\tonReset()\n\tend)\n\treturn row\nend\n\n\tlocal function makeAlpha(parent, startV, onInput, P)\n\t\tlocal box = Instance.new(\"Frame\")\n\t\tbox.Size = UDim2.new(1, -20, 0, 64)\n\t\tbox.Position = UDim2.fromOffset(10, 28)\n\t\tbox.BackgroundTransparency = 1\n\t\tbox.Parent = parent\n\n\t\tlocal readout = Instance.new(\"TextLabel\")\n\t\treadout.Size = UDim2.new(0, 48, 0, 16)\n\t\treadout.Position = UDim2.new(1, -48, 0, 0)\n\t\treadout.BackgroundTransparency = 1\n\t\treadout.Text = tostring(math.floor(startV * 100 + 0.5)) .. \"%\"\n\t\treadout.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\treadout.Font = Enum.Font.Code\n\t\treadout.TextSize = 14\n\t\treadout.TextXAlignment = Enum.TextXAlignment.Right\n\t\treadout.Parent = box\n\n\t\tlocal hint = Instance.new(\"TextLabel\")\n\t\thint.Size = UDim2.new(1, -56, 0, 14)\n\t\thint.Position = UDim2.fromOffset(0, 0)\n\t\thint.BackgroundTransparency = 1\n\t\thint.Text = \"0% = opaque · 85% = clear\"\n\t\thint.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\t\thint.Font = Enum.Font.Gotham\n\t\thint.TextSize = 10\n\t\thint.TextXAlignment = Enum.TextXAlignment.Left\n\t\thint.Parent = box\n\n\t\tlocal hit = Instance.new(\"TextButton\")\n\t\thit.Name = \"AlphaHit\"\n\t\thit.Size = UDim2.new(1, 0, 0, 40)\n\t\thit.Position = UDim2.fromOffset(0, 20)\n\t\thit.BackgroundTransparency = 1\n\t\thit.Text = \"\"\n\t\thit.AutoButtonColor = false\n\t\thit.Parent = box\n\n\t\tlocal track = Instance.new(\"Frame\")\n\t\ttrack.Size = UDim2.new(1, 0, 0, 8)\n\t\ttrack.Position = UDim2.fromOffset(0, 36)\n\t\ttrack.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\t\ttrack.BorderSizePixel = 0\n\t\ttrack.Active = false\n\t\ttrack.Parent = box\n\t\tcorner(track, 99)\n\n\t\tlocal fill = Instance.new(\"Frame\")\n\t\tfill.Name = \"Fill\"\n\t\tfill.Size = UDim2.new(math.clamp(startV / 0.85, 0, 1), 0, 1, 0)\n\t\tfill.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\tfill.BorderSizePixel = 0\n\t\tfill.Parent = track\n\t\tcorner(fill, 99)\n\n\t\tlocal thumb = Instance.new(\"Frame\")\n\t\tthumb.Size = UDim2.fromOffset(18, 18)\n\t\tthumb.Position = UDim2.new(math.clamp(startV / 0.85, 0, 1), -9, 0.5, -9)\n\t\tthumb.BackgroundColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\t\tthumb.BorderSizePixel = 0\n\t\tthumb.ZIndex = 3\n\t\tthumb.Parent = track\n\t\tcorner(thumb, 99)\n\t\tpcall(function()\n\t\t\tlocal s = Instance.new(\"UIStroke\")\n\t\t\ts.Thickness = 2\n\t\t\ts.Color = P.bg or Color3.fromRGB(15, 19, 29)\n\t\t\ts.Parent = thumb\n\t\tend)\n\n\t\tlocal value = math.clamp(startV or 0, 0, 0.85)\n\t\tlocal dragging = false\n\t\tlocal UIS = game:GetService(\"UserInputService\")\n\n\t\tlocal function paint()\n\t\t\tlocal frac = math.clamp(value / 0.85, 0, 1)\n\t\t\tfill.Size = UDim2.new(frac, 0, 1, 0)\n\t\t\tthumb.Position = UDim2.new(frac, -9, 0.5, -9)\n\t\t\treadout.Text = tostring(math.floor(value * 100 + 0.5)) .. \"%\"\n\t\tend\n\n\t\tlocal function fromInput(input)\n\t\t\tlocal abs = track.AbsolutePosition.X\n\t\t\tlocal sizeX = track.AbsoluteSize.X\n\t\t\tif sizeX <= 0 then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tlocal frac = (input.Position.X - abs) / sizeX\n\t\t\tfrac = math.clamp(frac, 0, 1)\n\t\t\tvalue = frac * 0.85\n\t\t\tpaint()\n\t\t\tonInput(value)\n\t\tend\n\n\t\thit.InputBegan:Connect(function(input)\n\t\t\tif input.UserInputType ~= Enum.UserInputType.MouseButton1\n\t\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tdragging = true\n\t\t\tfromInput(input)\n\t\tend)\n\n\t\tUIS.InputChanged:Connect(function(input)\n\t\t\tif not dragging then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tif input.UserInputType ~= Enum.UserInputType.MouseMovement\n\t\t\t\tand input.UserInputType ~= Enum.UserInputType.Touch then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tfromInput(input)\n\t\tend)\n\n\t\tUIS.InputEnded:Connect(function(input)\n\t\t\tif input.UserInputType == Enum.UserInputType.MouseButton1\n\t\t\t\tor input.UserInputType == Enum.UserInputType.Touch then\n\t\t\t\tif dragging then\n\t\t\t\t\tdragging = false\n\t\t\t\tend\n\t\t\tend\n\t\tend)\n\n\t\tpaint()\n\t\treturn box\n\tend\n\nfunction SettingsWindow.Open(config)\n\tconfig = config or {}\n\tif window then\n\t\tif window._destroyed then\n\t\t\twindow = nil\n\t\telse\n\t\t\twindow:Destroy()\n\t\t\twindow = nil\n\t\t\treturn\n\t\tend\n\tend\n\n\tlocal WindowBase = env.WindowBase\n\tassert(WindowBase, \"WindowBase не загружен\")\n\tlocal GC = env.GlobalControler\n\tassert(GC, \"GlobalControler не загружен\")\n\n\tlocal P = currentPalette() or WindowBase.Palette\n\tlocal PAD = 6\n\tlocal SAVE_H = 88\n\tlocal LANG_H = 72\n\tlocal THEME_H = 72\n\tlocal COLOR_H = 72\n\tlocal ALPHA_H = 96\n\n\tlocal base = WindowBase.new(\"Settings\", GC:Str(\"settingsName\"), 300, 380)\n\twindow = base\n\tlocal content = base.Content\n\n\tlocal scroll = Instance.new(\"ScrollingFrame\")\n\tscroll.Name = \"Scroll\"\n\tscroll.Size = UDim2.fromScale(1, 1)\n\tscroll.BackgroundTransparency = 1\n\tscroll.BorderSizePixel = 0\n\tscroll.ScrollBarThickness = 3\n\tscroll.ScrollBarImageColor3 = P.line or Color3.fromRGB(58, 73, 75)\n\tscroll.ScrollingDirection = Enum.ScrollingDirection.Y\n\tscroll.CanvasSize = UDim2.fromOffset(0, 0)\n\tscroll.AutomaticCanvasSize = Enum.AutomaticSize.Y\n\tscroll.Parent = content\n\n\tlocal placeId, placeName = GC:GetPlaceInfo()\n\tlocal statusText = \"\"\n\n\tlocal ySave = PAD\n\tlocal yLang = ySave + SAVE_H + 6\n\tlocal yTheme = yLang + LANG_H + 6\n\tlocal yColor = yTheme + THEME_H + 6\n\tlocal yAlpha = yColor + COLOR_H + 6\n\n\tlocal secSave = section(scroll, GC:Str(\"settingsSaves\"), ySave, SAVE_H, P)\n\n\tlocal statusLbl\n\tlocal function setStatus(msg)\n\t\tstatusText = msg or \"\"\n\t\tif statusLbl then\n\t\t\tstatusLbl.Text = statusText\n\t\tend\n\tend\n\n\tstatusLbl = Instance.new(\"TextLabel\")\n\tstatusLbl.Name = \"SaveStatus\"\n\tstatusLbl.Size = UDim2.new(1, -20, 0, 14)\n\tstatusLbl.Position = UDim2.fromOffset(10, 66)\n\tstatusLbl.BackgroundTransparency = 1\n\tstatusLbl.Text = placeName\n\tstatusLbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)\n\tstatusLbl.Font = Enum.Font.Gotham\n\tstatusLbl.TextSize = 10\n\tstatusLbl.TextXAlignment = Enum.TextXAlignment.Left\n\tstatusLbl.TextTruncate = Enum.TextTruncate.AtEnd\n\tstatusLbl.ZIndex = 5\n\tstatusLbl.Parent = secSave\n\n\tlocal function makeBtn(parent, x, w, labelKey, onClick)\n\t\tlocal btn = Instance.new(\"TextButton\")\n\t\tbtn.Name = labelKey\n\t\tbtn.Size = UDim2.fromOffset(w, 28)\n\t\tbtn.Position = UDim2.fromOffset(x, 28)\n\t\tbtn.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\t\tbtn.BorderSizePixel = 0\n\t\tbtn.AutoButtonColor = true\n\t\tbtn.Text = GC:Str(labelKey)\n\t\tbtn.TextColor3 = P.text or Color3.fromRGB(223, 226, 240)\n\t\tbtn.Font = Enum.Font.GothamSemibold\n\t\tbtn.TextSize = 11\n\t\tbtn.TextTruncate = Enum.TextTruncate.AtEnd\n\t\tbtn.Parent = parent\n\t\tbtn.ZIndex = 4\n\t\tInstance.new(\"UICorner\", btn).CornerRadius = UDim.new(0, 4)\n\t\tpcall(function()\n\t\t\tlocal s = Instance.new(\"UIStroke\")\n\t\t\ts.Thickness = 1\n\t\t\ts.Color = P.line or Color3.fromRGB(58, 73, 75)\n\t\t\ts.Parent = btn\n\t\tend)\n\t\tbtn.MouseButton1Click:Connect(onClick)\n\t\treturn btn\n\tend\n\n\tlocal pickFrame = Instance.new(\"Frame\")\n\tpickFrame.Name = \"PickList\"\n\tpickFrame.Size = UDim2.new(1, -20, 0, 0)\n\tpickFrame.Position = UDim2.fromOffset(10, 88)\n\tpickFrame.BackgroundTransparency = 1\n\tpickFrame.Visible = false\n\tpickFrame.Parent = secSave\n\tlocal pickLayout = Instance.new(\"UIListLayout\")\n\tpickLayout.Padding = UDim.new(0, 4)\n\tpickLayout.SortOrder = Enum.SortOrder.LayoutOrder\n\tpickLayout.Parent = pickFrame\n\n\tlocal function openPicker()\n\t\tfor _, c in ipairs(pickFrame:GetChildren()) do\n\t\t\tif c:IsA(\"TextButton\") then\n\t\t\t\tc:Destroy()\n\t\t\tend\n\t\tend\n\t\tlocal list = GC:ListProfiles()\n\t\tif #list == 0 then\n\t\t\tpickFrame.Visible = false\n\t\t\tsecSave.Size = UDim2.new(1, 0, 0, SAVE_H)\n\t\t\tsetStatus(GC:Str(\"settingsNoSaves\"))\n\t\t\treturn\n\t\tend\n\t\tpickFrame.Visible = true\n\t\tfor i, item in ipairs(list) do\n\t\t\tlocal row = Instance.new(\"TextButton\")\n\t\t\trow.Size = UDim2.new(1, 0, 0, 26)\n\t\t\trow.BackgroundColor3 = P.panelAlt or Color3.fromRGB(27, 32, 41)\n\t\t\trow.BorderSizePixel = 0\n\t\t\trow.AutoButtonColor = true\n\t\t\trow.Text = \"  \" .. tostring(item.placeName)\n\t\t\trow.TextColor3 = P.text\n\t\t\trow.Font = Enum.Font.Gotham\n\t\t\trow.TextSize = 11\n\t\t\trow.TextXAlignment = Enum.TextXAlignment.Left\n\t\t\trow.LayoutOrder = i\n\t\t\trow.Parent = pickFrame\n\t\t\tInstance.new(\"UICorner\", row).CornerRadius = UDim.new(0, 4)\n\t\t\trow.MouseButton1Click:Connect(function()\n\t\t\t\tlocal ok, name = GC:LoadProfilePath(item.path)\n\t\t\t\tpickFrame.Visible = false\n\t\t\t\tsecSave.Size = UDim2.new(1, 0, 0, SAVE_H)\n\t\t\t\tif ok then\n\t\t\t\t\tsetStatus(GC:Str(\"settingsLoaded\") .. \" · \" .. tostring(name or item.placeName))\n\t\t\t\telse\n\t\t\t\t\tsetStatus(\"error load\")\n\t\t\t\tend\n\t\t\tend)\n\t\tend\n\t\tlocal h = SAVE_H + #list * 30 + 8\n\t\tpickFrame.Size = UDim2.new(1, -20, 0, #list * 30)\n\t\tsecSave.Size = UDim2.new(1, 0, 0, h)\n\t\tsetStatus(GC:Str(\"settingsLoad\"))\n\tend\n\n\tmakeBtn(secSave, 10, 92, \"settingsSave\", function()\n\t\tlocal ok, name = GC:SaveProfile()\n\t\tif ok then\n\t\t\tsetStatus(GC:Str(\"settingsSaved\") .. \" · \" .. tostring(name))\n\t\telse\n\t\t\tsetStatus(\"error save\")\n\t\tend\n\tend)\n\tmakeBtn(secSave, 106, 92, \"settingsLoad\", openPicker)\n\tmakeBtn(secSave, 202, 82, \"settingsResetAll\", function()\n\t\tpickFrame.Visible = false\n\t\tsecSave.Size = UDim2.new(1, 0, 0, SAVE_H)\n\t\tGC:ResetCurrentProfile()\n\t\tsetStatus(GC:Str(\"settingsResetAll\"))\n\tend)\n\n\tlocal autoHint = Instance.new(\"TextLabel\")\n\tautoHint.Size = UDim2.new(1, -20, 0, 12)\n\tautoHint.Position = UDim2.fromOffset(10, 54)\n\tautoHint.BackgroundTransparency = 1\n\tautoHint.Text = GC:Str(\"settingsAutoHint\")\n\tautoHint.TextColor3 = P.accent or Color3.fromRGB(0, 242, 254)\n\tautoHint.Font = Enum.Font.Gotham\n\tautoHint.TextSize = 9\n\tautoHint.TextXAlignment = Enum.TextXAlignment.Left\n\tautoHint.Parent = secSave\n\n\tlocal lang = GC.Config and GC.Config.language or \"ru\"\n\tlocal theme = (GC.Config and GC.Config.theme and GC.Config.theme.gui) or \"dark\"\n\tlocal accent = GC.Config and GC.Config.accent\n\tlocal alpha = GC:GetHubTransparency()\n\n\tlocal secLang = section(scroll, GC:Str(\"settingsLang\"), yLang, LANG_H, P)\n\tmakeSegments(secLang, {\n\t\t{ key = \"ru\", label = \"Русский\" },\n\t\t{ key = \"en\", label = \"English\" },\n\t}, lang, function(key)\n\t\tGC:SetLanguage(key)\n\tend, P)\n\n\tlocal secTheme = section(scroll, GC:Str(\"settingsTheme\"), yTheme, THEME_H, P)\n\tmakeSegments(secTheme, {\n\t\t{ key = \"dark\", label = \"Dark\" },\n\t\t{ key = \"light\", label = \"Light\" },\n\t}, theme, function(key)\n\t\tGC:SetTheme(key)\n\tend, P)\n\n\tlocal secColor = section(scroll, GC:Str(\"settingsColor\"), yColor, COLOR_H, P)\n\tmakeSwatches(\n\t\tsecColor,\n\t\taccent,\n\t\tfunction(r, g, b)\n\t\t\tGC:SetAccent(r, g, b)\n\t\tend,\n\t\tfunction()\n\t\t\tGC:SetAccent(nil)\n\t\tend,\n\t\tP\n\t)\n\n\tlocal secAlpha = section(scroll, GC:Str(\"settingsAlpha\"), yAlpha, ALPHA_H, P)\n\tmakeAlpha(secAlpha, alpha, function(v)\n\t\tGC:SetHubTransparency(v)\n\tend, P)\n\n\tbase:setSize(300, 380)\n\tbase.OnClosed = function()\n\t\twindow = nil\n\tend\nend\n\nenv.SettingsWindow = SettingsWindow\nreturn SettingsWindow\n",
}
local function loadEmbeddedInto(GC)
	local order = {"SpeedLogic", "TPLogic", "NoclipLogic", "JumpLogic", "SpoofingLogic", "PlayersLogic", "FastHealLogic", "WindowBase", "SpeedWindow", "TPWindow", "NoclipWindow", "JumpWindow", "SpoofingWindow", "PlayersWindow", "FastHealWindow", "SettingsWindow"}
	for _, name in ipairs(order) do
		local src = EMBEDDED[name]
		if src then
			local has = false
			for _, entry in ipairs(GC.Modules) do
				if entry.name == name then has = true break end
			end
			if not has then
				local result, err = compileAndRun(src, name)
				local mod = result
				if type(mod) ~= "table" and type(env[name]) == "table" then mod = env[name] end
				if type(mod) == "table" then
					GC.Modules[#GC.Modules + 1] = { name = name, mod = mod, path = "embed" }
					GC.Errors[name] = nil
					GC:Log("embed " .. name)
				elseif err then
					GC.Errors[name] = "embed: " .. tostring(err)
				end
			end
		end
	end
end

function GC:LoadModules()
	local base = self.Base or ""
	local files = collectFiles(base)
	local pending = {}
	local seenPath = {}
	local function push(p)
		local n = moduleNameOf(p)
		if not seenPath[n] then
			seenPath[n] = true
			pending[#pending + 1] = p
		end
	end
	for _, path in ipairs(files) do
		push(path)
	end
	for _, rel in ipairs(FALLBACK_FILES) do
		push(rel)
	end
	table.sort(pending, function(a, b)
		local function ord(path)
			local name = moduleNameOf(path)
			for i, n in ipairs(LOAD_ORDER) do
				if n == name then
					return i
				end
			end
			return 99
		end
		local ia, ib = ord(a), ord(b)
		if ia ~= ib then
			return ia < ib
		end
		return moduleNameOf(a) < moduleNameOf(b)
	end)
	for _ = 1, 5 do
		if #pending == 0 then
			break
		end
		local failed = {}
		local progressed = false
		for _, path in ipairs(pending) do
			local name = moduleNameOf(path)
			local already = nil
			for _, entry in ipairs(self.Modules) do
				if entry.name == name then
					already = entry
					break
				end
			end
			if already then
				progressed = true
			else
				local src, realPath, prechunk = readSource(base, path)
				local result, err
				if prechunk then
					local ok, res = pcall(prechunk)
					if ok then
						result = res
					else
						err = t(res)
					end
					realPath = realPath or path
				elseif src then
					result, err = compileAndRun(src, name)
				else
					err = "файл не найден"
				end
				if err then
					failed[#failed + 1] = path
					self.Errors[name] = err
				else
					progressed = true
					self.Errors[name] = nil
					local mod = result
					if type(mod) ~= "table" and type(env[name]) == "table" then
						mod = env[name]
					end
					if type(mod) == "table" then
						self.Modules[#self.Modules + 1] = {
							name = name,
							mod = mod,
							path = realPath or path,
						}
						self:Log("загружен " .. name)
					else
						self.Errors[name] = "не вернул таблицу"
						failed[#failed + 1] = path
					end
				end
			end
		end
		if not progressed then
			break
		end
		pending = failed
	end
	for _, path in ipairs(pending) do
		local name = moduleNameOf(path)
		if not self.Errors[name] then
			self.Errors[name] = "не загружен"
		end
	end
	loadEmbeddedInto(self)
	self:HarvestEnv()
end

function GC:HarvestEnv()
	local have = {}
	for _, entry in ipairs(self.Modules) do
		have[entry.name] = true
	end
	for name, mod in pairs(env) do
		if type(name) == "string"
			and type(mod) == "table"
			and not have[name]
			and (mod.GetTable ~= nil or mod.getTable ~= nil)
		then
			self.Modules[#self.Modules + 1] = {
				name = name,
				mod = mod,
				path = "env",
			}
			have[name] = true
			self:Log("взят из env " .. name)
		end
	end
end

function GC:CollectUI()
	local tabs = {}
	local seen = {}
	local function addTab(slot)
		if not seen[slot] then
			seen[slot] = true
			tabs[#tabs + 1] = slot
		end
	end
	for _, slot in ipairs(DEFAULT_TABS) do
		addTab(slot)
	end
	local byTab = {}
	for _, slot in ipairs(tabs) do
		byTab[slot] = {}
	end
	for _, entry in ipairs(self.Modules) do
		local slot = getMeta(entry.mod, "GetTable")
		if slot ~= nil then
			slot = t(slot)
			local pos = tonumber(getMeta(entry.mod, "GetPosition")) or 999
			entry.slot = slot
			entry.pos = pos
			entry.title = t(getMeta(entry.mod, "Name") or entry.name)
			entry.desc = t(getMeta(entry.mod, "Desc") or "")
			addTab(slot)
			if not byTab[slot] then
				byTab[slot] = {}
			end
			byTab[slot][#byTab[slot] + 1] = entry
		end
	end
	local defaults = {}
	for i, slot in ipairs(DEFAULT_TABS) do
		defaults[slot] = i
	end
	local extra = {}
	for _, slot in ipairs(tabs) do
		if not defaults[slot] then
			extra[#extra + 1] = slot
		end
	end
	table.sort(extra)
	tabs = {}
	for _, slot in ipairs(DEFAULT_TABS) do
		tabs[#tabs + 1] = slot
	end
	for _, slot in ipairs(extra) do
		tabs[#tabs + 1] = slot
	end
	for _, list in pairs(byTab) do
		table.sort(list, function(a, b)
			if a.pos ~= b.pos then
				return a.pos < b.pos
			end
			return a.name < b.name
		end)
	end
	return tabs, byTab
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 4)
	c.Parent = parent
	return c
end

local function stroke(parent, color)
	pcall(function()
		local s = Instance.new("UIStroke")
		s.Thickness = 1
		s.Color = color
		s.Parent = parent
	end)
end

local function viewportSize(gui)
	if gui then
		local s = gui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then
			return s
		end
	end
	local cam = workspace.CurrentCamera
	if cam then
		return cam.ViewportSize
	end
	return Vector2.new(800, 600)
end

local function isPrimaryInput(ty)
	return ty == Enum.UserInputType.MouseButton1 or ty == Enum.UserInputType.Touch
end

local function isMoveInput(ty)
	return ty == Enum.UserInputType.MouseMovement
		or ty == Enum.UserInputType.Touch
		or ty == Enum.UserInputType.MouseButton1
end

local function guiPointOver(guiObj, pos)
	if not guiObj or not pos then
		return false
	end
	local p = guiObj.AbsolutePosition
	local s = guiObj.AbsoluteSize
	return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

local function pointerPos(input, UIS)
	UIS = UIS or game:GetService("UserInputService")
	local ok, loc = pcall(function()
		return UIS:GetMouseLocation()
	end)
	if ok and loc then
		return loc
	end
	if input then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return nil
end

local function makeDraggable(handle, target, gui, opts)
	opts = opts or {}
	handle = handle or target
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local moved = false
	handle.Active = true

	local function shouldSkip(pos)
		if not opts.skip or not pos then
			return false
		end
		for _, s in ipairs(opts.skip) do
			if s and s.Visible and guiPointOver(s, pos) then
				return true
			end
		end
		return false
	end

	local function begin(pos)
		if dragging or not pos then
			return
		end
		if shouldSkip(pos) then
			return
		end
		dragging = true
		moved = false
		dragStart = pos
		startPos = target.Position
	end

	local function step(pos)
		if not dragging or not dragStart or not startPos or not pos then
			return
		end
		local delta = pos - dragStart
		if not moved then
			if math.abs(delta.X) <= 3 and math.abs(delta.Y) <= 3 then
				return
			end
			moved = true
		end
		target.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	local function finish()
		if not dragging then
			return
		end
		dragging = false
		dragStart = nil
		startPos = nil
		if opts.onEnd then
			opts.onEnd(moved, target)
		end
	end

	handle.InputBegan:Connect(function(input)
		if not isPrimaryInput(input.UserInputType) then
			return
		end
		begin(pointerPos(input))
	end)

	UIS.InputBegan:Connect(function(input)
		if dragging or not isPrimaryInput(input.UserInputType) then
			return
		end
		local pos = pointerPos(input)
		if not guiPointOver(handle, pos) then
			return
		end
		begin(pos)
	end)

	UIS.InputChanged:Connect(function(input)
		if not isMoveInput(input.UserInputType) then
			return
		end
		step(pointerPos(input))
	end)

	RunService.Heartbeat:Connect(function()
		if not dragging then
			return
		end
		step(pointerPos(nil))
	end)

	UIS.InputEnded:Connect(function(input)
		if not isPrimaryInput(input.UserInputType) then
			return
		end
		finish()
	end)

	return function()
		return moved
	end
end

function GC:HideHub()
	if self._hub then
		self._hub.Visible = false
	end
	if self._launcher then
		self._launcher.Visible = true
	end
end

function GC:ShowHub()
	if not self._hub then
		self:BuildHub()
	end
	if not self._hub then
		return
	end
	self._hub.Visible = true
	if self._launcher then
		self._launcher.Visible = false
	end
	self:ExitModuleView()
	self:RenderTab()
	self:ApplyHubTransparency(self:GetHubTransparency())
	task.defer(function()
		if self._hub and self._hub.Visible then
			self:RenderTab()
			self:ApplyHubTransparency(self:GetHubTransparency())
		end
	end)
end

function GC:ExitModuleView()
	if self._exitingModule then
		return
	end
	self._exitingModule = true
	self._moduleHost = nil
	self._activeModule = nil
	if self._moduleBack then
		self._moduleBack.Visible = false
	end
	if self._hubTitle and self._titleHome then
		self._hubTitle.Text = self._titleHome
		self._hubTitle.Position = UDim2.fromOffset(8, 0)
	end
	if self._tabBar then
		self._tabBar.Visible = true
	end
	if self._status then
		self._status.Visible = true
	end
	if self._statusLine then
		self._statusLine.Visible = true
	end
	if self._list then
		self._list.Visible = true
	end
	if self._relayoutHub then
		self._relayoutHub()
	end
	if self._grip then
		self._grip.Visible = true
	end
	if self._moduleHostFrame then
		self._moduleHostFrame.Visible = false
		for _, child in ipairs(self._moduleHostFrame:GetChildren()) do
			child:Destroy()
		end
	end
	local reg = env.WindowRegistry
	if type(reg) == "table" then
		for _, win in pairs(reg) do
			if win._embedded then
				pcall(function()
					win:Destroy()
				end)
			end
		end
	end
	self._exitingModule = false
	self:ApplyHubTransparency(self:GetHubTransparency())
end

function GC:OpenInHub(entry)
	if not self._hub or not self._list then
		return
	end
	local fn = entry.mod.Open or entry.mod.open or entry.mod.Run
	if type(fn) ~= "function" then
		warn("[GC] " .. entry.name .. ": нет Open/Run")
		return
	end

	local hub = self._hub
	local M = self._hubM or 6
	local HEADER_H = self._hubHeaderH or 32
	if self._tabBar then
		self._tabBar.Visible = false
	end
	if self._status then
		self._status.Visible = false
	end
	if self._statusLine then
		self._statusLine.Visible = false
	end
	if self._hubTitle then
		self._hubTitle.Text = entry.title or entry.name
		self._hubTitle.Position = UDim2.fromOffset(self._moduleBack and 72 or 8, 0)
	end
	if self._verBadge then
		self._verBadge.Text = VERSION
		self._verBadge.Visible = true
	end
	if self._grip then
		self._grip.Visible = false
	end

	local host = self._moduleHostFrame
	if not host then
		host = Instance.new("Frame")
		host.Name = "ModuleHost"
		host.BackgroundTransparency = 1
		host.BorderSizePixel = 0
		host.Visible = false
		host.Parent = hub
		self._moduleHostFrame = host
	end
	host.Position = UDim2.fromOffset(M, M + HEADER_H + 6)
	host.Size = UDim2.new(
		1, -M * 2,
		0, math.max(80, hub.Size.Y.Offset - (M * 2 + HEADER_H + 6))
	)
	host.Visible = true
	for _, child in ipairs(host:GetChildren()) do
		child:Destroy()
	end
	self._list.Visible = false
	if self._moduleBack then
		self._moduleBack.Visible = true
	end
	if self._relayoutHub then
		self._relayoutHub()
	end
	self._moduleHost = host
	self._activeModule = entry.name

	local cfg = self:GetModuleConfig(entry.name)
	local ok, err = pcall(fn, cfg)
	self._moduleHost = nil
	local hasEmbedded = false
	local reg = env.WindowRegistry
	if type(reg) == "table" then
		for _, win in pairs(reg) do
			if win._embedded and not win._destroyed then
				hasEmbedded = true
				break
			end
		end
	end
	if not ok then
		warn("[GC] " .. entry.name .. ": " .. t(err))
		self:ExitModuleView()
		self:RenderTab()
		self:ApplyHubTransparency(self:GetHubTransparency())
	elseif not hasEmbedded then
		self:ExitModuleView()
		self:RenderTab()
		self:ApplyHubTransparency(self:GetHubTransparency())
	else
		self:ApplyHubTransparency(self:GetHubTransparency())
	end
end

function GC:Destroy()
	self.Running = false
	for _, gui in ipairs({ self._gui }) do
		if gui then
			pcall(function()
				gui:Destroy()
			end)
		end
	end
	self._gui = nil
	self._launcher = nil
	self._hub = nil
	self._root = nil
	self._list = nil
	self._status = nil
	local reg = env.WindowRegistry
	if type(reg) == "table" then
		for _, win in pairs(reg) do
			pcall(function()
				win:Destroy()
			end)
		end
	end
	self._rects = {}
	if env.GlobalControler == self then
		env.GlobalControler = nil
	end
end

function GC:RenderTab()
	local P = self.Theme
	local list = self._list
	if not list then
		return
	end
	local layout = list:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
	end
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = P.line

	local slot = self._activeTab
	local byTab = self._byTab or {}
	local entries = byTab[slot] or {}

	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	if #entries == 0 then
		local wrap = Instance.new("Frame")
		wrap.Name = "Empty"
		wrap.Size = UDim2.new(1, -4, 1, 0)
		wrap.BackgroundColor3 = P.panel
		wrap.BackgroundTransparency = self:GetHubTransparency()
		wrap.BorderSizePixel = 0
		wrap.LayoutOrder = 1
		wrap.Parent = list
		corner(wrap, 4)
		stroke(wrap, P.line)

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromOffset(36, 36)
		icon.Position = UDim2.new(0.5, -18, 0.4, -40)
		icon.BackgroundTransparency = 1
		icon.Text = "▣"
		icon.TextColor3 = P.accent
		icon.TextTransparency = 0.55
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = 28
		icon.Parent = wrap

		local empty = Instance.new("TextLabel")
		empty.Name = "Title"
		empty.Size = UDim2.new(1, -24, 0, 18)
		empty.Position = UDim2.new(0, 12, 0.4, 4)
		empty.BackgroundTransparency = 1
		empty.Text = self:Str("emptyTitle")
		empty.TextColor3 = P.text
		empty.Font = Enum.Font.GothamSemibold
		empty.TextSize = 13
		empty.Parent = wrap

		local desc = Instance.new("TextLabel")
		desc.Name = "Desc"
		desc.Size = UDim2.new(1, -32, 0, 32)
		desc.Position = UDim2.new(0, 16, 0.4, 26)
		desc.BackgroundTransparency = 1
		desc.Text = self:Str("emptyDesc"):format(t(slot))
		desc.TextColor3 = P.textDim
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 11
		desc.TextWrapped = true
		desc.Parent = wrap
		self:ApplyHubTransparency(self:GetHubTransparency())
		return
	end

	local alpha = self:GetHubTransparency()
	for i, entry in ipairs(entries) do
		local featured = (i == 1)
		local cardH = featured and 56 or 48
		local btn = Instance.new("TextButton")
		btn.Name = "Module_" .. entry.name
		btn.Size = UDim2.new(1, -4, 0, cardH)
		btn.BackgroundColor3 = P.panel
		btn.BackgroundTransparency = alpha
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Text = ""
		btn.LayoutOrder = i
		btn.Parent = list
		corner(btn, 4)
		pcall(function()
			local s = Instance.new("UIStroke")
			s.Thickness = 1
			s.Color = featured and (P.accentDim or P.line) or P.line
			s.Transparency = 0
			s.Parent = btn
		end)

		local textX = 12
		local iconAsset = self:ResolveIcon(self:GetIconPath(entry.name))
		if iconAsset then
			local iconBox = Instance.new("Frame")
			iconBox.Name = "IconBox"
			iconBox.Size = UDim2.fromOffset(32, 32)
			iconBox.Position = UDim2.fromOffset(10, math.floor((cardH - 32) / 2))
			iconBox.BackgroundColor3 = P.panelAlt
			iconBox.BorderSizePixel = 0
			iconBox.Parent = btn
			corner(iconBox, 4)

			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.new(1, -8, 1, -8)
			icon.Position = UDim2.fromOffset(4, 4)
			icon.BackgroundTransparency = 1
			icon.Image = iconAsset
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Parent = iconBox
			textX = 50
		elseif featured then
			local tick = Instance.new("Frame")
			tick.Name = "Accent"
			tick.Size = UDim2.fromOffset(3, 28)
			tick.Position = UDim2.fromOffset(0, math.floor((cardH - 28) / 2))
			tick.BackgroundColor3 = P.accent
			tick.BorderSizePixel = 0
			tick.Parent = btn
			corner(tick, 2)
			textX = 14
		end

		local hasQuick = getMeta(entry.mod, "QuickToggle") == true
		local rightW = hasQuick and 56 or 28

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Title"
		nameLabel.Size = UDim2.new(1, -(textX + rightW + 8), 0, 16)
		nameLabel.Position = UDim2.fromOffset(textX, featured and 10 or 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.title
		nameLabel.TextColor3 = P.text
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = featured and 13 or 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = btn

		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Desc"
		descLabel.Size = UDim2.new(1, -(textX + rightW + 8), 0, 14)
		descLabel.Position = UDim2.fromOffset(textX, featured and 28 or 26)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = entry.desc
		descLabel.TextColor3 = P.textDim
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 11
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabel.Parent = btn

		local right = Instance.new("Frame")
		right.Name = "Right"
		right.Size = UDim2.new(0, rightW, 1, 0)
		right.Position = UDim2.new(1, -(rightW + 4), 0, 0)
		right.BackgroundTransparency = 1
		right.ZIndex = 3
		right.Parent = btn

		local chev = Instance.new("TextLabel")
		chev.Name = "Chev"
		chev.Size = UDim2.fromOffset(16, 16)
		chev.Position = UDim2.new(1, -18, 0.5, -8)
		chev.BackgroundTransparency = 1
		chev.Text = "›"
		chev.TextColor3 = P.textDim
		chev.Font = Enum.Font.GothamSemibold
		chev.TextSize = 16
		chev.ZIndex = 3
		chev.Parent = right

		local swallow = false

		if hasQuick then
			local sw = Instance.new("TextButton")
			sw.Name = "Quick"
			sw.Size = UDim2.fromOffset(34, 22)
			sw.Position = UDim2.new(0, 0, 0.5, -11)
			sw.BackgroundColor3 = P.btn or Color3.fromRGB(38, 42, 52)
			sw.BorderSizePixel = 0
			sw.AutoButtonColor = true
			sw.Text = ""
			sw.ZIndex = 5
			sw.Parent = right
			corner(sw, 99)

			local lbl = Instance.new("TextLabel")
			lbl.Name = "Lbl"
			lbl.Size = UDim2.new(1, -8, 1, 0)
			lbl.Position = UDim2.fromOffset(4, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = "OFF"
			lbl.TextColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
			lbl.Font = Enum.Font.Code
			lbl.TextSize = 9
			lbl.ZIndex = 6
			lbl.Parent = sw

			local knob = Instance.new("Frame")
			knob.Name = "Knob"
			knob.Size = UDim2.fromOffset(16, 16)
			knob.Position = UDim2.fromOffset(3, 3)
			knob.BackgroundColor3 = P.textDim or Color3.fromRGB(185, 202, 203)
			knob.BorderSizePixel = 0
			knob.ZIndex = 6
			knob.Parent = sw
			corner(knob, 99)

			local on = false
			pcall(function()
				on = entry.mod.IsOn and entry.mod.IsOn() == true
			end)

			local function paintQuick(state)
				on = state
				sw.BackgroundColor3 = state and (P.accent or Color3.fromRGB(0, 242, 254)) or (P.btn or Color3.fromRGB(38, 42, 52))
				lbl.Text = state and "ON" or "OFF"
				lbl.TextColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))
				knob.Position = state and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3)
				knob.BackgroundColor3 = state and (P.accentOn or Color3.fromRGB(0, 55, 58)) or (P.textDim or Color3.fromRGB(185, 202, 203))
			end
			paintQuick(on)

			sw.MouseButton1Click:Connect(function()
				swallow = true
				local nextOn = not on
				if type(entry.mod.SetOn) == "function" then
					pcall(entry.mod.SetOn, nextOn)
				end
				local now = nextOn
				if type(entry.mod.IsOn) == "function" then
					pcall(function()
						now = entry.mod.IsOn() == true
					end)
				end
				paintQuick(now)
			end)

			task.spawn(function()
				while sw.Parent do
					local cur = on
					pcall(function()
						cur = entry.mod.IsOn and entry.mod.IsOn() == true
					end)
					if cur ~= on then
						paintQuick(cur)
					end
					task.wait(0.5)
				end
			end)
		end

		btn.MouseButton1Click:Connect(function()
			if swallow then
				swallow = false
				return
			end
			self:OpenInHub(entry)
		end)
	end
	self:ApplyHubTransparency(self:GetHubTransparency())
end

function GC:BuildHub()
	if self._hub then
		return
	end
	local P = self.Theme
	local cfg = self.Config or DEFAULT_CONFIG
	local player = game:GetService("Players").LocalPlayer
	local gui = self._gui
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "GlobalControlerGui"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 10
		gui.Parent = player:WaitForChild("PlayerGui")
		self._gui = gui
	end

	local W = tonumber(cfg.window and cfg.window.width) or 480
	local H = tonumber(cfg.window and cfg.window.height) or 360
	local rect, pos = self:ClaimPosition(W, H)
	rect.isHub = true
	self._hubRect = rect

	local hub = Instance.new("Frame")
	hub.Name = "Hub"
	hub.Size = UDim2.fromOffset(W, H)
	hub.Position = pos
	hub.BackgroundColor3 = P.bg
	hub.BorderSizePixel = 0
	hub.ClipsDescendants = true
	hub.Active = true
	hub.Visible = true
	local cfgUI = cfg.ui
	hub.BackgroundTransparency = math.clamp(tonumber(cfgUI and cfgUI.transparency) or 0, 0, 0.85)
	hub.Parent = gui
	corner(hub, 4)
	stroke(hub, P.line)
	self._hub = hub
	self._root = hub

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 0)
	pad.PaddingRight = UDim.new(0, 0)
	pad.PaddingTop = UDim.new(0, 0)
	pad.PaddingBottom = UDim.new(0, 0)
	pad.Parent = hub

	local HEADER_H = 32
	local M = 6
	local TAB_H = 28
	local STATUS_H = 22
	self._hubM = M
	self._hubHeaderH = HEADER_H

	local header = Instance.new("TextButton")
	header.Name = "Header"
	header.Size = UDim2.new(1, -M * 2, 0, HEADER_H)
	header.Position = UDim2.fromOffset(M, M)
	header.BackgroundColor3 = P.header
	header.BorderSizePixel = 0
	header.AutoButtonColor = false
	header.Text = ""
	header.Active = true
	header.Selectable = false
	header.Parent = hub
	corner(header, 4)
	stroke(header, P.line)
	self._hubHeader = header

	local backBtn = Instance.new("TextButton")
	backBtn.Name = "Back"
	backBtn.Size = UDim2.new(0, 0, 0, HEADER_H - 6)
	backBtn.AutomaticSize = Enum.AutomaticSize.X
	backBtn.Position = UDim2.fromOffset(3, 3)
	backBtn.BackgroundTransparency = 1
	backBtn.BorderSizePixel = 0
	backBtn.AutoButtonColor = true
	backBtn.Text = self:Str("back")
	backBtn.TextColor3 = P.accent
	backBtn.Font = Enum.Font.GothamSemibold
	backBtn.TextSize = 12
	backBtn.Visible = false
	backBtn.Parent = header
	pcall(function()
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 6)
		p.PaddingRight = UDim.new(0, 6)
		p.Parent = backBtn
	end)
	backBtn.ZIndex = 3
	self._moduleBack = backBtn
	backBtn.MouseButton1Click:Connect(function()
		local reg = env.WindowRegistry
		if type(reg) == "table" then
			for _, win in pairs(reg) do
				if win._embedded then
					pcall(function()
						win:Destroy()
					end)
				end
			end
		end
		self:ExitModuleView()
		self:RenderTab()
		self:ApplyHubTransparency(self:GetHubTransparency())
	end)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -160, 1, 0)
	title.Position = UDim2.fromOffset(8, 0)
	title.BackgroundTransparency = 1
	title.Text = self:Str("title")
	title.TextColor3 = P.text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Active = false
	title.Parent = header
	self._hubTitle = title
	self._titleHome = title.Text

	local headRight = Instance.new("Frame")
	headRight.Name = "HeadRight"
	headRight.Size = UDim2.new(0, 120, 1, -6)
	headRight.Position = UDim2.new(1, -124, 0, 3)
	headRight.BackgroundTransparency = 1
	headRight.BorderSizePixel = 0
	headRight.Parent = header

	local verBadge = Instance.new("TextLabel")
	verBadge.Name = "Version"
	verBadge.Size = UDim2.new(0, 72, 0, 18)
	verBadge.Position = UDim2.new(0, 0, 0.5, -9)
	verBadge.BackgroundColor3 = P.bg
	verBadge.BorderSizePixel = 0
	verBadge.Text = VERSION
	verBadge.TextColor3 = P.accent
	verBadge.Font = Enum.Font.Code
	verBadge.TextSize = 9
	verBadge.Active = false
	verBadge.Parent = headRight
	corner(verBadge, 4)
	stroke(verBadge, P.line)
	verBadge.ZIndex = 2
	self._verBadge = verBadge

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.Position = UDim2.new(1, -30, 0.5, -13)
	closeBtn.BackgroundColor3 = P.danger
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = true
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = P.dangerText or Color3.fromRGB(255, 180, 171)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.Active = true
	closeBtn.Parent = headRight
	corner(closeBtn, 4)
	closeBtn.ZIndex = 3

	makeDraggable(header, hub, gui, {
		skip = { closeBtn, backBtn },
		onEnd = function()
			if self._hubRect then
				self:UpdateWindow(
					self._hubRect,
					hub.Position.X.Offset,
					hub.Position.Y.Offset,
					hub.Size.X.Offset,
					hub.Size.Y.Offset
				)
			end
		end,
	})
	header.ZIndex = 1
	title.ZIndex = 2
	title.Active = false
	headRight.Active = false
	verBadge.Active = false
	backBtn.ZIndex = 4
	closeBtn.ZIndex = 4

	local tabsTop = M + HEADER_H + 6
	local tabBar = Instance.new("Frame")
	tabBar.Name = "Tabs"
	tabBar.Size = UDim2.new(1, -M * 2, 0, TAB_H)
	tabBar.Position = UDim2.fromOffset(M, tabsTop)
	tabBar.BackgroundColor3 = P.panel
	tabBar.BorderSizePixel = 0
	tabBar.Parent = hub
	corner(tabBar, 4)
	stroke(tabBar, P.line)
	self._tabBar = tabBar
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabBar
	pcall(function()
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 3)
		p.PaddingRight = UDim.new(0, 3)
		p.PaddingTop = UDim.new(0, 3)
		p.PaddingBottom = UDim.new(0, 3)
		p.Parent = tabBar
	end)
	self._tabButtons = {}

	local listTop = tabsTop + TAB_H + 6
	local listBottom = STATUS_H + 4
	self._bodyTop = listTop
	self._listBottomPad = listBottom

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -M * 2, 0, 14)
	status.Position = UDim2.new(0, M, 0, H - STATUS_H + 2)
	status.BackgroundTransparency = 1
	status.TextColor3 = P.textDim
	status.Font = Enum.Font.Code
	status.TextSize = 10
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextTruncate = Enum.TextTruncate.AtEnd
	local errCount = 0
	for _ in pairs(self.Errors) do
		errCount = errCount + 1
	end
	local statusText = ("карточек %d · файлов %d"):format(self:CountUIModules(), #self.Modules)
	if errCount > 0 then
		statusText = statusText .. " · " .. self:Str("errors"):format(errCount)
		for name, e in pairs(self.Errors) do
			statusText = statusText .. " · " .. name .. ": " .. t(e):sub(1, 40)
			break
		end
	end
	if not self.Base then
		statusText = self:Str("noBase")
	end
	status.Text = statusText
	status.Parent = hub
	self._status = status

	local statusLine = Instance.new("Frame")
	statusLine.Name = "StatusLine"
	statusLine.Size = UDim2.new(1, -M * 2, 0, 1)
	statusLine.Position = UDim2.new(0, M, 0, H - STATUS_H - 12)
	statusLine.BackgroundColor3 = P.line
	statusLine.BorderSizePixel = 0
	statusLine.Parent = hub
	self._statusLine = statusLine

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(M, listTop)
	list.Size = UDim2.new(1, -M * 2, 0, math.max(40, H - listTop - listBottom))
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = P.line
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = hub
	self._list = list

	closeBtn.MouseButton1Click:Connect(function()
		self:HideHub()
	end)

	local grip = Instance.new("TextButton")
	grip.Name = "Resize"
	grip.Size = UDim2.fromOffset(20, 20)
	grip.Position = UDim2.new(1, -26, 1, -26)
	grip.BackgroundColor3 = P.panelAlt
	grip.BackgroundTransparency = 0.15
	grip.BorderSizePixel = 0
	grip.AutoButtonColor = true
	grip.Text = self:Str("resize")
	grip.TextColor3 = P.textDim
	grip.Font = Enum.Font.GothamBold
	grip.TextSize = 12
	grip.ZIndex = 6
	grip.Parent = hub
	corner(grip, 4)
	self._grip = grip
	self:ApplyHubTransparency(self:GetHubTransparency())

	do
		local UIS = game:GetService("UserInputService")
		local RunService = game:GetService("RunService")
		local resizing = false
		local rStart = nil
		local startSize = nil
		local MIN_W, MIN_H = 340, 240
		local MAX_W, MAX_H = 900, 640

		local function applyList()
			local h = hub.Size.Y.Offset
			if self._list then
				local top = listTop
				local bot = listBottom
				self._list.Position = UDim2.fromOffset(M, top)
				self._list.Size = UDim2.new(1, -M * 2, 0, math.max(40, h - top - bot))
			end
			if self._status then
				self._status.Position = UDim2.new(0, M, 0, h - STATUS_H + 2)
				self._status.Size = UDim2.new(1, -M * 2, 0, 14)
			end
			if self._statusLine then
				self._statusLine.Position = UDim2.new(0, M, 0, h - STATUS_H - 12)
				self._statusLine.Size = UDim2.new(1, -M * 2, 0, 1)
			end
			if self._moduleHostFrame and self._moduleHostFrame.Visible then
				self._moduleHostFrame.Position = UDim2.fromOffset(M, M + HEADER_H + 6)
				self._moduleHostFrame.Size = UDim2.new(
					1, -M * 2,
					0, math.max(80, h - (M * 2 + HEADER_H + 6))
				)
			end
		end

		local function clampSize(w, h)
			return math.clamp(w, MIN_W, MAX_W), math.clamp(h, MIN_H, MAX_H)
		end

		local function beginResize()
			if resizing then
				return
			end
			local pos = pointerPos(nil, UIS)
			if not pos then
				return
			end
			resizing = true
			rStart = pos
			startSize = hub.Size
		end

		local function stepResize(pos)
			if not resizing or not rStart or not startSize or not pos then
				return
			end
			local dx = pos.X - rStart.X
			local dy = pos.Y - rStart.Y
			local w, h = clampSize(startSize.X.Offset + dx, startSize.Y.Offset + dy)
			hub.Size = UDim2.fromOffset(w, h)
			applyList()
		end

		local function stopResize()
			if not resizing then
				return
			end
			resizing = false
			rStart = nil
			startSize = nil
			if self._hubRect then
				self:UpdateWindow(
					self._hubRect,
					hub.Position.X.Offset,
					hub.Position.Y.Offset,
					hub.Size.X.Offset,
					hub.Size.Y.Offset
				)
			end
		end

		grip.InputBegan:Connect(function(input)
			if isPrimaryInput(input.UserInputType) then
				beginResize()
			end
		end)
		UIS.InputBegan:Connect(function(input)
			if resizing or not isPrimaryInput(input.UserInputType) then
				return
			end
			if not guiPointOver(grip, pointerPos(input, UIS)) then
				return
			end
			beginResize()
		end)

		UIS.InputChanged:Connect(function(input)
			if not isMoveInput(input.UserInputType) then
				return
			end
			stepResize(pointerPos(input, UIS))
		end)

		RunService.Heartbeat:Connect(function()
			if not resizing then
				return
			end
			stepResize(pointerPos(nil, UIS))
		end)

		UIS.InputEnded:Connect(function(input)
			if isPrimaryInput(input.UserInputType) then
				stopResize()
			end
		end)

		self._relayoutHub = applyList
		applyList()
	end

	local tabs = self._tabs or DEFAULT_TABS
	local byTab = self._byTab or {}
	local active = self._activeTab or tabs[1]
	self._activeTab = active

	for i, slot in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab_" .. slot
		tab.Size = UDim2.new(1 / #tabs, -4, 1, 0)
		tab.BackgroundColor3 = P.panelAlt
		tab.BorderSizePixel = 0
		tab.AutoButtonColor = true
		tab.Text = slot
		tab.TextColor3 = P.textDim
		tab.Font = Enum.Font.GothamSemibold
		tab.TextSize = 11
		tab.LayoutOrder = i
		tab.Parent = tabBar
			corner(tab, 4)
			local slotName = slot
			local TAB_KEY = {
				Player = "tabPlayer",
				Server = "tabServer",
				Settings = "tabSettings",
			}
			if TAB_KEY[slot] then
				tab.Text = self:Str(TAB_KEY[slot])
			end
			-- после смены языка текст вкладок обновится через RebuildHub
		local function paint()
			local on = self._activeTab == slotName
			tab.BackgroundColor3 = on and P.accent or P.panelAlt
			tab.TextColor3 = on and (P.accentOn or Color3.new(1, 1, 1)) or P.textDim
		end
		paint()
		tab.MouseButton1Click:Connect(function()
			self._activeTab = slotName
			for _, b in pairs(self._tabButtons) do
				if b.paint then
					b.paint()
				end
			end
			self:RenderTab()
			self:ApplyHubTransparency(self:GetHubTransparency())
		end)
		self._tabButtons[i] = { paint = paint }
	end

	self:RenderTab()
	self:ApplyHubTransparency(self:GetHubTransparency())
	hub.Visible = false
end

function GC:BuildLauncher()
	if self._launcher then
		return
	end
	local P = self.Theme
	local player = game:GetService("Players").LocalPlayer
	local gui = self._gui
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "GlobalControlerGui"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 10
		gui.Parent = player:WaitForChild("PlayerGui")
		self._gui = gui
	end

	local btn = Instance.new("TextButton")
	btn.Name = "Launcher"
	btn.Size = UDim2.fromOffset(64, 64)
	btn.Position = UDim2.new(0, 16, 0.5, -32)
	btn.BackgroundColor3 = P.panel
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Text = self:Str("launcher")
	btn.TextColor3 = P.accent
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 22
	btn.Active = true
	btn.Parent = gui
	corner(btn, 4)
	stroke(btn, P.accent)
	self._launcher = btn

	local wasDrag = makeDraggable(btn, btn, gui, {})
	btn.MouseButton1Click:Connect(function()
		if wasDrag() then
			return
		end
		self:ShowHub()
	end)
end

function GC:Init()
	self.Base = findBase()
	self.Config = loadConfig(self.Base or "")
	self:TryAutoLoadProfile()
	self:ApplyAppearance()
	env.GCConfig = self.Config
	env.GCTheme = self.Theme
	if self.Base then
		self:Log("Base: " .. self.Base)
		self:LoadModules()
	else
		warn("[GC] " .. self:Str("noBase"))
		self:LoadModules()
	end
	self:ApplyAppearance()
	self:RefreshTitles()
	local tabs, byTab = self:CollectUI()
	self._tabs = tabs
	self._byTab = byTab
	self._activeTab = tabs[1]
	self:RestoreQuickToggles()
	self:RestoreTPPoints()
	self:BuildLauncher()
	self.Running = true
	self:Log(("карточек %d · файлов %d"):format(self:CountUIModules(), #self.Modules))
	for name, err in pairs(self.Errors) do
		self:Log("ошибка " .. name .. ": " .. err)
	end
end

local ok, err = pcall(GC.Init, GC)
if not ok then
	GC.Running = false
	warn("[GC] init: " .. t(err))
	error(err)
end

return GC
