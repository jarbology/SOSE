local class = require "jaeger.Class"

-- Manage jaeger.Sprite
-- Creation parameters:
-- * name: name of the sprite
-- * autoPlay(optional): whether an animation should be played automatically
-- Messages:
-- * msgChangeSprite(spriteName): change the sprite
-- * msgPlayAnimation(): play the sprite
return class(..., function(i)
	function i:start(engine)
		self.assetMgr = engine:getSystem("jaeger.AssetManager")
		engine:getSystem("jaeger.EntityManager"):registerComponent("jaeger.Sprite", self, "createSprite")
	end

	function i:createSprite(entity, data)
		local anim = MOAIAnim.new()
		anim:reserveLinks(1)

		return {
			anim = anim,
			autoPlay = data.autoPlay,
			spriteName = data.spriteName
		}
	end

	function i:msgChangeSprite(component, entity, spriteName)
		component.spriteName = spriteName
		local sprite = self.assetMgr:getAsset("sprite:"..spriteName)
		local prop = component.prop
		local anim = component.anim

		prop:setDeck(sprite.bank)
		prop:setIndex(sprite.firstFrame)
		anim:setLink(1, sprite.animCurve, prop, MOAIProp2D.ATTR_INDEX)
		anim:setMode(sprite.mode)
		anim:setSpeed(1 / sprite.animTime)
		anim:setTime()

		if component.autoPlay then
			entity:sendMessage("msgPlayAnimation")
		end
	end

	function i:msgPlayAnimation(component, entity)
		entity:sendMessage("msgPerformAction", component.anim)
	end

	function i:msgActivate(component, entity)
		component.prop = assert(entity:query("getProp"), "Need a prop to play animation")
		entity:sendMessage("msgChangeSprite", component.spriteName)
	end
end)
