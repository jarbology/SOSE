local class = require "jaeger.Class"

return class(..., function(i)
	local SPEED = 5

	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC,    MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIColor.INHERIT_COLOR,  MOAIColor.COLOR_TRAIT },
		{ MOAIProp2D.INHERIT_VISIBLE,   MOAIProp2D.ATTR_VISIBLE }
	}

	function i:msgActivate()
		local zone = self.entity:query("getZone") 
		self.zone = zone

		local weaponQueue = zone:getWeaponQueue("robot")
		self.weaponQueue = weaponQueue

		weaponQueue:enqueue(self.entity)

		local layer = zone:getLayer("projectile")
		local robot = createEntity{
			{"jaeger.Renderable", layer=layer},
			{"jaeger.Sprite", spriteName="projectiles/robot_down"}
		}
		self.entity:sendMessage("msgAttach", robot, LINK_SPEC)
		self.robot = robot
		robot:link(self.entity)
		robot:query("getProp"):setLoc(0, 10)
		self.upgraded = false
	end

	function i:canUpgrade()
		return not self.upgraded
	end

	function i:msgDestroy()
		self.weaponQueue:remove(self.entity)
	end

	function i:msgAttack(targetZone, targetX, targetY, quadrant)
		local zone = self.zone
		local vx, vy
		local startX, startY
		local xScale
		local zoneWidth, zoneHeight = zone:getSize()
		local sprite

		if quadrant == "left" then--left to right
			xScale = 1
			startX = 1
			startY = targetY
			vx = SPEED
			vy = 0
			sprite = "projectiles/robot_right"
		elseif quadrant == "top" then--top to bottom
			xScale = 1
			startX = targetX
			startY = zoneHeight
			vx = 0
			vy = -SPEED
			sprite = "projectiles/robot_down"
		elseif quadrant == "right" then--right to left
			xScale = -1
			startX = zoneWidth
			startY = targetY
			vx = -SPEED
			vy = 0
			sprite = "projectiles/robot_left"
		else--bottom to top
			xScale = 1
			startX = targetX
			startY = 1
			vx = 0
			vy = SPEED
			sprite = "projectiles/robot_up"
		end

		createEntity{
			{"jaeger.Renderable", layer=targetZone:getLayer("projectile"), xScale=xScale},
			{"jaeger.Actor", phase="robots"},
			{"jaeger.Sprite", spriteName=sprite, autoPlay=true},
			{"Projectile", x=startX, y=startY,
			               zone=targetZone, grid="bots"},
			{"Destructible", hp=5},
			{"Robot", vx=vx, vy=vy, damage=1, base=self.entity}
		}

		local robotProp = self.robot:query("getProp")
		robotProp:seekLoc(0, 1000, 1.7, MOAIEaseType.SOFT_EASE_OUT)
	end

	function i:msgRobotReturned()
		if self.entity:isAlive() then
			self.weaponQueue:enqueue(self.entity)
			local robotProp = self.robot:query("getProp")
			robotProp:setLoc(0, 1000)
			robotProp:seekLoc(0, 10, 1.7, MOAIEaseType.SOFT_EASE_IN)
		end
	end

	function i:msgRobotDestroyed()
		self.entity:sendMessage("msgPerformWithDelay", 10, function()
			self:msgRobotReturned()
		end)
	end
end)
