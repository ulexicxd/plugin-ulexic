local ServerScriptService = game:GetService("ServerScriptService")
local HTTPService = game:GetService("HttpService")

local API = script.Parent.Parent:WaitForChild("API")
local Packages = script.Parent:WaitForChild("Packages")

local Signal = require(Packages:WaitForChild("Signal"))

local CurrentAPI = {}

local function Merge(target, source)
	for k, v in pairs(source) do
		if type(v) == "table" then
			if type(target[k] or false) == "table" then
				Merge(target[k] or {}, source[k] or {})
			else
				target[k] = v
			end
		else
			target[k] = v
		end
	end
	return target
end

local function ReturnListenables(signal)
	return {
		Connect = function(self, callback)
			return signal:Connect(callback)
		end,
		Wait = function(self)
			return signal:Wait()
		end,
		Once = function(self, callback)
			return signal:Once(callback)
		end,
	}
end

local function APIReload(APIFolder: Folder?)
	CurrentAPI = {}
	
	local folder = APIFolder or API
	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local success, result = pcall(require, module)
			if success then
				CurrentAPI[module.Name] = result
			else
				warn("Failed to load API module: " .. module.Name .. " | " .. tostring(result))
			end
		end
	end
end

local Plugin = {}
Plugin.__index = Plugin

Plugin.LoadedPlugins = {}

function Plugin.new(pluginConfig: any)
	local self = setmetatable({}, Plugin)
    APIReload()

	self.ImportsAllowed = true
	self.ExportsAllowed = true

	Merge(self, pluginConfig or {})

	self.Id = HTTPService:GenerateGUID(false)
	self._exports = {}
	self.API = table.clone(CurrentAPI)

	self.Initialized = false
	self.Started = false

	self.Signals = {
		InitializedSignal = Signal.new(),
		StartedSignal = Signal.new(),
		StoppedSignal = Signal.new()
	}

	Merge(self.API, {
		["import"] = function(pluginHandle:string)
			if self.ImportsAllowed then
				local fetchedPlugin = Plugin.LoadedPlugins[pluginHandle]

				if fetchedPlugin then
					return fetchedPlugin._exports
				end
			end
		end,
		["export"] = function(exportTable)
			if self.ExportsAllowed then
				self._exports = exportTable
			end
		end,
		["plugin"] = {
			Init = ReturnListenables(self.Signals.InitializedSignal),
			Start = ReturnListenables(self.Signals.StartedSignal),
			Stop = self.Signals.StoppedSignal,
			ImportsAllowed = self.ImportsAllowed,
			ExportsAllowed = self.ExportsAllowed
		}
	})

	Plugin.LoadedPlugins[(self.Author or "UnknownPublisher") .. "/" .. (self.Name or self.Id)] = self
	return self
end

function Plugin:Init()
	if not self.Initialized and not self.Started then
		local pluginCode = self.PluginCode
		local loadedPlugin = loadstring(pluginCode, (self.Author or "UnknownPublisher") .. "/" .. (self.Name or self.Id))

		setfenv(loadedPlugin, self.API)

		local connection

		local pluginThread = task.spawn(function()
			local success, result = pcall(loadedPlugin)

			if not success then 
				warn("Plugin " .. self.Id .. " by " .. (self.Author or "UnknownPublisher") .. " ran into a problem. Error: ", result)
			end
		end)

		connection = self.Signals.StoppedSignal:Connect(function()
			self.Started = false
			self.Initialized = false

			if pluginThread then
				task.cancel(pluginThread)
				connection:Disconnect()
			else
				connection:Disconnect()
			end
		end)

		self.Signals.InitializedSignal:Fire()
		self.Initialized = true
	end
end

function Plugin:Start()
	if self.Initialized and not self.Started then
		self.Signals.StartedSignal:Fire()
		self.Started = true
	end
end

function Plugin:Stop()
	if self.Started then
		self.Signals.StoppedSignal:Fire()
		self.Started = false
		self.Initialized = false
	end
end

function Plugin.ReloadAPI(APIFolder:Folder?)
	APIReload(APIFolder or API)
end

return Plugin
