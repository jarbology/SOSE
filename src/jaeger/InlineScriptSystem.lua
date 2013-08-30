local class = require "jaeger.Class"

-- Allow scripts to be put inside an entity specification
-- Only use this for prototyping/demo/GUI scripting
-- Complex scripts should be made into a system
-- Relevant entity specs:
--	* script: a table where each key is a message name and value is the handler
--	  handler will be called as: handler(component, entity, ...)
return class(..., function(i)
	function i:__constructor()
	end

	function i:start(engine)
		self.engine = self.engine
		engine
			:getSystem("jaeger.EntityManager")
			.entityCreated
			:addListener(self, "onEntityCreated")
	end

	function i:onEntityCreated(entity, spec)
		if spec.script then
			local component = setmetatable(
				{
					system = self,
					name = "jaeger.Script",
					engine = self.engine
				},
				{__index = spec.script}
			)
			entity:addComponent(component)
		end
	end

	function i:onMessage(msg, component, entity, ...) 
		local handler = component[msg]
		if handler then
			handler(component, entity, ...)
		end
	end
end)
