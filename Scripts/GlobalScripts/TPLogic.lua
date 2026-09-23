local env = getgenv and getgenv() or _G
if env.TPLogic then return env.TPLogic end

local TPLogic = {}
TPLogic.__index = TPLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local store = env.TPModuleStore or {}
env.TPModuleStore = store

local function persist()
	local GC = env.GlobalControler
	if GC and GC.SaveModuleState then
		local pts = {}
		for i, pos in ipairs(store) do
			pts[i] = { x = pos.X, y = pos.Y, z = pos.Z }
		end
		GC:SaveModuleState("TPWindow", { points = pts })
	end
end

function TPLogic.setPoints(list)
	store = {}
	env.TPModuleStore = store
	if type(list) == "table" then
		for _, item in ipairs(list) do
			if type(item) == "table" then
				local x = tonumber(item.x or item[1])
				local y = tonumber(item.y or item[2])
				local z = tonumber(item.z or item[3])
				if x and y and z then
					store[#store + 1] = Vector3.new(x, y, z)
				end
			end
		end
	end
	return #store
end

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
	persist()
	return #store
end

function TPLogic.deletePoint(index)
	if not store[index] then return false end
	table.remove(store, index)
	persist()
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

	local started = os.clock()
	teleportTask = task.spawn(function()
		for _ = 1, 50 do
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
