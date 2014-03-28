local class = require "jaeger.Class"
local Property = require "jaeger.Property"

-- Occupies a tile in the Zone's building grid
-- Parameters:
-- * x, y: _grid_ coordinate
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
		local zone = self.zone
		zone:addBuilding(self.x, self.y, self.entity)
		
		local prop = self.entity:query("getProp")
		prop:setLoc(zone:getTileLoc(self.x, self.y))
		prop:setVisible(zone:isTileVisible(self.x, self.y))
		self.prop = prop
	end

	function i:msgDestroy()
		self.zone:removeBuildingAt(self.x, self.y)
	end

	function i:msgReveal()
		self.prop:setVisible(true)
	end

	function i:getZone()
		return self.zone
	end
end)
