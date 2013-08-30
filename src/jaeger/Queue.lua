local class = require "jaeger.class"

-- A FIFO container
return class(..., function(i)
	function i:__constructor()
		self.items = {}
		self.head = 1
		self.tail = 1
	end

	-- Enqueue an item
	function i:enqueue(item)
		self.items[self.tail] = item
		self.tail = self.tail + 1
	end

	-- Check whether the queue is empty
	function i:isEmpty()
		return self.head == self.tail
	end

	-- Dequeue an item
	function i:dequeue()
		assert(not self:isEmpty(), "Queue is empty")

		local item = self.items[self.head]

		if self.head + 1 == self.tail then
			-- Reset head and tail to stay in Lua table's optimized part
			-- (refer to "Programming in Lua" for details)
			self.head = 1
			self.tail = 1
		else
			self.head = self.head + 1
		end

		return item
	end

	-- Get the first item without dequeueing
	function i:peek()
		assert(not self:isEmpty(), "Queue is empty")
		return self.items[self.head]
	end

	function i:getSize()
		return self.tail - self.head
	end
end)
