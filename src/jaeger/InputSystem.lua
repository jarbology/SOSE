local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Provide input events for multiple listeners
-- Relevant entity spec:
-- * receiveInput: boolean
--
-- Events:
--
-- mouseMoved
-- keyboard
-- textInput
-- mouseLeft
-- mouseRight
-- mouseMiddle
-- mouseWheel
return class(..., function(i)

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
		engine:getSystem("jaeger.EntityManager").entityCreated:addListener(self, "onEntityCreated")
	end

	function i:onSceneBegin(scene)
		self.renderTable = scene:getRenderTable()
	end

	function i:onSceneEnd(scene)
		self.renderTable = nil
	end

	function i:onEntityCreated(entity, spec)
		if spec.receiveInput then
			entity:addComponent{
				system = self,
				name = "jaeger.InputReceiver"
			}
			entity.receiveInput = true
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
		self:dispatcEventMsg("msgMouseMoved", ...)
	end

	function i:onMouseWheel(...)
		self:dispatcEventMsg("msgMouseWheel", ...)
	end

	function i:onMouseLeft(...)
		self:dispatcEventMsg("msgMouseLeft", ...)
	end

	function i:onMouseMiddle(...)
		self:dispatcEventMsg("msgMouseMiddle", ...)
	end

	function i:onMouseRight(...)
		self:dispatcEventMsg("msgMouseRight", ...)
	end

	function i:dispatcEventMsg(msg, ...)
		if not self.renderTable then return end

		if self.focusEntity ~= nil then
			self.focusEntity:sendMessage(msg, ...)
		else
			local mouseX, mouseY = MOAIInputMgr.device.mouse:getLoc()
			for _, renderPass in ipairs(self.renderTable) do
				-- if the render pass is a layer
				if renderPass.wndToWorld then
					local localX, localY = renderPass:wndToWorld(mouseX, mouseY)
					local prop = renderPass:getPartition():propForPoint(localX, localY)
					if prop then
						local entity = prop.entity
						if entity and entity.receiveInput then
							entity:sendMessage(msg, ...)
						end
					end
				end
			end
		end
	end
end)
