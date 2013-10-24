local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(data)
		self.damage = data.damage
	end

	function i:msgActivate()
		self.entity:sendMessage("msgMove", 10, 0)
	end

	function i:msgTileChanged(x, y)
		local zone = self.entity:query("getZone")
		local building = zone:getBuildingAt(x, y)
		if building then
			building:sendMessage("msgDealDamage", self.damage)
			destroyEntity(self.entity)
		end
	end

	function i:msgHitZoneBorder()
		destroyEntity(self.entity)
	end
end)
