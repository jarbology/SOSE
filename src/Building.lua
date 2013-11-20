local class = require "jaeger.Class"
local Property = require "jaeger.Property"

return class(..., function(i)
	function i:__constructor(data)
		local currentScene = getCurrentScene()
		assert(currentScene.getZone, "Current scene does not contain zones")
		local zone = assert(currentScene:getZone(data.zone), "Zone "..data.zone.." does not exists")

		self.zone = zone
		self.x = data.x
		self.y = data.y
		self.hp = Property.new(data.hp or 1)
		self.maxHP = Property.new(data.hp or 1)
	end

	function i:getTileLoc()
		return self.x, self.y
	end

	function i:msgActivate()
		self.zone:addBuilding(self.x, self.y, self.entity)
		self.entity:query("getProp"):setLoc(self.zone:getTileLoc(self.x, self.y))
	end

	function i:msgDealDamage(dmg)
		local hp = self.hp:get() - dmg
		self.hp:set(hp)
		if hp <= 0 then
			destroyEntity(self.entity)
		end
	end

	function i:msgDestroy()
		self.zone:removeBuildingAt(self.x, self.y)
	end

	function i:getHP()
		return self.hp
	end

	function i:getMaxHP()
		return self.maxHP
	end
end)
