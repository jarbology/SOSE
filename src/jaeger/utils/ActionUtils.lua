local class = require "jaeger.Class"

return class(..., function(i, c)
	-- Create a coroutine that will call obj:methodName(delta, ...) every frame
	function c.newLoopCoroutine(obj, methodName, ...)
		local coro = MOAICoroutine.new()
		local yield = coroutine.yield
		coro:run(function(...)
			while true do
				obj[methodName](obj, yield(), ...)
			end
		end, ...)
		return coro
	end

	function c.skipFrames(n)
		local frameSkipped = 0
		local yield = coroutine.yield
		while frameSkipped < n do
			yield()
			frameSkipped = frameSkipped + 1
		end
	end
end)
