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
assert(serverSocket:listen())

print("Started server on port: "..port)
local numPlayersJoined = 0

while numPlayersJoined < numPlayers do
	local clientSocket = assert(serverSocket:accept())
	numPlayersJoined = numPlayersJoined + 1
	print("Player "..numPlayersJoined.." joined")
	clientSockets[numPlayersJoined] = clientSocket
	clientMsgSockets[numPlayersJoined] = MsgpackSocket.new(clientSocket)
end

print "All clients joined. Starting game"

local function broadcast(senderId, msg)
	for playerId, msgSocket in ipairs(clientMsgSockets) do
		msgSocket:send(senderId)
		msgSocket:send(msg)
	end
end

-- Tell all clients their id
for playerId, msgSocket in ipairs(clientMsgSockets) do
	msgSocket:send(playerId)
end

print "Id broadcasted"

while true do
	-- update sockets
	for playerId in ipairs(clientSockets) do
		clientMsgSockets[playerId]:update(0)
	end

	-- update message
	for playerId, msgSocket in ipairs(clientMsgSockets) do
		if msgSocket:hasData() then
			local msg = msgSocket:receive()
			print(playerId, msg)
			broadcast(playerId, msg)
		end
	end
end
