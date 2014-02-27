local class = require "jaeger.Class"
local Property = require "jaeger.Property"

return class(..., function(i)
	function i:__constructor(data)
		self.zone = data.zone
		self.x = data.x
		self.y = data.y
	end

	function i:getTileLoc()
		return self.x, self.y
	end

	function i:msgActivate()
		self.zone:addBuilding(self.x, self.y, self.entity)
		self.entity:query("getProp"):setLoc(self.zone:getTileLoc(self.x, self.y))
	end

	function i:msgDestroy()
		self.zone:removeBuildingAt(self.x, self.y)
	end

	function i:getZone()
		return self.zone
	end
end)
