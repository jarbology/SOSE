local class = require "jaeger.Class"
local Set = require "jaeger.Set"

return class(..., function(i, c)
	function c.makeListener(obj, methodName)
		return function(...)
			return obj[methodName](obj, ...)
		end
	end

	function i:__constructor(config)
		self.listeners = Set.new()
	end

	function i:addListener(listener)
		self.listeners:add(listener)
	end

	function i:removeListener(listener)
		self.listeners:remove(listener)
	end

	function i:fire(...)
		for listener in self.listeners:iterator() do
			listener(...)
		end
	end
end)
