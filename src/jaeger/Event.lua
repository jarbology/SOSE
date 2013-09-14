local class = require "jaeger.Class"
local Set = require "jaeger.Set"

-- Notifies an event to several receivers
return class(..., function(i, c)
	function c.makeListener(obj, methodName)
		assert(obj[methodName], "Object does not have method "..tostring(methodName))
		return function(...)
			return obj[methodName](obj, ...)
		end
	end

	function i:__constructor()
		self.listeners = Set.new()
	end

	-- Add a listener to the event
	-- A listener can either be
	-- a) a free function
	--    In this case, you can use: event:addListener(func)
	-- b) an object
	--    In this case, use: event:addListener(object, "methodName")
	--    addListener will return a reference which can be used to remove the listener
	function i:addListener(listener, methodName)
		if methodName ~= nil then
			local proxyListener = c.makeListener(listener, methodName)
			self.listeners:add(proxyListener)
			return proxyListener
		else
			self.listeners:add(listener)
		end
	end

	-- Remove a listener (rarely used)
	-- If the previously added listener is a function, "listener" refers to the function
	-- If the previously added listener is an object, "listener" refers to the reference that addListener returned
	function i:removeListener(listener)
		self.listeners:remove(listener)
	end

	-- Notifies all listener of the event
	-- All listeners will be invoked with the provided parameters
	function i:fire(...)
		for listener in self.listeners:iterator() do
			listener(...)
		end
	end
end)
