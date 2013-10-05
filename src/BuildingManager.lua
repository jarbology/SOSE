local class = require "jaeger.Class"

-- Manages buildings
return class(..., function(i)
	-- Private
	function i:start(engine, config)
		self.sceneMgr = engine:getSystem("jaeger.SceneManager")
		engine:getSystem("jaeger.EntityManager"):registerComponent("Building", self, "createBuilding")
	end

	function i:createBuilding(entity, data)
		local currentScene = self.sceneMgr:getCurrentScene()
		assert(currentScene.getZone, "Current scene does not contain zones")
		local zone = assert(currentScene:getZone(data.zone), "Zone "..data.zone.." does not exists")

		return {
			zone = zone,
			x = data.x,
			y = data.y
		}
	end

	function i:msgActivate(component, entity)
		component.zone:addBuilding(component.x, component.y, entity)
		entity:query("getProp"):setLoc(component.zone:getTileLoc(component.x, component.y))
	end

	function i:msgDestroy(component, entity)
		component.zone:removeBuildingAt(component.x, component.y)
	end

	function i:msgReveal(component, entity)
		if component.prop then
			component.prop:setVisible(true)
		end
	end
end)
