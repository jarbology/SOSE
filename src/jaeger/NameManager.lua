local class = require "jaeger.Class"

-- Manage entities with unique names
-- Manages: jaeger.Name
-- Creation parameters: name of the entity
-- Queries:
-- getName(): name of the entity
return class(..., function(i)
	function i:getEntityByName(name)
		return self.nameRegistry[name]
	end

	-- Private
	function i:start(engine)
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Name", self, "createName")
		engine:getSystem("jaeger.SceneManager").sceneEnd:addListener(self, "onSceneEnd")

		self.nameRegistry = {}
	end

	function i:onSceneEnd()
		-- Forget all names after scene ends
		self.nameRegistry = {}
	end

	function i:createName(entity, data)
		local nameRegistry = self.nameRegistry
		assert(nameRegistry[data.name] == nil, "Another entity with the name '"..tostring(data.name).."' already exists")
		nameRegistry[data.name] = entity

		return { name = data.name }
	end

	function i:msgDestroy(component, entity)
		self.nameRegistry[component.name] = nil
	end

	function i:getName(component, entity)
		return component.name
	end
end)
