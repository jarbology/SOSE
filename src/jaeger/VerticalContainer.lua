local class = require "jaeger.Class"

return class(..., function(i, c)
	local DEFAULT_LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC, MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIColor.INHERIT_COLOR, MOAIColor.COLOR_TRAIT },
		{ MOAIProp2D.INHERIT_VISIBLE, MOAIProp2D.ATTR_VISIBLE },
		{ MOAIProp2D.ATTR_PARTITION, MOAIProp2D.ATTR_PARTITION }
	}

	function i:__constructor(data)
		self.gap = data.gap or 0
		self.nextY = 0
	end

	function i:msgAddItem(item, linkSpec)
		self.entity:sendMessage("msgAttach", item, linkSpec or DEFAULT_LINK_SPEC)
		local prop = assert(item:query("getProp"), "Item does not have a prop")
		prop:setLoc(nil, self.nextY)
		local xMin, yMin, zMin, xMax, yMax, zMax = prop:getBounds()
		self.nextY = self.nextY - (yMax - yMin) - self.gap
	end
end)
