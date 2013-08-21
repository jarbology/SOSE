local class = require "jaeger.Class"

return class(..., function(i)
	local moduleFactory

	function i:__constructor(config)
		self.config = config.assets
		self.cache = setmetatable({}, {__mode = "v"})
		self.factories = {}
	end

	function i:start(systems)
		-- register module factory
		local oldRequire = require
		_G.require = function(modName)
			return self:getAsset("module:"..modName)
		end
		self.factories.module = function(name)
			package.loaded[name] = nil
			return oldRequire(name)
		end

		-- register other factories
		for assetType, assetFactoryName in pairs(self.config.factories) do
			self.factories[assetType] = require(assetFactoryName)
		end
	end

	function i:getAsset(name)
		assert(type(name) == "string", "Asset name must be a string, given "..tostring(name).."("..type(name)..")")
		return self.cache[name] or self:loadAsset(name)
	end

	function i:loadAsset(name)
		local colonPos = name:find(":")
		local assetType = name:sub(1, colonPos - 1)
		local assetName = name:sub(colonPos + 1)
		local factory = assert(self.factories[assetType], "Unknown asset type "..assetType)
		local asset, files = assert(factory(assetName, self.config, self, self.cache[name]))
		print("Loaded "..name)
		--TODO: watch files
		self.cache[name] = asset

		return asset
	end
end)
