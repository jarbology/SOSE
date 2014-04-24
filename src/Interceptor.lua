local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"

return class(..., function(i, c)
	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC,    MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIColor.INHERIT_COLOR,  MOAIColor.COLOR_TRAIT },
		{ MOAIProp2D.INHERIT_VISIBLE,   MOAIProp2D.ATTR_VISIBLE }
	}

	function i:msgActivate()
		self.entity:sendMessage("msgPerformAction", ActionUtils.newLoopCoroutine(self, "update"))
		self.zone = self.entity:query("getZone")
		self.x, self.y = self.entity:query("getTileLoc")

		local zone = self.entity:query("getZone") 
		local layer = zone:getLayer("projectile")
		local laser = createEntity{
			{"jaeger.Renderable", layer=layer},
			{"jaeger.LineRenderer", width=400, height=400, color={0, 0, 1, 1}, thickness=4}
		}
		self.entity:sendMessage("msgAttach", laser, LINK_SPEC)
		self.points = laser:query("getPoints")
		laser:link(self.entity)
		laser:query("getProp"):setVisible(false)

		self.laser = laser
		self.prop = self.entity:query("getProp")
		self.laserProp = laser:query("getProp")
	end

	function i:update()
		local zone = self.zone
		local obj = zone:pickFirstObjectIn("missiles", self.x - 2, self.x + 2, self.y - 2, self.y + 2, c.isAlive)
		if obj then
			self.laserProp:setVisible(true)
			local points = self.points
			local x, y = self.prop:getLoc()
			local targetX, targetY = obj:query("getProp"):getLoc()
			points[1] = 0
			points[2] = 10
			points[3] = targetX - x
			points[4] = targetY - y
			self.entity:sendMessage("msgPerformWithDelay", 1.0, function()
				self.laserProp:setVisible(false)
			end)

			obj:sendMessage("msgDealDamage", 5)
			zone:msgReveal(self.x, self.y, self.x, self.y)
			ActionUtils.skipFrames(60 * 3)
		end
	end

	function c.isAlive(entity)
		return entity:isAlive()
	end
end)
