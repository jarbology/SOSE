-- A set which allows addition of items during traversal
-- Good for holding a list of event subscribers

local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor()
		self.items = {}
		-- FIXME: WRONG, should be items to be added
		self.removedItems = {}
	end

	function i:add(item)
		self.items[item] = true
		self.removedItems[item] = nil
	end

	function i:remove(item)
		self.removedItems[item] = true -- only mark as removed
	end

	function i:hasItem(item)
		return (not self.removedItems[item]) and self.items[item]
	end

	function i:iterator()
		-- remove marked item
		for removedItem in pairs(self.removedItems) do
			self.items[removedItem] = nil
			self.removedItems[removedItem] = nil
		end

		return pairs(self.items)
	end

	function i:forEach(fun)
		for item in self:iterator() do
			fun(item)
		end
	end
end)
