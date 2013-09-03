local class = require "jaeger.class"
local socket = require "socket"
local msgpack = require "msgpack"
local MsgpackAccumulator = require "jaeger.MsgpackAccumulator"

return class(..., function(i)
	function i:__constructor(socket)
		assert(socket.send and socket.receive, "Invalid socket")
		self.socket = socket
		self.accumulator = MsgpackAccumulator.new()
	end

	function i:send(msg)
		local packet = msgpack.pack(msg)

		local socket = self.socket
		-- TODO: non-blocking send
		socket:settimeout(nil)
		return socket:send(packet)
	end

	function i:receive()
		assert(self:hasData(), "Empty stream")

		return self.accumulator:take()
	end

	function i:hasData()
		return self.accumulator:hasData()
	end

	function i:update(timeout)
		-- TODO: handle disconnection
		local socket = self.socket
		socket:settimeout(timeout)

		self:handleReceive(socket:receive())
	end

	function i:handleReceive(pattern, errorMsg, partial)
		if pattern then
			self.accumulator:feed(pattern)
		elseif errorMsg == 'timeout' and partial then
			self.accumulator:feed(partial)
		else -- TODO: do something
		end
	end
end)
