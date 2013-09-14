local class = require "jaeger.Class"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- Create a task tree where each system is has its own tasks
-- And updated repeatedly
-- Relevant config keys:
--		* tasks: an array of 2-tuple where
--			the first element is the system name
--			the second element is the method name
--		  This method will be called every frame
--		  When an update task is assigned to a system,
--		  system:setUpdateTask(methodName, task) will be called to inform
--		  the system of this task. It can choose to do nothing in this method
return class(..., function(i)
	function i:__constructor(config)
		self.config = config.tasks
		self.root = MOAIStickyAction.new()
		self.tasks = {}
	end

	function i:start(engine)
		MOAIActionMgr.setRoot(self.root)
		for _, taskDesc in ipairs(self.config) do
			local systemName, methodName = unpack(taskDesc)
			print("Spawning task "..systemName.."/"..methodName)
			local system = assert(engine:getSystem(systemName), "Cannot locate system "..systemName)
			local task = ActionUtils.newLoopCoroutine(system, methodName)
			system:setUpdateTask(methodName, task)
			task:attach(self.root)
		end
	end
end)
