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
return class(..., function(i)
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
		self.mouseLeft = self:listen(device.mouseLeft)
		self.mouseRight = self:listen(device.mouseRight)
		self.mouseMiddle = self:listen(device.mouseMiddle)
		self.mouseWheel = self:listen(device.mouseWheel)

		self.mouseMoved:addListener(self, "onMouseMoved")
		self.mouseLeft:addListener(self, "onMouseLeft")
		self.mouseRight:addListener(self, "onMouseRight")
		self.mouseMiddle:addListener(self, "onMouseMiddle")
		self.mouseWheel:addListener(self, "onMouseWheel")

		self.focusedEntity = nil
	end

	function i:start(engine, config)
		self.sceneMgr = engine:getSystem("jaeger.SceneManager")
		self.sceneMgr.sceneBegin:addListener(self, "onSceneBegin")
		self.sceneMgr.sceneEnd:addListener(self, "onSceneEnd")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.InputReceiver", self, "createInputReceiver")
	end

	function i:onSceneBegin(scene)
		self.renderTable = scene:getRenderTable()
	end

	function i:onSceneEnd(scene)
		self.renderTable = nil
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
		if not self.renderTable then return end

		local mouseX, mouseY = MOAIInputMgr.device.mouse:getLoc()

		local focusedEntity = self.focusedEntity
		if focusedEntity ~= nil then
			local worldX, worldY = focusedEntity:query("getProp").layer:wndToWorld(mouseX, mouseY)
			focusedEntity:sendMessage(msg, worldX, worldY, ...)
		else
			for _, renderPass in ipairs(self.renderTable) do
				-- if the render pass is a layer
				if renderPass.wndToWorld then
					local localX, localY = renderPass:wndToWorld(mouseX, mouseY)
					local partition = renderPass:getPartition()
					if partition then
						local prop = partition:propForPoint(localX, localY)
						if prop then
							local entity = prop.entity
							if entity and entity:hasComponent("jaeger.InputReceiver") then
								entity:sendMessage(msg, localX, localY, ...)
							end
						end
					end
				end
			end
		end
	end
end)
