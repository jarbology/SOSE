local class = require "jaeger.Class"

return class(..., function(i, c)
	local names = {
		"noop",
		"cmdBuild",
		"cmdUseBuilding"
	}

	local codes = {}
	for index, name in ipairs(names) do
		codes[name] = index
	end

	function c.codeToName(code)
		return names[code]
	end

	function c.nameToCode(name)
		return codes[name]
	end
end)
