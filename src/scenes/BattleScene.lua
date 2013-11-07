local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local NetworkCommands = require "NetworkCommands"
local Zone = require "Zone"

return class(..., function(i, c)
	-- Private
	function i:__constructor(mode)
		self.mode = mode
		self.renderTable = {}
		self.layerMap = {}

		local zoneParams = {
			map = {
				'o____o',
				'oooooo',
				'o_o__o',
				'o_oooo',
				'o_oooo',
				'o_oooo'
			},
			renderTable = self.renderTable,
			layerMap = self.layerMap
		}

		local width, height = MOAIGfxDevice.getViewSize()
		width = width / 2

		local leftViewport = MOAIViewport.new()
		leftViewport:setSize(0, 0, width, height)
		leftViewport:setScale(width, height)
		zoneParams.suffix = 1
		zoneParams.viewport = leftViewport
		local leftZone = Zone.new(zoneParams)

		local rightViewport = MOAIViewport.new()
		rightViewport:setSize(width, 0, width * 2, height)
		rightViewport:setScale(width, height)
		zoneParams.suffix = 2
		zoneParams.viewport = rightViewport
		local rightZone = Zone.new(zoneParams)

		self.zones = { leftZone, rightZone }
		self.cameras = { leftZone:getCamera(), rightZone:getCamera() }

		self:newRenderPass("overlay", RenderUtils.newFullScreenLayer())
	end

	function i:newRenderPass(name, pass)
		table.insert(self.renderTable, pass)
		self.layerMap[name] = pass
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

	function i:getLayer(name)
		return self.layerMap[name]
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

		local inputSystem = engine:getSystem("jaeger.InputSystem")
		inputSystem.mouseLeft:addListener(self, "onMouseLeft")
		inputSystem.mouseWheel:addListener(self, "onMouseWheel")

		if self.mode == "combo" then
			self:cmdBuild(2, 26, 22)
		end

		self.cameras[1]:setScl(1.7, 1.7)
		self.cameras[2]:setScl(1.7, 1.7)

		MOAIDebugLines.showStyle(MOAIDebugLines.TEXT_BOX)
		MOAIDebugLines.showStyle(MOAIDebugLines.TEXT_BOX_BASELINES)
		MOAIDebugLines.showStyle(MOAIDebugLines.TEXT_BOX_LAYOUT)
		createEntity{
			{"jaeger.Renderable", layer="overlay", x=-1024/2 + 20, y=576/2},
			{"jaeger.Text", rect={0, -30, 100, 0}, font="karmatic_arcade.ttf", text="2000", size=20},
			{"jaeger.InlineScript",
			}
		}
	end

	function i:onGameStart()
	end

	function i:onMouseWheel(x, y, delta)
		print(delta)
		local zoneIndex
		if x < (1024 / 2) then
			zoneIndex = 1
		else
			zoneIndex = 2
		end
		local camera = self.cameras[zoneIndex]
		camera:moveScl(-0.1, -0.1, 0.2)
	end

	function i:onMouseLeft(x, y, down)
		if not down then
			if x < (1024 / 2) then
				self:onTileClicked(1, self.zones[1]:wndToTile(x, y))
			else
				self:onTileClicked(2, self.zones[2]:wndToTile(x, y))
			end
		end
	end

	function i:onTileClicked(zoneId, x, y)
		if zoneId == 1 then
			self:onMyTileClicked(x, y)
		else
			self:onEnemyTileClicked(x, y)
		end
	end

	function i:onMyTileClicked(x, y)
		local zone = self.zones[1]
		if zone:isTileGround(x, y) then
			local building = zone:getBuildingAt(x, y)
		    if building == nil then
				self:sendCmd("cmdBuild", x, y)
			else
				self.selectedBuilding = zone:getBuildingAt(x, y)
			end
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

	function i:cmdBuild(playerId, x, y)
		local zoneIndex = self:selectZone(playerId)
		local zone = self.zones[zoneIndex]

		if zone:isTileGround(x, y) and
		   zone:getBuildingAt(x, y) == nil then
			createEntity{
				{"jaeger.Actor", phase="buildings"},
				{"jaeger.Sprite", spriteName="test/robot1", autoPlay=true},
				{"jaeger.Renderable", layer = "building"..zoneIndex},
				{"Building", zone = zoneIndex, x = x, y = y, hp = 4},
				{"MissileLauncher", damage = 2}
			}
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
		if playerId == self.client:getId() then
			return 1
		else
			return 2
		end
	end

	function i:onCommand(turnNum, playerId, cmd)
		if cmd ~= NetworkCommands.nameToCode("noop") then
			print("Cmd at:", turnNum)
			return self:invoke(playerId, unpack(cmd))
		end
	end

	function i:invoke(streamId, commandCode, ...)
		return self[NetworkCommands.codeToName(commandCode)](self, streamId, ...)
	end
end)
