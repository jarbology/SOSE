local class = require "jaeger.Class"

return class(..., function(i)
	local SPEED = 5

	function i:msgActivate()
		local zone = self.entity:query("getZone") 
		self.zone = zone

		local weaponQueue = zone:getWeaponQueue("robot")
		self.weaponQueue = weaponQueue

		weaponQueue:enqueue(self.entity)
	end

	function i:msgDestroy()
		self.weaponQueue:remove(self.entity)
	end

	function i:msgAttack(targetZone, targetX, targetY, quadrant)
		local zone = self.zone
		local vx, vy
		local startX, startY
		local zoneWidth, zoneHeight = zone:getSize()
		local sprite

		if quadrant == "left" then--left to right
			startX = 1
			startY = targetY
			vx = SPEED
			vy = 0
			sprite = "projectiles/robot_right"
		elseif quadrant == "top" then--top to bottom
			startX = targetX
			startY = zoneHeight
			vx = 0
			vy = -SPEED
			sprite = "projectiles/robot_down"
		elseif quadrant == "right" then--right to left
			startX = zoneWidth
			startY = targetY
			vx = -SPEED
			vy = 0
			sprite = "projectiles/robot_left"
		else--bottom to top
			startX = targetX
			startY = 1
			vx = 0
			vy = SPEED
			sprite = "projectiles/robot_up"
		end

		createEntity{
			{"jaeger.Renderable", layer=targetZone:getLayer("projectile")},
			{"jaeger.Actor", phase="robots"},
			{"jaeger.Sprite", spriteName=sprite, autoPlay=true},
			{"Projectile", x=startX, y=startY,
			               zone=targetZone, grid="bots"},
			{"Destructible", hp=5},
			{"Robot", vx=vx, vy=vy, damage=1, base=self.entity}
		}
	end

	function i:msgRobotReturned()
		if self.entity:isAlive() then
			self.weaponQueue:enqueue(self.entity)
		end
	end

	function i:msgRobotDestroyed()
		if self.entity:isAlive() then
			self.entity:sendMessage("msgPerformWithDelay", 10, function()
				self.weaponQueue:enqueue(self.entity)
			end)
		end
	end
end)
