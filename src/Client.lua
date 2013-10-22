local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local PaddedStream = require "jaeger.streams.PaddedStream"
local MemoryStream = require "jaeger.streams.MemoryStream"
local ActionUtils = require "jaeger.utils.ActionUtils"
local StreamUtils = require "jaeger.utils.StreamUtils"

return class(..., function(i)
	-- connection: an active input/output stream
	-- noopMsg: what to send when there is no command
	-- lockedPhase: the locked phase
	-- samplingInterval: how often to sample input
	-- interpreter: a function to execute replicated commands
	-- commandStream: an output stream to push command into
	function i:__constructor(params)
		self.playerId = nil
		self.commandStream = params.commandStream
		self.connection = params.connection
		self.uploadStream = MemoryStream.new()
		self.paddedUploadStream = PaddedStream.new(self.uploadStream, params.noopMsg)
		self.lockedPhase = params.lockedPhase
		self.samplingInterval = params.samplingInterval or 6 --TODO: stop hardcoding this
		self.commandReceived = Event.new()
		self.gameStarted = Event.new()
	end

	function i:sendCmd(cmd)
		self.uploadStream:push(cmd)
	end

	function i:start()
		local action = MOAIStickyAction.new()

		local executionCoro = ActionUtils.newCoroutine(self, "executionCoroutine")
		executionCoro:attach(action)

		self.action = action
		return action
	end

	function i:stop()
		self.action:stop()
	end

	function i:getId()
		return self.playerId
	end

	-- Private
	function i:executionCoroutine()
		local lockedPhase = self.lockedPhase
		local connection = self.connection

		self.playerId = StreamUtils.blockingPull(connection)
		print("Got id: " .. self.playerId .. ". Starting game.")
		local samplingCoro = ActionUtils.newLoopCoroutine(self, "samplingCoroutine")
		samplingCoro:attach(self.action)

		self.gameStarted:fire()

		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_RESET_CLOCK)

		local commandStream = self.commandStream
		local connection = self.connection
		local turnNum = 0
		while true do
			ActionUtils.skipFrames(self.samplingInterval - 1)

			lockedPhase:pause(true)
			turnNum = turnNum + 1
			local commands = StreamUtils.blockingPull(connection)
			local interpretFunc = self.interpretFunc
			for playerId, command in ipairs(commands) do
				self.commandReceived:fire(turnNum, playerId, command)
			end
			lockedPhase:pause(false)
		end
	end

	function i:samplingCoroutine()
		ActionUtils.skipFrames(self.samplingInterval - 1)
		self.connection:push(self.paddedUploadStream:pull())
	end
end)
