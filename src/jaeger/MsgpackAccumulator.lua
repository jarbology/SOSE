local class = require "jaeger.Class"
local msgpack = require "msgpack"

return class(..., function(i)
	function i:__constructor()
		self.buff = ''
		self.hasNext = false -- a separate flag since nextMsg can be nil or false
	end

	function i:put(data)
		self.buff = self.buff .. data
	end

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

	function i:take()
		assert(self:hasData(), "Stream is empty")

		self.buff = self.buff:sub(self.nextOffset)
		self.hasNext = false

		return self.nextMsg
	end
end)
