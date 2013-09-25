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
return class(..., function(i)
	-- Private
	function i:start(engine, config)
		self.input = engine:getSystem("jaeger.InputSystem")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Widget", self, "createWidget")
	end

	function i:createWidget(entity, data)
		return {}
	end

	function i:msgPlayGUIAnimation(component, entity, anim)
		if component.animation then
			component.animation:stop()
			component.animation = nil
		end
		if anim then
			entity:sendMessage("msgPerformAction", anim)
			component.animation = anim
		end
	end

	function i:msgMouseMoved(component, entity, x, y)
		local input = self.input

		if input:isFocused(entity) then
			local prop = entity:query("getProp")
			if not prop:inside(x, y) then--mouse moved out
				entity:sendMessage("msgGUIHoverOut", x, y)
				self.input:releaseFocus(entity)
			end
		else
			if self.input:grabFocus(entity) then
				entity:sendMessage("msgGUIHoverIn", x, y)
			end
		end
	end
end)
