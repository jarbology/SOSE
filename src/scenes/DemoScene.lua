local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function c.create(...)
		return c.new(...)
	end

	function i:__constructor(config)
		local defaultLayer = RenderUtil.newFullScreenLayer()
		self.renderTable = {
			defaultLayer
		}

		self.layerMap = {
			default = defaultLayer
		}
	end

	function i:start(systems)
		local entityMgr = systems["jaeger.EntityManager"]
		local entity = entityMgr:createEntity {
			name = "testEntity",
			layer = "default",
			sprite = {
				name = "test/man1_left",
				autoPlay = "true"
			},
			updatePhase = "gameplay"
		}
		entity:sendMessage("playAnimation")
		--entityMgr:destroyEntity(entity)
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
