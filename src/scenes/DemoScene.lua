local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function i:__constructor()
		local defaultLayer = RenderUtil.newLayer()
		defaultLayer:setSortMode(MOAILayer2D.SORT_PRIORITY_ASCENDING)
		self.renderTable = {
			defaultLayer
		}

		self.layers = {
			default = defaultLayer
		}
	end

	function i:start(engine)
		--getAsset("stretchPatch:dialog")
		local patch = createEntity{
			{"jaeger.Renderable", layer=self.layers.default},
			{"jaeger.StretchPatch", name="dialog"}
		}
	end

	function i:stop()
	end

	function i:getRenderTable()
		return self.renderTable
	end
end)
