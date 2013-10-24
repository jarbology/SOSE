local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Manage entities which gets updated every frame
-- Relevant config keys:
-- * updatePhases: an array of update phase names
-- Managed component: jaeger.Actor
-- Creation paramter: name of update phase
--
-- Messages:
-- * msgPerformAction(action): perform an action every frame
-- * msgPerformWithDelay(delay, func): call functions after <delay> number of seconds
--	                                   This is in entity's time which means if the entity's update phase is paused,
--	                                   the timer is also paused
-- * msgAddUpdateFunc(obj, methodName, ...): call obj:<methodName>(entity, ...) every frame
--
-- Queries:
-- getUpdateAction(): returns the action that updates the entity
return class(..., function(i, c)
	function i:getUpdatePhase(name)
		return self.updatePhases[name]
	end

	-- Private
	function i:__constructor(config)
		self.updateTreeConfig = config.updatePhases
	end

	function i:start(engine)
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Actor", self, "createActor")
		engine:getSystem("jaeger.SceneManager").sceneEnd:addListener(self, "onSceneEnd")
	end

	function i:createActor(entity, data)
		local updatePhase = assert(
			self.updatePhases[data.phase],
			"Unknown update phase '"..tostring(data.phase).."'"
		)
		local updateAction = MOAIStickyAction.new()
		updateAction:attach(updatePhase)
		return { updateAction = updateAction }
	end

	function i:spawnUpdate()
		local updatePhases = {}
		local rootTask = MOAIStickyAction.new()
		for _, updatePhase in ipairs(self.updateTreeConfig) do
			c.spawnUpdateTree(updatePhase, updatePhases, rootTask)
		end
		self.updatePhases = updatePhases
		self.rootTask = rootTask
		return rootTask
	end

	function i:onSceneEnd()
		for name, updatePhase in pairs(self.updatePhases) do
			updatePhase:clear()
		end
	end 

	function i:msgPerformAction(component, entity, action)
		action:attach(component.updateAction)
	end

	function i:msgPerformWithDelay(component, entity, delay, func)
		local timer = MOAITimer.new()
		timer:setSpan(delay)
		timer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, func)
		timer:attach(component.updateAction)
	end

	function i:msgAddUpdateFunc(component, entity, obj, methodName, ...)
		local action = ActionUtils.newLoopCoroutine(obj, methodName, ...)
		action:attach(component.updateAction)
	end

	function i:msgDestroy(component, entity)
		component.updateAction:stop()
	end

	function c.spawnUpdateTree(treeConfig, updatePhases, rootTask)
		local treeConfigType = type(treeConfig)
		if treeConfigType == "string" then --simple phase
			local updatePhase = MOAIStickyAction.new()
			updatePhases[treeConfig] = updatePhase
			updatePhase:attach(rootTask)
		elseif treeConfigType == "table" then -- tree phase
			local updatePhaseName, childPhases = unpack(treeConfig)
			local updatePhase = MOAIStickyAction.new()
			updatePhases[updatePhaseName] = updatePhase
			updatePhase:attach(rootTask)

			for _, childPhase in ipairs(childPhases) do
				c.spawnUpdateTree(childPhase, updatePhases, updatePhase)
			end
		end
	end

end)
