local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(stream, padValue)
		self.stream = stream
		self.padValue = padValue
	end

	function i:hasData()
		return true
	end

	function i:take()
		local stream = self.stream
		if stream:hasData() then
			return stream:take()
		else
			return self.padValue
		end
	end
end)
