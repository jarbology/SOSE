local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Provide input events for multiple listeners
-- Manage jaeger.InputReceiver
--
-- Events:
--
-- mouseMoved(x, y)
-- keyboard(keycode, down)
-- textInput(character)
-- mouseLeft(x, y, down): fired when the left mouse is pressed or released
-- mouseRight(x, y, down):
-- mouseMiddle(x, y, down):
-- mouseWheel(x, y, delta)
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
	function i:__constructor(config)
		-- TODO: use config to locate the sensors
		local device = MOAIInputMgr.device
		self.mouseMoved = self:listen(device.mouse)
		self.keyboard = self:listen(device.keyboard)
		self.textInput = self:listen(device.textInput)
		self.mouseLeft = self:listenMouse(device.mouseLeft)
		self.mouseRight = self:listenMouse(device.mouseRight)
		self.mouseMiddle = self:listenMouse(device.mouseMiddle)
		self.mouseWheel = self:listenMouse(device.mouseWheel)

		self.mouseMoved:addListener(self, "onMouseMoved")
		self.mouseLeft:addListener(self, "onMouseLeft")
		self.mouseRight:addListener(self, "onMouseRight")
		self.mouseMiddle:addListener(self, "onMouseMiddle")
		self.mouseWheel:addListener(self, "onMouseWheel")

		self.focusedEntity = nil
	end

	function i:start(engine, config)
		self.sceneMgr = engine:getSystem("jaeger.SceneManager")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.InputReceiver", self, "createInputReceiver")
	end

	function i:createInputReceiver(entity, data)
		return {}
	end

	function i:msgDestroy(component, entity)
		if self.focusedEntity == entity then
			self.focusedEntity = nil
		end
	end

	function i:listen(sensor)
		local event = Event.new()
		sensor:setCallback(function(...)
			event:fire(...)
		end)
		return event
	end

	function i:listenMouse(sensor)
		local event = Event.new()
		sensor:setCallback(function(...)
			local mouseX, mouseY = MOAIInputMgr.device.mouse:getLoc()
			event:fire(mouseX, mouseY, ...)
		end)
		return event
	end

	function i:onMouseMoved(...)
		self:dispatchEventMsg("msgMouseMoved", ...)
	end

	function i:onMouseWheel(...)
		self:dispatchEventMsg("msgMouseWheel", ...)
	end

	function i:onMouseLeft(...)
		self:dispatchEventMsg("msgMouseLeft", ...)
	end

	function i:onMouseMiddle(...)
		self:dispatchEventMsg("msgMouseMiddle", ...)
	end

	function i:onMouseRight(...)
		self:dispatchEventMsg("msgMouseRight", ...)
	end

	function i:dispatchEventMsg(msg, ...)
		local mouseX, mouseY = MOAIInputMgr.device.mouse:getLoc()

		local focusedEntity = self.focusedEntity
		if focusedEntity ~= nil then
			local worldX, worldY = focusedEntity:query("getProp").layer:wndToWorld(mouseX, mouseY)
			focusedEntity:sendMessage(msg, worldX, worldY, ...)
		else
			local entity, worldX, worldY = self.sceneMgr:pickFirstEntityAt(mouseX, mouseY, c.isInputReceiver)
			if entity and entity:hasComponent("jaeger.InputReceiver") then
				entity:sendMessage(msg, worldX, worldY, ...)
			end
		end
	end

	function c.isInputReceiver(entity)
		return entity:hasComponent("jaeger.InputReceiver")
	end
end)
