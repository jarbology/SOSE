local class = require "jaeger.Class"
local Queue = require "jaeger.Queue"

return class(..., function(i)
	function i:__constructor()
		self.queue = Queue.new()
	end

	function i:hasData()
		return not self.queue:isEmpty()
	end

	function i:take()
		return self.queue:dequeue()
	end

	function i:put(data)
		self.queue:enqueue(data)
	end
end)
