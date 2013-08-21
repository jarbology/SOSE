local class = require "jaeger.Class"
local Event = require "jaeger.Event"

return class(..., function(i)
	function i:__constructor(config)
		self.config = config.graphics
	end

	function i:start(engine)
		local config = self.config
		self.assetMgr = engine:getSystem("jaeger.AssetManager")
		MOAISim.openWindow(config.title, config.windowWidth, config.windowHeight)

		engine:getSystem("jaeger.EntityManager").entityCreated:addListener(self, "onEntityCreated")
	end

	function i:onEntityCreated(entity, spec)
		local spriteSpec = spec.sprite
		if spriteSpec then
			local prop = MOAIProp2D.new()
			prop.entity = entity

			local anim = MOAIAnim.new()
			anim:reserveLinks(1)

			local component = {
				system = self,
				name = "jaeger.Sprite",
				prop = prop,
				anim = anim
			}
			entity:addComponent(component)

			entity:registerResource("prop", prop)

			self:changeSprite(component, entity, spriteSpec.name)
		end
	end

	function i:changeSprite(component, entity, spriteName)
		local sprite = self.assetMgr:getAsset("sprite:"..spriteName)
		local prop = component.prop
		local anim = component.anim

		prop:setDeck(sprite.bank)
		prop:setIndex(sprite.firstFrame)
		anim:setLink(1, sprite.animCurve, prop, MOAIProp2D.ATTR_INDEX)
		anim:setMode(sprite.mode)
	end

	function i:playAnimation(component, entity)
		local updateAction = assert(
			entity:getResource("updateAction"),
			"Only active entity can play animation"
		)
		component.anim:start(updateAction)
	end
end)
