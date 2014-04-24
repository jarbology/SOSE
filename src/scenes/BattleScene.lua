local class = require "jaeger.Class"
local msgpack = require "msgpack"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local NetworkCommand = require "NetworkCommand"
local StringUtils = require "jaeger.utils.StringUtils"
local KeyCodes = require "jaeger.KeyCodes"
local RingMenuUtils = require "RingMenuUtils"
local Property = require "jaeger.Property"
local NetworkCommand = require "NetworkCommand"
local GameAnnouncer = require "GameAnnouncer"
local BuildingType = require "BuildingType"
local Popup = require "Popup"

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

	function i:__constructor(data)
		local viewport = RenderUtils.newFullScreenViewport()
		local GUI = RenderUtils.newLayer(viewport)
		local background = RenderUtils.newLayer(viewport)
		local altGUI = RenderUtils.newLayer(viewport)
		self.renderTable = {
			background,
			{},
			{},
			GUI
		}
		self.layers = {
			background = background,
			GUI = GUI,
			altGUI = altGUI
		}
		self.viewport = viewport

		if type(data) == "string" then
			local mode = data
			self.mode = data

			if mode == "host" then
				local map = 1
				self.announceData = msgpack.pack({"Test game", 1})
			else
				self.hostIP = "localhost"
			end
		else
			local mode = data.mode
			self.mode = mode
			
			if mode == "host" then
				local map = data.map
				self.announceData = msgpack.pack({data.gameName, data.map})
				print(self.announceData)
			else
				self.hostIP = data.ip
			end
		end
	end

	function i:start(engine, sceneTask)
		self:initSim()
		self:initNetwork(engine, sceneTask)
		self:initScene(engine, sceneTask)
	end

	function i:stop()
		if self.announcer then
			self.announcer:stop()
		end

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
			self.serverSkt:close()
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
			self.announcer = GameAnnouncer.new(9001)
			self.announcer:start(sceneTask, self.announceData)
		elseif self.mode == "join" then
			local client = Networking.initJoin(self.hostIP, lockedPhase, noopMsg)
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
		local viewWidth, viewHeight = MOAIGfxDevice.getViewSize()

		local leftHalf = MOAIViewport.new()
		leftHalf:setSize(viewWidth/2, viewHeight)
		leftHalf:setScale(viewWidth/2, viewHeight)
		local homeZone = createEntity{
			{"Zone", map=TEST_MAP, viewport=leftHalf},
			{"HomeZone", client=self.client}
		}
		local homeZoneRenderTable = homeZone:query("getRenderTable")
		function homeZoneRenderTable:hitTest(windowX, windowY)
			return windowX < viewWidth / 2
		end

		local rightHalf = MOAIViewport.new()
		rightHalf:setSize(viewWidth/2, 0, viewWidth, viewHeight)
		rightHalf:setScale(viewWidth/2, viewHeight)
		local enemyZone = createEntity{
			{"Zone", map=TEST_MAP, viewport=rightHalf},
			{"EnemyZone"}
		}
		local enemyZoneRenderTable = enemyZone:query("getRenderTable")
		function enemyZoneRenderTable:hitTest(windowX, windowY)
			return windowX > viewWidth / 2
		end

		self.renderTable[2] = homeZoneRenderTable
		self.renderTable[3] = enemyZoneRenderTable

		homeZone:sendMessage("msgLinkZone", enemyZone)
		enemyZone:sendMessage("msgLinkZone", homeZone)
		homeZone:query("getNumBases").changed:addListener(self, "onNumBasesChanged")
		enemyZone:query("getNumBases").changed:addListener(self, "onNumBasesChanged")
		self.numReadyZones = 0
		self.homeZone = homeZone
		self.enemyZone = enemyZone
		self.zones = {}
		
		--Create Background
		createEntity{
			{"jaeger.Renderable", layer = self.layers.background },
			{"jaeger.Background", texture = "bg1.png", width = 4000, height = 4000}
		}

		--Create GUI
		local sceneGUI = createEntity{{"BattleSceneGUI"}}
		RingMenuUtils.create(engine:getSystem("jaeger.EntityManager"), self.layers.GUI)

		local splitter = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=0, y=576/2, xScale=0.5},
			{"jaeger.Sprite", spriteName="ui/splitter"}
		}

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
		local LINK_SPEC = {
			{ MOAIProp2D.INHERIT_LOC, MOAIProp2D.TRANSFORM_TRAIT }
		}

		local weaponButtons = {}
		local function createWeaponButton(id, iconSprite)
			local button = createEntity{
				{"jaeger.Renderable", layer=self.layers.GUI},
				{"jaeger.Sprite", spriteName="ui/weaponBar"},
				{"jaeger.Widget", receiver=homeZone},
				{"Button", id=id, message="msgSwitchWeapon"}
			}
			local icon = createEntity{
				{"jaeger.Renderable", layer=self.layers.GUI},
				{"jaeger.Sprite", spriteName=iconSprite}
			}
			icon:query("getProp"):setLoc(58, -7)
			button:sendMessage("msgAttach", icon, LINK_SPEC)
			leftBar:sendMessage("msgAddItem", button)

			table.insert(weaponButtons, button)
		end
		self.weaponButtons = weaponButtons

		createWeaponButton("rocket", "ui/weaponIcons/rocket")
		createWeaponButton("robot", "ui/weaponIcons/robot")
		createWeaponButton("rocket2", "ui/weaponIcons/upgradedRocket")
		createWeaponButton("robot2", "ui/weaponIcons/upgradedRobot")

		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=225 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=homeZone:query("getWeaponQueue", "rocket"):getSize(), format="%02d"}
		}
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=171 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=homeZone:query("getWeaponQueue", "robot"):getSize(), format="%02d"}
		}
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=118 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=homeZone:query("getWeaponQueue", "rocket2"):getSize(), format="%02d"}
		}
		createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-515, y=63 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=homeZone:query("getWeaponQueue", "robot2"):getSize(), format="%02d"}
		}

		--Friendly bar
		local lblNumFriendlyBases = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=-90, y=290},
			{"jaeger.Sprite", spriteName="ui/friendlyBar"}
		}
		local txtNumFriendlyBases = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=37, y=-12 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=homeZone:query("getNumBases"), format="%01d"}
		}
		lblNumFriendlyBases:sendMessage("msgAttach", txtNumFriendlyBases, LINK_SPEC)
		--Enemy bar
		local lblNumEnemyBases = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=10, y=290},
			{"jaeger.Sprite", spriteName="ui/enemyBar"}
		}
		local txtNumEnemyBases = createEntity{
			{"jaeger.Renderable", layer=self.layers.GUI, x=37, y=-12 },
			{"jaeger.Text", text="01",
			                rect={0, -25, 35, 0},
			                font="karmatic_arcade.ttf",
			                alignment={MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY},
			                size=11},
			{"jaeger.TextDisplay", property=enemyZone:query("getNumBases"), format="%01d"}
		}
		lblNumEnemyBases:sendMessage("msgAttach", txtNumEnemyBases, LINK_SPEC)

		Popup.init(getSystem("jaeger.EntityManager"), self.layers.GUI)
		Popup.showInfoPopup("Waiting for opponent")

		homeZone:sendMessage("msgSwitchWeapon", "rocket")
	end

	function i:onNumBasesChanged(num)
		if num == 3 then
			self.numReadyZones = self.numReadyZones + 1
			if self.numReadyZones == 2 then
				self.homeZone:sendMessage("msgBattleStart")
			end
		end
	end

	function i:onGameStart()
		Popup.hidePopup()

		local myId = self.client:getId()
		self.zones[myId] = self.homeZone
		self.zones[3 - myId] = self.enemyZone

		--Test
		if self.mode == "combo" then
			self.client2:sendCmd{NetworkCommand.nameToCode("cmdBuild"), BuildingType.nameToCode("interceptor"), 21, 21}
			self.client2:sendCmd{NetworkCommand.nameToCode("cmdBuild"), BuildingType.nameToCode("turret"), 21, 22}
			self.client2:sendCmd{NetworkCommand.nameToCode("cmdBuild"), BuildingType.nameToCode("core"), 21, 24}
			self.client2:sendCmd{NetworkCommand.nameToCode("cmdBuild"), BuildingType.nameToCode("core"), 24, 24}
			self.client2:sendCmd{NetworkCommand.nameToCode("cmdBuild"), BuildingType.nameToCode("core"), 26, 24}
		end
	end

	function i:onCommand(turnNum, playerId, cmd)
		if cmd ~= NetworkCommand.nameToCode("noop") then
			self.zones[playerId]:sendMessage("msgNetworkCommand", unpack(cmd))
		end
	end
end)
