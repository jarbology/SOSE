local class = require "jaeger.Class"

-- String utilities
return class(..., function(_i, c)
	-- Check if a string begins with a prefix
	function c.beginsWith(string, prefix)
		return string.sub(string, 1, string.len(prefix)) == prefix
	end

	-- Check if a string ends with a suffix
	function c.endsWith(string, suffix)
		return suffix == '' or string.sub(string, -string.len(suffix)) == suffix
	end
end)
