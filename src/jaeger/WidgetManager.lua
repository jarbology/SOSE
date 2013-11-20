local class = require "jaeger.Class"

-- Manages jaeger.Widget
-- Messages:
--
-- Passive:
-- * msgPlayGUIAnimation(anim): Attach an animation to the entity's updateAction.
--   If there is already an animation playing, it will be cancelled. Useful for GUI effects.
--
-- Active:
-- * msgGUIHoverIn(x, y): Delivered when mouse hovers into this widget. x and y are mouse position
--   in world coordinate
-- * msgGUIHoverOut(x, y): Delivered when mouse hovers out of this widget.
return class(..., function(i, c)
	-- Deliver subsequent mouse events to this entity regardless of mouse position
	-- Returns whether the grab is successful (focus grabbing will fail if another 
	-- entity is grabbing focus)
	function i:grabFocus(entity)
		assert(entity.sendMessage, "Only entity can grab focus")
		if self.focusedEntity == nil then
			self.focusedEntity = entity
			return true
		else
			return false
		end
	end

	-- Release focus from an entity
	-- Returns whether this entity held the focus previously
	function i:releaseFocus(entity)
		if self.focusedEntity == entity then
			self.focusedEntity = nil
			return true
		else
			return false
		end
	end

	-- Check whether an entity has the focus
	function i:isFocused(entity)
		return self.focusedEntity == entity
	end

	-- Return the currently focused entity
	function i:isFocused(entity)
		return self.focusedEntity
	end

	-- Private
	function i:start(engine, config)
		local inputMgr = engine:getSystem("jaeger.InputManager")
		self:listen(inputMgr, "mouseMoved")
		self:listen(inputMgr, "mouseLeft")

		self.sceneMgr = engine:getSystem("jaeger.SceneManager")

		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Widget", self, "createWidget")
	end

	function i:createWidget(entity, data)
		return {}
	end

	function i:listen(inputMgr, mouseEvent)
		local msgName = "msg"..mouseEvent:gsub("^%l", string.upper)
		inputMgr[mouseEvent]:addListener(function(...)
			self:dispatchEventMsg(msgName, ...)
		end)
	end

	function i:dispatchEventMsg(msg, wndX, wndY, ...)
		local focusedEntity = self.focusedEntity
		if focusedEntity ~= nil then
			local layer = focusedEntity:query("getProp").layer
			local worldX, worldY = layer:wndToWorld(wndX, wndY)
			focusedEntity:sendMessage(msg, worldX, worldY, ...)
		else
			local entity, worldX, worldY = self.sceneMgr:pickFirstEntityAt(wndX, wndY, c.isWidget)
			if entity then
				entity:sendMessage(msg, worldX, worldY, ...)
			end
		end
	end

	function c.isWidget(entity)
		return entity:hasComponent("jaeger.Widget")
	end
end)
