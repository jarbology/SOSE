local classes = {}
local prototypes = {}

local makeClass
makeClass = function(name, decorate)
	--TODO: purge table of old members
	local class = classes[name] or {
		name = name
	}
	classes[name] = class

	local instance = prototypes[name] or {
		__class = class
	}
	prototypes[name] = instance

	local instanceMt = {
		__index = instance,
		__metatable = 0
	}
	class.prototype = instance

	decorate(instance, class)

	local metatable = getmetatable(instance)
	if metatable == nil then--protect the instance table
		setmetatable(instance, {__metatable = 0})
	end

	function class.new(...)
		local instance = setmetatable({}, instanceMt)
		local constructor = instance.__constructor
		if constructor then
			constructor(instance, ...)
		end
		return instance
	end

	function class.extend(name, decorate)
		return makeClass(name,
			function(c, i)
				setmetatable(
					c,
					{
						__index = class,
						__metatable = 0
					}
				)
				setmetatable(i, instanceMt)
				decorate(i, c, instance)
			end
		)
	end

	return class
end

return makeClass
