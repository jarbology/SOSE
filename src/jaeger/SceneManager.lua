local class = require "jaeger.Class"
local Event = require "jaeger.Event"

return class(..., function(i)
	function i:__constructor(config)
		self.currentScene = nil
		self.sceneBegin = Event.new()
		self.sceneEnd = Event.new()
	end

	function i:start(engine)
		self.engine = engine
		engine:getSystem("jaeger.EntityManager").entityCreated:addListener(self, "onEntityCreated")
	end

	function i:onEntityCreated(entity, spec)
		if spec.layer then
			entity:addComponent{
				system = self,
				name = "jaeger.Renderable"
			}
		end
	end

	function i:activateEntity(component, entity)
		local layerName = entity:getSpec().layer
		local prop = entity:getResource("prop")

		if layerName and prop then
			local layer = assert(self.currentScene:getLayer(layerName), "Cannot find layer '"..layerName.."' in current scene")
			layer:insertProp(prop)
		end
	end

	function i:destroyEntity(component, entity)
		local layerName = entity:getSpec().layer
		local prop = entity:getResource("prop")
		self.currentScene:getLayer(layerName):removeProp(prop)
	end

	function i:changeScene(sceneName, data)
		if self.currentScene then
			self.sceneEnd:fire(self.currentScene)
			self.currentScene:stop()
		end
		--TODO: gc here?

		local sceneClass = require(sceneName)
		local scene = assert(sceneClass.create(data))
		self.currentScene = scene
		MOAIRenderMgr.setRenderTable(scene:getRenderTable())
		scene:start(self.engine)
		self.sceneBegin:fire(scene)
	end
end)
