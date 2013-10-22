local class = require "jaeger.Class"

return class(..., function(i)
	function i:msgUse(zone, x, y)
		createEntity{
			{"jaeger.Renderable", layer = zone:getLayer("projectile")},
			{"jaeger.Actor", phase = "missiles"},
			{"jaeger.Sprite", spriteName = "test/missile", autoPlay = true},
			{"GridWalker", zone = zone,
			               gridName = "missiles",
			               x = x,
			               y = y},
			{"Missile", damage = 2}
		}
	end
end)
