local class = require "jaeger.Class"
local PaddedStream = require "jaeger.streams.PaddedStream"
local MemoryStream = require "jaeger.streams.MemoryStream"
local ActionUtils = require "jaeger.utils.ActionUtils"
local StreamUtils = require "jaeger.utils.StreamUtils"

-- Pull data from server
-- Push commands to server based on jaeger.LockstepSim on sample event
return class(..., function(i)
	-- connection: an active input/output stream
	-- noopMsg: what to send when there is no command
	-- lockstepSim: the current lockstepSim
	-- commandStream: an output stream to push command into
	function i:__constructor(params)
		self.playerId = nil
		self.commandStream = params.commandStream
		self.connection = params.connection
		self.uploadStream = MemoryStream.new()
		self.lockstepSim = params.lockstepSim
		self.paddedUploadStream = PaddedStream.new(self.uploadStream, params.noopMsg)
	end

	function i:sendCmd(cmd)
		self.uploadStream:push(cmd)
	end

	function i:start()
		local action = ActionUtils.newCoroutine(self, "run")
		self.action = action
		return action
	end

	function i:stop()
		self.action:stop()
		if self.eventHandle then
			self.lockstepSim.sample:removeListener(self.eventHandle)
		end
	end

	-- Private
	function i:run()
		self.playerId = StreamUtils.blockingPull(self.connection)

		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_RESET_CLOCK)
		self.eventHandle = self.lockstepSim.sample:addListener(self, "onSample")
		self.lockstepSim:startSim()

		local commandStream = self.commandStream
		local connection = self.connection
		while true do
			commandStream:push(StreamUtils.blockingPull(connection))
		end
	end

	function i:onSample()
		self.connection:push(self.paddedUploadStream:pull())
	end
end)