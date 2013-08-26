local class = require "jaeger.Class"

-- A set which allows addition of items during traversal
-- Good for holding a list of event listeners
return class(..., function(i)
	function i:__constructor()
		self.items = {}
		self.itemsToAdd = {}
	end

	-- Add an item to the set
	function i:add(item)
		self.itemsToAdd[item] = true
	end

	-- Remove an item from the set
	function i:remove(item)
		self.items[item] = nil
		self.itemsToAdd[item] = nil
	end

	-- Check whether the set has an item
	function i:hasItem(item)
		return self.items[item] or self.itemsToAdd[item]
	end

	-- Returns an iterator for a Lua's loop
	-- e.g: for item in set:iterator() do 
	--          --use item
	--      end
	function i:iterator()
		-- add delayed items
		for item in pairs(self.itemsToAdd) do
			self.items[item] = true
			self.itemsToAdd[item] = nil
		end

		return pairs(self.items)
	end
end)
