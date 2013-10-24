local class = require "jaeger.Class"
local min = math.min
local max = math.max

return class(..., function(i, c)
	function c.clamp(value, lower, upper)
		return min(max(value, lower), upper)
	end

	function c.sign(x)
		if x > 0 then
			return 1
		elseif x < 0 then
			return -1
		else
			return 0
		end
	end
end)
