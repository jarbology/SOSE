local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:__constructor(data)
		self.currentZone = 1
		self.homeZone = data.homeZone
	end
end)
