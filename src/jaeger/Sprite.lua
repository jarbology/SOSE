local class = require "jaeger.Class"

-- Creation parameters:
-- * name: name of the sprite
-- * autoPlay(optional): whether an animation should be played automatically
-- Messages:
-- * msgChangeSprite(spriteName): change the sprite
-- * msgPlayAnimation(): play the sprite
return class(..., function(i)
	function i:__constructor(data)
		local anim = MOAIAnim.new()
		anim:reserveLinks(1)

		self.anim = anim
		self.autoPlay = data.autoPlay
		self.spriteName = data.spriteName
	end

	function i:msgChangeSprite(spriteName)
		self.spriteName = spriteName
		local sprite = getAsset("sprite:"..spriteName)
		local prop = self.prop
		local anim = self.anim

		prop:setDeck(sprite.bank)
		prop:setIndex(sprite.firstFrame)
		anim:setLink(1, sprite.animCurve, prop, MOAIProp2D.ATTR_INDEX)
		anim:setMode(sprite.mode)
		anim:setSpeed(1 / sprite.animTime)

		if self.autoPlay then
			self.entity:sendMessage("msgPlayAnimation")
		end
	end

	function i:msgPlayAnimation()
		self.entity:sendMessage("msgPerformAction", self.anim)
	end

	function i:msgActivate()
		self.prop = assert(self.entity:query("getProp"), "Need a prop to play animation")
		self.entity:sendMessage("msgChangeSprite", self.spriteName)
	end
end)
