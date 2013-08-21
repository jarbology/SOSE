local class = require "jaeger.Class"
local AssetManager = require "jaeger.AssetManager"

return class(..., function(i)
	function i:__constructor()
		self.systems = {}
	end

	function i:start(config)
		-- AssetManager is a special system
		local assetManager = AssetManager.new(config)
		self.systems["jaeger.AssetManager"] = assetManager
		assetManager:start(self.systems)

		-- protect global environment
		setmetatable(_G, {
			__index = function(table, index)
				error("Trying to access non-existent global variable '" .. index.."'")
			end,
			__newindex = function(table, index)
				error("Cannot create global variable "..index)
			end
		})
		
		-- Load all systems
		local systems = self.systems
		local systemModuleNames = config.systems
		for _, systemModuleName in ipairs(systemModuleNames) do
			local systemModule = require(systemModuleName)
			local systemInstance = systemModule.new(config)
			systems[systemModuleName] = systemInstance
		end

		for _, systemModuleName in ipairs(systemModuleNames) do
			print("Starting " .. systemModuleName)
			systems[systemModuleName]:start(self, config)
		end
	end

	function i:getSystem(name)
		return self.systems[name]
	end
end)
