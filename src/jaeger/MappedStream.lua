local class = require "jaeger.Class"

-- A readable stream that transform all data from another stream
return class(..., function(i)
	-- mapFun(x)->x': a function to transform data
	-- stream: the underlying stream
	function i:__constructor(mapFun, stream)
		self.mapFun = mapFun
		self.stream = stream
	end

	function i:update(timeout)
		return self.stream:update(timeout)
	end

	function i:hasData()
		return self.stream:hasData()
	end

	function i:pull()
		return self.mapFun(self.stream:pull())
	end
end)
