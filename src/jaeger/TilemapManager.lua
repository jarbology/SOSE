local class = require "jaeger.Class"

return class(..., function(i)
	function i:start(engine)
		self.assetMgr = engine:getSystem("jaeger.AssetManager")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Tilemap", self, "createTilemap")
	end

	function i:createTilemap(entity, data)
		return {
			tileset = self.assetMgr:getAsset("tileset:"..data.tileset),
			grid = data.grid
		}
	end

	function i:msgActivate(component, entity)
		local prop = assert(entity:getResource("prop"), "A prop is needed to display tileset")
		prop:setDeck(component.tileset)
		prop:setGrid(component.grid)
	end
end)
