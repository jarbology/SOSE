local class = require "jaeger.Class"

return class(..., function(i, c)
	c.commandNames = {
		"noop",
		"cmdMove",
		"cmdStop"
	}

	local commandCodes = {}
	for index, name in ipairs(c.commandNames) do
		commandCodes[name] = index
	end
	c.commandCodes = commandCodes

	function i:__constructor(engine, config)
	end

	function i:setPlayerAvatar(player1, player2)
		self.avatars = { player1, player2 }
	end

	-- Private
	function i:execute(streamId, cmd)
		if cmd ~= c.commandCodes.noop then
			return self:invoke(streamId, unpack(cmd))
		end
	end

	function i:invoke(streamId, commandCode, ...)
		return self[c.commandNames[commandCode]](self, streamId, ...)
	end

	-- Cmd implementations
	function i:cmdMove(streamId, direction)
		self.avatars[streamId]:sendMessage("msgSetAccel", 150 * direction)
	end

	function i:cmdStop(streamId)
		self.avatars[streamId]:sendMessage("msgSetAccel", 0)
		self.avatars[streamId]:sendMessage("msgSetVec", 0)
	end
end)
