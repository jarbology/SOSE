local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local CmdInterpreter = require "CmdInterpreter"
local Zone = require "Zone"

return class(..., function(i, c)
	-- Private
	function i:__constructor(mode)
		self.mode = mode
		self.renderTable = {}
		self.layerMap = {}

		local zoneParams = {
			zoneWidth = 38,
			zoneHeight = 38,
			map = {
				'o_oooo',
				'oooooo',
				'o_o__o',
				'o_oooo',
				'o__ooo',
				'o__ooo'
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

	function i:onKey(keycode, down)
	end

	function i:initSim()
		MOAISim.clearLoopFlags()
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_ALLOW_SPIN)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_SURPLUS)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_DEFICIT)
	end

	function i:initNetwork(engine, sceneTask)
		local lockstepSim = engine:getSystem("jaeger.LockstepSim")
		local noopMsg = CmdInterpreter.commandCodes.noop
		local cmdInterpreter = CmdInterpreter.new()
		lockstepSim:setInterpreter(cmdInterpreter:getInterpretFunc())

		if self.mode == "host" then
			local client, server, serverSkt = Networking.initHost(lockstepSim, noopMsg)
			client:start():attach(sceneTask)
			server:start():attach(sceneTask)
			self.client = client
			self.server = server
			self.serverSkt = serverSkt
		elseif self.mode == "join" then
			local client = Networking.initJoin(lockstepSim, noopMsg)
			client:start():attach(sceneTask)
			self.client = client
		elseif self.mode == "combo" then
			local client1, client2, server = Networking.initCombo(lockstepSim, noopMsg)
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
	end
end)
