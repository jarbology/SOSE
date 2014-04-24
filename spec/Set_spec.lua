describe("Set", function()
	local Set 
	local set
	local a, b, c
	local d, e, f
	local originalOrder
	local newOrder
	
	setup(function()
		Set = require "jaeger.Set"
	end)

	teardown(function()
		Set = nil
	end)

	before_each(function()
		set = Set.new()
		a, b, c = {}, {}, {}
		d, e, f = {}, {}, {}
		originalOrder = {a, b, c}
		newOrder = {d, e, f}
	end)

	after_each(function()
		a, b, c = nil, nil, nil
		d, e, f = nil, nil, nil
		originalOrder = nil
		newOrder = nil
	end)

	it("holds items", function()
		set:add(a)

		set:beginIteration()
		for _, item in set:iterator() do
			assert.is.equal(a, item)
		end
		set:endIteration()
	end)

	it("preserves order", function()
		set:add(a)
		set:add(b)
		set:add(c)

		set:beginIteration()
		for index, item in set:iterator() do
			assert.is.equal(originalOrder[index], item)
		end
		set:endIteration()
	end)

	it("iterates only old elements", function()
		set:add(a)
		set:add(b)
		set:add(c)

		local numItems = 0
		set:beginIteration()
		for index, item in set:iterator() do
			set:add(newOrder[index])
			numItems = numItems + 1
			set:beginIteration()
			for newIndex, newItem in ipairs(newOrder) do
				assert.is_not.equal(newItem, item)
			end
			set:endIteration()
		end
		set:endIteration()

		assert.is.equal(3, numItems)

		numItems = 0

		set:beginIteration()
		for index, item in set:iterator() do
			numItems = numItems + 1

			if index <= 3 then
				assert.is.equal(originalOrder[index], item)
			else
				assert.is.equal(newOrder[index - 3], item)
			end
		end
		set:endIteration()

		assert.is.equal(6, numItems)
	end)

	it("defers removal", function()
		set:add(a)
		set:add(b)
		set:add(c)

		local numItems = 0
		set:beginIteration()
		for index, item in set:iterator() do
			numItems = numItems + 1
			set:remove(b)
			assert.is.equal(originalOrder[index], item)

			if index == 2 then
				assert.is.equal(b, item)
			end
		end
		set:endIteration()

		assert.is.equal(3, numItems)

		numItems = 0
		set:beginIteration()
		for index, item in set:iterator() do
			numItems = numItems + 1
			assert.is_true(item == a or item == c)
		end
		set:endIteration()

		assert.is.equal(2, numItems)
	end)

	it("ignores duplicates", function()
		set:add(a)
		set:add(b)
		set:add(c)
		set:add(a)
		set:add(c)

		local numItems = 0
		for index, item in set:iterator() do
			numItems = numItems + 1
		end

		assert.is.equal(numItems, 3)
	end)

	it("ignores double deletes", function()
		set:add(a)
		set:add(b)
		set:add(c)
		set:remove(a)
		set:remove(a)

		local numItems = 0
		set:beginIteration()
		for index, item in set:iterator() do
			numItems = numItems + 1
			assert.is_true(item == b or item == c)
		end
		set:endIteration()

		assert.is.equal(numItems, 2)
	end)

	it("ignores invalid deletes", function()
		set:add(a)
		set:add(b)
		set:add(c)
		set:remove(d)

		set:beginIteration()
		for index, item in set:iterator() do
			assert.is.equal(originalOrder[index], item)
		end
		set:endIteration()
	end)

	function scanFor(item, obj, path)
		local type = type(obj)
		if type == "table" then
			for k, v in pairs(obj) do
				scanFor(item, k, path.."."..tostring(k))
				scanFor(item, v, path.."."..tostring(v))
			end
		elseif item == object then
			return path
		end
	end

	it("releases removed item", function()
		local collected = false
		item = newproxy(true)
		getmetatable(item).__gc = function() collected = true end
		set:add(item)
		set:beginIteration()
		for index, item in set:iterator() do
			set:remove(item)
		end
		set:endIteration()
		item = nil
		collectgarbage()
		assert.is_true(collected)
	end)

	it("is fast enough", function()
		local start = os.clock()
		for i = 1, 100 do
			set:add(i)
		end
		for i = 1, 100 do
			set:remove(i)
		end
		for i = 1, 100 do
			set:add(i)
		end
		set:beginIteration()
		for index, item in set:iterator() do
			set:add(item)
			set:remove(item)
			set:add(item)
		end
		set:endIteration()
		local finish = os.clock()
		assert.is_true(finish - start < 0.2)
	end)

	it("allows re-addition", function()
		set:add(a)
		set:add(b)
		set:add(c)
		set:remove(a)
		set:add(a)

		local expectedOrder = {c, b, a}

		local size
		set:beginIteration()
		for index, item in set:iterator() do
			size = index
			assert.is.equal(expectedOrder[index], item)
		end
		set:endIteration()

		assert.is.equal(3, size)
	end)

	it("works after removal", function()
		for i = 1, 1000 do
			set:add(i)
			set:remove(i)
		end

		set:add(c)
		for i = 1, 100 do
			set:beginIteration()
			for index, item in set:iterator() do
				assert.is.equal(c, item)
			end
			set:endIteration()
		end
	end)

	it("works with one item", function()
		set:add(b)
		local size = 0
		set:beginIteration()
		for index, item in set:iterator() do
			size = index
		end
		set:endIteration()
		assert.is.equal(1, size)

		set:remove(b)

		local size = 0
		set:beginIteration()
		for index, item in set:iterator() do
			size = index
		end
		set:endIteration()
		assert.is.equal(0, size)

	end)
end)
