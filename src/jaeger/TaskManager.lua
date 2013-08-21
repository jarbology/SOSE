local class = require "jaeger.Class"

return class(..., function(i)
	function i:__constructor(config)
		self.config = config.tasks
		self.root = MOAIAction.new()
		self.tasks = {}
	end

	function i:start(systems)
		MOAIActionMgr.setRoot(self.root)
		for _, taskDesc in ipairs(self.config) do
			local systemName, methodName = unpack(taskDesc)
			print("Spawning task "..systemName.."/"..methodName)
			local system = assert(systems[systemName], "Cannot locate system "..systemName)
			local task = MOAICoroutine.new()
			task:attach(self.root)
			system:setUpdateTask(methodName, task)
			local yield = coroutine.yield
			task:run(function()
				while true do
					system[methodName](system)
					yield()
				end
			end)
		end
	end
end)
