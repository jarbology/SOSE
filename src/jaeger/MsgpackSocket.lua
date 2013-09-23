local class = require "jaeger.class"
local socket = require "socket"
local msgpack = require "msgpack"
local MsgpackAccumulator = require "jaeger.MsgpackAccumulator"

-- A socket wrapper which sends and receive Msgpack messages
-- It is an active readable stream + writable stream
return class(..., function(i)
	-- Create a MsgpackSocket from a luasocket
	function i:__constructor(socket)
		assert(socket.send and socket.receive, "Invalid socket")
		self.socket = socket
		self.accumulator = MsgpackAccumulator.new()
	end

	-- Send a msgpack-encodable object
	function i:push(msg)
		local packet = msgpack.pack(msg)

		local socket = self.socket
		-- TODO: non-blocking send
		socket:settimeout(nil)
		return socket:send(packet)
	end

	-- Receive a decoded msgpack message
	function i:pull()
		assert(self:hasData(), "Empty stream")

		return self.accumulator:pull()
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

	-- Private

	function i:handleReceive(pattern, errorMsg, partial)
		if pattern then
			self.accumulator:push(pattern)
		elseif errorMsg == 'timeout' then
			if partial then
				self.accumulator:push(partial)
			end
		else -- TODO: do something
			error(errorMsg)
		end
	end
end)
