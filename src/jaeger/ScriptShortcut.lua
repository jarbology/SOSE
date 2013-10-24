local class = require "jaeger.Class"

return class(..., function(i)
	function i:start(engine, config)
		local assetMgr = engine:getSystem("jaeger.AssetManager")
		engine:getSystem("jaeger.AssetManager").moduleLoaded:addListener(self, "onModuleLoaded")
		local entityMgr = engine:getSystem("jaeger.EntityManager")
		local sceneMgr = engine:getSystem("jaeger.SceneManager")
		local shortcutEnv = {
			getAsset = function(...)
				return assetMgr:getAsset(...)
			end,

			createEntity = function(...)
				return entityMgr:createEntity(...)
			end,

			destroyEntity = function(...)
				return entityMgr:destroyEntity(...)
			end,

			changeScene = function(...)
				return sceneMgr:changeScene(...)
			end,

			getCurrentScene = function()
				return sceneMgr:getCurrentScene()
			end
		}

		self.shortcutEnv = setmetatable(shortcutEnv, {__index = _G, __newindex = _G})
		self.shortcutEnabled = {}
	end

	function i:enableShortcut(moduleName)
		self.shortcutEnabled[moduleName] = true
	end

	function i:onModuleLoaded(name, module)
		if self.shortcutEnabled[name] then
			setfenv(module, self.shortcutEnv)
		end
	end
end)
