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
		createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		local sceneController = createEntity{
			{"jaeger.InlineScript",
				msgHostGame = function()
					changeScene("scenes.HostGame")
				end,
				msgJoinGame = function()
					changeScene("scenes.JoinGame")
				end,
				msgQuitGame = function()
				end
			}
		}

		local menu = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -10 },
			{"jaeger.VerticalContainer", gap=20 }
		}

		local buttonTemplate = {
			{"jaeger.Renderable", layer=self.layers.GUI, xScale = 1.6, yScale=1.2},
			{"jaeger.Widget", receiver = sceneController},
			{"Button"},
			{"jaeger.StretchPatch", name="dialog"}
		}

		local btnHostGame = createEntity(
			buttonTemplate,
			{
				["Button"] = { message = "msgHostGame" }
			}
		)
		menu:sendMessage("msgAddItem", btnHostGame)

		local btnJoinGame = createEntity(
			buttonTemplate,
			{
				["Button"] = { message = "msgJoinGame" }
			}
		)
		menu:sendMessage("msgAddItem", btnJoinGame)

		local btnQuitGame = createEntity(
			buttonTemplate,
			{
				["Button"] = { message = "msgQuitGame" }
			}
		)
		menu:sendMessage("msgAddItem", btnQuitGame)

		local labelTemplate = {
			{"jaeger.Renderable", layer=self.layers.GUI},
			{"jaeger.Text", rect={-250, -25, 250, 25},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=40},
		}

		local LINK_SPEC = {
			{ MOAIProp2D.INHERIT_LOC,    MOAIProp2D.TRANSFORM_TRAIT }
		}

		local lblHostGame = createEntity(
			labelTemplate,
			{
				["jaeger.Text"] = { text="Host game" },
			}
		)
		btnHostGame:sendMessage("msgAttach", lblHostGame, LINK_SPEC)

		local lblJoinGame = createEntity(
			labelTemplate,
			{
				["jaeger.Text"] = { text="Join game" },
			}
		)
		btnJoinGame:sendMessage("msgAttach", lblJoinGame, LINK_SPEC)

		local lblQuitGame = createEntity(
			labelTemplate,
			{
				["jaeger.Text"] = { text="Quit" },
			}
		)
		btnQuitGame:sendMessage("msgAttach", lblQuitGame, LINK_SPEC)
	end

	function i:stop()
	end
end)
