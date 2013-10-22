local class = require "jaeger.Class"
local StringUtils = require "jaeger.utils.StringUtils"
local Event = require "jaeger.Event"

-- Manage and cache assets, also takes care of hot reloading
-- Relevant config keys:
--	* assets: a table which contains:
--		* assetsPath: a folder which holds non-code assets
--			          AssetManager will monitor this folder for
--			          changes
--		* various asset paths, categorized by type. Refer to
--			asset factory of that type for more information
--		* factories: a table which maps a asset type to a factory
--			         Each factory is a module with only one function:
--			         func(name, config, assetManager, oldInstance)
--			          name: name of the asset
--			          config: configuration table
--			          oldInstance: the old instance of the asset if
--			                          it was loaded before, used for reloading
return class(..., function(i)
	local moduleFactory
	function i:__constructor(config)
		self.config = config.assets
		self.cache = {}
		self.factories = {}
		self.resourceMap = {}
		self.moduleLoaded = Event.new()
	end

	function i:start(engine)
		local function loader(modulename)
			local errmsg = ""
			-- Find source
			local modulepath = string.gsub(modulename, "%.", "/")
			for path in string.gmatch(package.path, "([^;]+)") do
				local filename = string.gsub(path, "%?", modulepath)
				-- Compile and return the module
				if MOAIFileSystem.checkFileExists(filename) then
					self:mapResource("module:"..modulename, filename)
					local moduleFunc = assert(loadfile(filename))
					self.moduleLoaded:fire(modulename, moduleFunc)
					return moduleFunc
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

	-- Try to load an asset, will return a cached version if it's already loaded
	--	* name: Name of the asset, in the form: typeName:assetName. e.g: texture:test.png
	function i:getAsset(name)
		assert(type(name) == "string", "Asset name must be a string, given "..tostring(name).."("..type(name)..")")
		return self.cache[name] or self:loadAsset(name)
	end

	-- Force loading of an asset. Use if you want to force an asset to reload
	function i:loadAsset(name)
		local assetType, assetName = unpack(StringUtils.split(name, ":"))
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
