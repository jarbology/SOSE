local class = require "jaeger.Class"
local VirtualConnection = require "jaeger.networking.VirtualConnection"
local CmdInterpreter = require "CmdInterpreter"
local socket = require "socket"
local Server = require "Server"
local Client = require "Client"
local AcceptedConnectionStream = require "jaeger.networking.AcceptedConnectionStream"
local MsgpackSocket = require "jaeger.networking.MsgpackSocket"
local CombinedStream = require "jaeger.streams.CombinedStream"
local MappedStream = require "jaeger.streams.MappedStream"
local MemoryStream = require "jaeger.streams.MemoryStream"
local StableStream = require "jaeger.streams.StableStream"
local VoidStream = require "jaeger.streams.VoidStream"

-- Common functions for setting up networking
return class(..., function(i, c)
	-- Make this game instance the "host"
	function c.initHost(lockedPhase, noopMsg)
		-- A host must run both client and server components
		-- "Connect" to the local server using a virtual connection
		local commandStream = MemoryStream.new()
		local client, backwardSkt = c.createLocalClient(lockedPhase, noopMsg, commandStream)

		local serverSkt = assert(socket.tcp())
		assert(serverSkt:bind("*", 9001))
		serverSkt:listen()
		local localConnectionStream = MemoryStream.new()
		localConnectionStream:push(backwardSkt)
		local clientConnectionStream = 
			CombinedStream.new(
				localConnectionStream,
				MappedStream.new(
					MsgpackSocket.new,
					AcceptedConnectionStream.new(serverSkt)
				)
			)
		local server = c.createServer(clientConnectionStream, noopMsg)

		return client, server, serverSkt
	end

	-- Make this game instance join the game
	function c.initJoin(lockedPhase, noopMsg)
		local socketConnection = assert(socket.tcp())
		assert(socketConnection:connect("localhost", 9001))

		local commandStream = MemoryStream.new()
		local client = Client.new{
			connection = MsgpackSocket.new(socketConnection),
			lockedPhase = lockedPhase,
			noopMsg = noopMsg,
			commandStream = commandStream
		}

		return client
	end

	-- Make this instance both the host and the client 
	function c.initCombo(lockedPhase, noopMsg)
		-- Run 2 clients and server
		local commandStream = MemoryStream.new()
		local client1, backwardSkt1 = c.createLocalClient(lockedPhase, noopMsg, commandStream)
		local client2, backwardSkt2 = c.createLocalClient(lockedPhase, noopMsg, VoidStream.new())

		local localConnectionStream = MemoryStream.new()
		localConnectionStream:push(backwardSkt1)
		localConnectionStream:push(backwardSkt2)
		local server = c.createServer(localConnectionStream, noopMsg)

		return client1, client2, server
	end

	function c.createServer(clientConnectionStream, noopMsg)
		return Server.new{
			clientConnectionStream = clientConnectionStream,
			numPlayers = 2,
			samplingInterval = 6, --TODO: pull from config
			maxLagTicks = 3,
			noopMsg = noopMsg
		}
	end

	function c.createLocalClient(lockedPhase, noopMsg, commandStream)
		local forwardSkt, backwardSkt = VirtualConnection.create()
		local client = Client.new{
			connection = forwardSkt,
			commandStream = commandStream,
			lockedPhase = lockedPhase,
			noopMsg = noopMsg
		}

		return client, backwardSkt
	end
end)
