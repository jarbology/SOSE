local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function i:__constructor()
		local defaultLayer = RenderUtil.newLayer()
		defaultLayer:setSortMode(MOAILayer2D.SORT_PRIORITY_ASCENDING)
		self.renderTable = {
			defaultLayer
		}

		self.layerMap = {
			default = defaultLayer
		}
	end

	function i:start(engine)
		local entity = createEntity{
			{"jaeger.Widget"},
			{"jaeger.Name", name="testEntity"},
			{"jaeger.Actor", phase="gui"},
			{"jaeger.Renderable", layer="default", x=40},
			--{"jaeger.Sprite", spriteName="test/coin", autoPlay="true"},
			{"jaeger.Text", rect={-40, -40, 40, 40}, font="karmatic_arcade.ttf", text="Test", size=20},
			{"Button"},
			{"jaeger.InlineScript",
				msgMouseLeft = function(self, entity, ...)
					print('mouseLeft', ...)
				end,
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

		local hp = createEntity{
			{"jaeger.Renderable", layer="default"},
			{"ProgressBar", width = 44, height = 6, backgroundColor = {1, 0, 0}, foregroundColor = {0, 1, 0}, borderThickness = 1}
		}
		hp:sendMessage("msgSetProgress", 0.7)

		local entity3 = createEntity{
			{"jaeger.InlineScript",
				msgDestroy = function(self, entity)
					print('dead2')
				end
			}
		}
		destroyEntity(entity3)

		local menu = createEntity{
			{"jaeger.Renderable", layer = "default"},
			{"jaeger.Widget"},
			{"jaeger.Sprite", spriteName = "test/radialMenu"},
			{"RingMenu",
				radius = 122,
				itemRadius = 35,
				backgroundSprite = "test/radialMenuButton",
				items = {
					{id = "robot", sprite = "test/robotIcon"},
					{id = "interceptor", sprite = "test/coreIcon"},
					{id = "factory", sprite = "test/coreIcon"},
					{id = "robot", sprite = "test/coreIcon"},
					{id = "factory", sprite = "test/coreIcon"}
				}
			}
		}
		menu:sendMessage("msgShow", 0, 0)

		-- This will never be printed
		--entity4:sendMessage("msgPerformWithDelay", 1, function() print("never") end)

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
