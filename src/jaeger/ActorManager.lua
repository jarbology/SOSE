local class = require "jaeger.Class"

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
return class(..., function(i)
	function i:getUpdatePhase(name)
		return self.updatePhases[name]
	end

	-- Private
	function i:__constructor(config)
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
	end

	function i:start(engine)
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Actor", self, "createActor")
		engine:getSystem("jaeger.SceneManager").sceneEnd:addListener(self, "onSceneEnd")
	end

	function i:createActor(entity, updatePhaseName)
		local updatePhase = assert(self.updatePhases[updatePhaseName], "Unknown update phase '"..updatePhaseName.."'")
		local updateAction = MOAIStickyAction.new()
		updateAction:attach(updatePhase)
		return { updateAction = updateAction }
	end

	function i:spawnUpdate()
		return self.updateTask
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

	function i:addUpdateFunc(component, entity, obj, methodName, ...)
		local action = ActionUtils.newLoopCoroutine(obj, methodName, entity, ...)
		action:attach(component.updateAction)
	end
end)
