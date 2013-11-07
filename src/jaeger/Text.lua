local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(data)
		local textbox = MOAITextBox.new()
		local style = MOAITextStyle.new()
		style:setFont(getAsset("font:"..data.font))
		style:setSize(data.size)
		textbox:setStyle(style)
		textbox:setYFlip(true)
		textbox:setRect(unpack(data.rect))
		textbox:setString(data.text)
		textbox:setAlignment(MOAITextBox.LEFT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY)
		self.textbox = textbox
	end

	function i:msgActivate()
		local prop = assert(self.entity:query("getProp"), "A prop is needed to display text")
		local textbox = self.textbox
		textbox:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, prop, MOAIProp2D.TRANSFORM_TRAIT)
		textbox:setAttrLink(MOAIProp2D.INHERIT_COLOR, prop, MOAIProp2D.COLOR_TRAIT)
		textbox:setAttrLink(MOAIProp2D.ATTR_PARTITION, prop, MOAIProp2D.ATTR_PARTITION)
		textbox.entity = self.entity
		prop.layer:insertProp(textbox)
	end

	function i:msgSetText(txt)
		local textbox = self.textbox
		textbox:setString(txt)
		local xMin, xMax, yMin, yMax = textbox:getRect()
		textbox:setBounds(xMin, yMin, 0, xMax, yMax, 1)
	end

	function i:getTextBox()
		return self.textbox
	end
end)
