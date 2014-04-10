local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local KeyCodes = require "jaeger.KeyCodes"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Manage scenes
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

		return self:pickEntityInRenderTable(renderTable, windowX, windowY, predicate)
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


	function i:pickEntityInRenderTable(renderTable, windowX, windowY, predicate)
		local numEntries = #renderTable
		for entryIndex = numEntries, 1, -1 do
			local renderPass = renderTable[entryIndex]
			local hit = true
			local hitTest = renderPass.hitTest
			if hitTest then
				hit = hitTest(renderPass, windowX, windowY)
			end
			if hit then
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
				elseif getmetatable(renderPass) == nil then--if renderPass is a table
					local entity, localX, localY = self:pickEntityInRenderTable(renderPass, windowX, windowY, predicate)
					if entity ~= nil then return entity, localX, localY end
				end
			end
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
end)
