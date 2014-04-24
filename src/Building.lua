local class = require "jaeger.Class"
local Property = require "jaeger.Property"

-- Occupies a tile in the Zone's building grid
-- Parameters:
-- * x, y: _grid_ coordinate
return class(..., function(i)
	function i:__constructor(data)
		self.zone = data.zone
		self.x = data.x
		self.y = data.y
		self.healthBarLayer = data.healthBarLayer
	end

	function i:getTileLoc()
		return self.x, self.y
	end

	function i:msgActivate()
		local zone = self.zone
		zone:addBuilding(self.x, self.y, self.entity)
		
		local prop = self.entity:query("getProp")
		prop:setLoc(zone:getTileLoc(self.x, self.y))
		prop:setVisible(zone:isTileVisible(self.x, self.y))
		self.prop = prop

		local healthBar = createEntity{
			{"jaeger.Renderable", layer=self.healthBarLayer, y=-15},
			{"ProgressBar", width=35, height=6, backgroundColor={1, 0, 0}, foregroundColor={0, 1, 0}, borderThickness=1},
			{"HealthBar", subject=self.entity}
		}
		self.healthBarProp = healthBar:query("getProp")
		self.healthBarProp:setVisible(false)
		self.layer = prop.layer
	end

	function i:msgDestroy()
		self.zone:removeBuildingAt(self.x, self.y)

		local x, y = self.prop:getLoc()
		local explosion = createEntity{
			{"jaeger.Renderable", x=x, y=y, layer=self.layer, xScale=1.6, yScale=1.6},
			{"jaeger.Sprite", spriteName="fx/explosionBig", autoPlay=true},
			{"jaeger.Actor", phase="visual"}
		}
		explosion:sendMessage("msgPerformWithDelay", 1.3, function()
			destroyEntity(explosion)
		end)
	end

	function i:msgReveal()
		self.prop:setVisible(true)
	end

	function i:msgFocus()
		self.healthBarProp:setVisible(true)
	end

	function i:msgUnfocus()
		self.healthBarProp:setVisible(false)
	end

	function i:getZone()
		return self.zone
	end
end)
