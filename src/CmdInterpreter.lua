local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(config)
	end

	function i:start(engine, config)
	end

	function i:cmdTest(queue, ...)
		print(queue, ...)
	end
end)
