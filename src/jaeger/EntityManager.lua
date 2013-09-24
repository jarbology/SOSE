local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local Set = require "jaeger.Set"
local ActionUtils = require "jaeger.utils.ActionUtils"

local Entity = class("jaeger.Entity", function(i)
	-- Don't call this manually
	-- You can't anyway
	function i:__constructor(spec)
		self.sharedResources = {}
		self.components = {}
		self.spec = spec
	end

	-- Register a shared resource.
	-- Should be used by components or systems
	function i:registerResource(name, resource)
		assert(self.sharedResources[name] == nil, "Resource name "..name.." is already registered")
		self.sharedResources[name] = resource
	end

	-- Retrieve a shared resource
	function i:getResource(name)
		return self.sharedResources[name]
	end

	-- Perform an action (attach the action to this entity's updateAction)
	function i:perform(action)
		local updateAction = assert(self.sharedResources.updateAction, "Only active entity can perform actions")
		action:attach(updateAction)
	end

	-- Call a function after an amount of time
	--	* delay: how many seconds to wait before calling the function.
	--	         This is in entity's time which means if the entity's update phase is paused,
	--	         the timer is also paused
	--	* func: a function with signature () -> nil to be called after the delay
	function i:performWithDelay(delay, func)
		local timer = MOAITimer.new()
		timer:setSpan(delay)
		timer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, func)
		self:perform(timer)
	end

	-- Call obj:funcName(delta, entity, ...) every frame
	-- Returns the coroutine which performs the action
	function i:addUpdateFunc(obj, funcName, ...)
		local action = ActionUtils.newLoopCoroutine(obj, funcName, self, ...)
		self:perform(action)
		return action
	end

	-- Get the entity unique name
	function i:getName() return self.name end

	-- Check whether it has a tag
	function i:hasTag(tag)
		return (self.tags ~= nil) and (self.tags[tag] ~= nil)
	end

	-- Get all tags
	function i:getTags()
		return pairs(self.tags)
	end

	-- Send a message to this entity
	function i:sendMessage(msg, ...)
		for _, component in pairs(self.components) do
			local manager = component.manager
			local messageHandler = manager[msg]
			if messageHandler then
				messageHandler(manager, component, self, ...)
			end
		end

		for _, component in pairs(self.components) do
			local manager = component.manager
			local messageHandler = manager.onMessage
			if messageHandler then
				messageHandler(manager, msg, component, self, ...)
			end
		end
	end

	-- Check whether entity has a component
	function i:hasComponent(type)
		return self.components[type] ~= nil
	end
end)

-- Manages entities
-- Relevant config keys:
-- * updatePhases: an array of update phase names
--
-- Special entity specs:
-- * name: an unique name to identify this entity. Only one entity of a given name can exists
-- * tags: an array of tags to identify this entity
-- * updatePhase: name of the phase this entity gets updated
--
-- Tasks:
-- * update: update all entities according to phases
-- * cleanup: really destroy entities
return class(..., function(i)
	function i:__constructor(config)
		self.nameRegistry = {}
		self.tagRegistry = {}
		self.componentFactories = {}

		local updateTask = MOAIStickyAction.new()
		local updatePhaseNames = config.updatePhases
		local updatePhases = {}
		for _, updatePhaseName in ipairs(updatePhaseNames) do
			local updatePhase = MOAIStickyAction.new()
			updatePhases[updatePhaseName] = updatePhase
			updatePhase:attach(updateTask)
		end
		self.updatePhases = updatePhases
		self.updateTask = updateTask

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

	function i:spawnTask(taskName)
		if taskName == "update" then
			return self.updateTask
		elseif taskName == "cleanUp" then
			return ActionUtils.newLoopCoroutine(self, "cleanUp")
		end
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

	-- Assign an unique name to an entity
	function i:nameEntity(entity, name)
		local nameRegistry = self.nameRegistry
		entity.name = name
		assert(nameRegistry[name] == nil, "Another entity with the name '"..name.."' already exists")
		nameRegistry[name] = entity
	end

	-- Remove a name from an entity
	function i:unnameEntity(entity)
		self.nameRegistry[entity.name] = nil
		entity.name = nil
	end

	-- Retrieve an entity by name
	function i:getEntityByName(name)
		return self.nameRegistry[name]
	end

	-- Add a tag to an entity
	function i:tagEntity(entity, tag)
		local entityTags = entity.tags or {}
		entityTags[tag] = true
		entity.tags = entityTags

		local tagRegistry = self.tagRegistry
		local entitySet = tagRegistry[tag] or Set.new()
		entitySet:add(entity)
		tagRegistry[tag] = entitySet
	end

	-- Remove a tag from an entity
	function i:untagEntity(entity, tag)
		local entityTags = assert(entity.tags, "Cannot untag an untagged entity")
		entityTags[tag] = nil

		local tagRegistry = self.tagRegistry
		local entitySet = tagRegistry[tag] 
		if entitySet ~= nil then
			entitySet:remove(entity)
		end
	end

	function i:registerComponent(name, manager, methodName)
		local componentFactories = self.componentFactories
		assert(componentFactories[name] == nil, "Component type "..name.." is already registered")
		componentFactories[name] = {manager, methodName}
		print("Registered component type "..name)
	end

	local function nullIterator() end

	-- Get an iterator to entities associated with a given tag
	-- e.g: for enemy in entityMgr:getEntitiesByTag("enemy") do
	--			-- do something with enemy
	--      end
	function i:getEntitiesByTag(tag)
		local tagRegistry = self.tagRegistry
		local entitySet = tagRegistry[tag]
		if entitySet == nil then
			return nullIterator
		else
			return entitySet:iterator()
		end
	end

	-- Create an entity using a specification (table)
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

		local componentFactories = self.componentFactories
		local componentSpecs = spec.components or {}
		for componentType, componentData in pairs(componentSpecs) do
			if type(componentType) == "number" then
				componentType = componentData 
				componentData = nil
			end
			local factory = assert(componentFactories[componentType], "Unknown component type "..componentType)
			local manager, methodName = unpack(factory)
			local component = manager[methodName](manager, entity, componentData)
			component.manager = manager
			component.type = componentType
			entity.components[componentType] = component
		end

		entity:sendMessage("msgActivate")
		return entity
	end

	-- Destroy an entity
	-- An entity is only marked as destroyed. Its destruction is
	-- deferred to the end of the frame
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
