describe("Event", function()
	local Event

	setup(function()
		Event = require "jaeger.Event"
	end)

	teardown(function()
		Event = nil
	end)

	it("works", function()
		local event = Event.new()
		local s = spy.new(function(...) end)
		event:addListener(s)
		local obj = {}
		function obj:method(...) end
		stub(obj, "method")
		local listener = event:addListener(obj, "method")

		local a = {}
		event:fire(1, 2, a)

		event:removeListener(s)
		event:fire(3, 4, 5)

		event:removeListener(listener)
		event:fire(6, 7, 8)
		
		assert.stub(obj.method).was.called(2)
		assert.stub(obj.method).was.called_with(obj, 1, 2, a)
		assert.stub(obj.method).was.called_with(obj, 3, 4, 5)

		assert.stub(s).was.called(1)
		assert.spy(s).was.called_with(1, 2, a)
	end)
end)
