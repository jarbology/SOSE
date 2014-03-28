local class = require "jaeger.Class"

-- Travels in a straight line and deal damage to a target
-- Parameters:
-- * damage: how much damage to do
return class(..., function(i)
	function i:__constructor(data)
		self.vx, self.vy = data.vx, data.vy
		self.targetX, self.targetY = data.targetX, data.targetY
		self.damage = data.damage
	end

	function i:msgActivate()
		self.entity:sendMessage("msgMove", self.vx, self.vy)
	end

	function i:msgTileChanged(x, y)
		if x == self.targetX and y == self.targetY then
			local zone = self.entity:query("getZone")
			local building = zone:getBuildingAt(x, y)
			if building then
				building:sendMessage("msgDealDamage", self.damage)
			end
			zone:msgReveal(x - 1, x + 1, y - 1, y + 1)
			destroyEntity(self.entity)
		end
	end
end)
