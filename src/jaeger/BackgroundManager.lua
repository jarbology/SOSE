local class = require "jaeger.Class"

return class(..., function(i)
	-- Private
	function i:start(engine)
		self.assetMgr = engine:getSystem("jaeger.AssetManager")
		engine:getSystem("jaeger.EntityManager").entityCreated:addListener(self, "onEntityCreated")
	end

	function i:onEntityCreated(entity, spec)
		local backgroundSpec = spec.background

		if backgroundSpec then
			local texture = self.assetMgr:getAsset("texture:"..backgroundSpec.texture)
			local deck = MOAIGfxQuad2D.new()
			local width, height = backgroundSpec.width, backgroundSpec.height
			deck:setRect(-width / 2, -height / 2, width / 2, height / 2)
			local textureWidth, textureHeight = texture:getSize()
			deck:setUVRect(0, 0, width / textureWidth, height / textureHeight)
			deck:setTexture(texture)

			local prop = MOAIProp2D.new()
			prop.entity = entity
			prop:setDeck(deck)

			entity:addComponent{
				system = self,
				name = "jaeger.Background",
				prop = prop
			}
			entity:registerResource("prop", prop)
		end
	end
end)
