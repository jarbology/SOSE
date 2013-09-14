local class = require "jaeger.Class"
local min = math.min
local max = math.max

return class(..., function(i, c)
	function c.clamp(value, lower, upper)
		return min(max(value, lower), upper)
	end
end)
