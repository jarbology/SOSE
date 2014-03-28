local class = require "jaeger.Class"
local RingMenuUtils = require "RingMenuUtils"
local NetworkCommand = require "NetworkCommand"
local BuildingType = require "BuildingType"
local WeaponType = require "WeaponType"
local Quadrant = require "Quadrant"

return class(..., function(i, c)
	local BUILD_MENU = {
		{id = "mechBay", sprite = "ui/radialMenu/mech"},
		{id = "rocketLauncher", sprite = "ui/radialMenu/rocketLauncher"},
		{id = "interceptor", sprite = "ui/radialMenu/interceptor"},
		{id = "turret", sprite = "ui/radialMenu/turret"},
		{id = "generator", sprite = "ui/radialMenu/generator"}
	}

	function i:__constructor(data)
		self.client = data.client
	end

	function i:msgLinkZone(zone)
		local zoneWidth, zoneHeight = self.entity:query("getSize")
		self.entity:sendMessage("msgReveal", 1, zoneWidth, 1, zoneHeight)
		self.currentWeapon = "rocket"
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

	function i:msgSwitchWeapon(weapon)
		print("switch weapon", weapon)
		self.currentWeapon = weapon
	end

	function i:msgItemChosen(item)
		local commandCode = NetworkCommand.nameToCode("cmdBuild")
		local buildingCode = BuildingType.nameToCode(item)
		self.client:sendCmd{commandCode, buildingCode, self.tileX, self.tileY}
	end

	function i:msgAttack(targetX, targetY, quadrant)
		local commandCode = NetworkCommand.nameToCode("cmdAttack")
		local weaponCode = WeaponType.nameToCode(self.currentWeapon)
		local quadrantCode = Quadrant.nameToCode(quadrant)
		self.client:sendCmd{commandCode, weaponCode, targetX, targetY, quadrantCode}
	end
end)
