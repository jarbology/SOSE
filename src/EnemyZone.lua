local class = require "jaeger.Class"
local Popup = require "Popup"

return class(..., function(i, c)
	function i:__constructor(data)
	end

	function i:msgLinkZone(zone)
		self.opposingZone = zone

		local cursor = createEntity{
			{"jaeger.Renderable", layer=self.entity:query("getLayer", "overlay")},
			{"jaeger.Sprite", spriteName="ui/arrowLeft"}
		}
		self.cursor = cursor
		local cursorProp = cursor:query("getProp")
		self.cursorProp = cursorProp

		local numBases = self.entity:query("getNumBases")
		numBases.changed:addListener(self, "onNumBasesChanged")
	end

	function i:onNumBasesChanged(new)
		if new <= 0 then
			MOAISim.showCursor()
			Popup.showInfoPopup("You win", function()
				changeScene("scenes.MainMenu")
			end)
		end
	end

	function i:msgTileClicked(tileX, tileY, worldX, worldY)
		local isGround = self.entity:query("isTileGround", tileX, tileY)
		local tileCenterX, tileCenterY = self.entity:query("getTileLoc", tileX, tileY)
		if isGround then
			local angle = math.deg(math.atan2(worldY - tileCenterY, worldX - tileCenterX))
			local quadrant = c.getQuadrant(angle)
			self.opposingZone:sendMessage("msgAttack", tileX, tileY, quadrant)
		end
	end

	function i:msgTileHovered(tileX, tileY, worldX, worldY)
		if self.entity:query("isTileGround", tileX, tileY) then
			self.cursorProp:setVisible(true)
			local tileCenterX, tileCenterY = self.entity:query("getTileLoc", tileX, tileY)
			local angle = math.deg(math.atan2(worldY - tileCenterY, worldX - tileCenterX))
			local quadrant = c.getQuadrant(angle)
			local sprite
			if quadrant == "right" then
				sprite = "ui/arrowLeft"
			elseif quadrant == "left" then
				sprite = "ui/arrowRight"
			elseif quadrant == "top" then
				sprite = "ui/arrowDown"
			else
				sprite = "ui/arrowUp"
			end
			self.cursor:sendMessage("msgChangeSprite", sprite)
			self.cursorProp:setLoc(worldX, worldY)
			MOAISim.hideCursor()
		else
			self.cursorProp:setVisible(false)
			MOAISim.showCursor()
		end
	end

	function c.getQuadrant(angle)
		if -45 < angle and angle <= 45 then
			return "right"
		elseif 45 < angle and angle <= 135 then
			return "top"
		elseif 135 < angle or angle <= - 135 then
			return "left"
		else
			return "bottom"
		end
	end
end)
