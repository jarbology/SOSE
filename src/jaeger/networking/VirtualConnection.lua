local class = require "jaeger.Class"
local Queue = require "jaeger.Queue"

-- A virtual connection. More efficient than a local socket connection
return class(..., function(i, c)
	-- Create the pair of connections
	-- Returns: 2 "sockets", one for server, one for client
	
	function c.create()
		local clientSkt = c.new()
		local serverSkt = c.new()
		clientSkt.output = serverSkt.input
		serverSkt.output = clientSkt.input
		return clientSkt, serverSkt
	end

	function i:hasData()
		return not self.input:isEmpty()
	end

	function i:update()
	end

	function i:push(data)
		self.output:enqueue(data)
	end

	function i:pull()
		assert(self:hasData(), "Stream is empty")
		return self.input:dequeue()
	end

	--Private
	function i:__constructor()
		self.input = Queue.new()
	end
end)
