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
				msgBack = function()
					sceneMgr:changeScene("scenes.MainMenu")
				end
			}
		}

		local buttonTemplate = {
			{"jaeger.Renderable", layer=self.layers.GUI},
			{"jaeger.Widget"},
			{"Button", receiver = sceneController},
			{"jaeger.Text", rect={0, -50, 250, 0},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.LEFT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=40}
		}

		entityMgr:createEntity(
			buttonTemplate,
			{
				["jaeger.Renderable"] = { x=-1024/2, y=576/2},
				["jaeger.Text"] = { text="Back" },
				["Button"] = { message = "msgBack" }
			}
		)
	end

	function i:stop()
	end
end)
