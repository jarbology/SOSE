local class = require "jaeger.Class"

-- Launch a missile at the opposing Zone
-- Parameters:
-- * zone: home zone
return class(..., function(i)
	local MENU = {
		{id = "upgrade", sprite = "ui/radialMenu/upgrade"},
		{id = "demolish", sprite = "ui/radialMenu/demolish"}
	}

	local SPEED = 5

	function i:msgActivate()
		local zone = self.entity:query("getZone") 
		self.zone = zone

		local weaponQueue = zone:getWeaponQueue("rocket")
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
		local rotation

		if quadrant == "left" then--left to right
			startX = 1
			startY = targetY
			vx = SPEED
			vy = 0
			rotation = 270
		elseif quadrant == "top" then--top to bottom
			startX = targetX
			startY = zoneHeight
			vx = 0
			vy = -SPEED
			rotation = 180
		elseif quadrant == "right" then--right to left
			startX = zoneWidth
			startY = targetY
			vx = -SPEED
			vy = 0
			rotation = 90
		else--bottom to top
			startX = targetX
			startY = 1
			vx = 0
			vy = SPEED
			rotation = 0
		end

		createEntity{
			{"jaeger.Renderable", layer=targetZone:getLayer("projectile"), rotation=rotation},
			{"jaeger.Actor", phase="missiles"},
			{"jaeger.Sprite", spriteName = "projectiles/rocket", autoPlay=true},
			{"Projectile", x=startX, y=startY,
			               zone=targetZone, grid="missiles"},
			{"Destructible", hp=5},
			{"Missile", vx=vx, vy=vy,
			            targetX=targetX, targetY=targetY,
			            damage=10}

		}

		self.entity:sendMessage("msgPerformWithDelay", 10, function()
			self.weaponQueue:enqueue(self.entity)
		end)
	end

	function i:getMenu()
		return MENU
	end
end)
