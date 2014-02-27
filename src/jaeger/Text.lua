local class = require "jaeger.Class"

return class(..., function(i)
	local DEFAULT_ALIGNMENT = {MOAITextBox.LEFT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY}

	function i:__constructor(data)
		local textbox = MOAITextBox.new()
		local style = MOAITextStyle.new()
		style:setFont(getAsset("font:"..data.font))
		style:setSize(data.size)
		textbox:setStyle(style)
		textbox:setYFlip(true)
		textbox:setRect(unpack(data.rect))
		textbox:setString(data.text)
		local alignment = data.alignment or DEFAULT_ALIGNMENT
		textbox:setAlignment(unpack(alignment))
		self.textbox = textbox
	end

	function i:msgActivate()
		local prop = assert(self.entity:query("getProp"), "A prop is needed to display text")
		local textbox = self.textbox
		textbox:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, prop, MOAIProp2D.TRANSFORM_TRAIT)
		textbox:setAttrLink(MOAIProp2D.INHERIT_COLOR, prop, MOAIProp2D.COLOR_TRAIT)
		textbox:setAttrLink(MOAIProp2D.ATTR_PARTITION, prop, MOAIProp2D.ATTR_PARTITION)
		local xMin, yMin, xMax, yMax = textbox:getRect()
		textbox:setBounds(xMin, yMin, 0, xMax, yMax, 1)
		prop:setBounds(xMin, yMin, 0, xMax, yMax, 1)
		textbox.entity = self.entity

		self.prop = prop
	end

	function i:msgSetText(txt)
		local textbox = self.textbox
		textbox:setString(txt)
		local xMin, yMin, xMax, yMax = textbox:getRect()
		textbox:setBounds(xMin, yMin, 0, xMax, yMax, 1)
		self.prop:setBounds(xMin, yMin, 0, xMax, yMax, 1)
	end

	function i:getTextBox()
		return self.textbox
	end
end)
