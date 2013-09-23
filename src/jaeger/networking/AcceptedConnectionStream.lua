local class = require "jaeger.Class"

-- An active readable stream of accepted connections
-- coming from a server socket
return class(..., function(i)
	-- Create the stream
	-- Params:
	-- socket: the underlying socket
	function i:__constructor(socket)
		self.socket = socket
	end

	function i:update(timeout)
		self.socket:settimeout(timeout)
		local clientSkt, errorMsg = self.socket:accept()
		if clientSkt then
			self.clientSkt = clientSkt
		elseif errorMsg ~= "timeout" then
			error(errorMsg)
		end
	end

	function i:hasData()
		return self.clientSkt ~= nil
	end

	function i:pull()
		local result = assert(self.clientSkt, "Pulling from empty stream")
		self.clientSkt = nil
		return result
	end
end)
