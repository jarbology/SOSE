local class = require "jaeger.Class"

-- Manage entities which gets updated every frame
-- Relevant config keys:
-- * updatePhases: an array of update phase names
return class(..., function(i, c)
	function i:getUpdatePhase(name)
		return self.updatePhases[name]
	end

	-- Private
	function i:__constructor(config)
		self.updateTreeConfig = config.updatePhases
	end

	function i:start(engine)
		engine:getSystem("jaeger.SceneManager").sceneEnd:addListener(self, "onSceneEnd")
	end

	function i:spawnUpdate()
		local updatePhases = {}
		local rootTask = MOAIAction.new()
		rootTask:setAutoStop(false)
		for _, updatePhase in ipairs(self.updateTreeConfig) do
			c.spawnUpdateTree(updatePhase, updatePhases, rootTask)
		end
		self.updatePhases = updatePhases
		self.rootTask = rootTask
		return rootTask
	end

	function i:onSceneEnd()
		for name, updatePhase in pairs(self.updatePhases) do
			if updatePhase.isLeaf then
				updatePhase:clear()
			end
		end
	end 

	function c.spawnUpdateTree(treeConfig, updatePhases, rootTask)
		local treeConfigType = type(treeConfig)
		if treeConfigType == "string" then --simple phase
			local updatePhase = MOAIAction.new()
			updatePhase:setAutoStop(false)
			updatePhases[treeConfig] = updatePhase
			updatePhase:attach(rootTask)
			updatePhase.isLeaf = true
		elseif treeConfigType == "table" then -- tree phase
			local updatePhaseName, childPhases = unpack(treeConfig)
			local updatePhase = MOAIAction.new()
			updatePhase:setAutoStop(false)
			updatePhases[updatePhaseName] = updatePhase
			updatePhase:attach(rootTask)
			updatePhase.isLeaf = false

			for _, childPhase in ipairs(childPhases) do
				c.spawnUpdateTree(childPhase, updatePhases, updatePhase)
			end
		end
	end
end)
