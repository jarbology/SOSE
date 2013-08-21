-- A set which allows addition of items during traversal
-- Good for holding a list of event listeners

local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor()
		self.items = {}
		self.itemsToAdd = {}
	end

	function i:add(item)
		self.itemsToAdd[item] = true
	end

	function i:remove(item)
		self.items[item] = nil
		self.itemsToAdd[item] = nil
	end

	function i:hasItem(item)
		return self.items[item] or self.itemsToAdd[item]
	end

	function i:iterator()
		-- add delayed items
		for item in pairs(self.itemsToAdd) do
			self.items[item] = true
			self.itemsToAdd[item] = nil
		end

		return pairs(self.items)
	end
end)
