describe("GameDiscovery", function()
	local GameAnnouncer
	local GameSearcher
	local ActionUtils
	local sock
	local searcher
	local announcer

	setup(function()
		GameAnnouncer = require "GameAnnouncer"
		GameSearcher = require "GameSearcher"
		ActionUtils = require "jaeger.utils.ActionUtils"
		require "socket"
		MOAICoroutine = {
			new = function() return MOAICoroutine end,
			run = function() end,
			attach = function() end,
			stop = function() end
		}
		mock(coroutine, true)

		announcer = GameAnnouncer.new(3003)
		searcher = GameSearcher.new(3003)
	end)

	teardown(function()
		announcer:stop()
		searcher:stop()
		GameAnnouncer = nil
		ActionUtils = nil
		MOAICoroutine = nil
	end)

	it("works", function()
		searcher:start()
		announcer:start(nil, "Test")

		local gameName
		local s = spy.new(function(data) gameName = data end)
		searcher.gameDiscovered:addListener(s)

		searcher:update()
		announcer:update()
		searcher:update()

		assert.spy(s).is.called(1)
		assert.is.equal("Test", gameName)
	end)
end)
