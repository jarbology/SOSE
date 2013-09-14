local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- This system keeps the locked phase synchronized across the network
-- and ensures determinism of simulation
-- It manages multiple command streams which are polled every update
-- Relevant config keys:
-- * lockstepSim: a table with the following keys:
--	* lockedPhase: name of the update phase to synchronize
--	* streams: an array of command stream names
-- Events:
--	* sample(): fired everytime LockstepSim starts to sample the command streams
return class(..., function(i)
	-- Register a command stream
	function i:registerCmdStream(name, stream)
		self.streams[name] = stream
	end

	-- Set the command interpreter
	-- interpreter(cmd) will be called for every command
	function i:setInterpreter(interpreter)
		self.interpreter = interpreter
	end

	-- Pause/unpause the simulation
	-- Paused by default
	function i:pause(status)
		self.updateTask:pause(status)
	end

	-- Private

	function i:__constructor(config)
		local config = config.lockstepSim
		self.samplingInterval = config.samplingInterval
		self.lockedPhaseName = config.lockedPhase
		self.streamNames = config.streams
		self.streams = {}
		self.sample = Event.new()
	end

	function i:start(engine, config)
		self.entityMgr = engine:getSystem("jaeger.EntityManager")
	end

	function i:setUpdateTask(methodName, task)
		self.updateTask = task
		self:pause(true)
	end

	function i:doSample()
	end

	function i:update()
		self.sample:fire()
		-- wait for the next frame to continue sampling
		local frameSkipped = 1
		local interval = self.samplingInterval
		local yield = coroutine.yield
		while frameSkipped < interval do
			yield()
			frameSkipped = frameSkipped + 1
		end

		local lockedPhase = self:getLockedPhase()
		local interpreter = self.interpreter
	
		-- first, pause the locked phase
		lockedPhase:pause(true)

		-- spinlock until all streams are ready
		for name, stream in pairs(self.streams) do
			while not stream:hasData() do
				yield()
				print 'pause!'
			end
		end

		if(self.streams[1].queue) then
			print(self.streams[1].queue:getSize(), self.streams[2].queue:getSize())
		end
		-- when all streams are ready
		for _, streamName in pairs(self.streamNames) do
			local stream = self.streams[streamName]
			local cmd = stream:take()
			interpreter(streamName, cmd)
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
