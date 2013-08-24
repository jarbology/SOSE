local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function c.create(...)
		return c.new(...)
	end

	function i:__constructor(config)
		local defaultLayer = RenderUtil.newFullScreenLayer()
		self.ignore = config
		self.renderTable = {
			defaultLayer
		}

		self.layerMap = {
			default = defaultLayer
		}
	end

	function i:start(engine)
		if self.ignore then return end

		local entityMgr = engine:getSystem("jaeger.EntityManager")
		local entity = entityMgr:createEntity {
			name = "testEntity",
			tags = {"coin", "shit"},
			layer = "default",
			sprite = {
				name = "test/coin",
				autoPlay = "true"
			},
			updatePhase = "gameplay"
		}
		entity:sendMessage("msgPlayAnimation")
	end

	function i:stop()
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:getLayer(name)
		return self.layerMap[name]
	end

end)
