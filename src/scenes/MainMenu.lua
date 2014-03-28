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
		local sceneMgr = engine:getSystem("jaeger.SceneManager")

		entityMgr:createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		local sceneController = entityMgr:createEntity{
			{"jaeger.InlineScript",
				msgHostGame = function()
					sceneMgr:changeScene("scenes.HostGame")
				end,
				msgJoinGame = function()
					sceneMgr:changeScene("scenes.JoinGame")
				end,
				msgQuitGame = function()
				end
			}
		}

		local menu = entityMgr:createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -10 },
			{"jaeger.VerticalContainer", gap=20 }
		}

		local buttonTemplate = {
			{"jaeger.Renderable", layer=self.layers.GUI},
			{"jaeger.Widget", receiver = sceneController},
			{"Button"},
			{"jaeger.Text", rect={-250, -50, 250, 0},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=40},
		}

		local btnHostGame = entityMgr:createEntity(
			buttonTemplate,
			{
				["jaeger.Text"] = { text="Host game" },
				["Button"] = { message = "msgHostGame" }
			}
		)
		menu:sendMessage("msgAddItem", btnHostGame)

		local btnJoinGame = entityMgr:createEntity(
			buttonTemplate,
			{
				["jaeger.Text"] = { text="Join game" },
				["Button"] = { message = "msgJoinGame" }
			}
		)
		menu:sendMessage("msgAddItem", btnJoinGame)

		local btnQuitGame = entityMgr:createEntity(
			buttonTemplate,
			{
				["jaeger.Text"] = { text="Quit" },
				["Button"] = { message = "msgQuitGame" }
			}
		)
		menu:sendMessage("msgAddItem", btnQuitGame)
	end

	function i:stop()
	end
end)
