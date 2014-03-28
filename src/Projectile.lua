local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"
local MathUtils = require "jaeger.utils.MathUtils"

-- Moves at a fixed velocity through the grid
-- Paramters:
-- * zone: the zone to move through
-- * grid
-- * x, y: starting position
-- Messages:
-- * msgMoveToCell(x, y): move the projectile to a new position
-- Queries:
-- * getZone(): get the zone this projectile belongs to
return class(..., function(i)
	function i:__constructor(data)
		self.zone = data.zone
		self.gridName = data.grid
		self.x = data.x
		self.y = data.y
	end

	function i:msgActivate()
		self.zone:addProjectile(self.gridName, self.x, self.y, self.entity)

		local entity = self.entity
		local prop = entity:query("getProp")
		prop:setLoc(self.zone:getTileLoc(self.x, self.y))
	end

	function i:msgDestroy()
		self.zone:removeProjectile(self.gridName, self.x, self.y, self.entity)
	end

	function i:msgMove(vx, vy)
		self:msgStop()

		local entity = self.entity
		local prop = entity:query("getProp")
		prop:setLoc(self.zone:getTileLoc(self.x, self.y))
		local moveAction = ActionUtils.newCoroutine(self, "move", vx, vy)
		entity:sendMessage("msgPerformAction", moveAction)
		self.moveAction = moveAction
	end

	function i:msgStop()
		if self.moveAction then
			self.moveAction:stop()
			self.moveAction = nil
		end
	end

	function i:getGridLoc()
		return self.x, self.y
	end

	function i:getZone()
		return self.zone
	end

	function i:move(vx, vy)
		local entity = self.entity
		local zone = self.zone
		local gridName = self.gridName
		local zoneWidth, zoneHeight = zone:getSize()
		local prop = self.entity:query("getProp")
		local propX, propY = prop:getLoc()
		local xDir = MathUtils.sign(vx)
		local yDir = MathUtils.sign(vy)
		local x, y = self.x, self.y
		local nextX, nextY = x + xDir, y + yDir
		local yield = coroutine.yield
		local targetX, targetY = zone:getTileLoc(nextX, nextY)
		local xLessThanTargetX = propX < targetX
		local yLessThanTargetY = propY < targetY

		if nextX < 1 or nextY < 1 or nextX > zoneWidth or nextY > zoneHeight then
			return entity:sendMessage("msgHitZoneBorder")
		end

		while true do
			propX, propY = propX + vx, propY + vy
			prop:setLoc(propX, propY)

			-- check if we reached a new tile
			local xLessThanTargetX2 = propX < targetX
			local yLessThanTargetY2 = propY < targetY

			if xLessThanTargetX ~= xLessThanTargetX2 or yLessThanTargetY ~= yLessThanTargetY2 then
				zone:moveProjectile(gridName, x, y, nextX, nextY, entity)
				x, y = nextX, nextY
				self.x, self.y = x, y
				entity:sendMessage("msgTileChanged", x, y)

				nextX, nextY = x + xDir, y + yDir
				targetX, targetY = zone:getTileLoc(nextX, nextY)
				xLessThanTargetX = propX < targetX
				yLessThanTargetY = propY < targetY

				if nextX <= 1 or nextY <= 1 or nextX >= zoneWidth or nextY >= zoneHeight then
					return entity:sendMessage("msgHitZoneBorder")
				end
			end
			yield()
		end
	end
end)
