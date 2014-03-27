local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Manages jaeger.Widget
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
	function i:__constructor()
		self.mouseLeft = Event.new()
		self.mouseMoved = Event.new()
	end
	
	function i:start(engine, config)
		local inputMgr = engine:getSystem("jaeger.InputManager")
		self:listen(inputMgr, "mouseMoved")
		self:listen(inputMgr, "mouseLeft")

		self.sceneMgr = engine:getSystem("jaeger.SceneManager")
	end

	function i:listen(inputMgr, mouseEvent)
		local msgName = "msg"..mouseEvent:gsub("^%l", string.upper)
		inputMgr[mouseEvent]:addListener(function(...)
			local captured = self:dispatchEventMsg(msgName, ...)
			if not captured then
				self[mouseEvent]:fire(...)
			end
		end)
	end

	function i:dispatchEventMsg(msg, wndX, wndY, ...)
		local focusedEntity = self.focusedEntity
		if focusedEntity ~= nil then
			local layer = focusedEntity:query("getProp").layer
			if layer then
				local worldX, worldY = layer:wndToWorld(wndX, wndY)
				focusedEntity:sendMessage(msg, worldX, worldY, ...)
				return true
			end
		else
			local entity, worldX, worldY = self.sceneMgr:pickFirstEntityAt(wndX, wndY, c.isWidget)
			if entity then
				entity:sendMessage(msg, worldX, worldY, ...)
				return true
			end
		end

		return false
	end

	function c.isWidget(entity)
		return entity:hasComponent("jaeger.Widget")
	end
end)
