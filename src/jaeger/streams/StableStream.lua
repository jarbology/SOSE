local class = require "jaeger.Class"
local Queue = require "jaeger.Queue"

return class(..., function(i)
	function i:__constructor(minSize, targetSize)
		self.queue = Queue.new()
		self.minSize = minSize
		self.targetSize = targetSize
		self.skipping = false
	end

	function i:hasData()
		if self.skipping then
			if self.queue:getSize() >= self.targetSize then
				self.skipping = false
				return true
			else
				return false
			end
		else
			if self.queue:getSize() <= self.minSize then
				self.skipping = true
				return false
			else
				return true
			end
		end
	end

	function i:pull()
		return self.queue:dequeue()
	end

	function i:update()
	end

	function i:push(data)
		self.queue:enqueue(data)
	end
end)
