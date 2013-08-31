local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function c.create(...)
		return c.new(...)
	end

	function i:__constructor()
		local defaultLayer = RenderUtil.newFullScreenLayer()
		self.renderTable = {
			defaultLayer
		}

		self.layerMap = {
			default = defaultLayer
		}
	end

	function i:start(engine)
		local entityMgr = engine:getSystem("jaeger.EntityManager")
		local entity = entityMgr:createEntity {
			name = "testEntity",
			tags = {"coin", "shit"},
			layer = "default",
			sprite = {
				name = "test/coin",
				autoPlay = "true"
			},
			updatePhase = "gui",
			receiveInput = true,
			widgetType = "jaeger.Button",
			script = {
				msgPlayAnimation = function(self, entity)
					print 'start playing anim'
				end,
				msgMouseLeft = function(self, entity, down)
					print('mouseLeft', down)
				end,
				msgGUIHoverIn = function(self, entity)
					entity:sendMessage(
						"msgPlayGUIAnimation",
						entity:getResource("prop"):seekScl(1.2, 1.2, 0.3)
					)
				end,
				msgGUIHoverOut = function(self, entity)
					entity:sendMessage(
						"msgPlayGUIAnimation",
						entity:getResource("prop"):seekScl(1.0, 1.0, 0.3)
					)
				end
			}
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
