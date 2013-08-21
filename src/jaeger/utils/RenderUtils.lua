local class = require "jaeger.Class"

return class(..., function(i, c)
	function c.newFullScreenLayer()
		local viewport = MOAIViewport.new()
		viewport:setSize(MOAIGfxDevice.getViewSize())
		viewport:setScale(MOAIGfxDevice.getViewSize())
		local layer = MOAILayer2D.new()
		layer:setViewport(viewport)

		return layer
	end
end)
