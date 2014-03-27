describe("WeaponQueue", function()
	local WeaponQueue 
	local queue
	local a, b, c
	
	setup(function()
		WeaponQueue = require "WeaponQueue"
	end)

	teardown(function()
		WeaponQueue = nil
	end)

	before_each(function()
		queue = WeaponQueue.new()
		a, b, c = {}, {}, {}
	end)

	after_each(function()
		a, b, c = nil, nil, nil
	end)

	it("has FIFO", function()
		queue:enqueue(a)
		queue:enqueue(b)
		queue:enqueue(c)

		assert.is.equal(a, queue:dequeue())
		queue:enqueue(a)

		assert.is.equal(b, queue:dequeue())
		queue:enqueue(b)

		assert.is.equal(c, queue:dequeue())
		queue:enqueue(c)

		assert.is.equal(a, queue:dequeue())
		assert.is.equal(b, queue:dequeue())
		assert.is.equal(c, queue:dequeue())
	end)

	it("keeps track of size", function()
		local size = queue:getSize()
		assert.is.equal(0, size:get())

		queue:enqueue(a)
		assert.is.equal(1, size:get())

		queue:enqueue(b)
		assert.is.equal(2, size:get())

		queue:enqueue(c)
		assert.is.equal(3, size:get())

		queue:dequeue()
		assert.is.equal(2, size:get())

		queue:dequeue()
		assert.is.equal(1, size:get())

		queue:dequeue()
		assert.is.equal(0, size:get())
	end)

	it("supports random removal", function()
		local size = queue:getSize()
		assert.is.equal(0, size:get())

		queue:enqueue(a)
		assert.is.equal(1, size:get())

		queue:enqueue(b)
		assert.is.equal(2, size:get())

		queue:enqueue(c)
		assert.is.equal(3, size:get())

		queue:remove(b)
		assert.is.equal(2, size:get())

		assert.is.equal(a, queue:dequeue())
		assert.is.equal(c, queue:dequeue())
		assert.is.equal(0, size:get())
	end)
end)
