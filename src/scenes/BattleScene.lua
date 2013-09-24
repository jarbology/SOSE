local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"
local Networking = require "Networking"
local CmdInterpreter = require "CmdInterpreter"

return class(..., function(i, c)
	-- Private
	function i:__constructor(mode)
		self.mode = mode
		self.renderTable = {}
		self.layerMap = {}

		local width, height = MOAIGfxDevice.getViewSize()
		width = width / 2
		local leftViewport = MOAIViewport.new()
		leftViewport:setSize(0, 0, width, height)
		leftViewport:setScale(width, height)
		self:newZone(leftViewport, 1)

		local rightViewport = MOAIViewport.new()
		rightViewport:setOffset(1, 0)
		rightViewport:setSize(width, 0, width * 2, height)
		rightViewport:setScale(width, height)
		self:newZone(rightViewport, 2)

		self:newRenderPass("overlay", RenderUtils.newFullScreenLayer())
	end

	function i:newZone(viewport, suffix)
		self:newLayer("background"..suffix, viewport)
		self:newLayer("ground"..suffix, viewport)
		self:newLayer("building"..suffix, viewport)
		self:newLayer("projectile"..suffix, viewport)
		self:newLayer("artificialFog"..suffix, viewport)
		self:newLayer("fog"..suffix, viewport)
	end

	function i:newLayer(name, viewport)
		self:newRenderPass(name, c.newLayer(viewport))
	end

	function i:newRenderPass(name, renderPass)
		table.insert(self.renderTable, renderPass)
		self.layerMap[name] = renderPass
	end

	function c.newLayer(viewport)
		local layer = MOAILayer2D.new()
		layer:setSortMode(MOAILayer2D.SORT_NONE)
		layer:setViewport(viewport)
		return layer
	end

	function i:start(engine, sceneTask)
		MOAISim.clearLoopFlags()
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_ALLOW_SPIN)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_SURPLUS)
		MOAISim.setLoopFlags(MOAISim.SIM_LOOP_NO_DEFICIT)

		local lockstepSim = engine:getSystem("jaeger.LockstepSim")
		local noopMsg = CmdInterpreter.commandCodes.noop
		local cmdInterpreter = CmdInterpreter.new()
		lockstepSim:setInterpreter(cmdInterpreter:getInterpretFunc())

		if self.mode == "host" then
			local client, server, serverSkt = Networking.initHost(lockstepSim, noopMsg)
			client:start():attach(sceneTask)
			server:start():attach(sceneTask)
			self.client = client
			self.server = server
			self.serverSkt = serverSkt
		elseif self.mode == "join" then
			local client = Networking.initJoin(lockstepSim, noopMsg)
			client:start():attach(sceneTask)
			self.client = client
		elseif self.mode == "combo" then
			local client1, client2, server = Networking.initCombo(lockstepSim, noopMsg)
			client1:start():attach(sceneTask)
			client2:start():attach(sceneTask)
			server:start():attach(sceneTask)
			self.client = client1
			self.client2 = client2
			self.server = server
		end

		local entityMgr = engine:getSystem("jaeger.EntityManager")
		entityMgr:createEntity{
			components = {
				["jaeger.Renderable"] = {
					layer = "background1"
				},

				["jaeger.Background"] = {
					texture = "bg1.png",
					width = 2000,
					height = 2000
				}
			}
		}
		entityMgr:createEntity{
			components = {
				["jaeger.Renderable"] = {
					layer = "background2"
				},

				["jaeger.Background"] = {
					texture = "bg1.png",
					width = 2000,
					height = 2000
				}
			},
		}
	end

	function i:stop()
		if self.server then
			self.server:stop()
		end

		if self.client then
			self.client:stop()
		end

		if self.client2 then
			self.client2:stop()
		end

		if self.serverSkt then
			self.serverSkt:shutdown()
		end
	end

	function i:onKey(keycode, down)
	end

	function i:getRenderTable()
		return self.renderTable
	end

	function i:getLayer(name)
		return self.layerMap[name]
	end
end)
