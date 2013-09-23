local class = require "jaeger.Class"

return class(..., function(i, c)
	function c.newFullScreenLayer()
		return c.newLayer(MOAIGfxDevice.getViewSize())
	end

	function c.newLayer(width, height)
		local viewport = MOAIViewport.new()
		viewport:setSize(width, height)
		viewport:setScale(width, height)
		local layer = MOAILayer2D.new()
		layer:setViewport(viewport)

		return layer
	end
end)
