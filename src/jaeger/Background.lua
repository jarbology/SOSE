local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(data)
		local texture = getAsset("texture:"..data.texture)
		local deck = MOAIGfxQuad2D.new()
		local width, height = data.width, data.height
		deck:setRect(-width / 2, -height / 2, width / 2, height / 2)
		local textureWidth, textureHeight = texture:getSize()
		deck:setUVRect(0, 0, width / textureWidth, height / textureHeight)
		deck:setTexture(texture)

		self.deck = deck
	end

	function i:msgActivate()
		local prop = assert(self.entity:query("getProp"), "A prop is required to display background")
		prop:setDeck(self.deck)
	end
end)
