local class = require "jaeger.Class"
local VirtualConnection = require "jaeger.VirtualConnection"
local CmdInterpreter = require "CmdInterpreter"
local socket = require "socket"
local Server = require "Server"
local Client = require "Client"
local AcceptedConnectionStream = require "jaeger.AcceptedConnectionStream"
local MsgpackSocket = require "jaeger.MsgpackSocket"
local CombinedStream = require "jaeger.CombinedStream"
local MappedStream = require "jaeger.MappedStream"
local MemoryStream = require "jaeger.MemoryStream"
local StableStream = require "jaeger.StableStream"
local VoidStream = require "jaeger.VoidStream"

return class(..., function(i, c)
	function c.initHost(lockstepSim, noopMsg)
		-- A host must run both client and server components
		-- "Connect" to the local server using a virtual connection
		local commandStream = StableStream.new(0, 2)
		local client, backwardSkt = c.createLocalClient(lockstepSim, noopMsg, commandStream)
		lockstepSim:setCommandStream(commandStream)

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

	function c.initJoin(lockstepSim, noopMsg)
		local socketConnection = assert(socket.tcp())
		assert(socketConnection:connect("localhost", 9001))

		local commandStream = StableStream.new(0, 2)
		local client = Client.new{
			connection = MsgpackSocket.new(socketConnection),
			lockstepSim = lockstepSim,
			noopMsg = noopMsg,
			commandStream = commandStream
		}
		lockstepSim:setCommandStream(commandStream)

		return client
	end

	function c.initCombo(lockstepSim, noopMsg)
		-- Run 2 clients and server
		local commandStream = StableStream.new(0, 2)
		local client1, backwardSkt1 = c.createLocalClient(lockstepSim, noopMsg, commandStream)
		local client2, backwardSkt2 = c.createLocalClient(lockstepSim, noopMsg, VoidStream.new())
		lockstepSim:setCommandStream(commandStream)

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

	function c.createLocalClient(lockstepSim, noopMsg, commandStream)
		local forwardSkt, backwardSkt = VirtualConnection.create()
		local client = Client.new{
			connection = forwardSkt,
			lockstepSim = lockstepSim,
			commandStream = commandStream,
			noopMsg = noopMsg
		}

		return client, backwardSkt
	end
end)
