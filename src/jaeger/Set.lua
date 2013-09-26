local class = require "jaeger.Class"

-- A set which allows addition of items during traversal
-- Good for holding a list of event listeners
return class(..., function(i, c)
	function i:__constructor()
		self.items = {}
		self.numItems = 0
		self.numIterations = 0
		self.indices = {}

		self.deferredItems = {}
		self.deferredOps = {}
		self.numDeferredOps = 0
	end

	-- Add an item to the set
	function i:add(item)
		if self.numIterations > 0 then
			self:defer("add", item)
		else
			self:doAdd(item)
		end
	end

	-- Remove an item from the set
	function i:remove(item)
		if self.numIterations > 0 then
			self:defer("remove", item)
		else
			self:doRemove(item)
		end
	end

	-- MUST BE CALLED BEFORE CALLING iterator()
	-- IF YOU DON'T, I'LL FIND YOU AND KILL YOU
	function i:beginIteration()
		local numIterations = self.numIterations + 1
		self.numIterations = numIterations
	end

	-- MUST BE CALLED BETWEEN beginIteration() and endIteration()
	-- IF YOU DON'T, I'LL FIND YOU AND KILL YOU
	-- A typical loop looks like this:
	-- set:beginIteration()
	-- for index, item in set:iterator() do
	--   doThings(index, item)
	-- end
	-- set:endIteration()
	function i:iterator()
		return ipairs(self.items)
	end

	-- MUST BE CALLED AFTER CALLING iterator()
	-- IF YOU DON'T, I'LL FIND YOU AND KILL YOU
	function i:endIteration()
		local numIterations = self.numIterations - 1
		self.numIterations = numIterations
		if numIterations == 0 then
			self:normalize()
		end
	end

	-- Private
	function i:defer(op, item)
		local numDeferredOps = self.numDeferredOps + 1
		self.deferredOps[numDeferredOps] = op
		self.deferredItems[numDeferredOps] = item
		self.numDeferredOps = numDeferredOps
	end

	function i:normalize()
		local numDeferredOps = self.numDeferredOps
		local deferredOps = self.deferredOps
		local deferredItems = self.deferredItems

		for opIndex = 1, numDeferredOps do
			local op = deferredOps[opIndex]
			if op == "add" then
				self:doAdd(deferredItems[opIndex])
			elseif op == "remove" then
				self:doRemove(deferredItems[opIndex])
			end

			deferredItems[opIndex] = nil
		end

		self.numDeferredOps = 0
	end

	function i:doAdd(item)
		local indices = self.indices
		if indices[item] then return end

		local numItems = self.numItems + 1
		self.items[numItems] = item
		self.indices[item] = numItems
		self.numItems = numItems
	end

	function i:doRemove(item)
		local indices = self.indices
		local removeIndex = indices[item]

		if removeIndex == nil then return end

		local numItems = self.numItems
		local items = self.items
		items[removeIndex] = items[numItems]
		items[numItems] = nil
		indices[item] = nil

		self.numItems = self.numItems - 1
	end
end)
