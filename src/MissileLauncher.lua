local class = require "jaeger.Class"

return class(..., function(i)
	local MENU = {
		{id = "attack", sprite = "test/attackIcon"},
		{id = "upgrade", sprite = "test/upgradeIcon"},
		{id = "demolish", sprite = "test/demolishIcon"}
	}

	function i:msgUse(zone, x, y)
		local worldX, worldY = zone:getTileLoc(x, y)
		createEntity{
			{"jaeger.Renderable", layer = zone:getLayer("projectile")},
			{"jaeger.Actor", phase = "missiles"},
			{"jaeger.Sprite", spriteName = "test/rocket"},
			{"Projectile", zone = zone, x = 1, y = y, grid = "missiles"},
			{"Missile", damage = 2}
		}
	end

	function i:getMenu()
		return MENU
	end
end)
