local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(data)
		local currentScene = getCurrentScene()
		assert(currentScene.getZone, "Current scene does not contain zones")
		local zone = assert(currentScene:getZone(data.zone), "Zone "..data.zone.." does not exists")

		self.zone = zone
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
end)
