local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local NetworkCommands = require "NetworkCommands"
local Zone = require "Zone"
local StringUtils = require "jaeger.utils.StringUtils"
local KeyCodes = require "jaeger.KeyCodes"

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

	local BUILD_MENU = {
		{id = "buildMechBay", sprite = "test/robotIcon"},
		{id = "buildRocketLauncher", sprite = "test/rocketLauncherIcon"},
		{id = "buildInterceptor", sprite = "test/interceptorIcon"},
		{id = "buildGenerator", sprite = "test/generatorIcon"},
		{id = "buildFogGenerator", sprite = "test/coreIcon"},
		{id = "buildWall", sprite = "test/coreIcon"}
	}

	function i:__constructor(mode)
		self.mode = mode
		self.currentZone = 1

		local viewport = RenderUtils.newFullScreenViewport()
		local leftZone = Zone.new(TEST_MAP, viewport)
		local rightZone = Zone.new(TEST_MAP, viewport)
		self.zones = { leftZone, rightZone }

		local background = RenderUtils.newLayer(viewport)
		local overlay = RenderUtils.newLayer(viewport)
		self.renderTable = {
			background,
			leftZone:getRenderTable(),
			overlay
		}
		self.layers = {
			overlay = overlay,
			background = background
		}
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
		local noopMsg = NetworkCommands.nameToCode("noop")

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
		local entityMgr = engine:getSystem("jaeger.EntityManager")

		for _, zone in ipairs(self.zones) do
			zone:init(entityMgr)
		end

		local inputMgr = engine:getSystem("jaeger.WidgetManager")
		inputMgr.mouseLeft:addListener(self, "onMouseLeft")
		engine:getSystem("jaeger.InputManager").mouseRight:addListener(self, "onMouseRight")
		engine:getSystem("jaeger.InputManager").keyboard:addListener(self, "onKey")

		if self.mode == "combo" then
			self:cmdBuild(2, "rocketLauncher", 21, 26)
		end

		local resourceTxt = createEntity{
			{"jaeger.Renderable", layer=self.layers.overlay, x=-1024/2 + 20, y=576/2},
			{"jaeger.Text", rect={0, -30, 100, 0}, font="karmatic_arcade.ttf", text="2000", size=20},
		}
		self.zones[1]:getResource().changed:addListener(function(newValue)
			resourceTxt:sendMessage("msgSetText", tostring(newValue))
		end)

		self.ringMenu = createEntity{
			{"jaeger.Renderable", layer = self.layers.overlay },
			{"jaeger.Sprite", spriteName = "test/radialMenu"},
			{"RingMenu",
				radius = 122,
				itemRadius = 35,
				backgroundSprite = "test/radialMenuButton",
				message = "msgItemChosen"
			},
			{"jaeger.InlineScript",
				msgItemChosen = function(component, entity, id)
					self:onItemChosen(id)
				end
			}
		}
	end

	function i:onGameStart()
	end

	function i:onMouseLeft(x, y, down)
		if not down then
			local tileX, tileY = self.zones[1]:wndToTile(x, y)
			self:onTileClicked(tileX, tileY, x, y)
		end
	end

	function i:onMouseRight(x, y, down)
		if not down then
			self.ringMenu:sendMessage("msgHide")
		end
	end

	function i:onTileClicked(...)
		if self.currentZone == 1 then
			return self:onMyTileClicked(...)
		else
			return self:onEnemyTileClicked(...)
		end
	end

	function i:onMyTileClicked(tileX, tileY, wndX, wndY)
		print("Tile:", tileX, tileY)
		local zone = self.zones[1]
		self.currentTileX = tileX
		self.currentTileY = tileY
		if zone:isTileGround(tileX, tileY) then
			local building = zone:getBuildingAt(tileX, tileY)
			local tileWndX, tileWndY = zone:worldToWnd(zone:getTileLoc(tileX, tileY))
			local worldX, worldY = self.layers.overlay:wndToWorld(tileWndX, tileWndY)
			local menu = building == nil and BUILD_MENU or building:query("getMenu")
			self.ringMenu:sendMessage("msgShow", worldX, worldY, menu)
			self.currentBuilding = building
		end
	end

	function i:onEnemyTileClicked(x, y)
		local selectedBuilding = self.selectedBuilding
		if selectedBuilding == nil then return end

		local srcX, srcY = selectedBuilding:query("getTileLoc")
		self:sendCmd("cmdUseBuilding", srcX, srcY, x, y)
	end

	function i:sendCmd(cmdName, ...)
		self.client:sendCmd{NetworkCommands.nameToCode(cmdName), ...}
	end

	function i:cmdBuild(playerId, buildingType, x, y)
		local zoneIndex = self:selectZone(playerId)
		local zone = self.zones[zoneIndex]
		print("Build", buildingType, x, y)

		if zone:isTileGround(x, y) and zone:getBuildingAt(x, y) == nil then
			local building
			if buildingType == "rocketLauncher" then
				zone:changeResource(-100)
				building = createEntity{
					{"jaeger.Actor", phase = "buildings"},
					{"jaeger.Renderable", layer = zone:getLayer("building") },
					{"jaeger.Sprite", spriteName="test/core", autoPlay = true},
					{"Building", zone = zone, x = x, y = y, hp = 5},
					{"MissileLauncher", damage = 2}
				}
			elseif buildingType == "generator" then
				zone:changeResource(-200)
				building = createEntity{
					{"jaeger.Actor", phase = "buildings"},
					{"jaeger.Renderable", layer = zone:getLayer("building") },
					{"jaeger.Sprite", spriteName="test/generator", autoPlay = true},
					{"Building", zone = zone, x = x, y = y, hp = 5},
					{"Generator", yield = 2, interval = 60}
				}
			end

			createEntity{
				{"jaeger.Renderable", layer = zone:getLayer("overlay")},
				{"ProgressBar", width = 44, height = 6, backgroundColor = {1, 0, 0}, foregroundColor = {0, 1, 0}, borderThickness = 1},
				{"HealthBar", subject = building}
			}
		end
	end

	function i:onKey(key, down)
		if not down and key == KeyCodes.SPACE then
			self.currentZone = 3 - self.currentZone
			self.renderTable[2] = self.zones[self.currentZone]:getRenderTable()
		end
	end

	function i:cmdUseBuilding(playerId, buildingX, buildingY, targetX, targetY)
		local zoneIndex = self:selectZone(playerId)
		local zone = self.zones[zoneIndex]
		local building = zone:getBuildingAt(buildingX, buildingY)
		if building == nil then return end

		building:sendMessage("msgUse", self.zones[3 - zoneIndex], targetX, targetY)
	end

	function i:selectZone(playerId)
		return playerId == self.client:getId() and 1 or 2
	end

	function i:onItemChosen(item)
		local handler = assert(self[item], "Unsupported operation: "..item)
		handler(self)
	end

	function i:buildRocketLauncher()
		self:sendCmd("cmdBuild", "rocketLauncher", self.currentTileX, self.currentTileY)
	end

	function i:buildGenerator()
		self:sendCmd("cmdBuild", "generator", self.currentTileX, self.currentTileY)
	end

	function i:attack()
		self.selectedBuilding = self.currentBuilding
	end

	function i:onCommand(turnNum, playerId, cmd)
		if cmd ~= NetworkCommands.nameToCode("noop") then
			return self:invoke(playerId, unpack(cmd))
		end
	end

	function i:invoke(streamId, commandCode, ...)
		return self[NetworkCommands.codeToName(commandCode)](self, streamId, ...)
	end
end)
