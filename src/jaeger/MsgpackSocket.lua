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

	i.put = i.send

	function i:receive()
		assert(self:hasData(), "Empty stream")

		return self.accumulator:take()
	end

	function i:blockingReceive(timeout)
		local yield = coroutine.yield
		while not self:hasData() do
			self:update(timeout)
			yield()
		end

		return self:receive()
	end

	i.take = i.receive

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
			self.accumulator:put(pattern)
		elseif errorMsg == 'timeout' then
			if partial then
				self.accumulator:put(partial)
			end
		else -- TODO: do something
			error(errorMsg)
		end
	end
end)
