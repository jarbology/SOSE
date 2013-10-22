local class = require "jaeger.Class"

return class(..., function(i)
	function i:msgUse(zone, x, y)
		print("pew pew", x, y)
	end
end)
