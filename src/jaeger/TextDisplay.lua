local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:__constructor(data)
		self.format = data.format or "%01d"
		self.property = data.property
	end

	function i:msgActivate()
		self.property.changed:addListener(self, "changeText")
		self:changeText(self.property:get())
	end

	function i:changeText(value)
		self.entity:sendMessage("msgSetText", self.format:format(value))
	end
end)
