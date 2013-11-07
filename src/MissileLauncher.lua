local class = require "jaeger.Class"

return class(..., function(i)
	function i:msgUse(zone, x, y)
		local worldX, worldY = zone:getTileLoc(x, y)
		createEntity{
			{"jaeger.Renderable", layer = zone:getLayer("projectile")},
			{"jaeger.Actor", phase = "missiles"},
			{"jaeger.Sprite", spriteName = "test/rocket"},

			{"Projectile", zone = zone:getId(), x = 1, y = y, grid = "missiles"},
			{"Missile", damage = 2}
		}
	end
end)
