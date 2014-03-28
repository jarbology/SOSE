local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"
local MathUtils = require "jaeger.utils.MathUtils"

-- Travels in a straight line and deal damage to a target
-- Parameters:
-- * damage: how much damage to do
return class(..., function(i)
	function i:__constructor(data)
		self.vx, self.vy = data.vx, data.vy
		self.damage = data.damage
		self.base = data.base
	end

	function i:msgActivate()
		self.entity:sendMessage("msgMove", self.vx, self.vy)
		self.zone = self.entity:query("getZone")
	end

	function i:msgDestroy()
		self.base:sendMessage("msgRobotDestroyed")
	end

	function i:msgTileChanged(x, y)
		local zone = self.zone
		local dx, dy = MathUtils.sign(self.vx), MathUtils.sign(self.vy)
		zone:msgReveal(x + dx, x + dx, y + dy, y + dy)
		local building = zone:getBuildingAt(x + dx, y + dy)
		if building then
			self.entity:sendMessage("msgStop")
			self.entity:sendMessage("msgPerformAction", ActionUtils.newCoroutine(self, "attack", building))
		end
	end

	function i:attack(building)
		while building:isAlive() do--attack till building is destroyed
			building:sendMessage("msgDealDamage", self.damage)
			ActionUtils.skipFrames(60)
		end
		self.entity:sendMessage("msgMove", self.vx, self.vy)
	end

	function i:msgHitZoneBorder()
		self.base:sendMessage("msgRobotReturned")
	end
end)
