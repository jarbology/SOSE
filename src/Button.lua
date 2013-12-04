local class = require "jaeger.Class"

return class(..., function(i)
	local DEFAULT_CLICK_SCALE = { 1.1, 1.1 }
	local DEFAULT_ANIM_TIME = 0.3

	function i:__constructor(data)
		self.clickScale = data.clickScale or DEFAULT_CLICK_SCALE
		self.animTime = data.animTime or DEFAULT_ANIM_TIME
	end

	function i:msgActivate()
		self.prop = assert(self.entity:query("getProp"), "Need prop for effect")
	end

	function i:msgMouseLeft(x, y, down)
		if down then
			getSystem("jaeger.WidgetManager"):grabFocus(self.entity)
			self.entity:sendMessage("msgQueueAction", function()
				return self.prop:seekScl(self.clickScale[1], self.clickScale[2], self.animTime)
			end)
		else
			getSystem("jaeger.WidgetManager"):releaseFocus(self.entity)
			self.entity:sendMessage("msgQueueAction", function()
				return self.prop:seekScl(1, 1, self.animTime)
			end)
		end
	end
end)