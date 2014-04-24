local class = require "jaeger.Class"
local AudioSystem = getSystem "jaeger.AudioSystem"

-- Launch a missile at the opposing Zone
-- Parameters:
-- * zone: home zone
return class(..., function(i)
	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC,    MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIColor.INHERIT_COLOR,  MOAIColor.COLOR_TRAIT },
		{ MOAIProp2D.INHERIT_VISIBLE,   MOAIProp2D.ATTR_VISIBLE }
	}

	local SPEED = 5

	function i:msgActivate()
		local zone = self.entity:query("getZone") 
		self.zone = zone
		self.upgraded = false

		local weaponQueue = zone:getWeaponQueue("rocket")
		self.weaponQueue = weaponQueue

		weaponQueue:enqueue(self.entity)

		local layer = zone:getLayer("projectile")
		local missile = createEntity{
			{"jaeger.Renderable", layer=layer},
			{"jaeger.Sprite", spriteName="projectiles/rocket_stationary"}
		}
		self.entity:sendMessage("msgAttach", missile, LINK_SPEC)
		self.missile = missile
		missile:link(self.entity)
		self.damage = 10
		self.stationarySprite = "projectiles/rocket_stationary"
		self.launchSprite = "projectiles/rocket_launched"
		self.projectileSprite = "projectiles/rocket"
		self.available = true
	end

	function i:canUpgrade()
		return not self.upgraded
	end

	function i:msgDestroy()
		self.weaponQueue:remove(self.entity)
	end

	function i:msgUpgrade()
		self.upgraded = true
		self.damage = 20

		self.stationarySprite = "projectiles/big_rocket_stationary"
		self.launchSprite = "projectiles/big_rocket_launched"
		self.projectileSprite = "projectiles/big_rocket"
		self.missile:sendMessage("msgChangeSprite", self.stationarySprite)

		local zone = self.entity:query("getZone") 
		local weaponQueue = zone:getWeaponQueue("rocket2")

		if self.available then
			self.weaponQueue:remove(self.entity)
			weaponQueue:enqueue(self.entity)
		end

		self.weaponQueue = weaponQueue
	end

	function i:msgAttack(targetZone, targetX, targetY, quadrant)
		self.available = false

		local zone = self.zone
		local vx, vy
		local startX, startY
		local zoneWidth, zoneHeight = zone:getSize()
		local rotation
		AudioSystem:playOnce("gun1.wav")

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
			{"jaeger.Sprite", spriteName = self.projectileSprite, autoPlay=true},
			{"Projectile", x=startX, y=startY,
			               zone=targetZone, grid="missiles"},
			{"Destructible", hp=5},
			{"Missile", vx=vx, vy=vy,
			            targetX=targetX, targetY=targetY,
			            damage=self.damage}
		}

		local missile = self.missile
		local missileProp = missile:query("getProp")
		missileProp:seekLoc(0, 1000, 1.7, MOAIEaseType.SOFT_EASE_OUT)
		missile:sendMessage("msgChangeSprite", self.launchSprite)
		missile:sendMessage("msgPlayAnimation")

		self.entity:sendMessage("msgPerformWithDelay", 10, function()
			self.available = true
			self.weaponQueue:enqueue(self.entity)

			missile:sendMessage("msgChangeSprite", self.stationarySprite)
			missileProp:setLoc(0, 0)
			missileProp:setColor(1, 1, 1, 0)
			missileProp:seekColor(1, 1, 1, 1, 1.7)
		end)
	end

	function i:getMenu()
		return MENU
	end
end)
