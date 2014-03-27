local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Create resource for the zone at an interval
-- Requires:
-- * Building
-- Parameters:
-- * yield: How much resource to produce
-- * interval: Number of frames to wait after each resource production
return class(..., function(i)
	local MENU = {
		{id = "upgrade", sprite = "test/upgradeIcon"},
		{id = "demolish", sprite = "test/demolishIcon"}
	}

	function i:__constructor(data)
		self.yield = data.yield
		self.interval = data.interval
	end

	function i:msgActivate()
		self.zone = self.entity:query("getZone")
		self.entity:sendMessage("msgPerformAction", ActionUtils.newLoopCoroutine(self, "addResource"))
	end

	function i:addResource()
		self.zone:changeResource(self.yield)
		ActionUtils.skipFrames(self.interval)
	end

	function i:getMenu()
		return MENU
	end
end)
