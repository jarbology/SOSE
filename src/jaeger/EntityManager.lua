local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local Set = require "jaeger.Set"

local Entity = class("jaeger.Entity", function(i)
	function i:__constructor(spec)
		self.sharedResources = {}
		self.components = {}
		self.spec = spec
	end

	function i:registerResource(name, resource)
		assert(self.sharedResources[name] == nil, "Resource name "..name.." is already registered")
		self.sharedResources[name] = resource
	end

	function i:getResource(name)
		return self.sharedResources[name]
	end

	function i:addComponent(component)
		table.insert(self.components, component)
	end

	function i:getSpec()
		return self.spec
	end

	function i:activate()
		self:sendMessage("activateEntity")
	end

	function i:sendMessage(msg, ...)
		for _, component in ipairs(self.components) do
			local system = component.system
			local messageHandler = system[msg]
			if messageHandler then
				messageHandler(system, component, self, ...)
			end
		end

		for _, component in ipairs(self.components) do
			local system = component.system
			local messageHandler = system.onMessage
			if messageHandler then
				messageHandler(system, component, self, ...)
			end
		end
	end
end)

return class(..., function(i)
	function i:__constructor(config)
		self.entityCreated = Event.new()
		self.namedEntities = {}
		local updatePhaseNames = config.updatePhases
		local updatePhases = {}
		for _, updatePhaseName in ipairs(updatePhaseNames) do
			updatePhases[updatePhaseName] = MOAIAction.new()
		end
		self.updatePhases = updatePhases
		self.updatePhaseNames = updatePhaseNames

		self.destroyedEntities = Set.new()
	end

	function i:start(systems)
	end

	function i:setUpdateTask(methodName, task)
		for _, updatePhaseName in ipairs(self.updatePhaseNames) do
			self.updatePhases[updatePhaseName]:attach(task)
		end
	end

	function i:update()
	end

	function i:cleanUp()
		local destroyedEntities = self.destroyedEntities
		for entity in destroyedEntities:iterator() do
			local updateAction = entity:getResource("updateAction")
			if updateAction then
				updateAction:stop()
			end

			if entity.name then self:unnameEntity(entity) end
			entity:sendMessage("destroyEntity")
			destroyedEntities:remove(entity)
		end
	end

	function i:nameEntity(entity, name)
		entity.name = name
		assert(self.namedEntities[name] == nil, "Another entity with the name '"..name.."' already exists")
		self.namedEntities[name] = entity
	end

	function i:unnameEntity(entity)
		self.namedEntities[entity.name] = nil
		entity.name = nil
	end

	function i:getNamedEntity(name)
		return self.namedEntities[name]
	end

	function i:createEntity(spec)
		local entity = Entity.new(spec)

		local updatePhaseName = spec.updatePhase
		if updatePhaseName then
			local updatePhase = assert(self.updatePhases[updatePhaseName], "Unknown update phase '"..updatePhaseName.."'")
			local updateAction = MOAIAction.new()
			updateAction:attach(updatePhase)
			entity:registerResource("updateAction", updateAction)
		end

		local name = spec.name
		if name then self:nameEntity(entity, name) end

		self.entityCreated:fire(entity, spec)
		entity:activate()
		return entity
	end

	function i:destroyEntity(entity)
		self.destroyedEntities:add(entity)
	end
end)
