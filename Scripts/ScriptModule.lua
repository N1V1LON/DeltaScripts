local env = getgenv and getgenv() or _G
if env.ScriptModule then return env.ScriptModule end

local ScriptModule = {}
ScriptModule.__index = ScriptModule

local Registry = {
	Modules = {},
	Controller = nil,
}

function ScriptModule.new(info)
	local name = info.gui and info.gui.name
	for _, existing in ipairs(Registry.Modules) do
		if existing.gui.name == name then
			existing.gui = info.gui or {}
			existing.logic = info.logic or {}
			if Registry.Controller then
				Registry.Controller:Refresh(Registry.Modules)
			end
			return existing
		end
	end

	local self = setmetatable({}, ScriptModule)
	self.gui = info.gui or {}
	self.logic = info.logic or {}

	table.insert(Registry.Modules, self)
	if Registry.Controller then
		Registry.Controller:Refresh(Registry.Modules)
	end
	return self
end

function ScriptModule:getData()
	local gui = self.gui
	local logic = self.logic
	return {
		name = gui.name or "Без имени",
		desc = gui.desc or "",
		icon = gui.icon,
		group = gui.group or "Общие",
		what = gui.what and gui.what() or gui.desc or "",
		hasAccess = logic.canRun and logic.canRun() or false,
		run = logic.run,
		module = self,
	}
end

function ScriptModule.setController(controller)
	Registry.Controller = controller
	if Registry.Controller then
		Registry.Controller:Refresh(Registry.Modules)
	end
end

function ScriptModule.getCount()
	return #Registry.Modules
end

env.ScriptModule = ScriptModule
return ScriptModule