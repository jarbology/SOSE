local class = require "jaeger.Class"

-- A data grid
-- Indices are 1-based
return class(..., function(i)
	function i:__constructor(width, height)
		self.width = width
		self.height = height
		self.data = {}
	end

	function i:set(x, y, value)
		assert(1 <= x and x <= self.width and 1 <= y and y <= self.height, "Index out of bound")
		self.data[(y - 1) * self.height + x] = value
	end

	function i:get(x, y)
		assert(1 <= x and x <= self.width and 1 <= y and y <= self.height, "Index out of bound")
		return self.data[(y - 1) * self.height + x]
	end
end)
