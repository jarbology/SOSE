local class = require "jaeger.Class"
local Property = require "jaeger.Property"
local ActionUtils = require "jaeger.utils.ActionUtils"

return class(..., function(i)
	function i:__constructor(data)
	end

	function i:msgActivate()
		self.entity:sendMessage("msgPerformAction", ActionUtils.newCoroutine(self, "update"))
	end

	function i:update(prop)
		local prop = self.entity:query("getProp")
		local x, y = prop:getLoc()
		local yield = coroutine.yield
		for i = 1, 40 do
			y = y + 0.7
			prop:setLoc(x, y)
			yield()
		end
		destroyEntity(self.entity)
	end
end)
