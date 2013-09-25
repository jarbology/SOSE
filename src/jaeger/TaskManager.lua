local class = require "jaeger.Class"
local StringUtils = require "jaeger.utils.StringUtils"

-- Create a task tree where each system is has its own tasks
-- And updated repeatedly
-- Relevant config keys:
--		* tasks: an array of tasks with the format: "SystemFQN/TaskName"
--		  TaskManager will call system:spawn<TaskName>() to spawn the task
--		  The method must return a MOAIAction
return class(..., function(i)
	function i:__constructor(config)
		self.root = MOAIStickyAction.new()
		self.tasks = {}
	end

	function i:start(engine, config)
		MOAIActionMgr.setRoot(self.root)
		for _, taskDesc in ipairs(config.tasks) do
			print("Spawning task ", taskDesc)
			local systemName, taskName = unpack(StringUtils.split(taskDesc, "/"))
			local system = assert(engine:getSystem(systemName), "Cannot locate system "..systemName)
			local task = assert(system["spawn"..taskName](system), "Cannot spawn task "..taskDesc)
			task:attach(self.root)
		end
	end
end)
