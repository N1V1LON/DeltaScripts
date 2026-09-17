local env = getgenv and getgenv() or _G
if env.SpeedLogic then return env.SpeedLogic end

local SpeedLogic = {}
SpeedLogic.__index = SpeedLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

SpeedLogic.BASE_SPEED = 16

local originalSpeed = nil

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

function SpeedLogic.setSpeed(value)
	local h = SpeedLogic.getHumanoid()
	if not h then return false end
	if originalSpeed == nil then
		originalSpeed = h.WalkSpeed
	end
	h.WalkSpeed = value
	return true
end

function SpeedLogic.resetSpeed()
	local h = SpeedLogic.getHumanoid()
	if not h then return false end
	h.WalkSpeed = originalSpeed or SpeedLogic.BASE_SPEED
	return true
end

function SpeedLogic.getBaseSpeed()
	return originalSpeed or SpeedLogic.BASE_SPEED
end

env.SpeedLogic = SpeedLogic
return SpeedLogic