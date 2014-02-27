local class = require "jaeger.Class"
local Property = require "jaeger.Property"

return class(..., function(i)
	function i:__constructor(data)
		self.hp = Property.new(data.hp or 1)
		self.maxHP = Property.new(data.hp or 1)
	end

	function i:getHP()
		return self.hp
	end

	function i:getMaxHP()
		return self.maxHP
	end

	function i:msgDealDamage(dmg)
		local hp = self.hp:get() - dmg
		self.hp:set(hp)
		if hp <= 0 then
			destroyEntity(self.entity)
		end
	end
end)
