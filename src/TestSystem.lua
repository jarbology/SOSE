local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(config)
	end

	function i:start(systems)
		local assetManager = systems["jaeger.AssetManager"]
		assetManager:getAsset("sprite:test/man1_down")
	end

	function i:update()
	end

	function i:setUpdateTask(methodName, task)
	end
end)
