local class = require "jaeger.Class"

-- Create a task tree where each system is has its own tasks
-- And updated repeatedly
-- Relevant config keys:
--		* tasks: an array where
--			the first element is the system name
--			the following elements describe the task in an arbitrary manner
--		  TaskManager will call system:spawnTask(...) with arguments in the array (except the first one)
--		  The method must return a MOAIAction
return class(..., function(i)
	function i:__constructor(config)
		self.config = config.tasks
		self.root = MOAIStickyAction.new()
		self.tasks = {}
	end

	function i:start(engine)
		MOAIActionMgr.setRoot(self.root)
		for _, taskDesc in ipairs(self.config) do
			local systemName = taskDesc[1]
			print("Spawning task ", unpack(taskDesc))
			local system = assert(engine:getSystem(systemName), "Cannot locate system "..systemName)
			local task = assert(system:spawnTask(select(2, unpack(taskDesc))), "Cannot spawn task")
			task:attach(self.root)
		end
	end
end)
