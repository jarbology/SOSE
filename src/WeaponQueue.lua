local class = require "jaeger.Class"
local Property = require "jaeger.Property"

return class(..., function(i, c)
	function i:__constructor(idField)
		self.set = {}
		self.lastId = 0
		self.idField = idField or "__queueId"
		self.size = Property.new(0)
	end

	function i:enqueue(item)
		local itemId = self.lastId + 1
		item[self.idField] = itemId
		self.lastId = itemId
		self.size:set(self.size:get() + 1)
		self.set[itemId] = item
	end

	function i:dequeue()
		self.size:set(self.size:get() - 1)
		local set = self.set
		local lowestId = 1/0
		local result
		for _, item in pairs(self.set) do
			local id = item[self.idField]
			if id < lowestId then
				lowestId = id
				result = item
			end
		end

		if result ~= nil then
			self.set[lowestId] = nil
			result[self.idField] = nil
			return result
		end
	end

	function i:remove(item)
		local id = item[self.idField]
		local storedItem = self.set[id]
		if storedItem == item then
			self.set[id] = nil
			item[self.idField] = nil
			self.size:set(self.size:get() - 1)
		end
	end

	function i:getSize()
		return self.size
	end
end)
