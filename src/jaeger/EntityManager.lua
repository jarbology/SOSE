local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local ActionUtils = require "jaeger.utils.ActionUtils"

local Entity = class("jaeger.Entity", function(i)
	-- Don't call this manually
	-- You can't anyway
	function i:__constructor()
		self.components = {}
		self.alive = true
	end

	-- Send a message to this entity
	function i:sendMessage(msg, ...)
		-- TODO: would the order be indeterministic?
		for _, component in ipairs(self.components) do
			local messageHandler = component[msg]
			if messageHandler then
				messageHandler(component, ...)
			end
		end

		for _, component in ipairs(self.components) do
			local messageHandler = component.onMessage
			if messageHandler then
				messageHandler(component, msg, ...)
			end
		end
	end

	-- Query an entity
	function i:query(queryMsg, ...)
		for _, component in ipairs(self.components) do
			local queryHandler = component[queryMsg]
			if queryHandler then
				return queryHandler(component, ...)
			end
		end
	end

	function i:link(entity)
		local linkedEntities = entity.linkedEntities or {}
		local numLinkedEntities = (entity.numLinkedEntities or 0) + 1
		linkedEntities[numLinkedEntities] = self
		entity.linkedEntities = linkedEntities
		entity.numLinkedEntities = numLinkedEntities
	end

	function i:isAlive()
		return self.alive
	end

	-- Check whether an entity has a component
	function i:hasComponent(componentType)
		return self.components[componentType] ~= nil
	end
end)

-- Manages entities
--
-- Tasks:
-- * cleanup: really destroy entities
return class(..., function(i)
	-- Create an entity using a specification (table)
	function i:createEntity(spec, overrides)
		local entity = Entity.new()
		overrides = overrides or {}
		for index, componentSpec in ipairs(spec) do
			local componentType = componentSpec[1]
			local componentSpecOverride = overrides[componentType] or {}
			for k, v in pairs(componentSpecOverride) do
				componentSpec[k] = v
			end

			self.scriptShortcut:enableShortcut(componentType)
			local componentClass = require(componentType)
			local component = componentClass.new(componentSpec)
			component.entity = entity
			entity.components[index] = component
			entity.components[componentType] = component
		end
		entity:sendMessage("msgActivate")

		return entity
	end

	-- Destroy an entity
	-- An entity is only marked as destroyed. Its destruction is
	-- deferred to the end of the frame
	function i:destroyEntity(entity)
		assert(entity.__class == Entity, "Wrong type")
		if not entity.alive then return end

		entity.alive = false

		local numDestroyedEntities = self.numDestroyedEntities + 1
		self.destroyedEntities[numDestroyedEntities] = entity
		self.numDestroyedEntities = numDestroyedEntities

		-- Also destroy linked entities
		local linkedEntities = entity.linkedEntities
		local numLinkedEntities = entity.numLinkedEntities or 0
		for i = 1, numLinkedEntities do
			self:destroyEntity(linkedEntities[i])
		end
	end

	-- Private
	function i:__constructor(config)
		self.destroyedEntities = {}
		self.numDestroyedEntities = 0
	end

	function i:start(engine, config)
		self.scriptShortcut = engine:getSystem("jaeger.ScriptShortcut")
	end

	function i:spawnCleanUp()
		return ActionUtils.newLoopCoroutine(self, "cleanUp")
	end

	function i:cleanUp()
		local numDestroyedEntities = self.numDestroyedEntities
		local destroyedEntities = self.destroyedEntities
		for i = 1, numDestroyedEntities do
			local entity = destroyedEntities[i]
			entity:sendMessage("msgDestroy")
			destroyedEntities[i] = nil
		end

		self.numDestroyedEntities = 0
	end
end)
