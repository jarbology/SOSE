local class = require "jaeger.Class"

-- A progress bar
-- Parameters:
-- * width
-- * height
-- * foregroundColor
-- * backgroundColor
-- * borderThickness
-- * progress: 1-100
-- Messages:
-- msgSetProgress(number): set progress for this bar
return class(..., function(i)
	function i:__constructor(data)
		self.width = data.width
		self.height = data.height
		self.foregroundColor = data.foregroundColor
		self.backgroundColor = data.backgroundColor
		self.borderThickness = data.borderThickness
		self.progress = 1

		local deck = MOAIScriptDeck.new()
		local halfHeight = data.height / 2
		local halfWidth = data.width / 2
		deck:setRect(-halfWidth, -halfHeight, halfWidth, halfHeight)
		deck:setDrawCallback(function(...)
			return self:draw(...)
		end)
		self.deck = deck
	end

	function i:msgActivate()
		self.entity:query("getProp"):setDeck(self.deck)
	end

	function i:msgSetProgress(value)
		self.progress = value
	end

	function i:draw(index, xOff, yOff, xScale, yScale)
		local MOAIDraw = MOAIDraw
		local width, height = self.width, self.height
		local halfWidth, halfHeight = width / 2, height / 2
		MOAIGfxDevice.setPenWidth(1)
		MOAIGfxDevice.setPenColor(unpack(self.backgroundColor))
		MOAIDraw.fillRect(-halfWidth, -halfHeight, halfWidth, halfHeight)
		MOAIGfxDevice.setPenColor(unpack(self.foregroundColor))

		local thickness = self.borderThickness
		local xMin = -halfWidth + thickness
		local progressWidth = self.progress * (width - thickness * 2)
		local xMax = xMin + progressWidth
		MOAIDraw.fillRect(xMin, -halfHeight + thickness, xMax, halfHeight - thickness)
	end
end)
