local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:__constructor(data)
		self.zone = data.zone
	end

	function i:msgActivate()
		self.prop = self.entity:query("getProp")
		self.grid = self.entity:query("getGrid")
	end

	function i:isTileVisible(x, y)
		return self.fogGrid:getTile(x, y) == 0
	end

	function i:msgMouseLeft(x, y, down)
		if not down then
			local tileX, tileY = self:worldToTile(x, y)
			self.zone:sendMessage("msgTileClicked", tileX, tileY, x, y)
		end
	end

	function i:worldToTile(x, y)
		return self.grid:locToCoord(
			self.prop:worldToModel(x, y)
		)
	end
end)
