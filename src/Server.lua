-- Simple blocking server for lockstep game

local socket = require "socket"
local Queue = require "jaeger.Queue"
local MsgpackSocket = require "jaeger.MsgpackSocket"

if select('#', ...) ~= 2 then
	print "Usage: server <port> <numPlayers>"
	return -1
end

local port, numPlayers = ...
numPlayers = assert(tonumber(numPlayers))
port = assert(tonumber(port))

local clientSockets = {}
local clientMsgSockets = {}
local serverSocket = assert(socket.tcp())
assert(serverSocket:bind('*', port))
assert(serverSocket:listen(3))

print("Started server on port: "..port)
local numPlayersJoined = 0

while numPlayersJoined < numPlayers do
	local clientSocket = assert(serverSocket:accept())
	clientSocket:setoption('tcp-nodelay', true)
	numPlayersJoined = numPlayersJoined + 1
	print("Player "..numPlayersJoined.." joined")
	clientSockets[numPlayersJoined] = clientSocket
	clientMsgSockets[numPlayersJoined] = MsgpackSocket.new(clientSocket)
end

print "All clients joined. Starting game"

local function broadcast(msg)
	for playerId, msgSocket in ipairs(clientMsgSockets) do
		msgSocket:send(msg)
	end
end

-- Tell all clients their id
for playerId, msgSocket in ipairs(clientMsgSockets) do
	msgSocket:send(playerId)
end

print "Id broadcasted"

local numSkippedFrames = {0, 0}
while true do
	-- update message
	local msgBuff = {}
	for playerId, msgSocket in ipairs(clientMsgSockets) do
		msgSocket:update(0)
		if msgSocket:hasData() then
			msgBuff[playerId] = msgSocket:receive()
			numSkippedFrames[playerId] = 0
		else
			local playerSkippedFrames = numSkippedFrames[playerId]
			if playerSkippedFrames >= 2 then
				print(playerId, 'pause!')
				repeat
					msgSocket:update(0)
				until msgSocket:hasData()
				msgBuff[playerId] = msgSocket:receive()
			else
				msgBuff[playerId] = 1
				numSkippedFrames[playerId] = playerSkippedFrames + 1
				print (playerId, 'skipped', playerSkippedFrames)
			end
		end
		--[[while not msgSocket:hasData() do
			msgSocket:update(0)
			socket.sleep(0)
		end]]

		--msgBuff[playerId] = msgSocket:receive()
	end
	broadcast(msgBuff)
	socket.sleep(0.05)
end
