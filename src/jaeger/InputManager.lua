local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Provide input events for multiple listeners
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
	-- Private
	function i:__constructor(config)
		-- TODO: use config to locate the sensors
		local device = MOAIInputMgr.device
		self.mouseMoved = c.mux(device.mouse)
		self.keyboard = c.mux(device.keyboard)
		self.textInput = c.mux(device.textInput)
		self.mouseLeft = c.muxMouse(device.mouseLeft)
		self.mouseRight = c.muxMouse(device.mouseRight)
		self.mouseMiddle = c.muxMouse(device.mouseMiddle)
		self.mouseWheel = c.muxMouse(device.mouseWheel)
	end

	function i:start(engine, config)
	end

	function i:msgDestroy(component, entity)
		if self.focusedEntity == entity then
			self.focusedEntity = nil
		end
	end

	function c.mux(sensor)
		local event = Event.new()
		sensor:setCallback(function(...)
			event:fire(...)
		end)
		return event
	end

	function c.muxMouse(sensor)
		local event = Event.new()
		sensor:setCallback(function(...)
			local mouseX, mouseY = MOAIInputMgr.device.mouse:getLoc()
			event:fire(mouseX, mouseY, ...)
		end)
		return event
	end
end)
