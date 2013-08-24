local class = require "jaeger.Class"

-- Manage and cache assets, also takes care of hot reloading
return class(..., function(i)
	local moduleFactory

	function i:__constructor(config)
		self.config = config.assets
		self.cache = {}
		self.factories = {}
		self.resourceMap = {}
	end

	function i:start(engine)
		local function loader(modulename)
			local errmsg = ""
			-- Find source
			local modulepath = string.gsub(modulename, "%.", "/")
			for path in string.gmatch(package.path, "([^;]+)") do
				local filename = string.gsub(path, "%?", modulepath)
				self:mapResource("module:"..modulename, filename)
				-- Compile and return the module
				if MOAIFileSystem.checkFileExists(filename) then
					return assert(loadfile(filename))
				end
				errmsg = errmsg.."\n\tno file '"..filename.."' (checked with custom loader)"
			end
			return errmsg
		end

		-- Load built-in modules which create global variable
		-- TODO: figure out a more elegant way to do this
		require "socket"
		require "lfs"

		-- register custom loader and make loaded modules sticky
		table.insert(package.loaders, 2, loader)
		for moduleName, module in pairs(package.loaded) do
			package.preload[moduleName] = function()
				return module
			end
		end

		-- register module factory and override the require function
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

		local function onFileChanged(watchId, directory, filename, action)
			self:onFileChanged(watchId, directory, filename, action)
		end

		Titan.addWatch(".", onFileChanged)
		Titan.addWatch(self.config.assetsPath, onFileChanged)
	end

	function i:onFileChanged(watchId, directory, filename, action)
		if action == Titan.FILE_ACTION_MODIFY then --only reload when a file is edited
			local absPath = MOAIFileSystem.getAbsoluteFilePath(directory.."/"..filename)
			print(absPath.." changed")
			for filePath, resourceName in pairs(self.resourceMap) do
				if filePath == absPath then
					local oldInstance = self.cache[resourceName]
					if oldInstance then --only reload when it's still active
						print("Reloading "..resourceName)
						self:loadAsset(resourceName)
						return
					end
				end
			end
			print("Don't know what to do")
		end
	end

	function i:mapResource(resourceName, filePath)
		local absPath = MOAIFileSystem.getAbsoluteFilePath(filePath)
		self.resourceMap[absPath] = resourceName
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
		self.cache[name] = asset

		-- watch files
		if type(files) == 'table' then
			for _, filename in ipairs(files) do
				-- the resourceMap may grow indefinetly but whatever
				self:mapResource(name, filename)
			end
		end

		return asset
	end
end)
