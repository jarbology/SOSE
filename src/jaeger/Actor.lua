local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Creation paramter:
-- * phase: name of update phase
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
	local actorMgr = getSystem "jaeger.ActorManager"

	function i:__constructor(data)
		local updatePhase = assert(
			actorMgr:getUpdatePhase(data.phase),
			"Unknown update phase '"..tostring(data.phase).."'"
		)
		local updateAction = MOAIAction.new()
		updateAction:setAutoStop(false)
		updateAction:attach(updatePhase)
		self.updateAction = updateAction
	end

	function i:msgPerformAction(action)
		action:attach(self.updateAction)
	end

	function i:msgPerformWithDelay(delay, func)
		local timer = MOAITimer.new()
		timer:setSpan(delay)
		timer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, func)
		timer:attach(self.updateAction)
	end

	function i:msgAddUpdateFunc(obj, methodName, ...)
		local action = ActionUtils.newLoopCoroutine(obj, methodName, ...)
		action:attach(self.updateAction)
	end

	function i:msgDestroy()
		self.updateAction:stop()
	end
end)
