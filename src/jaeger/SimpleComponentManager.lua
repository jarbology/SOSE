local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:start(engine, config)
		local componentNames = config.components

		local scriptShortcut = engine:getSystem("jaeger.ScriptShortcut")
		scriptShortcut:enableShortcut(componentNames)

		local entityMgr = engine:getSystem("jaeger.EntityManager")
		for _, componentName in ipairs(componentNames) do
			local componentClass = require(componentName)
			local manager = {
				createComponent = function(self, entity, data)
					local component = componentClass.new(data)
					component.entity = entity
					return component
				end,
				onMessage = function(self, component, entity, msg, ...)
					return c.onMessage(component, msg, ...)
				end,
				onQuery = function(self, component, entity, queryMsg, ...)
					return component[queryMsg](component, ...)
				end,
				canAnswerQuery = function(self, component, queryMsg)
					return component[queryMsg] ~= nil
				end
			}
			entityMgr:registerComponent(componentName, manager, "createComponent")
		end
	end

	function c.onMessage(component, msg, ...)
		local handler = component[msg]
		if handler then
			return handler(component, ...)
		end

		local catchAllHandler = component.onMessage
		if catchAllHandler then
			return catchAllHandler(component, msg, ...)
		end
	end
end)
