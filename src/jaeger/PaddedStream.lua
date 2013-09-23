local class = require "jaeger.Class"

-- A readable stream
-- It is backed by another stream and a default "padding" value
-- This stream always has readable data
-- When the backing stream cannot supply data, this stream supply
-- the "padding" value instead
return class(..., function(i)
	-- Create a PaddedStream
	-- stream: the backing stream
	-- padValue: the padding value
	function i:__constructor(stream, padValue)
		self.stream = stream
		self.padValue = padValue
	end

	function i:hasData()
		return true
	end

	function i:update(timeout)
		return self.stream:update(timeout)
	end

	function i:pull()
		local stream = self.stream
		if stream:hasData() then
			return stream:pull()
		else
			return self.padValue
		end
	end
end)
