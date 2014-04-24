local class = require "jaeger.Class"
local Property = require "jaeger.Property"

-- Take damage and destroy itself once it runs out of health
-- Parameters:
-- * hp(property<number>)
-- * maxHP(property<number>)
return class(..., function(i)
	function i:__constructor(data)
		self.hp = Property.new(data.hp or 1)
		self.maxHP = Property.new(data.hp or 1)
	end

	function i:msgActivate()
		self.prop = self.entity:query("getProp")
	end

	-- Get current hp
	function i:getHP()
		return self.hp
	end

	-- Get max hp
	function i:getMaxHP()
		return self.maxHP
	end

	-- Deal damage and destroy the entity if hp <= 0
	function i:msgDealDamage(dmg)
		if dmg==nil then
			print(debug.traceback())
		end
		if self.prop then
			local damageText = createEntity{
				{"jaeger.Actor", phase="visual"},
				{"jaeger.Renderable", color={1, 0, 0, 1}, layer=self.prop.layer},
				{"jaeger.Text", rect={-13, -13, 13, 13},
				                text="-"..dmg,
				                font="karmatic_arcade.ttf",
				                alignment={MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY},
				                size=12},
				{"DamageText"}
			}
			damageText:query("getProp"):setLoc(self.prop:getLoc())
		end

		local hp = self.hp:get() - dmg
		self.hp:set(hp)
		local hitAudio
		if hp <= 0 then
			hitAudio = getAsset("audio:building_destroyed.wav")
			destroyEntity(self.entity)
		else
			hitAudio = getAsset("audio:building_hit.wav")
		end
		if not hitAudio:isPlaying() then
			hitAudio:play()
		end
	end
end)
