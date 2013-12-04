local class = require "jaeger.Class"

return class(..., function(i, c)
	function c.newLayer(viewport)
		local layer = MOAILayer2D.new()
		layer:setViewport(viewport or c.newFullScreenViewport())
		return layer
	end

	function c.newFullScreenViewport()
		local viewport = MOAIViewport.new()
		viewport:setSize(MOAIGfxDevice.getViewSize())
		viewport:setScale(MOAIGfxDevice.getViewSize())
		return viewport
	end
end)
