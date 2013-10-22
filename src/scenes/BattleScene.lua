local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local Zone = require "Zone"
local BattleGUI = require "BattleGUI"

return class(..., function(i, c)
	c.commandNames = {
		"noop",
		"cmdBuild"
	}

	local commandCodes = {}
	for index, name in ipairs(c.commandNames) do
		commandCodes[name] = index
	end
	c.commandCodes = commandCodes

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
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_ALLOW_SPIN)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_SURPLUS)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_DEFICIT)
	end

	function i:initNetwork(engine, sceneTask)
		local actorMgr = engine:getSystem("jaeger.ActorManager")
		local lockedPhase = assert(actorMgr:getUpdatePhase("gamelogic"))
		local noopMsg = c.commandCodes.noop

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

		self.entityMgr = engine:getSystem("jaeger.EntityManager")
	end

	function i:onGameStart()
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
		self:sendCmd("cmdBuild", x, y)
	end

	function i:onEnemyTileClicked(x, y)
	end

	function i:sendCmd(cmdName, ...)
		self.client:sendCmd{c.commandCodes[cmdName], ...}
	end

	function i:cmdBuild(playerId, x, y)
		local zoneIndex = self:selectZone(playerId)
		local zone = self.zones[zoneIndex]

		if zone:isTileGround(x, y) and zone:getBuildingAt(x, y) == nil then
			self.entityMgr:createEntity{
				["jaeger.Actor"] = "gamelogic",
				["jaeger.Sprite"] = {
					spriteName = "test/coin",
					autoPlay = true
				},

				["jaeger.Renderable"] = {
					layer = "building"..zoneIndex
				},

				["Building"] = {
					zone = zoneIndex,
					x = x,
					y = y
				}
			}

			if playerId == self.client:getId() then
				print("I build at ", x, y)
			else
				print("Enemy build at ", x, y)
			end
		end
	end

	function i:selectZone(playerId)
		if playerId == self.client:getId() then
			return 1
		else
			return 2
		end
	end

	function i:onCommand(turnNum, playerId, cmd)
		if cmd ~= c.commandCodes.noop then
			print("Cmd at:", turnNum)
			return self:invoke(playerId, unpack(cmd))
		end
	end

	function i:invoke(streamId, commandCode, ...)
		return self[c.commandNames[commandCode]](self, streamId, ...)
	end
end)
