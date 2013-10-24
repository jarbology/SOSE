local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local ActionUtils = require "jaeger.utils.ActionUtils"
local StreamUtils = require "jaeger.utils.StreamUtils"

return class(..., function(i)
	-- connection: an active input/output stream
	-- noopMsg: what to send when there is no command
	-- lockedPhase: the locked phase
	-- samplingInterval: how often to sample input
	function i:__constructor(params)
		self.playerId = nil
		self.connection = params.connection
		self.lockedPhase = params.lockedPhase
		self.samplingInterval = params.samplingInterval or 6 --TODO: stop hardcoding this
		self.commandReceived = Event.new()
		self.gameStarted = Event.new()
	end

	function i:sendCmd(cmd)
		self.connection:push(cmd)
	end

	function i:start()
		local action = ActionUtils.newCoroutine(self, "run")
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
	function i:run()
		local lockedPhase = self.lockedPhase
		local connection = self.connection

		self.playerId = StreamUtils.blockingPull(connection)
		print("Got id: " .. self.playerId .. ". Starting game.")

		self.gameStarted:fire()

		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_RESET_CLOCK)

		local connection = self.connection
		local turnNum = 0
		while true do
			ActionUtils.skipFrames(self.samplingInterval - 1)

			lockedPhase:pause(true)
			local commands = StreamUtils.blockingPull(connection)
			turnNum = turnNum + 1
			local interpretFunc = self.interpretFunc
			for playerId, command in ipairs(commands) do
				self.commandReceived:fire(turnNum, playerId, command)
			end
			lockedPhase:pause(false)
		end
	end
end)
