local class = require "jaeger.Class"
local msgpack = require "msgpack"
local RenderUtils = require "jaeger.utils.RenderUtils"
local GameSearcher = require "GameSearcher"

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

		local searcher = GameSearcher.new(9001)
		searcher:start(sceneTask)
		searcher.searchStart:addListener(self, "onSearchStart")
		searcher.gameDiscovered:addListener(self, "onGameDiscovered")
		self.searcher = searcher

		entityMgr:createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		local sceneController = entityMgr:createEntity{
			{"jaeger.InlineScript",
				msgBack = function()
					sceneMgr:changeScene("scenes.MainMenu")
				end,
				msgJoinGame = function(state, entity, gameData)
					local params = {
						mode = "join",
						ip = gameData[2]
					}
					changeScene("scenes.BattleScene", params)
				end
			}
		}

		local buttonTemplate = {
			{"jaeger.Renderable", layer=self.layers.GUI},
			{"jaeger.Widget", receiver = sceneController},
			{"Button"},
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

		self.gameList = entityMgr:createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -10 },
			{"jaeger.VerticalContainer", gap=20 }
		}
		self.sceneController = sceneController
	end

	function i:stop()
		self.searcher:stop()
	end

	function i:onGameDiscovered(dataBin, ip, port)
		local success, size, data = pcall(msgpack.unpack, dataBin)
		if success then
			local gameName = data[1]
			self.gameList:sendMessage("msgAddItem",
				createEntity{
					{"jaeger.Renderable", layer=self.layers.GUI},
					{"jaeger.Widget", receiver = self.sceneController},
					{"Button", id = {gameName, ip, port}, message="msgJoinGame"},
					{"jaeger.Text", text=gameName.."-"..ip..":"..tostring(port),
									rect={-250, -50, 250, 0},
									font="karmatic_arcade.ttf",
									alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
									size=20}
				}
			)
		end
	end

	function i:onSearchStart()
		destroyEntity(self.gameList)
		self.gameList = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -10 },
			{"jaeger.VerticalContainer", gap=20 }
		}	
	end
end)
