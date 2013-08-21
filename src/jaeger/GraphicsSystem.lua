local class = require "jaeger.Class"
local Event = require "jaeger.Event"

return class(..., function(i)
	function i:__constructor(config)
		self.config = config.graphics
	end

	function i:start(systems)
		local config = self.config
		self.assetMgr = systems["jaeger.AssetManager"]
		MOAISim.openWindow(config.title, config.windowWidth, config.windowHeight)

		systems["jaeger.EntityManager"].entityCreated:addListener(Event.makeListener(self, "onEntityCreated"))
	end

	function i:onEntityCreated(entity, spec)
		local spriteSpec = spec.sprite
		if spriteSpec then
			local spriteName = spriteSpec.name
			local prop = MOAIProp2D.new()
			local anim = MOAIAnim.new()
			anim:reserveLinks(1)

			entity:addComponent{
				system = self,
				name = "jaeger.Sprite",
				prop = prop,
				anim = anim
			}

			entity:registerResource("prop", prop)
		end
	end

	function i:activateEntity(component, entity)
		local sprite = self.assetMgr:getAsset("sprite:"..entity:getSpec().sprite.name)
		local prop = component.prop
		prop:setDeck(sprite.bank)
		prop:setIndex(sprite.firstFrame)
		component.sprite = sprite
	end

	function i:playAnimation(component, entity)
		local anim = component.anim
		local sprite = component.sprite
		anim:setLink(1, sprite.animCurve, component.prop, MOAIProp2D.ATTR_INDEX)
		anim:setMode(sprite.mode)
		anim:start(entity:getResource("updateAction"))
	end
end)
