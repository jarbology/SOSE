local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:__constructor(data)
		local radius = data.radius
		local itemRadius = data.itemRadius
		self.radius = radius
		self.itemRadius = itemRadius
		self.itemDescs = data.items
		self.backgroundSprite = assert(data.backgroundSprite, "No backgroundSprite")
	end

	local linkSpec = {
		{ MOAIProp2D.INHERIT_LOC,    MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIProp2D.INHERIT_COLOR,  MOAIProp2D.COLOR_TRAIT },
		{ MOAIProp2D.ATTR_PARTITION, MOAIProp2D.ATTR_PARTITION },
		{ MOAIProp2D.ATTR_VISIBLE, MOAIProp2D.ATTR_VISIBLE }
	}

	function i:msgActivate()
		local prop = self.entity:query("getProp")
		prop:setPriority(2)
		local layerName = self.entity:query("getLayerName")
		local numItems = #self.itemDescs
		local angleStep = - math.pi * 2 / numItems
		local angle = math.pi / 2
		local radius = self.radius
		for _, itemDesc in ipairs(self.itemDescs) do
			local x = radius * math.cos(angle)
			local y = radius * math.sin(angle)

			local itemBackground = createEntity{
				{"jaeger.Actor", phase = "gui"},
				{"jaeger.Renderable", layer = layerName, x = x, y = y},
				{"jaeger.Sprite", spriteName = self.backgroundSprite},
				{"jaeger.Widget"},
				{"Button"}
			}
			itemBackground:query("getProp"):setPriority(3)
			self.entity:sendMessage("msgLink", itemBackground, linkSpec)

			local item = createEntity{
				{"jaeger.Renderable", layer = layerName},
				{"jaeger.Sprite", spriteName = itemDesc.sprite}
			}
			item:query("getProp"):setPriority(4)
			itemBackground:sendMessage("msgLink", item, linkSpec)

			angle = angle + angleStep
		end

		prop:setVisible(false)

		self.prop = prop
		self.numItems = numItems
	end

	function i:msgShow(x, y)
		local prop = self.prop
		self.prop:setLoc(x, y)
		self.prop:setScl(0)
		prop:setVisible(true)

		self.entity:sendMessage("msgPerformAction", self.prop:seekScl(1, 1, 0.6))
	end

	function i:msgHide()
		prop:setVisible(false)
	end
end)
