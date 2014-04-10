local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC, MOAIProp2D.TRANSFORM_TRAIT }
	}
	local NAME_LEFT = {"happy", "jolly", "dreamy", "sad", "angry", "pensive", "focused", "sleepy", "grave", "distracted", "determined", "stoic", "stupefied", "sharp", "agitated", "cocky", "tender", "goofy", "furious", "desperate", "hopeful", "compassionate", "silly", "lonely", "condescending", "naughty", "kickass", "drunk", "boring", "nostalgic", "ecstatic", "insane", "cranky", "mad", "jovial", "sick", "hungry", "thirsty", "elegant", "backstabbing", "clever", "trusting", "loving", "suspicious", "berserk", "high", "romantic", "prickly", "evil"}
	local NAME_RIGHT = {"lovelace", "franklin", "tesla", "einstein", "bohr", "davinci", "pasteur", "nobel", "curie", "darwin", "turing", "ritchie", "torvalds", "pike", "thompson", "wozniak", "galileo", "euclid", "newton", "fermat", "archimedes", "poincare", "heisenberg", "feynman", "hawking", "fermi", "pare", "mccarthy", "engelbart", "babbage", "albattani", "ptolemy", "bell", "wright", "lumiere", "morse", "mclean", "brown", "bardeen", "brattain", "shockley", "goldstine", "hoover", "hopper", "bartik", "sammet", "jones", "perlman", "wilson", "kowalevski", "hypatia", "goodall", "mayer", "elion", "blackwell", "lalande", "kirch", "ardinghelli", "colden", "almeida", "leakey", "meitner", "mestorf", "rosalind", "sinoussi", "carson", "mcclintock", "yonath"}

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

		createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		self.sceneController = createEntity{
			{"jaeger.InlineScript",
				msgBack = function()
					changeScene("scenes.MainMenu")
				end,
				msgChangeName = function()
					self.gameName = c.randomName()
					self.lblGameName:sendMessage("msgSetText", self.gameName)
				end,
				msgChangeMap = function(state, entity, id)
					print(id)
					local mapButtons = self.mapButtons
					for _, btn in ipairs(mapButtons) do
						btn:sendMessage("msgChangeSprite", "ui/weaponBar")
					end

					self.mapButtons[id]:sendMessage("msgChangeSprite", "ui/weaponBarActive")
				end
			}
		}

		self:createButton(-420, -250, "Back", "msgBack")
		self:createButton(420, -250, "Start", "msgStart")

		--Window
		local window = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y = -20, xScale = 2.2, yScale=4.5},
			{"jaeger.StretchPatch", name="dialog"}
		}
		local windowPivot = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI}
		}
		window:sendMessage("msgAttach", windowPivot, LINK_SPEC)

		local lbl = self:createLabel(0, 150, "Game name", {-125, -25, 125, 25})
		windowPivot:sendMessage("msgAttach", lbl, LINK_SPEC)

		local btnChangeName = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, y=100, xScale = 1.5, yScale=0.65},
			{"jaeger.Widget", receiver=self.sceneController},
			{"Button", message="msgChangeName"},
			{"jaeger.StretchPatch", name="dialog"}
		}
		local name = c.randomName()
		local label = self:createLabel(0, 0, name, {-125, -25, 125, 25})
		btnChangeName:sendMessage("msgAttach", label, LINK_SPEC)
		windowPivot:sendMessage("msgAttach", btnChangeName, LINK_SPEC)
		self.gameName = name
		self.lblGameName = label

		local lbl = self:createLabel(0, 50, "Map name", {-125, -25, 125, 25})
		windowPivot:sendMessage("msgAttach", lbl, LINK_SPEC)

		--Maps
		local  mapButtons = {}
		local btn = self:createMapBtn(-200, 30, "Lams pam - Small", 1)
		windowPivot:sendMessage("msgAttach", btn, LINK_SPEC)
		mapButtons[1] = btn

		local btn = self:createMapBtn(-200, -28, "Ruidem Dmal - Medium", 2)
		windowPivot:sendMessage("msgAttach", btn, LINK_SPEC)
		mapButtons[2] = btn

		local btn = self:createMapBtn(-200, -86, "Eguh Ecalp - Large", 3)
		windowPivot:sendMessage("msgAttach", btn, LINK_SPEC)
		mapButtons[3] = btn
		self.mapButtons = mapButtons

		self.sceneController:sendMessage("msgChangeMap", 1)

		--MOAIDebugLines.showStyle(MOAIDebugLines.TEXT_BOX)
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

	function i:createMapBtn(x, y, name, mapId)
		local button = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=x, y=y},
			{"jaeger.Widget", receiver=self.sceneController},
			{"Button", message="msgChangeMap", id=mapId},
			{"jaeger.Sprite", spriteName="ui/weaponBar"}
		}

		local lbl = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI},
			{"jaeger.Text", text=name,
			                rect={0, -55, 400, 0},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.CENTER_JUSTIFY},
							size=18}
		}
		button:sendMessage("msgAttach", lbl, LINK_SPEC)

		return button
	end

	function i:stop()
	end

	function c.randomName()
		local left = NAME_LEFT[math.random(#NAME_LEFT)]
		local right = NAME_RIGHT[math.random(#NAME_RIGHT)]
		return left .."-"..right
	end
end)
