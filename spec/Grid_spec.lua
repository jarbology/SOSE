describe("Set", function()
	local Grid

	setup(function()
		Grid = require "jaeger.Grid"
	end)

	teardown(function()
		Grid = nil
	end)

	it("works", function()
		local grid = Grid.new(2, 2)
		local a = {}
		grid:set(1, 2, a)
		assert.is.equal(a, grid:get(1, 2))
	end)
end)
