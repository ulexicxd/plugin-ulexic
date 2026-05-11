local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._listeners = {}
	return (self :: any)
end

function Signal:Connect(callback: (...any) -> ())
	local connection = {}
	connection._callback = callback
	connection._signal = self

	function connection:Disconnect()
		if self._signal then
			self._signal._listeners[self] = nil
			self._signal = nil
		end
	end

	self._listeners[connection] = true
	return connection
end

function Signal:Fire(...: any)
	for connection in pairs(self._listeners) do
		task.spawn(connection._callback, ...)
	end
end

function Signal:Once(callback: (...any) -> ())
	local connection
	connection = self:Connect(function(...: any)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...: any)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	for connection in pairs(self._listeners) do
		connection:Disconnect()
	end
end

function Signal:Destroy()
	self:DisconnectAll()
	setmetatable(self, nil)
	self._listeners = nil
end

return Signal