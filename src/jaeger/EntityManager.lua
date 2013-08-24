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
		self:sendMessage("msgActivate")
	end
	
	function i:getName() return self.name end

	function i:hasTag(tag)
		return (self.tags ~= nil) and (self.tags[tag] ~= nil)
	end

	function i:getTags()
		return pairs(self.tags)
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
		self.nameRegistry = {}
		self.tagRegistry = {}

		local updatePhaseNames = config.updatePhases
		local updatePhases = {}
		for _, updatePhaseName in ipairs(updatePhaseNames) do
			updatePhases[updatePhaseName] = MOAIStickyAction.new()
		end
		self.updatePhases = updatePhases
		self.updatePhaseNames = updatePhaseNames

		self.destroyedEntities = Set.new()
	end

	function i:start(engine)
		local sceneMgr = engine:getSystem("jaeger.SceneManager")
		sceneMgr.sceneEnd:addListener(self, "onSceneEnd")
	end

	function i:onSceneEnd()
		for name, updatePhase in pairs(self.updatePhases) do
			updatePhase:clear()
		end

		-- Reset named and tagged entities
		self.nameRegistry = {}
		self.tagRegistry = {}
	end 

	function i:getUpdatePhase(name)
		return self.updatePhases[name]
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

			entity:sendMessage("msgDestroy")
			destroyedEntities:remove(entity)
		end
	end

	function i:nameEntity(entity, name)
		local nameRegistry = self.nameRegistry
		entity.name = name
		assert(nameRegistry[name] == nil, "Another entity with the name '"..name.."' already exists")
		nameRegistry[name] = entity
	end

	function i:unnameEntity(entity)
		self.nameRegistry[entity.name] = nil
		entity.name = nil
	end

	function i:getEntityByName(name)
		return self.nameRegistry[name]
	end

	function i:tagEntity(entity, tag)
		local entityTags = entity.tags or {}
		entityTags[tag] = true
		entity.tags = entityTags

		local tagRegistry = self.tagRegistry
		local entitySet = tagRegistry[tag] or Set.new()
		entitySet:add(entity)
		tagRegistry[tag] = entitySet
	end

	function i:untagEntity(entity, tag)
		local entityTags = assert(entity.tags, "Cannot untag an untagged entity")
		entityTags[tag] = nil

		local tagRegistry = self.tagRegistry
		local entitySet = tagRegistry[tag] 
		if entitySet ~= nil then
			entitySet:remove(entity)
		end
	end

	local function nullIterator() end
	function i:getEntitiesByTag(tag)
		local tagRegistry = self.tagRegistry
		local entitySet = tagRegistry[tag]
		if entitySet == nil then
			return nullIterator
		else
			return entitySet:iterator()
		end
	end

	function i:createEntity(spec)
		local entity = Entity.new(spec)

		local updatePhaseName = spec.updatePhase
		if updatePhaseName then
			local updatePhase = assert(self.updatePhases[updatePhaseName], "Unknown update phase '"..updatePhaseName.."'")
			local updateAction = MOAIStickyAction.new()
			updateAction:attach(updatePhase)
			entity:registerResource("updateAction", updateAction)
		end

		local name = spec.name
		if name then self:nameEntity(entity, name) end

		local tags = spec.tags
		if tags then
			for _, tag in ipairs(tags) do
				self:tagEntity(entity, tag)
			end
		end

		self.entityCreated:fire(entity, spec)
		entity:activate()
		return entity
	end

	function i:destroyEntity(entity)
		if entity.name then self:unnameEntity(entity) end
		if entity.tags then
			for tag in pairs(entity.tags) do
				self:untagEntity(entity, tag)
			end
		end
		self.destroyedEntities:add(entity)
	end
end)
