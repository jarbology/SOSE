local class = require "jaeger.Class"

-- Can receive mouse input
return class(..., function(i, c)
	function i:__constructor(data)
		self.receiver = data.receiver
	end

	-- Change event receiver
	function i:msgSetEventReceiver(receiver)
		self.receiver = receiver
	end

	-- Dispatch an event to the specified receiver
	function i:msgDispatchGUIEvent(msg, ...)
		local receiver = self.receiver or self.entity
		receiver:sendMessage(msg, ...)
	end
end)
