local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:__constructor(data)
		self.currentZone = 1
		self.homeZone = data.homeZone
	end

	function i:msgSwitchZone()
		self.currentZone = 3 - self.currentZone
		getCurrentScene():switchZone(self.currentZone)
	end
end)
