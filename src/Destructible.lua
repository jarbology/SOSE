local class = require "jaeger.Class"
local Property = require "jaeger.Property"

-- Take damage and destroy itself once it runs out of health
-- Parameters:
-- * hp(property<number>)
-- * maxHP(property<number>)
return class(..., function(i)
	function i:__constructor(data)
		self.hp = Property.new(data.hp or 1)
		self.maxHP = Property.new(data.hp or 1)
	end

	-- Get current hp
	function i:getHP()
		return self.hp
	end

	-- Get max hp
	function i:getMaxHP()
		return self.maxHP
	end

	-- Deal damage and destroy the entity if hp <= 0
	function i:msgDealDamage(dmg)
		local hp = self.hp:get() - dmg
		self.hp:set(hp)
		if hp <= 0 then
			destroyEntity(self.entity)
		end
	end
end)
