local class = require "jaeger.Class"
local socket = require "socket"

-- Open a remote console which let user enter a command and see it execute
-- Relevant config keys
--	* config: a table with the following keys:
--		* port: the port to open a listening UDP socket
--		* setupScript: the script to setup the console environment
-- Tasks:
--  * update
return class(..., function(i)
	function i:__constructor(config)
		self.setupScript = assert(loadfile(config.console.setupScript))
	end

	function i:start(engine, config)
		local socket = assert(socket.udp())
		socket:setsockname('*', config.console.port)
		socket:settimeout(0)
		self.socket = socket
		self.environments = {}
		self.engine = engine
	end

	function i:setUpdateTask()
	end

	local getEnv, processCmdResult
	function i:update()
		local socket = self.socket
		local cmd, ipOrError, port = socket:receivefrom()

		if cmd then
			if cmd:sub(1, 1) == '=' then
				cmd = "return "..cmd:sub(2)
			end
			local clientId = ipOrError..":"..port
			local cmdFunc, error = loadstring(cmd, clientId)
			if cmdFunc then
				setfenv(cmdFunc, getEnv(self, clientId, ipOrError, port))
				processCmdResult(self, ipOrError, port, xpcall(cmdFunc, debug.traceback))
			else
				socket:sendto(error, ipOrError, port)
			end
			socket:sendto("\n", ipOrError, port)
		elseif ipOrError ~= 'timeout' then
			print("Socket error: "..ipOrError)
		end
	end

	local send
	processCmdResult = function(self, ip, port, success, ...)
		local socket = self.socket
		if success then
			send(self.socket, ip, port, ...)
		else
			local error = ...
			socket:sendto(error, ip, port)
		end
	end

	local envMt = {__index = _G}
	getEnv = function(self, clientId, ip, port)
		local env = self.environments[clientId]

		if env == nil then
			env = {
				engine = self.engine,
				print = function(...)
					send(self.socket, ip, port, ...)
					send(self.socket, ip, port, "\n")
				end
			}
			setmetatable(env, envMt)
			self.environments[clientId] = env
			setfenv(self.setupScript, env)
			self.setupScript()
		end

		return env
	end

	send = function(socket, ip, port, ...)
		local numValues = select('#', ...)
		local values = {...}
		local first = true
		for index = 1, numValues do
			socket:sendto(tostring(values[index]), ip, port)
			if not first then
				socket:sendto("\t", ip, port)
			end
			first = false
		end
	end
end)
