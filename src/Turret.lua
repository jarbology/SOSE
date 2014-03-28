local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"

return class(..., function(i, c)
	function i:msgActivate()
		self.entity:sendMessage("msgPerformAction", ActionUtils.newLoopCoroutine(self, "update"))
		self.zone = self.entity:query("getZone")
		self.x, self.y = self.entity:query("getTileLoc")
	end

	function i:update()
		local zone = self.zone
		local obj = zone:pickFirstObjectIn("bots", self.x - 1, self.x + 1, self.y - 1, self.y + 1, c.isAlive)
		if obj then
			obj:sendMessage("msgDealDamage", 3)
			zone:msgReveal(self.x, self.y, self.x, self.y)
			ActionUtils.skipFrames(60)
		end
	end

	function c.isAlive(entity)
		return entity:isAlive()
	end
end)
