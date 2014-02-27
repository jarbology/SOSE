local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function i:__constructor()
		local viewport = RenderUtils.newFullScreenViewport()
		local background = RenderUtils.newLayer(viewport)
		local GUI = RenderUtils.newLayer(viewport)

		self.renderTable = {
			background,
			GUI
		}
		self.layers = {
			background = background,
			GUI = GUI
		}
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:start(engine, sceneTask)
		local entityMgr = engine:getSystem("jaeger.EntityManager")
		entityMgr:createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		local menu = entityMgr:createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -10 },
			{"jaeger.VerticalContainer", gap=20 }
		}

		local mainMenuButtonTemplate = {
			{"jaeger.Renderable", layer=self.layers.GUI},
			{"jaeger.Widget"},
			{"jaeger.Text", rect={-250, -50, 250, 0},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=40},
		}

		local btnHostGame = entityMgr:createEntity(
			mainMenuButtonTemplate,
			{
				["jaeger.Text"] = { text="Host game" }
			}
		)
		menu:sendMessage("msgAddItem", btnHostGame)

		local btnJoinGame = entityMgr:createEntity(
			mainMenuButtonTemplate,
			{
				["jaeger.Text"] = { text="Join game" }
			}
		)
		menu:sendMessage("msgAddItem", btnJoinGame)

		local btnQuitGame = entityMgr:createEntity(
			mainMenuButtonTemplate,
			{
				["jaeger.Text"] = { text="Quit" }
			}
		)
		menu:sendMessage("msgAddItem", btnQuitGame)
	end

	function i:stop()
	end
end)
