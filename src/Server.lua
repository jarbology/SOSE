local class = require "jaeger.Class"
local Queue = require "jaeger.Queue"
local ActionUtils = require "jaeger.utils.ActionUtils"
local StreamUtils = require "jaeger.utils.StreamUtils"

-- Simple blocking server for lockstep game
return class(..., function(i)
	-- Params:
	-- clientConnectionStream: an active input stream of client sockets (wrapped with MsgpackSocket)
	-- numPlayers: number of players in a game
	-- samplingInterval: how often should server aggregates messages
	-- maxLagTicks: how far can a client lag behind before the game pauses
	-- noopMsg: what to send to clients if a client doesn't send updates
	function i:__constructor(params)
		self.clientConnectionStream = params.clientConnectionStream
		self.numPlayers = params.numPlayers
		self.samplingInterval = params.samplingInterval
		self.maxLagTicks = params.maxLagTicks
		self.noopMsg = params.noopMsg
		self.clientSockets = {}
	end

	-- Spawn and return a coroutine which updates the server
	function i:start()
		local action = ActionUtils.newCoroutine(self, "run")
		self.action = action
		return action
	end

	function i:stop()
		self.action:stop()
	end

	-- Private
	function i:run()
		self:waitForPlayers(self.numPlayers)

		-- Tell all clients their id
		for playerId, msgSocket in ipairs(self.clientSockets) do
			msgSocket:push(playerId)
		end

		print "All clients joined. Starting game"
		self:gameLoop()
	end

	function i:waitForPlayers(numPlayers)
		local numPlayersJoined = 0
		local clientSockets = self.clientSockets

		while numPlayersJoined < numPlayers do
			local clientSocket = StreamUtils.blockingPull(self.clientConnectionStream)
			numPlayersJoined = numPlayersJoined + 1
			print("Player "..numPlayersJoined.." joined")
			clientSockets[numPlayersJoined] = clientSocket
		end
	end

	function i:gameLoop()
		-- Track number of ticks a player lagged
		local numLagTicks = {0, 0}
		local msgBuff = {}
		local samplingGap = self.samplingInterval - 1
		local maxLagTicks = self.maxLagTicks
		local clientSockets = self.clientSockets
		local noopMsg = self.noopMsg

		while true do
			ActionUtils.skipFrames(samplingGap)

			-- aggregate message from all players
			for playerId, msgSocket in ipairs(clientSockets) do
				msgSocket:update(0)
				if msgSocket:hasData() then
					-- when a client sends data, reset numLagTicks to 0
					msgBuff[playerId] = msgSocket:pull()
					numLagTicks[playerId] = 0
				else
					local playerLagTicks = numLagTicks[playerId]
					if playerLagTicks > maxLagTicks then
						-- client lagged for too many ticks, pause the game
						print("Pause to wait for ", playerId)
						msgBuff[playerId] = StreamUtils.blockingPull(msgSocket)
						print("Resumed")
					else
						-- number of lagged ticks is still acceptable, send a noopMsg
						msgBuff[playerId] = noopMsg
						numLagTicks[playerId] = playerLagTicks + 1
					end
				end
			end

			for playerId, msgSocket in ipairs(clientSockets) do
				msgSocket:push(msgBuff)
			end
		end
	end
end)
