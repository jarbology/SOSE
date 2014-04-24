local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local ActionUtils = require "jaeger.utils.ActionUtils"

return class(..., function(i)
	function i:__constructor(port)
		self.port = port
		self.searchStart = Event.new()
		self.gameDiscovered = Event.new()
	end

	function i:start(task)
		local socket = assert(socket.udp())
		assert(socket:settimeout(0))
		assert(socket:setoption('broadcast', true))
		self.socket = socket

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
			self.gameDiscovered:fire(data, ip, port)
		end
		socket:sendto("?", "255.255.255.255", self.port)
		ActionUtils.skipFrames(60)
		self.searchStart:fire()
	end
end)
