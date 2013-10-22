local class = require "jaeger.Class"

-- Messages:
-- * msgMoveToCell(x, y): move the walker to a new position
-- Queries:
-- * getZone(): get the zone this walker belongs to
return class(..., function(i)
	function i:__constructor(data)
		local currentScene = self.sceneMgr:getCurrentScene()
		assert(currentScene.getZone, "Current scene does not contain zones")
		local zone = assert(currentScene:getZone(data.zone), "Zone "..data.zone.." does not exists")

		self.zone = zone
		self.gridName = data.gridName
		self.x = data.x
		self.y = data.y
	end

	function i:msgActivate()
		self.zone:addGridWalker(self.gridName, self.x, self.y, self.entity)
	end

	function i:msgDestroy(self)
		self.zone:removeGridWalker(self.gridName, self.x, self.y, self.entity)
	end

	function i:msgMoveToCell(self, x, y)
		self.zone:moveGridWalker(self.gridName, self.x, self.y, x, y, self.entity)
		self.x, self.y = x, y
	end
end)
