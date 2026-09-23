local env = getgenv and getgenv() or _G
if env.NoclipLogic then return env.NoclipLogic end

local NoclipLogic = {}
NoclipLogic.__index = NoclipLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local clipTask = nil

function NoclipLogic.getCharacter()
	return LocalPlayer.Character
end

function NoclipLogic.canRun()
	local char = NoclipLogic.getCharacter()
	return char ~= nil and char:FindFirstChildOfClass("Humanoid") ~= nil
end

function NoclipLogic.isEnabled()
	return enabled
end

local function applyNoCollide(char)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function startLoop()
	if clipTask then return end
	clipTask = task.spawn(function()
		while enabled do
			local char = NoclipLogic.getCharacter()
			if char then
				applyNoCollide(char)
			end
			task.wait(0.05)
		end
		clipTask = nil
	end)
end

function NoclipLogic.enable()
	enabled = true
	if NoclipLogic.canRun() then
		startLoop()
	end
	return true
end

function NoclipLogic.disable()
	if not enabled then return true end
	enabled = false
	if clipTask then
		task.cancel(clipTask)
		clipTask = nil
	end
	local char = NoclipLogic.getCharacter()
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	return true
end

function NoclipLogic.toggle()
	if enabled then
		return NoclipLogic.disable()
	end
	return NoclipLogic.enable()
end

LocalPlayer.CharacterAdded:Connect(function()
	if enabled then
		task.wait(0.2)
		startLoop()
	end
end)

env.NoclipLogic = NoclipLogic
return NoclipLogic
