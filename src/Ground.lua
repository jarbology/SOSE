local class = require "jaeger.Class"

return class(..., function(i, c)
	local widgetMgr = getSystem "jaeger.WidgetManager"

	function i:__constructor(data)
		self.zone = data.zone
		self.camera = self.zone:query("getCamera")
	end

	function i:msgActivate()
		self.prop = self.entity:query("getProp")
		self.grid = self.entity:query("getGrid")
	end

	function i:isTileVisible(x, y)
		return self.fogGrid:getTile(x, y) == 0
	end

	function i:msgMouseLeft(x, y, down)
		if down then
			self.clickCancelled = false
			self.dragging = true
			self.oldX, self.oldY = MOAIInputMgr.device.mouse:getLoc()
			widgetMgr:grabFocus(self.entity)
		else
			self.dragging = false
			widgetMgr:releaseFocus(self.entity)
		end

		if not self.clickCancelled and not down then
			local tileX, tileY = self:worldToTile(x, y)
			self.zone:sendMessage("msgTileClicked", tileX, tileY, x, y)
		end
	end

	function i:msgMouseMoved(x, y)
		if self.dragging then
			self.clickCancelled = true
			local x, y = MOAIInputMgr.device.mouse:getLoc()
			self.camera:addLoc(self.oldX - x, y - self.oldY)
			self.oldX = x
			self.oldY = y
		end
	end

	function i:worldToTile(x, y)
		return self.grid:locToCoord(
			self.prop:worldToModel(x, y)
		)
	end
end)
