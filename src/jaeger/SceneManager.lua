local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local KeyCodes = require "jaeger.KeyCodes"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Manage scenes
-- Component: jaeger.Renderable
-- Relevant entity specs:
--	* layer: name of the layer this entity will be rendered in
-- Events:
--	* sceneBegin(scene): fired at the beginning of a scene.
--	* sceneEnd(scene): fired at the end of a scene
return class(..., function(i)
	-- Change to a scene
	--	* sceneName: name of the scene class
	--	* data: userdata to pass to the scene
	-- A scene must have:
	-- __constructor(data): where data is the data passed in earlier
	-- start(engine, task): initialize the scene. task is the scene manager's update task.
	--                      The scene can use it as parent for its own update task(s)
	-- getRenderTable(): returns a Moai render table (see MOAIRenderMgr)
	-- getLayer(name): return the layer with the given name or nil
	function i:changeScene(sceneName, data)
		self.nextScene = sceneName
		self.nextSceneData = data
	end

	-- Private
	function i:__constructor(config)
		self.reloadKeyName = config.sceneManager.reloadKey
		self.currentScene = nil
		self.sceneBegin = Event.new()
		self.sceneEnd = Event.new()
	end

	function i:start(engine)
		self.engine = engine
		engine:getSystem("jaeger.EntityManager").entityCreated:addListener(self, "onEntityCreated")
		engine:getSystem("jaeger.InputSystem").keyboard:addListener(self, "onKey")
	end

	function i:onEntityCreated(entity, spec)
		if spec.layer then
			entity:addComponent{
				system = self,
				name = "jaeger.Renderable"
			}
		end
	end

	function i:onKey(keycode, down)
		if not down and keycode == KeyCodes[self.reloadKeyName] then
			self:changeScene(self.currentSceneName, self.currentSceneData)
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

	function i:spawnTask(taskName)
		if taskName == "update" then
			local task = ActionUtils.newLoopCoroutine(self, "update")
			self.updateTask = task
			return task
		end
	end

	function i:update()
		if self.nextScene then
			local sceneName = self.nextScene
			local data = self.nextSceneData
			self.nextScene = nil
			self.nextSceneData = nil

			if self.currentScene then
				print("Ending scene:", self.currentSceneName)
				self.sceneEnd:fire(self.currentScene)
				self.currentScene:stop()
				self.updateTask:clear()
			end

			self.currentSceneName = sceneName
			self.currentSceneData = data

			print("Starting scene:", sceneName)
			local sceneClass = require(sceneName)
			local scene = assert(sceneClass.new(data))
			self.currentScene = scene
			MOAIRenderMgr.setRenderTable(scene:getRenderTable())
			scene:start(self.engine, self.updateTask)
			self.sceneBegin:fire(scene)
		end
	end
end)
