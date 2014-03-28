local class = require "jaeger.Class"

return class(..., function(i, c)
	function i:__constructor(data)
	end

	function i:msgLinkZone(zone)
		self.opposingZone = zone
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
