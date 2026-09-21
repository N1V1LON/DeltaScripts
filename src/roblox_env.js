const fengari = require('fengari');
const lua = fengari.lua;
const lauxlib = fengari.lauxlib;
const lualib = fengari.lualib;

function createRobloxEnvironment(onUIUpdateCallback) {
	const L = lauxlib.luaL_newstate();
	lualib.luaL_openlibs(L);

	// Expose JS notification bridge
	lua.lua_pushjsfunction(L, function(L_state) {
		const ptr = lua.lua_tojsstring(L_state, 1);
		const jsonStr = ptr ? ptr : "";
		if (onUIUpdateCallback && jsonStr) {
			try {
				const event = JSON.parse(jsonStr);
				onUIUpdateCallback(event);
			} catch (e) {
				console.error("[RobloxEnv] Error parsing UI event from Lua:", e);
			}
		}
		return 0;
	});
	lua.lua_setglobal(L, fengari.to_luastring("__send_ui_event"));

	// Lua bootstrap script providing full Roblox API mocks
	const bootstrapLua = `
		local send_event = __send_ui_event or function() end

		-- Global loadstring compatibility for Lua 5.3/5.4
		loadstring = load

		local getgenv_table = {}
		function getgenv()
			return getgenv_table
		end

		_G.getgenv = getgenv
		_G.loadstring = loadstring

		-- Signals
		local Signal = {}
		Signal.__index = Signal
		function Signal.new()
			return setmetatable({ _listeners = {} }, Signal)
		end
		function Signal:Connect(fn)
			table.insert(self._listeners, fn)
			return {
				Disconnect = function()
					for i, l in ipairs(self._listeners) do
						if l == fn then
							table.remove(self._listeners, i)
							break
						end
					end
				end
			}
		end
		function Signal:Fire(...)
			for _, fn in ipairs(self._listeners) do
				task.spawn(fn, ...)
			end
		end

		-- Math & Geometry Types
		UDim = {}
		UDim.__index = UDim
		function UDim.new(scale, offset)
			return setmetatable({ Scale = scale or 0, Offset = offset or 0 }, UDim)
		end

		UDim2 = {}
		UDim2.__index = UDim2
		function UDim2.new(sx, ox, sy, oy)
			return setmetatable({
				X = UDim.new(sx, ox),
				Y = UDim.new(sy, oy)
			}, UDim2)
		end
		function UDim2.fromOffset(x, y)
			return UDim2.new(0, x, 0, y)
		end
		function UDim2.fromScale(x, y)
			return UDim2.new(x, 0, y, 0)
		end

		Color3 = {}
		Color3.__index = Color3
		function Color3.new(r, g, b)
			return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3)
		end
		function Color3.fromRGB(r, g, b)
			return Color3.new(r/255, g/255, b/255)
		end

		Vector3 = {}
		Vector3.__index = Vector3
		function Vector3.new(x, y, z)
			return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
		end
		function Vector3.__add(a, b)
			return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
		end
		function Vector3.__sub(a, b)
			return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
		end

		CFrame = {}
		CFrame.__index = CFrame
		function CFrame.new(x, y, z)
			if type(x) == "table" and x.X then
				return setmetatable({ Position = x }, CFrame)
			end
			return setmetatable({ Position = Vector3.new(x, y, z) }, CFrame)
		end

		-- Enum Mock
		Enum = {
			UserInputType = {
				MouseButton1 = "MouseButton1",
				MouseMovement = "MouseMovement",
				Touch = "Touch"
			},
			Font = {
				Gotham = "Gotham",
				GothamSemibold = "GothamSemibold",
				Code = "Code"
			},
			EasingStyle = { Quad = "Quad" },
			EasingDirection = { Out = "Out" },
			TextXAlignment = { Left = "Left", Center = "Center", Right = "Right" },
			TextYAlignment = { Top = "Top", Center = "Center", Bottom = "Bottom" },
			TextTruncate = { None = "None", AtEnd = "AtEnd" },
			ZIndexBehavior = { Sibling = "Sibling", Global = "Global" },
			AutomaticSize = { None = "None", X = "X", Y = "Y", XY = "XY" }
		}

		TweenInfo = {}
		TweenInfo.__index = TweenInfo
		function TweenInfo.new(time, style, dir)
			return setmetatable({ Time = time or 1, Style = style, Direction = dir }, TweenInfo)
		end

		-- Instance Registry & Methods
		local nextId = 1
		local instanceMap = {}

		Instance = {}

		function Instance:IsA(className)
			return self.ClassName == className
		end

		function Instance:GetChildren()
			local res = {}
			for _, child in ipairs(self._children) do
				table.insert(res, child)
			end
			return res
		end

		function Instance:FindFirstChild(name)
			for _, child in ipairs(self._children) do
				if child.Name == name then return child end
			end
			return nil
		end

		function Instance:FindFirstChildOfClass(className)
			for _, child in ipairs(self._children) do
				if child.ClassName == className then return child end
			end
			return nil
		end

		function Instance:WaitForChild(name)
			local child = self:FindFirstChild(name)
			if not child then
				child = Instance.new("Folder")
				child.Name = name
				child.Parent = self
			end
			return child
		end

		function Instance:Destroy()
			if self._parent then
				for i, child in ipairs(self._parent._children) do
					if child == self then
						table.remove(self._parent._children, i)
						break
					end
				end
			end
			instanceMap[self.Id] = nil
			send_event(string.format('{"type":"destroyed","id":"%s"}', self.Id))
		end

		-- Instance property setter metatable indexing
		local instance_meta = {
			__index = function(t, k)
				return rawget(t, k) or Instance[k]
			end,
			__newindex = function(t, k, v)
				if k == "Parent" then
					local oldParent = rawget(t, "_parent")
					if oldParent then
						for i, child in ipairs(oldParent._children) do
							if child == t then
								table.remove(oldParent._children, i)
								break
							end
						end
					end
					rawset(t, "_parent", v)
					if v then
						table.insert(v._children, t)
					end
					send_event(string.format('{"type":"parent_changed","id":"%s","parentId":"%s"}', t.Id, v and v.Id or ""))
					return
				end

				rawset(t, k, v)

				if k == "Text" or k == "Position" or k == "Size" or k == "BackgroundColor3" or k == "BackgroundTransparency" or k == "Visible" or k == "WalkSpeed" or k == "CFrame" or k == "CanvasSize" then
					send_event(string.format('{"type":"prop_changed","id":"%s","key":"%s"}', t.Id, k))
				end
			end
		}

		local function createInstanceObj(className)
			local id = "inst_" .. nextId
			nextId = nextId + 1

			local self = setmetatable({
				Id = id,
				ClassName = className,
				Name = className,
				_children = {},
				_parent = nil,
				Position = UDim2.new(0,0,0,0),
				Size = UDim2.new(0,0,0,0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0,
				BorderSizePixel = 1,
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				PlaceholderText = "",
				PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				Visible = true,
				Active = false,
				ClipsDescendants = false,
				AutoButtonColor = true,
				CornerRadius = UDim.new(0, 0),
				Thickness = 1,
				Color = Color3.fromRGB(0,0,0),
				CanvasSize = UDim2.new(0,0,0,0),
				AutomaticCanvasSize = Enum.AutomaticSize.None,
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = Color3.fromRGB(128, 128, 128),
				DisplayOrder = 0,
				AbsoluteSize = Vector3.new(240, 200, 0),
				AbsolutePosition = Vector3.new(60, 60, 0),

				-- Signals
				MouseButton1Click = Signal.new(),
				InputBegan = Signal.new(),
				InputEnded = Signal.new(),
				Changed = Signal.new(),
			}, instance_meta)

			instanceMap[id] = self
			return self
		end

		function Instance.new(className, parent)
			local self = createInstanceObj(className)
			send_event(string.format('{"type":"created","id":"%s","className":"%s"}', self.Id, className))

			if parent then
				self.Parent = parent
			end

			return self
		end

		function getInstanceById(id)
			return instanceMap[id]
		end

		-- Helper for serializing full UI tree safely into JSON string
		function __export_ui_tree()
			local function escape_str(s)
				s = tostring(s or "")
				s = s:gsub('\\\\', '\\\\\\\\')
				s = s:gsub('"', '\\"')
				s = s:gsub('\\n', '\\\\n')
				s = s:gsub('\\r', '\\\\r')
				return '"' .. s .. '"'
			end

			local function serializeColor(c)
				if not c then return '{"r":255,"g":255,"b":255}' end
				local r = math.floor((c.R or 0)*255)
				local g = math.floor((c.G or 0)*255)
				local b = math.floor((c.B or 0)*255)
				return string.format('{"r":%d,"g":%d,"b":%d}', r, g, b)
			end

			local function serializeUDim2(u)
				if not u then return '{"x":{"scale":0,"offset":0},"y":{"scale":0,"offset":0}}' end
				local xs = u.X and u.X.Scale or 0
				local xo = u.X and u.X.Offset or 0
				local ys = u.Y and u.Y.Scale or 0
				local yo = u.Y and u.Y.Offset or 0
				return string.format('{"x":{"scale":%f,"offset":%d},"y":{"scale":%f,"offset":%d}}', xs, math.floor(xo), ys, math.floor(yo))
			end

			local function serializeUDim(u)
				if not u then return '{"scale":0,"offset":0}' end
				local s = u.Scale or 0
				local o = u.Offset or 0
				return string.format('{"scale":%f,"offset":%d}', s, math.floor(o))
			end

			local function buildJsonNode(inst)
				if not inst then return "null" end

				local childParts = {}
				if inst._children then
					for _, c in ipairs(inst._children) do
						table.insert(childParts, buildJsonNode(c))
					end
				end

				local childrenJson = "[" .. table.concat(childParts, ",") .. "]"

				return string.format(
					'{"id":%s,"name":%s,"className":%s,"text":%s,"placeholderText":%s,"visible":%s,' ..
					'"textSize":%d,"textXAlignment":%s,"position":%s,"size":%s,"backgroundColor":%s,' ..
					'"backgroundTransparency":%f,"textColor":%s,"cornerRadius":%s,"thickness":%d,"color":%s,"children":%s}',
					escape_str(inst.Id),
					escape_str(inst.Name),
					escape_str(inst.ClassName),
					escape_str(inst.Text),
					escape_str(inst.PlaceholderText),
					inst.Visible ~= false and "true" or "false",
					tonumber(inst.TextSize) or 14,
					escape_str(inst.TextXAlignment or "Center"),
					serializeUDim2(inst.Position),
					serializeUDim2(inst.Size),
					serializeColor(inst.BackgroundColor3),
					tonumber(inst.BackgroundTransparency) or 0,
					serializeColor(inst.TextColor3),
					serializeUDim(inst.CornerRadius),
					tonumber(inst.Thickness) or 1,
					serializeColor(inst.Color),
					childrenJson
				)
			end

			local pg = getInstanceById("PlayerGui")
			return buildJsonNode(pg)
		end

		-- Task scheduler mock
		task = {
			spawn = function(fn, ...)
				local args = {...}
				fn(table.unpack(args))
			end,
			delay = function(sec, fn, ...)
				local args = {...}
				fn(table.unpack(args))
			end,
			cancel = function(t) end,
			wait = function(sec) return sec or 0 end
		}

		-- Services
		local UserInputService = {
			InputChanged = Signal.new(),
			InputEnded = Signal.new()
		}

		local TweenService = {
			Create = function(self, instance, tweenInfo, props)
				return {
					Play = function()
						for k, v in pairs(props) do
							instance[k] = v
						end
					end
				}
			end
		}

		-- Player & Character Instances
		local PlayerGui = Instance.new("Folder")
		PlayerGui.Id = "PlayerGui"
		PlayerGui.Name = "PlayerGui"
		instanceMap["PlayerGui"] = PlayerGui

		local LocalPlayer = Instance.new("Player")
		LocalPlayer.Name = "LocalPlayer"
		PlayerGui.Parent = LocalPlayer
		LocalPlayer.PlayerGui = PlayerGui

		local Humanoid = Instance.new("Humanoid")
		Humanoid.WalkSpeed = 16

		local HumanoidRootPart = Instance.new("Part")
		HumanoidRootPart.Name = "HumanoidRootPart"
		HumanoidRootPart.Position = Vector3.new(0, 5, 0)
		HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)

		local Character = Instance.new("Model")
		Character.Name = "Character"
		Humanoid.Parent = Character
		HumanoidRootPart.Parent = Character
		LocalPlayer.Character = Character

		local Players = {
			LocalPlayer = LocalPlayer
		}

		local Services = {
			Players = Players,
			UserInputService = UserInputService,
			TweenService = TweenService
		}

		game = {
			GetService = function(self, name)
				return Services[name]
			end
		}

		_G.game = game
		_G.Instance = Instance
		_G.UDim2 = UDim2
		_G.UDim = UDim
		_G.Color3 = Color3
		_G.Vector3 = Vector3
		_G.CFrame = CFrame
		_G.Enum = Enum
		_G.TweenInfo = TweenInfo
		_G.task = task

		_G.getgenv = getgenv
	`;

	lauxlib.luaL_dostring(L, fengari.to_luastring(bootstrapLua));

	return {
		state: L,
		execute: function(luaCode, chunkName = "chunk") {
			const status = lauxlib.luaL_dostring(L, fengari.to_luastring(luaCode, chunkName));
			if (status !== lua.LUA_OK) {
				const ptr = lua.lua_tojsstring(L, -1);
				const err = ptr ? ptr : "Unknown Lua Error";
				lua.lua_pop(L, 1);
				throw new Error(err);
			}
		},
		triggerEvent: function(instanceId, eventName, eventData) {
			const luaTrigger = `
				local inst = getInstanceById("${instanceId}")
				if inst and inst.${eventName} then
					inst.${eventName}:Fire(${JSON.stringify(eventData || {})})
				end
			`;
			lauxlib.luaL_dostring(L, fengari.to_luastring(luaTrigger));
		},
		updateProperty: function(instanceId, key, value) {
			const luaUpdate = `
				local inst = getInstanceById("${instanceId}")
				if inst then
					inst["${key}"] = ${JSON.stringify(value)}
				end
			`;
			lauxlib.luaL_dostring(L, fengari.to_luastring(luaUpdate));
		},
		getTreeState: function() {
			const exportLua = `__tree_export_res = __export_ui_tree()`;
			lauxlib.luaL_dostring(L, fengari.to_luastring(exportLua));
			lua.lua_getglobal(L, fengari.to_luastring("__tree_export_res"));
			const jsonStr = lua.lua_tojsstring(L, -1);
			lua.lua_pop(L, 1);
			return JSON.parse(jsonStr || "{}");
		}
	};
}

module.exports = { createRobloxEnvironment };
