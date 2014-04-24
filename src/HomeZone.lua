local class = require "jaeger.Class"
local RingMenuUtils = require "RingMenuUtils"
local NetworkCommand = require "NetworkCommand"
local BuildingType = require "BuildingType"
local WeaponType = require "WeaponType"
local Quadrant = require "Quadrant"
local Popup = require "Popup"

return class(..., function(i, c)
	local BUILDING_MENU = {
		{id = "upgrade", sprite = "ui/radialMenu/upgrade"},
		{id = "demolish", sprite = "ui/radialMenu/demolish"}
	}

	local BUILDING_MENU_DEMOLISH = {
		{id = "demolish", sprite = "ui/radialMenu/demolish"}
	}

	local TILE_MENU = {
		{id = "mechBay", sprite = "ui/radialMenu/mech"},
		{id = "rocketLauncher", sprite = "ui/radialMenu/rocketLauncher"},
		{id = "interceptor", sprite = "ui/radialMenu/interceptor"},
		{id = "turret", sprite = "ui/radialMenu/turret"},
		{id = "generator", sprite = "ui/radialMenu/generator"},
		{id = "fakeCore", sprite = "ui/radialMenu/core"}
	}

	function i:__constructor(data)
		self.client = data.client
	end

	function i:msgLinkZone(zone)
		local zoneWidth, zoneHeight = self.entity:query("getSize")
		self.entity:sendMessage("msgReveal", 1, zoneWidth, 1, zoneHeight)
		self.currentWeapon = "rocket"
		self.numBases = self.entity:query("getNumBases")
		self.battleStarted = false

		self.numBases.changed:addListener(self, "onNumBasesChanged")
	end

	function i:onNumBasesChanged(new)
		if new <= 0 then
			MOAISim.showCursor()
			Popup.showInfoPopup("You lose", function()
				changeScene("scenes.MainMenu")
			end)
		end
	end

	function i:msgTileClicked(tileX, tileY, worldX, worldY)
		local isGround = self.entity:query("isTileGround", tileX, tileY)
		if isGround then
			if not self.battleStarted then
				if self.numBases:get() < 3 then
					self:build("core", tileX, tileY)
				end
			else
				local wndX, wndY = self.entity:query("worldToWnd", worldX, worldY)
				local building = self.entity:query("getBuildingAt", tileX, tileY)
				if building then
					self.mode = "building"
					if building:query("canUpgrade") then
						RingMenuUtils.show(BUILDING_MENU, wndX, wndY, self.entity)
					else
						RingMenuUtils.show(BUILDING_MENU_DEMOLISH, wndX, wndY, self.entity)
					end
				else
					RingMenuUtils.show(TILE_MENU, wndX, wndY, self.entity)
					self.mode = "tile"
				end
				self.tileX, self.tileY = tileX, tileY
			end
		else
			RingMenuUtils.hide()
		end
	end

	function i:msgSwitchWeapon(weapon)
		print("switch weapon", weapon)
		self.currentWeapon = weapon

		local weaponButtons = getCurrentScene().weaponButtons
		for _, button in ipairs(weaponButtons) do
			button:sendMessage("msgChangeSprite", "ui/weaponBar")
		end

		local idx
		if weapon=="rocket" then
			idx = 1
		elseif weapon=="robot" then
			idx = 2
		elseif weapon=="rocket2" then
			idx = 3
		else
			idx = 4
		end
		weaponButtons[idx]:sendMessage("msgChangeSprite", "ui/weaponBarActive")
	end

	function i:msgItemChosen(item)
		if self.mode == "tile" then
			self:build(item, self.tileX, self.tileY)
		elseif item == "upgrade" then
			self:upgrade(self.tileX, self.tileY)
		elseif item == "demolish" then
			self:destroy(self.tileX, self.tileY)
		end
	end

	function i:msgBattleStart()
		self.battleStarted = true
	end

	function i:upgrade(x, y)
		local commandCode = NetworkCommand.nameToCode("cmdUpgrade")
		self.client:sendCmd{commandCode, x, y}
	end

	function i:destroy(x, y)
		local commandCode = NetworkCommand.nameToCode("cmdDestroy")
		self.client:sendCmd{commandCode, x, y}
	end

	function i:build(item, x, y)
		local commandCode = NetworkCommand.nameToCode("cmdBuild")
		local buildingCode = BuildingType.nameToCode(item)
		self.client:sendCmd{commandCode, buildingCode, x, y}
	end

	function i:msgAttack(targetX, targetY, quadrant)
		local commandCode = NetworkCommand.nameToCode("cmdAttack")
		local weaponCode = WeaponType.nameToCode(self.currentWeapon)
		local quadrantCode = Quadrant.nameToCode(quadrant)
		self.client:sendCmd{commandCode, weaponCode, targetX, targetY, quadrantCode}
	end
end)
