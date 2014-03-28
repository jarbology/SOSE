local class = require "jaeger.Class"

-- Travels in a straight line and deal damage to a target
-- Parameters:
-- * damage: how much damage to do
return class(..., function(i)
	function i:__constructor(data)
	end

	function i:msgActivate()
		local numBases = self.entity:query("getZone").numBases
		numBases:set(numBases:get() + 1)
	end

	function i:msgDestroy()
		local numBases = self.entity:query("getZone").numBases
		numBases:set(numBases:get() - 1)
	end
end)
