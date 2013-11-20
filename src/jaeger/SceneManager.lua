local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local KeyCodes = require "jaeger.KeyCodes"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Manage scenes
-- Manage jaeger.Renderable
-- Creation parameters:
-- * layer: name of the layer this entity will be rendered in
-- * x (optional)
-- * y (optional)
-- * xScale (optional)
-- * yScale (optional)
-- * rotation (optional)
-- Events:
-- * sceneBegin(scene): fired at the beginning of a scene.
-- * sceneEnd(scene): fired at the end of a scene
return class(..., function(i, c)
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

	-- Get the current scene
	function i:getCurrentScene()
		return self.currentScene
	end

	function i:pickFirstEntityAt(windowX, windowY, predicate)
		local renderTable = self.renderTable
		if not renderTable then return end

		for _, renderPass in ipairs(renderTable) do
			-- if the render pass is a layer
			if renderPass.wndToWorld then
				local localX, localY = renderPass:wndToWorld(windowX, windowY)
				local partition = renderPass:getPartition()
				if partition then
					local entity = c.pickFirstProp(predicate, partition:propListForPoint(localX, localY))
					if entity then
						return entity, localX, localY
					end
				end
			end
		end
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
		self.scriptShortcut = engine:getSystem("jaeger.ScriptShortcut")
		engine:getSystem("jaeger.InputManager").keyboard:addListener(self, "onKey")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Renderable", self, "createRenderable")
	end

	function i:onKey(keycode, down)
		if not down and keycode == KeyCodes[self.reloadKeyName] then
			self:changeScene(self.currentSceneName, self.currentSceneData)
		end
	end

	function i:spawnUpdate()
		local task = ActionUtils.newLoopCoroutine(self, "update")
		self.updateTask = task
		return task
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
			self.scriptShortcut:enableShortcut(sceneName)
			local sceneClass = require(sceneName)
			local scene = assert(sceneClass.new(data))
			self.currentScene = scene
			local renderTable = scene:getRenderTable()
			MOAIRenderMgr.setRenderTable(renderTable)
			self.renderTable = renderTable -- save for entity picking
			scene:start(self.engine, self.updateTask)
			self.sceneBegin:fire(scene)
		end
	end

	function c.pickFirstProp(predicate, prop, ...)
		if prop and prop.entity then
			if predicate(prop.entity) then
				return prop.entity
			else
				return c.pickFirstProp(predicate, ...)
			end
		end
	end

	-- jaeger.Renderable
	function i:createRenderable(entity, data)
		local prop = MOAIProp2D.new()
		prop.entity = entity
		prop:setLoc(data.x or 0, data.y or 0)
		prop:setScl(data.xScale or 1, data.yScale or 1)
		prop:setRot(data.rotation or 0)

		return {
			prop = prop,
			layerName = assert(data.layer, "No layer specified")
		}
	end

	function i:getProp(component, entity)
		return component.prop
	end

	function i:msgLink(component, entity, child, linkSpec)
		local childProp = assert(child:query("getProp"), "Need a prop to be linked")
		local parent = component.prop

		for _, linkPair in ipairs(linkSpec) do
			local srcAttr, dstAttr = unpack(linkPair)
			childProp:setAttrLink(srcAttr, parent, dstAttr)
		end
	end

	function i:msgActivate(component, entity)
		local layerName = component.layerName
		local prop = component.prop
		local layer = assert(self.currentScene:getLayer(component.layerName), "Cannot find layer '"..layerName.."' in current scene")
		layer:insertProp(component.prop)
		prop.layer = layer
	end

	function i:msgDestroy(component, entity)
		local layerName = component.layerName
		local prop = component.prop
		self.currentScene:getLayer(layerName):removeProp(prop)
	end

	function i:getLayerName(component)
		return component.layerName
	end
end)
