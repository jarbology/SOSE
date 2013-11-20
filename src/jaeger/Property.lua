local class = require "jaeger.Class"
local Event = require "jaeger.Event"

return class(..., function(i)
	function i:__constructor(initialValue)
		self.value = initialValue
		self.changed = Event.new()
	end

	function i:set(value)
		local oldValue = self.value
		self.value = value
		self.changed:fire(value, oldValue)
	end

	function i:get()
		return self.value
	end
end)
