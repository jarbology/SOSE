local class = require "jaeger.Class"

-- Launch a missile at the opposing Zone
-- Parameters:
-- * zone: home zone
return class(..., function(i)
	local MENU = {
		{id = "upgrade", sprite = "ui/radialMenu/upgrade"},
		{id = "demolish", sprite = "ui/radialMenu/demolish"}
	}

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

	function i:msgUse(zone, x, y)
		local worldX, worldY = zone:getTileLoc(x, y)
		createEntity{
			{"jaeger.Renderable", layer = zone:getLayer("projectile")},
			{"jaeger.Actor", phase = "missiles"},
			{"jaeger.Sprite", spriteName = "projectiles/rocket"},
			{"Projectile", zone = zone, x = 1, y = y, grid = "missiles"},
			{"Missile", damage = 2}
		}
	end

	function i:getMenu()
		return MENU
	end
end)
