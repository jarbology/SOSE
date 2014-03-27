local class = require "jaeger.Class"
local RingMenuUtils = require "RingMenuUtils"
local NetworkCommand = require "NetworkCommand"
local BuildingType = require "BuildingType"

return class(..., function(i, c)
	local BUILD_MENU = {
		{id = "mechBay", sprite = "ui/radialMenu/mech"},
		{id = "rocketLauncher", sprite = "ui/radialMenu/rocketLauncher"},
		{id = "interceptor", sprite = "ui/radialMenu/interceptor"},
		{id = "turret", sprite = "ui/radialMenu/turret"},
		{id = "generator", sprite = "ui/radialMenu/generator"}
	}

	function i:__constructor(data)
		print(data.client)
		self.client = data.client
	end

	function i:msgLinkZone(zone)
		self.enemyZone = zone
	end

	function i:msgTileClicked(tileX, tileY, worldX, worldY)
		local isGround = self.entity:query("isTileGround", tileX, tileY)
		if isGround then
			local wndX, wndY = self.entity:query("worldToWnd", worldX, worldY)
			RingMenuUtils.show(BUILD_MENU, wndX, wndY, self.entity)
			self.tileX, self.tileY = tileX, tileY
		else
			RingMenuUtils.hide()
		end
	end

	function i:msgItemChosen(item)
		local commandCode = NetworkCommand.nameToCode("cmdBuild")
		local buildingCode = BuildingType.nameToCode(item)
		self.client:sendCmd{commandCode, buildingCode, self.tileX, self.tileY}
	end
end)
