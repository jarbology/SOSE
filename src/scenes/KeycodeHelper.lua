local class = require "jaeger.Class"
local RenderUtil = require "jaeger.utils.RenderUtils"
local KeyNames = require "jaeger.KeyNames"

return class(..., function(i, c)
	function i:__constructor()
		local defaultLayer = RenderUtil.newFullScreenLayer()
		self.renderTable = {
			defaultLayer
		}
		local textbox = MOAITextBox.new()
		defaultLayer:insertProp(textbox)
		textbox:setRect(-200, 40, 200, -40)
		textbox:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.RIGHT_JUSTIFY)
		textbox:setYFlip(true)
		self.textbox = textbox
		self:onKey(0)
	end

	function i:start(engine)
		local input = engine:getSystem("jaeger.InputSystem")
		local font = engine:getSystem("jaeger.AssetManager"):getAsset("font:arial.fnt")
		self.textbox:setFont(font)
		input.keyboard:addListener(self, "onKey")
	end

	function i:onKey(keycode)
		local name = KeyNames[keycode] or "UNKNOWN"
		self.textbox:setString(name .. '(' .. keycode .. ')')
	end

	function i:stop()
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:getLayer()
		return nil
	end
end)
