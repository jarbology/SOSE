local class = require "jaeger.Class"
local MathUtils = require "jaeger.utils.MathUtils"

return class(..., function(i, c)
	-- Private
	function i:__constructor(config)
	end

	function i:start(engine, config)
		local entityMgr = engine:getSystem("jaeger.EntityManager")
		entityMgr.entityCreated:addListener(self, "onEntityCreated")
	end

	function i:onEntityCreated(entity, spec)
		local movableSpec = spec.movable
		if movableSpec then
			local component = {
				system = self,
				name = "jaeger.Movable",
				maxSpeedX = movableSpec.maxSpeedX or 0,
				maxSpeedY = movableSpec.maxSpeedY or 0,
				vecX = movableSpec.vecX or 0,
				vecY = movableSpec.vecY or 0,
				accelX = movableSpec.accelX or 0,
				accelY = movableSpec.accelY or 0
			}
			entity:addComponent(component)
			entity:addUpdateFunc(self, "update", component)
		end
	end

	function i:msgActivate(component, entity)
		component.prop = assert(entity:getResource("prop"), "Entity must have a prop to be moved")
	end

	function i:update(delta, entity, component)
		local vecX, vecY = component.vecX, component.vecY
		local accelX, accelY = component.accelX, component.accelY
		local maxSpeedX, maxSpeedY = component.maxSpeedX, component.maxSpeedY
		vecX = MathUtils.clamp(vecX + accelX * delta, -maxSpeedX, maxSpeedX)
		vecY = MathUtils.clamp(vecY + accelY * delta, -maxSpeedY, maxSpeedY)
		component.vecX, component.vecY = vecX, vecY

		local x, y = component.prop:getLoc()
		x = x + vecX * delta
		y = y + vecY * delta
		component.prop:setLoc(x, y)
	end

	function i:msgSetAccel(component, entity, x, y)
		component.accelX = x or component.accelX
		component.accelY = y or component.accelY
	end

	function i:msgSetVec(component, entity, x, y)
		component.vecX = x or component.vecX
		component.vecY = y or component.vecY
	end
end)
