local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(data)
		self.tileset = getAsset("tileset:"..data.tileset)
		self.grid = data.grid
	end

	function i:msgActivate()
		local prop = assert(self.entity:query("getProp"), "A prop is needed to display tileset")
		prop:setDeck(self.tileset)
		prop:setGrid(self.grid)
	end
end)
