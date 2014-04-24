describe("GameSearcher", function()
	local GameSearcher
	local ActionUtils
	local sock
	local searcher

	setup(function()
		GameSearcher = require "GameSearcher"
		ActionUtils = require "jaeger.utils.ActionUtils"
		MOAICoroutine = {
			new = function() return MOAICoroutine end,
			run = function() end,
			attach = function() end,
			stop = function() end
		}
		mock(coroutine, true)

		local socket = require "socket"
		sock = assert(socket.udp())
		assert(sock:setsockname("*", 3000))

		searcher = GameSearcher.new(3000)
	end)

	teardown(function()
		sock:close()
		searcher:stop()
		GameSearcher = nil
		ActionUtils = nil
		MOAICoroutine = nil
	end)

	it("works", function()
		searcher:start()
		searcher:update()

		assert.is_not.equal(sock:receivefrom(), nil)
	end)
end)
