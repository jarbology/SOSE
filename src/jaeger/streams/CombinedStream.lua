local class = require "jaeger.Class"

-- A readable stream that returns data from one stream until it's empty
-- and then return data from the other
return class(..., function(i)
	-- stream1: the stream to return data from first
	-- stream2: the stream to return data from second
	function i:__constructor(stream1, stream2)
		self.stream1 = stream1
		self.stream2 = stream2
		self.currentStream = stream1
	end

	function i:update(timeout)
		self.currentStream:update(timeout)
	end

	function i:hasData()
		if self.currentStream:hasData() then
			return true
		elseif self.currentStream == self.stream1 then
			-- switch to stream2
			self.currentStream = self.stream2
			return self.currentStream:hasData()
		else
			return false
		end
	end

	function i:pull()
		return self.currentStream:pull()
	end
end)
