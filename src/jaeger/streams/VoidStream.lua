local class = require "jaeger.Class"

-- A stream that does nothing and never has data
return class(..., function(i)
	function i:__constructor()
	end

	function i:hasData()
		return false
	end

	function i:pull()
		error("Stream is empty")
	end

	function i:update()
	end

	function i:push(data)
	end
end)
