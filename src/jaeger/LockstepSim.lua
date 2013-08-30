local class = require "jaeger.Class"
local Queue = require "jaeger.Queue"

-- This system keeps the locked phase synchronized across the network
-- and ensures determinism of simulation
-- It manages multiple command queues which are polled every update
-- A command is of the form:
--	* {cmdName, ...}: see below for explanation
--  * nil: noop, ignored
-- Relevant config keys:
-- * lockstepSim: a table with the following keys:
--	* lockedPhase: name of the update phase to synchronize
--	* queues: an array of command queue names
--	* interpreter: FQN of a system which will interpret the commands
--	  interpreter:cmdName(queueName, ...) will be called for every command
return class(..., function(i)
	-- Retrieve a command queue
	function i:getCmdQueue(name)
		return self.queues[name]
	end

	-- Private

	function i:__constructor(config)
		self.lockedPhaseName = config.lockstepSim.lockedPhase
		local queues = {}
		for _, queueName in ipairs(config.lockstepSim.queues) do
			queues[queueName] = Queue.new()
		end
		self.queues = queues
	end

	function i:start(engine, config)
		self.interpreter = assert(engine:getSystem(config.lockstepSim.interpreter), "Can't locate interpreter")
		self.entityMgr = engine:getSystem("jaeger.EntityManager")
	end

	function i:setUpdateTask(methodName, task)
	end

	function i:update()
		local lockedPhase = self:getLockedPhase()
		local yield = coroutine.yield
		local interpreter = self.interpreter
	
		-- first, pause the locked phase
		lockedPhase:pause(true)

		-- spinlock loop
		while true do
			-- check if all queues are ready
			local wait = false
			for name, queue in pairs(self.queues) do
				if queue:isEmpty() then
					wait = true
					break
				end
			end

			if wait then
				yield() -- spin
			else
				for name, queue in pairs(self.queues) do
					local cmd = queue:dequeue()
					if cmd then
						local cmdName = cmd[1]
						interpreter[cmdName](interpreter, name, select(2, unpack(cmd)))
					end
				end
				break
			end
		end

		-- allow game to update
		lockedPhase:pause(false)
	end

	function i:getLockedPhase()
		local lockedPhase = self.lockedPhase
		if lockedPhase == nil then
			lockedPhase = self.entityMgr:getUpdatePhase(self.lockedPhaseName)
			self.lockedPhase = lockedPhase
		end
		return lockedPhase
	end
end)
