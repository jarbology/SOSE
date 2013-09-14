local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"
local CmdInterpreter = require "CmdInterpreter"
local KeyCodes = require "jaeger.KeyCodes"
local NetworkController = require "NetworkController"
local ActionUtils = require "jaeger.utils.ActionUtils"
local MemoryStream = require "jaeger.MemoryStream"
local PaddedStream = require "jaeger.PaddedStream"
local StableStream = require "jaeger.StableStream"

return class(..., function(i, c)
	function i:__constructor(server)
		self.server = server
		local defaultLayer = RenderUtil.newFullScreenLayer()
		self.renderTable = {
			defaultLayer
		}

		self.layerMap = {
			default = defaultLayer
		}
	end

	function i:start(engine)
		MOAISim.clearLoopFlags()
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_ALLOW_SPIN)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_SURPLUS)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_DEFICIT)

		local entityMgr = engine:getSystem("jaeger.EntityManager")
		local lockstepSim = engine:getSystem("jaeger.LockstepSim")
		local spec = {
			layer = "default",
			sprite = {
				name = "test/coin"
			},
			updatePhase = "gamelogic",
			movable = {
				maxSpeedX = 100
			}
		}
		local entity1 = entityMgr:createEntity(spec)
		local entity2 = entityMgr:createEntity(spec)

		local cmdInterpreter = CmdInterpreter.new()
		cmdInterpreter:setPlayerAvatar(entity1, entity2)
		lockstepSim:setInterpreter(function(streamId, cmd)
			cmdInterpreter:execute(streamId, cmd)
		end)
		if self.server == "nil" then
			local controlStream = MemoryStream.new()
			self.controlStream = controlStream

			lockstepSim:pause(false)
			lockstepSim:registerCmdStream(1, PaddedStream.new(controlStream, CmdInterpreter.commandCodes.noop))
			lockstepSim:registerCmdStream(2, PaddedStream.new(MemoryStream.new(), CmdInterpreter.commandCodes.noop))
		else
			local controller = NetworkController.new(self.server)
			self.controlStream = controller:getControlStream()
			ActionUtils.newLoopCoroutine(controller, "update")
			
			controller:registerCmdStream(lockstepSim)
		end

		engine:getSystem("jaeger.InputSystem").keyboard:addListener(self, "onKey")
	end

	function i:onKey(keycode, down)
		if keycode == KeyCodes.LEFT then
			if down then
				self.controlStream:put{CmdInterpreter.commandCodes.cmdMove, -1}
			else
				self.controlStream:put{CmdInterpreter.commandCodes.cmdStop}
			end
		elseif keycode == KeyCodes.RIGHT then
			if down then
				self.controlStream:put{CmdInterpreter.commandCodes.cmdMove, 1}
			else
				self.controlStream:put{CmdInterpreter.commandCodes.cmdStop}
			end
		end
	end

	function i:stop()
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:getLayer(name)
		return self.layerMap[name]
	end

end)
