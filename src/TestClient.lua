-- Simple test client


local socket = require "socket"
local MsgpackSocket = require "jaeger.MsgpackSocket"

local socket = assert(socket.tcp())
assert(socket:connect("localhost", 9002))
local msgSocket = MsgpackSocket.new(socket)

local function receive()
	-- wait for msg
	while not msgSocket:hasData() do
		msgSocket:update(0)
	end

	return msgSocket:receive()
end

local function receiveGameMsg()
	local sender = receive()
	local message = receive()
	return sender, message
end

local id = receive()

print("Id: "..id)

if id == 1 then
	print "Player 1 sending"
	msgSocket:send(1)
	msgSocket:send(true)
	msgSocket:send(false)
	msgSocket:send(nil)
	msgSocket:send('string')
	msgSocket:send({1, 2, '2'})
	print "Done"
end

print "Waiting for broadcast"
local function assertEqual(expectation, actual)
	assert(expectation == actual, "Expectated "..tostring(expectation).." got "..tostring(actual))
end

local function assertReceive(expectedSender)
	local sender, msg = receiveGameMsg()
	assertEqual(expectedSender, sender)
	return msg
end

assertEqual(1, assertReceive(1))
assertEqual(true, assertReceive(1))
assertEqual(false, assertReceive(1))
assertEqual(nil, assertReceive(1))
assertEqual('string', assertReceive(1))
local table = assertReceive(1)
assertEqual(1, table[1])
assertEqual(2, table[2])
assertEqual('2', table[3])
assertEqual(3, #table)
print "Done"

if id == 2 then
	print "Player 2 sending"
	msgSocket:send({a=2})
	print "Done"
end

print "Waiting for broadcast"
local table = assertReceive(2)
assertEqual(2, table.a)
print "Done"

print "Passed"
