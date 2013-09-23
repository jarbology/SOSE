local class = require "jaeger.Class"

-- Collection of functions for stream handling
return class(..., function(i, c)
	-- Block the current action until an active stream returns data
	function c.blockingPull(stream)
		local yield = coroutine.yield

		while not stream:hasData() do
			stream:update(0)
			yield()
		end

		return stream:pull()
	end
end)
