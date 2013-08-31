local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Manage scenes
-- Component: jaeger.Renderable
-- Relevant entity specs:
--	* layer: name of the layer this entity will be rendered in
-- Events:
--	* sceneBegin(scene): fired at the beginning of a scene.
--	* sceneEnd(scene): fired at the end of a scene
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

	function i:msgActivate(component, entity)
		local layerName = entity:getSpec().layer
		local prop = entity:getResource("prop")

		if layerName and prop then
			local layer = assert(self.currentScene:getLayer(layerName), "Cannot find layer '"..layerName.."' in current scene")
			layer:insertProp(prop)
			prop.layer = layer
		end
	end

	function i:msgDestroy(component, entity)
		local layerName = entity:getSpec().layer
		local prop = entity:getResource("prop")
		self.currentScene:getLayer(layerName):removeProp(prop)
	end

	-- Change to a scene
	--	* sceneName: name of the scene class
	--	* data: userdata to pass to the scene
	-- A scene must have:
	-- __constructor(data): where data is the data passed in earlier
	-- start(engine): initialize the scene
	-- getRenderTable(): returns a Moai render table (see MOAIRenderMgr)
	-- getLayer(name): return the layer with the given name or nil
	function i:changeScene(sceneName, data)
		if self.currentScene then
			self.sceneEnd:fire(self.currentScene)
			self.currentScene:stop()
		end

		local sceneClass = require(sceneName)
		local scene = assert(sceneClass.new(data))
		self.currentScene = scene
		MOAIRenderMgr.setRenderTable(scene:getRenderTable())
		scene:start(self.engine)
		self.sceneBegin:fire(scene)
	end
end)
