describe("GameAnnouncer", function()
	local GameAnnouncer
	local ActionUtils
	local sock
	local searcher
	local announcer

	setup(function()
		GameAnnouncer = require "GameAnnouncer"
		ActionUtils = require "jaeger.utils.ActionUtils"
		socket = require "socket"
		MOAICoroutine = {
			new = function() return MOAICoroutine end,
			run = function() end,
			attach = function() end,
			stop = function() end
		}
		mock(coroutine, true)

		local socket = require "socket"
		sock = assert(socket.udp())
		assert(sock:setoption('broadcast', true))

		announcer = GameAnnouncer.new(3002)
	end)

	teardown(function()
		announcer:stop()
		sock:close()
		GameAnnouncer = nil
		ActionUtils = nil
		MOAICoroutine = nil
	end)

	it("works", function()
		announcer:start(nil, "Test")
		sock:sendto("?", "255.255.255.255", 3002)
		announcer:update()

		assert.is.equal(sock:receivefrom(), "Test")
	end)
end)
