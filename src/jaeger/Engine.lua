-- protect global environment
setmetatable(_G, {
	__index = function(table, index)
		error("Trying to access non-existent global variable '" .. index.."'")
	end,
	__newindex = function()
		error "Cannot create global variable"
	end
})

local systems = {}

local function start(config)
	local AssetManager = require "jaeger.AssetManager"
	local assetManager = AssetManager.new(config)
	systems["jaeger.AssetManager"] = assetManager
	assetManager:start(systems)
	
	local systemModuleNames = config.systems
	for _, systemModuleName in ipairs(systemModuleNames) do
		local systemModule = require(systemModuleName)
		local systemInstance = systemModule.new(config)
		systems[systemModuleName] = systemInstance
	end

	for _, systemModuleName in ipairs(systemModuleNames) do
		print("Starting " .. systemModuleName)
		systems[systemModuleName]:start(systems)
	end

	return systems
end

local function getSystem(name)
	return systems[name]
end

return {
	start = start,
	getSystem = getSystem
}
