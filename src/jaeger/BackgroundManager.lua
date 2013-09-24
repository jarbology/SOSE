local class = require "jaeger.Class"

return class(..., function(i)
	-- Private
	function i:start(engine)
		self.assetMgr = engine:getSystem("jaeger.AssetManager")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Background", self, "createBackground")
	end

	function i:createBackground(entity, data)
		local texture = self.assetMgr:getAsset("texture:"..data.texture)
		local deck = MOAIGfxQuad2D.new()
		local width, height = data.width, data.height
		deck:setRect(-width / 2, -height / 2, width / 2, height / 2)
		local textureWidth, textureHeight = texture:getSize()
		deck:setUVRect(0, 0, width / textureWidth, height / textureHeight)
		deck:setTexture(texture)

		return {
			deck = deck
		}
	end

	function i:msgActivate(component, entity)
		assert(entity:getResource("prop"), "A prop is required to display background"):setDeck(component.deck)
	end
end)
