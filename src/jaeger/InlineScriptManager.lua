local class = require "jaeger.Class"

-- Allow scripts to be put inside an entity specification
-- Only use this for prototyping/demo/GUI scripting
-- Complex scripts should be made into a system
return class(..., function(i)
	function i:start(engine)
		engine
			:getSystem("jaeger.EntityManager")
			:registerComponent("jaeger.InlineScript", self, "createInlineScript")
	end

	function i:createInlineScript(entity, data)
		return setmetatable({},	{__index = data})
	end

	function i:onMessage(msg, component, entity, ...) 
		local handler = component[msg]
		if handler then
			handler(component, entity, ...)
		end
	end
end)
