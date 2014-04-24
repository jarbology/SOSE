local class = require "jaeger.Class"
local MOAIDraw = MOAIDraw
local MOAIGfxDevice = MOAIGfxDevice

return class(..., function(i)
	function i:__constructor(data)
		local deck = MOAIScriptDeck.new()
		local halfHeight = data.height / 2
		local halfWidth = data.width / 2
		deck:setRect(-halfWidth, -halfHeight, halfWidth, halfHeight)
		deck:setDrawCallback(function(...)
			return self:draw(...)
		end)
		self.deck = deck
		self.points = {}
		self.color = data.color or {1, 1, 1, 0}
		self.thickness = data.thickness
	end

	function i:msgActivate()
		self.entity:query("getProp"):setDeck(self.deck)
	end

	function i:getPoints()
		return self.points
	end

	function i:draw(index, xOff, yOff, xScale, yScale)
		MOAIGfxDevice.setPenWidth(self.thickness)
		MOAIGfxDevice.setPenColor(unpack(self.color))
		MOAIDraw.drawLine(self.points)
	end
end)
