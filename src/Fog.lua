local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:isTileVisible(x, y)
		return self.fogGrid:getTile(x, y) == 0
	end

end)
