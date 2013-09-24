local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Manages the window and sprites (soon will be moved to SpriteManager)
return class(..., function(i)
	-- Private
	function i:start(engine, config)
		local config = config.graphics
		MOAISim.openWindow(config.title, config.windowWidth, config.windowHeight)
	end
end)
