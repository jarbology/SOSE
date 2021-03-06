local class = require "jaeger.Class"
local AssetManager = require "jaeger.AssetManager"

-- Manages systems, provide a hub where systems can find each other
return class(..., function(i)
	function i:__constructor()
		self.systems = {}
	end

	-- Start the engine with the given configurations
	-- Relevant keys:
	--	* systems: an array of fully qualified system names
	--	           systems will be initialized in this order
	-- A system needs the following methods:
	-- __constructor(config):
	--		* config is the same config table passed into Engine.start
	-- start(engine, config)
	--		* engine points to the engine instance that initialized this sytem
	--		* config is the config table passed into Engine.start
	function i:start(config)
		-- AssetManager is a special system
		local assetManager = AssetManager.new(config)
		self.systems["jaeger.AssetManager"] = assetManager
		assetManager:start(self.systems)

		-- protect global environment
		setmetatable(_G, {
			__index = function(table, index)
				error("Trying to access non-existent global variable '" .. index.."'", 2)
			end,
			__newindex = function(table, index)
				error("Cannot create global variable "..index, 2)
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

	-- Retrieves a system using it's FQN (fully qualified name)
	function i:getSystem(name)
		return self.systems[name]
	end
end)
