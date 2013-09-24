local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local StreamUtils = require "jaeger.utils.StreamUtils"
local ActionUtils = require "jaeger.utils.ActionUtils"

-- This system keeps the locked phase synchronized across the network
-- and ensures determinism of simulation
-- Relevant config keys:
-- * lockstepSim: a table with the following keys:
--	* lockedPhase: name of the update phase to synchronize
--	* samplingInterval: how often should commands be sent to server
-- Events:
--	* sample(): fired everytime LockstepSim starts to sample the command streams
return class(..., function(i)
	-- Set the command stream
	-- Must be called once before unpausing LockstepSim
	function i:setCommandStream(stream)
		self.cmdStream = stream
	end

	-- Set the command interpreter
	-- Must be called once before unpausing LockstepSim
	-- interpreter(playerId, cmd) will be called for every command
	function i:setInterpreter(interpreter)
		self.interpreter = interpreter
	end

	-- Start the simulation
	function i:startSim()
		if self.updateTask then return end

		local updateTask = ActionUtils.newLoopCoroutine(self, "update")
		updateTask:attach(self.rootTask)
		self.updateTask = updateTask
	end

	-- Stop the simulation
	function i:stopSim()
		if self.updateTask then
			self.updateTask:stop()
			self.updateTask = nil
		end
	end

	-- Private

	function i:__constructor(config)
		self.sample = Event.new()

		local config = config.lockstepSim
		self.samplingInterval = config.samplingInterval
		self.lockedPhaseName = config.lockedPhase
	end

	function i:start(engine, config)
		self.entityMgr = engine:getSystem("jaeger.EntityManager")
		engine:getSystem("jaeger.SceneManager").sceneEnd:addListener(self, "onSceneEnd")
	end

	function i:onSceneEnd()
		self:stopSim()
		self:setInterpreter(nil)
		self:setCommandStream(nil)
	end

	function i:spawnTask(taskName)
		assert(taskName == "update", "Unknown task")

		local task = MOAIStickyAction.new()
		self.rootTask = task
		return task
	end

	function i:update()
		self.sample:fire()
		-- wait for the next frame to continue sampling
		ActionUtils.skipFrames(self.samplingInterval - 1)

		-- pause the locked phase
		local lockedPhase = self:getLockedPhase()
		lockedPhase:pause(true)

		-- wait for commands
		local commands = StreamUtils.blockingPull(self.cmdStream)
		local interpreter = self.interpreter
		for playerId, command in pairs(commands) do
			interpreter(playerId, command)
		end

		-- allow game to update
		lockedPhase:pause(false)
	end

	function i:getLockedPhase()
		local lockedPhase = self.lockedPhase
		if lockedPhase == nil then
			lockedPhase = assert(self.entityMgr:getUpdatePhase(self.lockedPhaseName), "Can't find phase "..self.lockedPhaseName)
			self.lockedPhase = lockedPhase
		end
		return lockedPhase
	end
end)
