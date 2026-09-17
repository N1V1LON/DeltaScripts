local env = getgenv and getgenv() or _G
if env.TPLogic then return env.TPLogic end

local TPLogic = {}
TPLogic.__index = TPLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local store = env.TPModuleStore or {}
env.TPModuleStore = store

function TPLogic.getRoot()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

function TPLogic.canRun()
	return TPLogic.getRoot() ~= nil
end

function TPLogic.getPoints()
	return store
end

function TPLogic.getPoint(index)
	return store[index]
end

function TPLogic.addPoint()
	local root = TPLogic.getRoot()
	if not root then return nil end
	local point = root.Position
	table.insert(store, point)
	return #store
end

function TPLogic.deletePoint(index)
	if not store[index] then return false end
	table.remove(store, index)
	return true
end

local teleportTask = nil

function TPLogic.teleportTo(index)
	local pos = store[index]
	if not pos then return false end
	local root = TPLogic.getRoot()
	if not root then return false end

	local cf = CFrame.new(pos)
	root.CFrame = cf

	if teleportTask then
		task.cancel(teleportTask)
		teleportTask = nil
	end

	local tries = 50
	local started = os.clock()
	teleportTask = task.spawn(function()
		for i = 1, tries do
			if os.clock() - started > 2.0 then break end
			local r = TPLogic.getRoot()
			if r then
				r.CFrame = cf
			end
			task.wait(0.03)
		end
		teleportTask = nil
	end)

	return true
end

env.TPLogic = TPLogic
return TPLogic