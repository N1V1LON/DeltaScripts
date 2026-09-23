local env = getgenv and getgenv() or _G
if env.JumpLogic then return env.JumpLogic end

local JumpLogic = {}
JumpLogic.__index = JumpLogic

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local power = 50
local jumpConn = nil
local originalPower = nil

function JumpLogic.getHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function JumpLogic.canRun()
	return JumpLogic.getHumanoid() ~= nil
end

function JumpLogic.isEnabled()
	return enabled
end

function JumpLogic.getPower()
	return power
end

local function onJumpRequest()
	if not enabled then return end
	local h = JumpLogic.getHumanoid()
	if not h then return end
	if originalPower == nil then
		originalPower = h.JumpPower
	end
	h.JumpPower = power
	h:ChangeState(Enum.HumanoidStateType.Jumping)
end

function JumpLogic.enable()
	if enabled then return true end
	enabled = true
	local h = JumpLogic.getHumanoid()
	if h and originalPower == nil then
		originalPower = h.JumpPower
	end
	if h then
		h.JumpPower = power
	end
	if not jumpConn then
		jumpConn = UserInputService.JumpRequest:Connect(onJumpRequest)
	end
	return true
end

function JumpLogic.disable()
	if not enabled then return true end
	enabled = false
	if jumpConn then
		jumpConn:Disconnect()
		jumpConn = nil
	end
	local h = JumpLogic.getHumanoid()
	if h and originalPower then
		h.JumpPower = originalPower
	end
	return true
end

function JumpLogic.toggle()
	if enabled then
		return JumpLogic.disable()
	end
	return JumpLogic.enable()
end

function JumpLogic.setPower(value)
	power = math.max(20, math.floor(value + 0.5))
	if enabled then
		local h = JumpLogic.getHumanoid()
		if h then
			h.JumpPower = power
		end
	end
	return power
end

LocalPlayer.CharacterAdded:Connect(function()
	if enabled then
		task.wait(0.2)
		local h = JumpLogic.getHumanoid()
		if h then
			if originalPower == nil then
				originalPower = h.JumpPower
			end
			h.JumpPower = power
		end
		if not jumpConn then
			jumpConn = UserInputService.JumpRequest:Connect(onJumpRequest)
		end
	end
end)

env.JumpLogic = JumpLogic
return JumpLogic
