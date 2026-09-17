local env = getgenv and getgenv() or _G
if env.SpeedLogic then return env.SpeedLogic end

local SpeedLogic = {}
SpeedLogic.__index = SpeedLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

SpeedLogic.BASE_SPEED = 16

local originalSpeed = nil
local desiredSpeed = nil
local keepTask = nil

function SpeedLogic.getHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function SpeedLogic.canRun()
	return SpeedLogic.getHumanoid() ~= nil
end

function SpeedLogic.getCurrentSpeed()
	local h = SpeedLogic.getHumanoid()
	return h and h.WalkSpeed or 0
end

local function startKeep()
	if keepTask then return end
	keepTask = task.spawn(function()
		while desiredSpeed do
			local h = SpeedLogic.getHumanoid()
			if h and math.abs(h.WalkSpeed - desiredSpeed) > 0.001 then
				h.WalkSpeed = desiredSpeed
			end
			task.wait(0.4)
		end
		keepTask = nil
	end)
end

function SpeedLogic.setSpeed(value)
	desiredSpeed = value
	local h = SpeedLogic.getHumanoid()
	if h then
		if originalSpeed == nil then
			originalSpeed = h.WalkSpeed
		end
		h.WalkSpeed = value
	end
	startKeep()
	return true
end

function SpeedLogic.resetSpeed()
	desiredSpeed = nil
	if keepTask then
		task.cancel(keepTask)
		keepTask = nil
	end
	local h = SpeedLogic.getHumanoid()
	if h then
		h.WalkSpeed = originalSpeed or SpeedLogic.BASE_SPEED
	end
	return true
end

function SpeedLogic.getBaseSpeed()
	return originalSpeed or SpeedLogic.BASE_SPEED
end

env.SpeedLogic = SpeedLogic
return SpeedLogic