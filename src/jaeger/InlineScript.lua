local class = require "jaeger.Class"

-- Allow scripts to be put inside an entity specification
-- Only use this for prototyping/demo/GUI scripting
-- Complex scripts should be made into a separate behaviour
return class(..., function(i)
	function i:__constructor(script)
		self.script = script
		self.state = {}
	end

	function i:onMessage(msg, ...) 
		local handler = self.script[msg]
		if handler then
			handler(self.state, self.entity, ...)
		end
	end
end)
