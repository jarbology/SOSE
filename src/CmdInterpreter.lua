local class = require "jaeger.Class"

return class(..., function(i, c)
	c.commandNames = {
		"noop"
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

	function i:getInterpretFunc()
		return function(playerId, cmd)
			return self:execute(playerId, cmd)
		end
	end

	-- Private
	function i:execute(playerId, cmd)
		if cmd ~= c.commandCodes.noop then
			return self:invoke(playerId, unpack(cmd))
		end
	end

	function i:invoke(streamId, commandCode, ...)
		return self[c.commandNames[commandCode]](self, streamId, ...)
	end
end)
