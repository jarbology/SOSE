local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- An observable property
-- Events:
-- * changed(newValue, oldValue): fired when the property changes
return class(..., function(i)
	function i:__constructor(initialValue)
		self.value = initialValue
		self.changed = Event.new()
	end

	-- Set a new value for the property
	function i:set(value)
		local oldValue = self.value
		self.value = value
		self.changed:fire(value, oldValue)
	end

	-- Get the property's current value
	function i:get()
		return self.value
	end
end)
