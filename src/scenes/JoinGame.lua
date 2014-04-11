local class = require "jaeger.Class"
local msgpack = require "msgpack"
local RenderUtils = require "jaeger.utils.RenderUtils"
local GameSearcher = require "GameSearcher"

return class(..., function(i, c)
	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC, MOAIProp2D.TRANSFORM_TRAIT }
	}
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
		self.sceneController = sceneController

		local window = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -20, xScale = 3.0, yScale=5.0},
			{"jaeger.StretchPatch", name="dialog"}
		}
		self:createButton(-420, -250, "Back", "msgBack")

		self.gameList = entityMgr:createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = 150 },
			{"jaeger.VerticalContainer", gap=20 }
		}
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
					{"jaeger.Text", text=gameName.."- Small",
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
			{"jaeger.Renderable", layer=self.layers.GUI, y = 150 },
			{"jaeger.VerticalContainer", gap=20 }
		}	
	end

	function i:createButton(x, y, label, message)
		local button = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=x, y=y, xScale = 0.75, yScale=0.75},
			{"jaeger.Widget", receiver=self.sceneController},
			{"Button", message=message},
			{"jaeger.StretchPatch", name="dialog"}
		}
		local label = self:createLabel(0, 0, label)
		button:sendMessage("msgAttach", label, LINK_SPEC)

		return button
	end

	function i:createLabel(x, y, label, rect)
		return createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=x, y=y},
			{"jaeger.Text", text=label,
			                rect=rect or {-75, -25, 75, 25},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY},
			                size=22}
		}
	end
end)
