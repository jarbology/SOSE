local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local ActionUtils = require "jaeger.utils.ActionUtils"

return class(..., function(i)
	function i:__constructor(port)
		self.port = port
	end

	function i:start(task, gameName)
		local socket = assert(socket.udp())
		assert(socket:setsockname('*', self.port))
		assert(socket:settimeout(0))
		self.socket = socket
		self.gameName = gameName

		local action = ActionUtils.newLoopCoroutine(self, "update")
		action:attach(task)
		self.action = action
	end

	function i:stop()
		self.action:stop()
		self.socket:close()
	end

	function i:update()
		local socket = self.socket
		local data, ip, port = socket:receivefrom()
		if data ~= nil then
			socket:sendto(self.gameName, ip, port)
		end
	end
end)
