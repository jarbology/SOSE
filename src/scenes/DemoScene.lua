local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
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
		local entity = createEntity{
			{"jaeger.InputReceiver"},
			{"jaeger.Widget"},
			{"jaeger.Name", name="testEntity"},
			{"jaeger.Actor", phase="gui"},
			{"jaeger.Renderable", layer="default", x=40},
			{"jaeger.Sprite", spriteName="test/coin", autoPlay="true"},
			{"jaeger.InlineScript",
				msgPlayAnimation = function(self, entity)
					print 'start playing anim'
				end,
				msgMouseLeft = function(self, entity, ...)
					print('mouseLeft', ...)
				end,
				msgGUIHoverIn = function(self, entity)
					entity:sendMessage(
						"msgPlayGUIAnimation",
						entity:query("getProp"):seekScl(1.2, 1.2, 0.3)
					)
				end,
				msgGUIHoverOut = function(self, entity)
					entity:sendMessage(
						"msgPlayGUIAnimation",
						entity:query("getProp"):seekScl(1.0, 1.0, 0.3)
					)
				end
			}
		}
		entity:sendMessage("msgPerformWithDelay", 2.5, function() print('timer') end)

		local entity2 = createEntity{
			{"jaeger.InlineScript",
				msgDestroy = function(self, entity)
					print('dead')
				end
			}
		}
		destroyEntity(entity2)

		local entity3 = createEntity{
			{"jaeger.InlineScript",
				msgDestroy = function(self, entity)
					print('dead2')
				end
			}
		}
		destroyEntity(entity3)

		-- This will never be printed
		entity4:sendMessage("msgPerformWithDelay", 1, function() print("never") end)

		-- pausing gameplay phase will pause all of its children
		engine:getSystem("jaeger.ActorManager"):getUpdatePhase("gamelogic"):pause()
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
