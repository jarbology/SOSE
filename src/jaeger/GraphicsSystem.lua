local class = require "jaeger.Class"
local Event = require "jaeger.Event"

-- Manages the window and sprites (soon will be moved to SpriteManager)
-- Component: jaeger.Sprite
-- Relevant entity spec:
--	* sprite: a table with the following keys:
--		* name: name of the sprite
--		* autoPlay: whether the sprite plays on created (not yet implemented)
-- Shared resources:
--	* prop: MOAIProp2D of the sprite
-- Messages:
--	* msgChangeSprite(spriteName): change the sprite
--	* msgPlayAnimation(): play the sprite
return class(..., function(i)
	function i:__constructor(config)
		self.config = config.graphics
	end

	--
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

			self:msgChangeSprite(component, entity, spriteSpec.name)
		end
	end

	function i:msgChangeSprite(component, entity, spriteName)
		local sprite = self.assetMgr:getAsset("sprite:"..spriteName)
		local prop = component.prop
		local anim = component.anim

		prop:setDeck(sprite.bank)
		prop:setIndex(sprite.firstFrame)
		anim:setLink(1, sprite.animCurve, prop, MOAIProp2D.ATTR_INDEX)
		anim:setMode(sprite.mode)
		anim:setSpeed(1 / sprite.animTime)
	end

	function i:msgPlayAnimation(component, entity)
		local updateAction = assert(
			entity:getResource("updateAction"),
			"Only active entity can play animation"
		)
		component.anim:start(updateAction)
	end
end)
