local class = require "jaeger.Class"
local Queue = require "jaeger.Queue"

-- A FIFO readable + writable stream
return class(..., function(i)
	function i:__constructor()
		self.queue = Queue.new()
	end

	function i:hasData()
		return not self.queue:isEmpty()
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
