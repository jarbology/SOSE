local class = require "jaeger.Class"

return function(name, enums)
	return class(name, function(i, c)

		local codes = {}

		for index, name in ipairs(enums) do
			codes[name] = index
		end

		function c.codeToName(code)
			return enums[code]
		end

		function c.nameToCode(name)
			return codes[name]
		end
	end)
end
