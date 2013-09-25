local class = require "jaeger.Class"
local Set = require "jaeger.Set"

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

	function i:createName(entity, name)
		local nameRegistry = self.nameRegistry
		assert(nameRegistry[name] == nil, "Another entity with the name '"..name.."' already exists")
		nameRegistry[name] = entity

		return { name = name }
	end

	function i:msgDestroy(component, entity)
		self.nameRegistry[component.name] = nil
	end

	function i:getName(component, entity)
		return component.name
	end
end)
