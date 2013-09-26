local class = require "jaeger.Class"

-- Manages objects which travels the grids
-- Messages:
-- * msgMoveToCell(x, y): move the walker to a new position
return class(..., function(i)
	-- Private
	function i:start(engine, config)
		self.sceneMgr = engine:getSystem("jaeger.SceneManager")
		engine:getSystem("jaeger.EntityManager"):registerComponent("GridWalker", self, "createGridWalker")
	end

	function i:createGridWalker(entity, data)
		local currentScene = self.sceneMgr:getCurrentScene()
		assert(currentScene.getZone, "Current scene does not contain zones")
		local zone = assert(currentScene:getZone(data.zone), "Zone "..data.zone.." does not exists")

		return {
			zone = zone,
			gridName = data.gridName,
			x = data.x,
			y = data.y
		}
	end

	function i:msgActivate(component, entity)
		component.zone:addGridWalker(component.gridName, component.x, component.y, entity)
	end

	function i:msgDestroy(component, entity)
		component.zone:removeGridWalker(component.gridName, component.x, component.y, entity)
	end

	function i:msgMoveToCell(component, entity, x, y)
		component.zone:moveGridWalker(component.gridName, component.x, component.y, x, y, entity)
		component.x, component.y = x, y
	end
end)
