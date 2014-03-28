local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local NetworkCommand = require "NetworkCommand"
local StringUtils = require "jaeger.utils.StringUtils"
local KeyCodes = require "jaeger.KeyCodes"
local RingMenuUtils = require "RingMenuUtils"
local Property = require "jaeger.Property"
local NetworkCommand = require "NetworkCommand"
local BuildingType = require "BuildingType"

return class(..., function(i, c)

	-- Private
	local TEST_MAP = {
		'o____oooo_',
		'oooooo____',
		'o_o__ooooo',
		'o_ooooooo_',
		'o_oooo__o_',
		'o_oooooooo'
	}

	function i:__constructor(mode)
		local viewport = RenderUtils.newFullScreenViewport()
		local GUI = RenderUtils.newLayer(viewport)
		local background = RenderUtils.newLayer(viewport)
		self.renderTable = {
			background,
			{},
			GUI
		}
		self.layers = {
			background = background,
			GUI = GUI
		}
		self.viewport = viewport

		self.mode = mode
	end

	function i:start(engine, sceneTask)
		self:initSim()
		self:initNetwork(engine, sceneTask)
		self:initScene(engine, sceneTask)
	end

	function i:stop()
		if self.server then
			self.server:stop()
		end

		if self.client then
			self.client:stop()
		end

		if self.client2 then
			self.client2:stop()
		end

		if self.serverSkt then
			self.serverSkt:shutdown()
		end
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:getZone(index)
		return self.zones[index]
	end

	function i:initSim()
		MOAISim.clearLoopFlags()
		MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED)
	end

	function i:initNetwork(engine, sceneTask)
		local actorMgr = engine:getSystem("jaeger.ActorManager")
		local lockedPhase = assert(actorMgr:getUpdatePhase("gamelogic"))
		local noopMsg = NetworkCommand.nameToCode("noop")

		if self.mode == "host" then
			local client, server, serverSkt = Networking.initHost(lockedPhase, noopMsg)
			client.commandReceived:addListener(self, "onCommand")
			client.gameStarted:addListener(self, "onGameStart")
			client:start():attach(sceneTask)
			server:start():attach(sceneTask)
			self.client = client
			self.server = server
			self.serverSkt = serverSkt
		elseif self.mode == "join" then
			local client = Networking.initJoin(lockedPhase, noopMsg)
			client.gameStarted:addListener(self, "onGameStart")
			client.commandReceived:addListener(self, "onCommand")
			client:start():attach(sceneTask)
			self.client = client
		elseif self.mode == "combo" then
			local client1, client2, server = Networking.initCombo(lockedPhase, noopMsg)
			client1.commandReceived:addListener(self, "onCommand")
			client1.gameStarted:addListener(self, "onGameStart")
			client1:start():attach(sceneTask)
			client2:start():attach(sceneTask)
			server:start():attach(sceneTask)
			self.client = client1
			self.client2 = client2
			self.server = server
		end
	end

	function i:initScene(engine, sceneTask)
		--Create zones
		local homeZone = createEntity{
			{"Zone", map=TEST_MAP, viewport=self.viewport},
			{"HomeZone", client=self.client}
		}
		local enemyZone = createEntity{
			{"Zone", map=TEST_MAP, viewport=self.viewport},
			{"EnemyZone"}
		}
		homeZone:sendMessage("msgLinkZone", enemyZone)
		enemyZone:sendMessage("msgLinkZone", homeZone)
		self.zoneRenderTables = { homeZone:query("getRenderTable"), enemyZone:query("getRenderTable") }
		self.homeZone = homeZone
		self.enemyZone = enemyZone
		self.zones = {}
		self:switchZone(1)

		--Create Background
		createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		--Create GUI
		local sceneGUI = createEntity{{"BattleSceneGUI"}}
		RingMenuUtils.create(engine:getSystem("jaeger.EntityManager"), self.layers.GUI)

		local leftBar = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-512, y=288 },
			{"jaeger.VerticalContainer", gap=0 }
		}

		--Resource count
		leftBar:sendMessage("msgAddItem",
			createEntity{
				{"jaeger.Renderable", layer=self.layers.GUI, x=-512, y=288},
				{"jaeger.Sprite", spriteName="ui/resourceBar"}
			}
		)

		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-480, y=279 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 75, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=18},
			{"jaeger.TextDisplay", property=homeZone:query("getResource"), format="%03d"}
		}
		
		--Weapon buttons
		for i = 1, 4 do
			leftBar:sendMessage("msgAddItem",
				createEntity{
					{"jaeger.Renderable", layer=self.layers.GUI},
					{"jaeger.Sprite", spriteName="ui/weaponBar"}
				}
			)
		end

		local dummyProperty = Property.new(0)
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=224 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=homeZone:query("getWeaponQueue", "rocket"):getSize(), format="%02d"}
		}
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=174 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=dummyProperty, format="%02d"}
		}
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=124 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=dummyProperty, format="%02d"}
		}
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=74 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=dummyProperty, format="%02d"}
		}

		--Friendly bar
		leftBar:sendMessage("msgAddItem",
			createEntity{
				{"jaeger.Renderable", layer=self.layers.GUI},
				{"jaeger.Sprite", spriteName="ui/friendlyBar"}
			}
		)
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-474, y=30 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=dummyProperty, format="%01d"}
		}
		--Enemy bar
		leftBar:sendMessage("msgAddItem",
			createEntity{
				{"jaeger.Renderable", layer=self.layers.GUI},
				{"jaeger.Sprite", spriteName="ui/enemyBar"}
			}
		)
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-474, y=-19 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=dummyProperty, format="%01d"}
		}
		--Switch button
		leftBar:sendMessage("msgAddItem",
			createEntity{
				{"jaeger.Renderable", layer=self.layers.GUI},
				{"jaeger.Sprite", spriteName="ui/friendlyBar"},
				{"jaeger.Widget", receiver=sceneGUI},
				{"Button", message="msgSwitchZone"}
			}
		)
	end

	function i:onGameStart()
		local myId = self.client:getId()
		self.zones[myId] = self.homeZone
		self.zones[3 - myId] = self.enemyZone

		--Test
		if self.mode == "combo" then
			self.client2:sendCmd{NetworkCommand.nameToCode("cmdBuild"), BuildingType.nameToCode("interceptor"), 21, 21}
		end
	end

	function i:switchZone(index)
		self.renderTable[2] = self.zoneRenderTables[index]
	end

	function i:onCommand(turnNum, playerId, cmd)
		if cmd ~= NetworkCommand.nameToCode("noop") then
			self.zones[playerId]:sendMessage("msgNetworkCommand", unpack(cmd))
		end
	end
end)
