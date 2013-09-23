local class = require "jaeger.Class"
local msgpack = require "msgpack"

-- A buffer to deal with tcp fragmenting
-- It is a readable + writable stream
return class(..., function(i)
	function i:__constructor()
		self.buff = ''
		self.hasNext = false -- a separate flag since nextMsg can be nil or false
	end

	-- Write raw data to the buffer
	function i:push(data)
		self.buff = self.buff .. data
	end

	-- Check if a message is ready
	function i:hasData()
		if self.hasNext then return true end

		local success, size, msg = pcall(msgpack.unpack, self.buff)

		if success and size then
			self.nextOffset = size + 1
			self.nextMsg = msg
			self.hasNext = true
			return true
		else
			return false
		end
	end

	-- Pull a decoded msgpack message from the buffer
	function i:pull()
		assert(self:hasData(), "Stream is empty")

		self.buff = self.buff:sub(self.nextOffset)
		self.hasNext = false

		return self.nextMsg
	end
end)
