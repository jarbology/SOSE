local class = require "jaeger.Class"
local MsgpackSocket = require "jaeger.MsgpackSocket"
local MemoryStream = require "jaeger.MemoryStream"
local StableStream = require "jaeger.StableStream"
local PaddedStream = require "jaeger.PaddedStream"
local socket = require "socket"

return class(..., function(i)
	function i:__constructor(server)
		local skt = assert(socket.tcp())
		assert(skt:setoption('tcp-nodelay', true))
		assert(skt:connect(server, 9002))
		local msgSocket = MsgpackSocket.new(skt)
		self.msgSocket = msgSocket
		self.playerId = nil
		self.commandStreams = {
			StableStream.new(0, 2),
			StableStream.new(0, 2)
		}
		self.controlStream = MemoryStream.new()
		self.paddedControlStream = PaddedStream.new(self.controlStream, 1)
	end

	function i:getControlStream()
		return self.controlStream
	end

	function i:registerCmdStream(lockstepSim)
		lockstepSim:registerCmdStream(1, self.commandStreams[1])
		lockstepSim:registerCmdStream(2, self.commandStreams[2])
		self.lockstepSim = lockstepSim
	end

	function i:update()
		collectgarbage("step", 0)

		local msgSock = self.msgSocket
		local yield = coroutine.yield

		if self.playerId == nil then
			-- wait for both players to join
			print 'Waiting'
			self.playerId = msgSock:blockingReceive(0)
			print 'Starting'

			self.lockstepSim:pause(false)
			MOAISim.setLoopFlags(MOAISim.SIM_LOOP_RESET_CLOCK)

			self.lockstepSim.sample:addListener(self, "onSample")
		else
			local cmd1, cmd2 = unpack(msgSock:blockingReceive(0))
			self.commandStreams[1]:put(cmd1)
			self.commandStreams[2]:put(cmd2)
		end
	end

	function i:sendCmd()
	end

	function i:onSample()
		self.msgSocket:send(self.paddedControlStream:take())
	end
end)
