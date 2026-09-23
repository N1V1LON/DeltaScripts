local env = getgenv and getgenv() or _G
if env.SpoofingLogic then return env.SpoofingLogic end

local SpoofingLogic = {}
SpoofingLogic.__index = SpoofingLogic

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local flags = {
	speed = true,
	jump = true,
	tp = true,
}
local keepTask = nil
local hooksReady = false
local lastJumpAt = 0
local lockUntil = 0
local lockCF = nil

function SpoofingLogic.getHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function SpoofingLogic.getRoot()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

function SpoofingLogic.canRun()
	return SpoofingLogic.getHumanoid() ~= nil
end

function SpoofingLogic.isEnabled()
	return enabled
end

function SpoofingLogic.getFlag(name)
	return flags[name] == true
end

function SpoofingLogic.setFlag(name, value)
	if flags[name] == nil then
		return false
	end
	flags[name] = value == true
	return flags[name]
end

function SpoofingLogic.getFlags()
	return {
		speed = flags.speed,
		jump = flags.jump,
		tp = flags.tp,
	}
end

function SpoofingLogic.noteTeleport()
	if not enabled or not flags.tp then
		return
	end
	local root = SpoofingLogic.getRoot()
	if not root then
		return
	end
	lockCF = root.CFrame
	lockUntil = os.clock() + 1.2
end

local function spoofedBase(value, base)
	if value == nil then
		return base
	end
	if math.abs(value - base) < 0.01 then
		return value
	end
	return base
end

local function installHooks()
	if hooksReady then
		return
	end
	hooksReady = true
	if type(hookmetamethod) ~= "function" then
		return
	end
	pcall(function()
		local old
		old = hookmetamethod(game, "__index", newcclosure(function(self, key)
			if enabled and (key == "WalkSpeed" or key == "JumpPower") and typeof(self) == "Instance" then
				local h = SpoofingLogic.getHumanoid()
				if h and self == h then
					local real = old(self, key)
					if key == "WalkSpeed" and flags.speed then
						local SL = env.SpeedLogic
						if SL and SL.isEnabled and SL.isEnabled() then
							return real
						end
						return spoofedBase(real, 16)
					end
					if key == "JumpPower" and flags.jump then
						return spoofedBase(real, 50)
					end
				end
			end
			return old(self, key)
		end))
	end)
end

local function applySpeed()
	if not flags.speed then
		return
	end
	local SL = env.SpeedLogic
	local h = SpoofingLogic.getHumanoid()
	if not h then
		return
	end
	if SL and SL.isEnabled and SL.isEnabled() then
		local want = SL.getDesired and SL.getDesired()
		if want and math.abs(h.WalkSpeed - want) > 0.001 then
			h.WalkSpeed = want
		end
	end
end

local function applyJump()
	if not flags.jump then
		return
	end
	local JL = env.JumpLogic
	local h = SpoofingLogic.getHumanoid()
	if not h then
		return
	end
	if JL and JL.isEnabled and JL.isEnabled() then
		local want = JL.getPower and JL.getPower()
		if want and math.abs(h.JumpPower - want) > 0.001 then
			h.JumpPower = want
		end
	end
end

local function applyTp()
	if not flags.tp then
		return
	end
	if os.clock() < lockUntil and lockCF then
		local root = SpoofingLogic.getRoot()
		if root and (root.CFrame.Position - lockCF.Position).Magnitude > 4 then
			root.CFrame = lockCF
		end
	end
end

local function startKeep()
	if keepTask then
		return
	end
	keepTask = task.spawn(function()
		while enabled do
			pcall(applySpeed)
			pcall(applyJump)
			pcall(applyTp)
			task.wait(0.08)
		end
		keepTask = nil
	end)
end

local function stopKeep()
	if keepTask then
		task.cancel(keepTask)
		keepTask = nil
	end
	lockUntil = 0
	lockCF = nil
end

function SpoofingLogic.enable()
	if enabled then
		return true
	end
	enabled = true
	installHooks()
	startKeep()
	return true
end

function SpoofingLogic.disable()
	if not enabled then
		return true
	end
	enabled = false
	stopKeep()
	return true
end

function SpoofingLogic.toggle()
	if enabled then
		return SpoofingLogic.disable()
	end
	return SpoofingLogic.enable()
end

LocalPlayer.CharacterAdded:Connect(function()
	if enabled then
		task.wait(0.2)
		startKeep()
	end
end)

local TP = env.TPLogic
if type(TP) == "table" and type(TP.teleportTo) == "function" and not TP._spoofWrapped then
	local raw = TP.teleportTo
	TP.teleportTo = function(...)
		local ok = raw(...)
		if ok then
			SpoofingLogic.noteTeleport()
		end
		return ok
	end
	TP._spoofWrapped = true
end

env.SpoofingLogic = SpoofingLogic
return SpoofingLogic
