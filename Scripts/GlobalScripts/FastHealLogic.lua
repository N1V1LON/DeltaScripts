local env = getgenv and getgenv() or _G
if env.FastHealLogic then return env.FastHealLogic end

local FastHealLogic = {}
FastHealLogic.__index = FastHealLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local amount = 5
local healTask = nil

function FastHealLogic.getHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function FastHealLogic.canRun()
	return FastHealLogic.getHumanoid() ~= nil
end

function FastHealLogic.isEnabled()
	return enabled
end

function FastHealLogic.getAmount()
	return amount
end

function FastHealLogic.setAmount(value)
	value = tonumber(value) or 5
	amount = math.clamp(math.floor(value + 0.5), 1, 50)
	return amount
end

local function startLoop()
	if healTask then
		return
	end
	healTask = task.spawn(function()
		while enabled do
			local h = FastHealLogic.getHumanoid()
			if h and h.Health > 0 and h.Health < h.MaxHealth then
				pcall(function()
					h.Health = math.min(h.MaxHealth, h.Health + amount)
				end)
			end
			task.wait(0.12)
		end
		healTask = nil
	end)
end

local function stopLoop()
	if healTask then
		task.cancel(healTask)
		healTask = nil
	end
end

function FastHealLogic.enable()
	if enabled then
		return true
	end
	enabled = true
	if FastHealLogic.canRun() then
		startLoop()
	end
	return true
end

function FastHealLogic.disable()
	if not enabled then
		return true
	end
	enabled = false
	stopLoop()
	return true
end

function FastHealLogic.toggle()
	if enabled then
		return FastHealLogic.disable()
	end
	return FastHealLogic.enable()
end

LocalPlayer.CharacterAdded:Connect(function()
	if enabled then
		task.wait(0.2)
		startLoop()
	end
end)

env.FastHealLogic = FastHealLogic
return FastHealLogic
