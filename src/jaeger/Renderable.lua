local class = require "jaeger.Class"

-- Creation parameters:
-- * layer: name of the layer this entity will be rendered in
-- * x (optional)
-- * y (optional)
-- * xScale (optional)
-- * yScale (optional)
-- * rotation (optional)
return class(..., function(i, c)
	function i:__constructor(data)
		local prop = MOAIProp2D.new()
		prop:setLoc(data.x or 0, data.y or 0)
		prop:setScl(data.xScale or 1, data.yScale or 1)
		prop:setRot(data.rotation or 0)
		prop:setBlendMode(MOAIProp2D.GL_SRC_ALPHA, MOAIProp2D.GL_ONE_MINUS_SRC_ALPHA)

		self.prop = prop
		self.layer = assert(data.layer, "No layer specified")
	end

	function i:getProp()
		return self.prop
	end

	function i:msgAttach(child, linkSpec)
		local childProp = assert(child:query("getProp"), "Need a prop to be linked")
		local parent = self.prop

		for _, linkPair in ipairs(linkSpec) do
			local srcAttr, dstAttr = unpack(linkPair)
			childProp:setAttrLink(srcAttr, parent, dstAttr)
		end
	end

	function i:msgActivate()
		local layer = self.layer
		local prop = self.prop
		prop.entity = self.entity
		layer:insertProp(prop)
		prop.layer = layer
	end

	function i:msgDestroy()
		local prop = self.prop
		prop:clearAttrLink(MOAIProp2D.ATTR_PARTITION)
		self.layer:removeProp(prop)
		self.layer = nil
		prop.layer = nil
	end

	function i:getLayer()
		return self.layer
	end
end)
