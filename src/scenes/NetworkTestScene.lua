local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local CmdInterpreter = require "CmdInterpreter"

return class(..., function(i, c)
	-- Private
	function i:__constructor(mode)
		self.mode = mode
		local defaultLayer = RenderUtil.newFullScreenLayer()
		self.renderTable = {
			defaultLayer
		}

		self.layerMap = {
			default = defaultLayer
		}
	end

	function i:start(engine, sceneTask)
		MOAISim.clearLoopFlags()
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_ALLOW_SPIN)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_SURPLUS)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_DEFICIT)

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

	function i:stop()
		if self.serverSkt then
			self.serverSkt:shutdown()
		end
	end

	function i:onKey(keycode, down)
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:getLayer(name)
		return self.layerMap[name]
	end
end)
